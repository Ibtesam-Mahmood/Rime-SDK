import 'package:pubnub/pubnub.dart';

import '../../models/chat.dart';
import '../store/pollarStoreBloc.dart';

class ChatState{

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ STATE VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///Current chat client
  final PubNub chatClient;

  ///Map from chatID to chat object
  final Map<String, Chat> chats;

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CONSTRUCTORS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///Base constructor  for `ChatState`
  ChatState(this.chats, {this.chatClient});

  ///Initial empty state, with no chat client
  factory ChatState.initial() {
    return ChatState({});
  }

  ///Initializes the chat client with the provided loginUserId and populates the list of chats
  factory ChatState.initialize(String loginUserID){

    //Creates the chat client
    PubNub chatClinet = PubNub(defaultKeyset: Keyset(
      // publishKey: ConfigReader.getPublishKey(),
      // subscribeKey: ConfigReader.getSubscribeKey(),
      // uuid: UUID(loginUserID),
      // authKey: ConfigReader.getSubscribeKey()
    ));

    return ChatState({}, chatClient: chatClinet);
  }

  ///Edits an exsisting chat state
  factory ChatState.editState(ChatState original, {Map<String, Chat> newChats}){
    return ChatState(
      newChats ?? original.chats,
      chatClient: original.chatClient
    );
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///Returns the chat with the matching id
  Chat operator [](String other) {
    return chats[other];
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///Returns a list of all chats
  List<Chat> get allChats => chats.values.toList();

  ///Retruns a list of all accepted chats, removes hidden chats. 
  ///Sorted based on timeToken
  List<Chat> get acceptedChats => allChats..retainWhere((c) => c.chatAccepted[PollarStoreBloc().loggedInUserID] && c.hidden == false && c?.messages?.isNotEmpty == true)
    ..sort((a, b) => b.messages.last.timeToken.compareTo(a.messages.last.timeToken));

  ///Returns a list of all requested chats, removes hidden chats. 
  ///Sorted based on timeToken
  List<Chat> get requestedChats => allChats..removeWhere((c) => c.chatAccepted[PollarStoreBloc().loggedInUserID] || c.hidden == true || c?.messages?.isNotEmpty != true)
    ..sort((a, b) => b.timeToken.compareTo(a.timeToken));

  ///Checks if the state is intialized
  bool get isInitialized => chatClient != null;

} 