


import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';

abstract class RimeEvent {}

/// Iniitalizes the Rime channel service by retreiving and subscring to channels. 
/// 
/// UserID provided is a unique identifier used to access user channels
class RimeInitEvent extends RimeEvent{

  final String userID;

  RimeInitEvent(this.userID);

}

///Create a channel event sends a request to create a chat and stores it within the state
class CreateChannelEvent extends RimeEvent{
  final RimeChannel channel;
  final Function(RimeChannel) onSuccess;
  CreateChannelEvent(this.channel, {this.onSuccess});
}

///Sends a message through the pubnub RimeChannel and adds the Message object to state
class MessageEvent extends RimeEvent{
  final BaseMessage message;
  final String channel;
  MessageEvent(this.channel, this.message);
}

///Sends a Delete Message though the pubnub RimeChannel and deletes and hides a chat for a user
class DeleteEvent extends RimeEvent{
  final String channel;
  DeleteEvent(this.channel);
}

///Removes memebership from a channel
class LeaveEvent extends RimeEvent{
  final String channel;
  LeaveEvent(this.channel);
}

///Stores a channel into the state
class StoreEvent extends RimeEvent{
  final RimeChannel channel;
  StoreEvent(this.channel);
}

///Stores a chat into the chat state and binds it to the client
class InitChannelEvent extends RimeEvent{
  final RimeChannel channel;
  InitChannelEvent(this.channel);
}

///Clears all chats from state and resets the chat client
class ClearRimeEvent extends RimeEvent{
  ClearRimeEvent();
}