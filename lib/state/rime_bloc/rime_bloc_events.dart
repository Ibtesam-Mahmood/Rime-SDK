import 'package:rime/model/channel.dart';

abstract class RimeEvent {}

/// Initializes the Rime channel service by retreiving and subscring to channels.
///
/// UserId provided is a unique identifier used to access user channels
class InitializeRime extends RimeEvent {
  final String userId;

  InitializeRime(this.userId);
}

class GetChannelsEvent extends RimeEvent {
  GetChannelsEvent();
}

///Create a channel event sends a request to create a chat and stores it within the state
class CreateChannelEvent extends RimeEvent {
  final List<String> users;
  final Function(RimeChannel) onSuccess;
  CreateChannelEvent(this.users, {this.onSuccess});
}

///Sends a message through the pubnub RimeChannel and adds the Message object to state
class MessageEvent extends RimeEvent {
  final dynamic payload;
  final String type;
  final String channel;
  MessageEvent(this.channel, this.type, this.payload);
}

///Sends a Delete Message though the pubnub RimeChannel and deletes and hides a chat for a user
class DeleteEvent extends RimeEvent {
  final String channel;
  DeleteEvent(this.channel);
}

///Removes membership from a channel
class LeaveEvent extends RimeEvent {
  final String channel;
  LeaveEvent(this.channel);
}

///Stores a channel into the state
class StoreEvent extends RimeEvent {
  final RimeChannel channel;
  StoreEvent(this.channel);
}

///Clears all chats from state and resets the chat client
class ClearRimeEvent extends RimeEvent {
  ClearRimeEvent();
}
