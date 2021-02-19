
import '../../models/chat.dart';
import '../../models/message.dart';

///Abstract base chat event
abstract class ChatEvent {}

///Initialing chat bloc event, loads in all user chats based on the defined `loginUserId`. 
///Creates the chat client and binds all chats to it
class InitializeChatBlocEvent extends ChatEvent{
  final String loginUserId;
  InitializeChatBlocEvent(this.loginUserId);
}

///Create chat event sends a request to create a chat and stores it within the state
class CreateChatEvent extends ChatEvent{
  final Chat chat;
  final Function(Chat) onSuccess;
  CreateChatEvent(this.chat, {this.onSuccess});
}

///Sends a message through the pubnub Channel and adds the Message object to state
class MessageEvent extends ChatEvent{
  final ChatMessage message;
  final String chatId;
  MessageEvent(this.chatId, this.message);
}

///Edit chat event sends request to edit the chat and stores the editted version in the state. 
///The chat is eddited based the provided `copyChat`
class EditChatEvent extends ChatEvent{
  final String chatId;

  ///That chat whose properties will be transfered over to the current chat on edit, null properties will not transfer
  final Chat copyChat;

  EditChatEvent(this.chatId, this.copyChat);
}

///Sends a Delete Message though the pubnub Channel sets the Message hide variable to true
class DeleteEvent extends ChatEvent{
  final String chatId;
  DeleteEvent(this.chatId);
}

///If the chat is a group chat, leaves the group chat, if not 
class LeaveEvent extends ChatEvent{
  final String chatId;
  LeaveEvent(this.chatId);
}

///Stores a chat into the chat state
class StoreChatEvent extends ChatEvent{
  final Chat chat;
  StoreChatEvent(this.chat);
}

///Stores a chat into the chat state and binds it to the client
class InitChatEvent extends ChatEvent{
  final Chat chat;
  InitChatEvent(this.chat);
}

///Loads more messages into the chat with the defined id
class LoadMoreMessages extends ChatEvent {
  final String chatId;
  final Function onSuccess;

  LoadMoreMessages(this.chatId, this.onSuccess);
}

///Clears all chats from state and resets the chat client
class ClearChatBlocEvent extends ChatEvent{
  ClearChatBlocEvent();
}

class RefreshChatBlocEvent extends ChatEvent{

  final Function onSuccess;
  RefreshChatBlocEvent(this.onSuccess);
}