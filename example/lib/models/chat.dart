import 'dart:convert';
import 'package:pubnub/pubnub.dart';

import '../state/chat/chatBloc.dart';
import '../state/chat/chatEvent.dart';
import '../state/store/pollarStoreBloc.dart';
import '../state/store/storable.dart';
import '../util/chat_functions.dart';
import 'message.dart';

class Chat extends Storable<Chat>{

  static const int CHUNK_SIZE = 50;

  final List<String> users;
  final List<ChatMessage> messages;
  final String chatImage;
  final String chatName;
  final DateTime timeToken;
  final bool read;
  final bool hidden;
  final Map<String, dynamic> sendReadReceipts;
  final Map<String, dynamic> chatAccepted;
  final bool groupChat;
  final Map<String, bool> muteChat;
  final Map<String, ChatMessage> readMessageIndex;
  final String hash;
  final PaginatedChannelHistory history;
  final Channel channel;
  final Subscription subscription;
  final List<String> typing;

  Chat({
    String channelID, 
    this.users, 
    this.muteChat, 
    this.timeToken, 
    this.groupChat, 
    this.chatName, 
    this.chatAccepted,
    this.sendReadReceipts, 
    this.read, 
    this.hidden, 
    this.messages, 
    this.chatImage, 
    this.readMessageIndex,
    this.hash, 
    this.history, 
    this.channel,
    this.subscription,
    this.typing
    }) : super(channelID); 

  factory Chat.fromJson(Map<String, dynamic> json){

    List<String> userIds = [];
    if(json==null)return null;
    if(json['users'] != null)
      {for(var id in json['users']) 
        {userIds.add(id);}}

    return Chat(
      channelID: json['channel'],
      users: userIds,
      chatName: json['chatName'],
      chatAccepted: json['chatAccepted'],
      chatImage: json['image'],
      read: true,
      hidden: false,
      sendReadReceipts: json['sendReadReceipts'],
      groupChat: json['groupChat'] ?? userIds.length >= 2,
      timeToken: DateTime.parse(json['time']),
      messages: List<ChatMessage>(),
      readMessageIndex: {},
      muteChat: (json['notificationsEnabled'] as Map<String, dynamic>).cast<String, bool>(),
      typing: []
    );
  }

  String toJson() {
      Map<String, dynamic> object = {
        'channel': id,
        'users': users,
        'chatName': chatName,
        'chatAccepted': chatAccepted,
        'chatImage': chatImage,
        'sendReadReceipts': sendReadReceipts,
        'time': timeToken,
        'notificationsEnabled': muteChat
      };
    return jsonEncode(object);
  }

  @override
  Chat copy(){
    return Chat(
      channelID: id,
      users: users,
      chatName: chatName,
      chatAccepted: chatAccepted
    );
  }

  @override
  bool compare(Chat comparable) {
    // TODO: implement compare
    return null;
  }

  ///Returns an intialzed chat with a channel
  ///The channel is binded with an on listen function
  Future<Chat> init(Channel pubnubChannel) async {
    assert(pubnubChannel != null);

    //Subscribe to channel
    Subscription sub = await pubnubChannel.subscribe(withPresence: false);

    //Bind message listener
    sub.messages.listen(_handleMessage);

    //Add channel
    Chat initChat = copyWith(Chat(channel: pubnubChannel, subscription: sub));

    return initChat;
  }

  ///Disposes the chat channel connection
  Chat dispose(){

    if(channel != null){
      //Channel defined, dipose channel

      Chat copyChat = Chat(
        channelID: id,
        users: users, 
        muteChat: muteChat, 
        timeToken: timeToken, 
        groupChat: groupChat, 
        chatName: chatName, 
        chatAccepted: chatAccepted,
        sendReadReceipts: sendReadReceipts, 
        read: read, 
        hidden: hidden, 
        messages: [], 
        chatImage: chatImage, 
        readMessageIndex: readMessageIndex,
        hash: hash, 
        history: null, 
        channel: null,
        subscription: null
      );

      //dispose listner
      if(subscription != null){
        subscription.unsubscribe();
        subscription.dispose();
      }

      return copyChat;

    }

    return this;

  }

  ///Loads more messages into history and returns a chat object
  Future<Chat> more() async {
    
    assert(channel != null);
    assert(history != null);

    //Loads more messages based on the chat if possible
    if(history.hasMore){
      //Previous length
      int messagesLength = history.messages.length;

      //Load more
      await history.more();

      //Story history
      Chat copyChat = copyWith(Chat(history: history));

      //Add messages to list of messages
      copyChat = ChatFunctions.handleOldMessageList(copyChat, history.messages, messagesLength);

      return copyChat;
    }

    return this;
  }

  ///Resets the chat messages to the innial message count
  ///The chunk size set will be used as the increase limit for loading more
  Future<Chat> reset({int chunkSize = CHUNK_SIZE}) async {

    assert(channel != null);

    //Reset the history to the innital count
    PaginatedChannelHistory resetHistory = channel.history(chunkSize: chunkSize);

    //Load the innitial chunk 
    await resetHistory.more();

    //Story the history within the chat and reset messages
    Chat copyChat = copyWith(Chat(history: resetHistory, messages: []));

    //Add messages to list of messages
    copyChat = ChatFunctions.handleOldMessageList(copyChat, resetHistory.messages, 0);

    return copyChat;

  }

  @override
  Chat copyWith(Chat copy) {
    if(copy == null) return this;

    return Chat(
      channelID: copy.id ?? id,
      users: copy.users ?? users,
      chatName: copy.chatName ?? chatName,
      chatAccepted: copy.chatAccepted ?? chatAccepted,
      sendReadReceipts: copy.sendReadReceipts ?? sendReadReceipts,
      read: copy.read ?? read,
      hidden: copy.hidden ?? hidden,
      chatImage: copy.chatImage ?? chatImage,
      messages: copy.messages ?? messages,
      groupChat: copy.groupChat ?? groupChat,
      muteChat: copy.muteChat ?? muteChat,
      readMessageIndex: copy.readMessageIndex ?? readMessageIndex,
      timeToken: copy.timeToken ?? timeToken,
      hash: copy.hash ?? hash,
      history: copy.history ?? history,
      channel: copy.channel ?? channel,
      subscription: copy.subscription ?? subscription,
      typing: copy.typing ?? typing
    );
  }

  ///Validates the object for errors
  @override
  bool validate() {
    return true;
  }
}

///Handles receiving a new message
void _handleMessage(Envelope en){

  //retreives the chat from the state
  Chat chat = ChatBloc().state[en.channel];

  //Typing action
  if(en.messageType == MessageType.signal){
    //Do nothing on own typing messages
    if(en.uuid.value == PollarStoreBloc().loggedInUserID) return;

    if(en.payload == 'typing1' && !chat.typing.contains(en.uuid.value)){
      chat.typing.add(en.uuid.value);
    }
    else if(en.payload == 'typing0'){
      chat.typing.remove(en.uuid.value);
    }
  }
  
  //Message action
  else if(en.messageType == MessageType.normal){

    //Due to parsing the content must be wrapped in an additional 'message' tag
    Message decoded = Message.fromJson(en.payload);

    decoded.contents = {'message': decoded.contents};

    //Decode the message received
    ChatMessage newMessage = ChatMessage.decodeMessage(decoded);

    //Handle appending the message to the chat
    chat = ChatFunctions.handleNewMessage(chat, newMessage);

  }
  
  //Add save chat event
  ChatBloc().add(StoreChatEvent(chat));
}