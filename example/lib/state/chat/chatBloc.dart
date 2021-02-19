import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';

import '../../api/endpoints/chatApi.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../util/chat_functions.dart';
import '../store/pollarStoreBloc.dart';
import 'chatEvent.dart';
import 'chatState.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState>{

  //Pollar store singleton
  static final ChatBloc _store = ChatBloc._internal();

  //Private constructor to innitialize the singleton
  ChatBloc._internal();

  factory ChatBloc(){
    return _store;
  }

  //Drains the login bloc singleton
  static void drainSington() {
    _store.drain();
  }

  @override
  ChatState get initialState => ChatState.initial();

  @override
  Stream<ChatState> mapEventToState(ChatEvent event) async* {
    if(event is InitializeChatBlocEvent){
      yield* _mapInitBlocToState(event.loginUserId);
    }
    else if(event is ClearChatBlocEvent){
      //reset chat state
      yield initialState;
    }
    else if(state.isInitialized){
      //Initialized chat state events
      if(event is InitChatEvent){
        //intiailized the chat in state
        yield* _mapInitChatToState(event.chat);
      }
      else if(event is StoreChatEvent){
        //Stores the chat to the state
        yield* _mapStoreToState(event.chat);
      }
      else if(event is CreateChatEvent){
        //Creates a chat, intializes it and adds it to the state
        yield* _mapCreateChatToState(event.chat, onSuccess: event.onSuccess);
      }
      else if(event is MessageEvent){
        //Sends a message to defined chat and pushes the message through the chat stream
        yield* _mapMessageToState(event.chatId, event.message);
      }
      else if(event is EditChatEvent){
        //Edits the defined chat and sends a request to update chat properties in the backend
        yield* _mapEditChatToState(event.chatId, event.copyChat);
      }
      else if(event is DeleteEvent){
        //Sends a delete message to the chat
        yield* _mapMessageToState(event.chatId, DeleteMessage(clientID: PollarStoreBloc().loggedInUserID));
      }
      else if(event is LeaveEvent){
        //Removes you from the chat and sends a request to update the backend
        yield* _mapLeaveChatToState(event.chatId);
      }
      else if(event is LoadMoreMessages){
        //Loads the defined amount of messages ontop of the current messages in the chat
        yield* _mapLoadMoreToState(event.chatId, event.onSuccess);
      }
      else if(event is ClearChatBlocEvent){
        yield* _mapClearChatBlocEvent();
      }
      else if(event is RefreshChatBlocEvent){
        yield* _mapRefreshChatBlocEvent(event.onSuccess);
      }
    }
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ MAP TO STATE FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///Stores the defined chat into the chat state by its ID
  Stream<ChatState> _mapStoreToState(Chat chat) async* {

    //Current chats in state
    Map<String, Chat> currentChats = Map.from(state.chats);
    
    //If not null compares values from the new chat
    Chat currentStored = state[chat.id];

    if(currentStored != null){
      //Chat founds, copy vlaues
      currentStored = currentStored.copyWith(chat);

    }
    //Store new chat
    else {currentStored = chat;}

    currentStored = currentStored.copyWith(Chat(hash: ChatFunctions.hash()));

    //adds the chat to state
    currentChats[chat.id] = currentStored;

    //Yields the new state
    yield ChatState.editState(state, newChats: currentChats);

  }

  ///Initializes all exsisting chats
  Stream<ChatState> _mapInitBlocToState(String loginID) async* {

    //Yield the initilization of the chat state
    yield ChatState.initialize(loginID);

    //Get all chats
    List<Chat> userChats = await ChatApi.getAllChats();

    //Loop through all chats and initialize them
    for(Chat chat in userChats){
      
      //Create hash key
      chat = chat.copyWith(Chat(hash: ChatFunctions.hash()));

      ChatBloc().add(InitChatEvent(chat));
    }

  }

  ///Populates a chat with 5 messages initially. 
  ///This is accounted for when loading more messages. 
  ///Initializes the chat object and returns it back
  Stream<ChatState> _mapInitChatToState(Chat chat, [Function(Chat) onSuccess]) async* {

    //Remove the current logged in user from the chat that was recently pulled in
    chat.users.remove(PollarStoreBloc().loggedInUserID);

    //Subscribe to the channel so onMessage received will fire
    chat = await chat.init(state.chatClient.channel(chat.id));

    //Load inital message count
    chat = await chat.reset();
    
    if(chat?.messages?.isNotEmpty ?? false){

      //Initial date message
      DateMessage dateMessage = DateMessage(clientID: 'DateMessage', timeToken: chat.messages[0].timeToken);

      chat.messages.insert(0, dateMessage);
      
    }

    //Run onsucess before chat created event sent
    if(onSuccess != null){
      onSuccess(chat);
    }

    //Store chat to state
    yield* _mapStoreToState(chat);

  }

  ///Makes request to create a new chat
  ///Adds the chat to state
  Stream<ChatState> _mapCreateChatToState(Chat chat, {Function(Chat) onSuccess}) async* {

    //Give the chat a proper ID and populate it within state for now
    chat = chat.copyWith(Chat(
      channelID: 'Pollar' + chat.users[0] + PollarStoreBloc().loggedInUserID + DateTime.now().toString(),
      muteChat: {PollarStoreBloc().loggedInUserID: false}, 
      timeToken: DateTime.now(), 
      chatAccepted: {PollarStoreBloc().loggedInUserID: true},
      sendReadReceipts: {PollarStoreBloc().loggedInUserID: true},
      read: true,
      hidden: false,
      // loadMore: false,  
      messages: [],
    ));

    //Add store chat event with updated params
    yield* _mapStoreToState(chat);

    //Send request to create new chat
    Chat newChat = await ChatApi.createChat(chat.users, chat.id);

    //Initialize chat to subscribe
    yield* _mapInitChatToState(newChat, onSuccess);

  }
  
  ///Sends a request to edit the caht and edits the chat using the following properties
  Stream<ChatState> _mapEditChatToState(String chatId, Chat copyChat) async* {

    //The current chat
    Chat currentChat = state[chatId];

    //Only allows certain values to be editted
    currentChat = currentChat.copyWith(Chat(
      chatName: copyChat.chatName,
      chatAccepted: copyChat.chatAccepted,
      sendReadReceipts: copyChat.sendReadReceipts,
      muteChat: copyChat.muteChat,
      users: copyChat.users,
      timeToken: copyChat.timeToken,
    ));

    //Send a store event to store the current chat
    yield* _mapStoreToState(currentChat);

    Map<String, dynamic> fileEncoding = copyChat.chatImage?.isNotEmpty == true ? jsonDecode(copyChat.chatImage) : null;

    //Send request to edit chat
    Chat newChat = await ChatApi.editChat(chatId, 
      chatName: copyChat.chatName,
      chatAccepted: copyChat.chatAccepted,
      sendReadReceipts: copyChat.sendReadReceipts,
      users: copyChat.users,
      time: copyChat.timeToken?.toString(),
      muteChat: copyChat.muteChat,
      fileName: fileEncoding != null ? fileEncoding['file'] as String : null,
      encoding: fileEncoding != null ? fileEncoding['encoding'] as String : null,
    );

    //Only allows certain values to be editted
    currentChat = currentChat.copyWith(Chat(
      chatName: newChat.chatName,
      chatAccepted: newChat.chatAccepted,
      sendReadReceipts: newChat.sendReadReceipts,
      muteChat: newChat.muteChat,
      users: newChat.users..removeWhere((id) => id == PollarStoreBloc().loggedInUserID),
      timeToken: newChat.timeToken,
      chatImage: newChat.chatImage,
    ));

    //Send a store event to store the current chat
    yield* _mapStoreToState(currentChat);
    
  }

  ///Leave a chat by editing the users in the backend
  ///Remove the chat by editing the state
  Stream<ChatState> _mapLeaveChatToState(String chatId) async* {

    Chat chat = state[chatId];

    if(chat != null){

      await ChatApi.editChat(chatId, users: chat.users);
      
      yield ChatState.editState(state, newChats: state.chats..remove(chatId));
    }

  }


  Stream<ChatState> _mapMessageToState(String chatId, ChatMessage message) async* {

    //Current chat
    Chat chat = state[chatId];
    
    if(!(message is ReadMessage) && !(message is DeleteMessage)){

      //Append message and add delivered tag
      message.delivered = false;
      
      
      if(!(message is ImageMessage) && !(message is VideoMessage)){
        chat.messages.add(message);
      }

      //Updates the timeToken on the current chat
      ChatBloc().add(EditChatEvent(chatId, Chat(timeToken: DateTime.now())));

      //Send notification
      if(message.notificationMessage != null)
        {ChatApi.sendNotification(chatId, message.notificationMessage);}

      //Add Store event
      yield* _mapStoreToState(chat);
    }
    else if(message is DeleteMessage){
      
      //Hides the chat from view
      chat = chat.copyWith(Chat(hidden: true));

      //Add store event
      yield* _mapStoreToState(chat);

    }

    //Send message through pubnub channel
    try{
      chat.channel.publish(message.toJson(), storeMessage: true, ttl: 0);
    }catch(e){print(e);}
  }

  Stream<ChatState> _mapLoadMoreToState(String chatId, Function onSuccess) async* {

    //The Current chat
    Chat chat = state[chatId];

    //remove old date message
    if((chat?.messages?.length ?? 0) > 0 && chat.messages[0] is DateMessage){
      chat.messages.removeAt(0);
    }

    chat = await chat.more();

    //Insert top date message
    if(!chat.history.hasMore && !(chat.messages[0] is DateMessage)){
      chat.messages.insert(0, DateMessage(clientID: 'DateMessage', timeToken: chat.messages[0].timeToken));
    }

    //Send store event
    ChatBloc().add(StoreChatEvent(chat));

    if(onSuccess != null){
      onSuccess();
    }

  }

  Stream<ChatState> _mapClearChatBlocEvent() async* {

    for(Chat chat in state.allChats){
      chat.dispose();
    }

    yield initialState;
  }

  Stream<ChatState> _mapRefreshChatBlocEvent(Function() onSuccess) async*{

    //Get all chats
    List<Chat> chats = await ChatApi.getAllChats();

    for(Chat chat in chats){

      if(state.allChats.isEmpty || state.allChats.singleWhere((c) => c.id == chat.id) == null){
        
        //Create hash key
        chat = chat.copyWith(Chat(hash: ChatFunctions.hash()));

        //Initialize Chat
        ChatBloc().add(InitChatEvent(chat));
  
      }
    }

    //Run onsucess before chat created event sent
    if(onSuccess != null){
      onSuccess();
    }

  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ HELPER FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///Find user chat allows you to locate a chat with a user, if no chat is found or if group caht is created, new chat is retrurned
  Chat findUserChat(List<String> userIds){

    //Has to be known before crating a 'DUMMY' chat
    bool groupChat = true;
    
    //If length of users is 1 try to find the chat being searched for
    if(userIds.length == 1){
      
      for(Chat chat in state.allChats){

        if(chat.users.length == 1){
          if(chat.users.first == userIds.first){
            return chat;
          }
        }
      }

      groupChat = false;

    }

    //If no chat is found
    return Chat(
      channelID: 'DUMMY-${PollarStoreBloc().loggedInUserID}',
      users: userIds, 
      groupChat: groupChat,
      read: true,
      timeToken: DateTime.now(),
      chatAccepted: {PollarStoreBloc().loggedInUserID: true},
      messages: [],
      muteChat: {PollarStoreBloc().loggedInUserID: false}
    );

  }
}