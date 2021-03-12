import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/model/rimeMessage.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:rime/state/rime_bloc/rime_bloc_events.dart';
import 'package:rime/state/rime_bloc/rime_bloc_state.dart';
import 'package:tuple/tuple.dart';

export 'rime_bloc_events.dart';
export 'rime_bloc_state.dart';

///[RimeBloc] is a Singleton Global State Manager for Rime
///
///Manages application wide buinsess logic for channels allowing components to directly subscribe to a stream of up-to-date channel data.
///
///The RimeBloc acts as the user's primary interface to communicate with Rime and the underlying Pubnub interface safely.
class RimeBloc extends Bloc<RimeEvent, RimeState> {
  ///Maps the innitial state for the RimeBloc
  RimeBloc._(RimeState initialState) : super(initialState);

  ///Primary contructor for the RimeBloc singleton
  factory RimeBloc() {
    RimeBloc bloc;

    try {
      bloc = GetIt.instance.get<RimeBloc>();
    } catch (e) {
      GetIt.instance.registerSingleton(RimeBloc._(initialState));
      bloc = GetIt.instance.get<RimeBloc>();
    }

    return bloc;
  }

  ///Getter for initial state
  static RimeState get initialState => RimeEmptyState();

  @override
  Stream<RimeState> mapEventToState(RimeEvent event) async* {
    if (event is InitializeRime) {
      yield* _mapInitializeToState(event.userId);
    } else if (event is ClearRimeEvent) {
      yield* _mapClearToState();
    }

    //Rime must be live to run the following requests
    if (state is RimeLiveState) {
      if (event is GetChannelsEvent) {
        yield* _mapChannelsToState();
      } else if (event is CreateChannelEvent) {
        yield* _mapCreateChannelToState(event.users, event.onSuccess);
      } else if (event is MessageEvent) {
        yield* _mapMessageToState(event.payload, event.channel, event.type);
      } else if (event is DeleteEvent) {
        yield* _mapDeleteToState(event.channel);
      } else if (event is LeaveEvent) {
        yield* _mapLeaveToState(event.channel);
      } else if (event is StoreEvent) {
        yield* _mapStoreToState(event.channel);
      }
    }
  }

  ///Initializes the pubnub service and requests channels through [GetChannelsEvent()]
  Stream<RimeState> _mapInitializeToState(String userId) async* {
    // Initialize rime state
    await RimeRepository().initializeRime(userId);

    RimeRepository().addListener('rime-bloc-listener', onMessageCallBack);

    yield RimeLiveState.initial();

    //Load in first batch of channels
    add(GetChannelsEvent());
  }

  ///Retreives more channels based on a starting time token limited to 50 channels per request
  Stream<RimeState> _mapChannelsToState() async* {
    //Previous page token for retreiving channels
    String pageToken = (state as RimeLiveState).pageToken;

    Tuple2<List<RimeChannel>, String> pagenatedResponse =
        await RimeAPI.getMostRecentChannels(limit: 50, start: pageToken);

    RimeLiveState newState = (state as RimeLiveState).addChannelsBatch(
        pagenatedResponse.item1,
        (await RimeRepository().client.time()).value,
        pagenatedResponse.item2);

    yield newState;
  }

  ///Creates a channel based on a list of user ids with the initial user defined by [RimeRepository]
  ///
  ///Provides an [onSuccess] callback which returns a [RimeChannel]
  Stream<RimeState> _mapCreateChannelToState(
      List<String> users, Function(RimeChannel) onSuccess) async* {
    //Create channel
    RimeChannel channel = await RimeAPI.createChannel(users);
    //Map channel to state
    yield* _mapStoreToState(channel);
    //Successfully added
    onSuccess(channel);
  }

  ///Encodes a message to json using [RimeMessage]
  ///
  ///Calls the [RimeAPI] to send message through PubNub
  ///
  ///Changes the order of the channels
  Stream<RimeState> _mapMessageToState(
      dynamic message, String channel, String type) async* {
    RimeChannel rimeChannel = retireveChannel(channel);

    //Create Rime message
    Map<String, dynamic> encodedRimeMessage = RimeMessage.toRimeMesageEncoding(
        RimeRepository().userId, type, message);

    //Send Message request
    Tuple2<ChannelMetadataDetails, RimeMessage> res =
        await RimeAPI.sendMessage(channel, encodedRimeMessage);

    rimeChannel = rimeChannel.copyWith(RimeChannel(
        subtitle: res.item2.content, lastUpdated: res.item2.publishedAt.value));

    _mapStoreToState(rimeChannel);
  }

  ///Deletes a channel from [RimeLiveState]
  ///
  ///Calls the [RimeAPI] to change the membership data corresponding to the UUID
  Stream<RimeState> _mapDeleteToState(String channel) async* {
    //get channels from state
    Map<String, RimeChannel> storedChannels =
        (state as RimeLiveState).storedChannels;
    //get specific channel
    RimeChannel currentChannel = storedChannels[channel];
    //API call to delete channel on PubNub
    RimeAPI.deleteChannel(channel);
    //Delete channel from state
    yield RimeLiveState.initial().removeChannel(
        currentChannel, (await RimeRepository().client.time()).value);
  }

  ///Deletes a channel from [RimeLiveState]
  ///
  ///Changes the authentication for the user through [RimeAPI]
  ///Removes subscription status from UUID
  Stream<RimeState> _mapLeaveToState(String channel) async* {
    //get channels from state
    Map<String, RimeChannel> storedChannels =
        (state as RimeLiveState).storedChannels;
    //get specific channel
    RimeChannel currentChannel = storedChannels[channel];
    //API call to leave channel on PubNub
    RimeAPI.leaveChannel(RimeRepository().userId, channel);
    //Delete channel from state
    yield RimeLiveState.initial().removeChannel(
        currentChannel, (await RimeRepository().client.time()).value);
  }

  ///Adds a channel to the [RimeLiveState]
  ///
  ///if [Exception] is thrown then modifies the channel within [RimeLiveState]
  Stream<RimeState> _mapStoreToState(RimeChannel channel) async* {
    try {
      //new channel
      yield (state as RimeLiveState)
          .addChannel(channel, (await RimeRepository().client.time()).value);
    } catch (e) {
      //update channel with info
      yield (state as RimeLiveState)
          .modifyChannel(channel, (await RimeRepository().client.time()).value);
    }
  }

  ///Clears the [RimeLiveState] of all channels
  ///
  ///yields the [initialState]
  Stream<RimeState> _mapClearToState() async* {
    Map<String, RimeChannel> storedChannels =
        (state as RimeLiveState).storedChannels;

    for (String channel in (state as RimeLiveState).orgainizedChannels) {
      storedChannels[channel].dispose();
    }

    RimeRepository().removeListener('rime-bloc-listener');

    yield initialState;
  }

  // ~~~~~~~~~~~~~~~~~~~~~ Helper Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Callback for receiving a message event binded through [RimeRepository]
  ///
  ///Reveives an [Envelope] and is parsed to a [RimeMessage]
  ///
  ///Channel is then modified in [RimeLiveState]
  void onMessageCallBack(Envelope en) async {
    // Updates the lastUpdated time for the channel and subititle of the channel
    if (en.messageType == MessageType.normal) {
      RimeMessage message = RimeMessage.fromBaseMessage(en);

      //Check if state has channel
      RimeChannel channel = retireveChannel(en.channel);
      if (retireveChannel(en.channel) == null) {
        channel = await RimeAPI.getChannel(en.channel);
      }

      // Modify the primary content
      channel.subtitle = message.encode();

      // modify the time token
      channel.lastUpdated = message.publishedAt.value;

      add(StoreEvent(channel));
    }

    // Updates the metadata within a membership to read = true
    else if (en.messageType == MessageType.messageAction) {
      //Edit metadata

      //Check if state has channel
      RimeChannel channel = retireveChannel(en.channel);
      if (channel != null) {
        //Get userId for read action
        String readUserId;

        //Get value for read action
        int messageToken;

        Map<String, int> readMap = channel?.readMap;
        readMap[readUserId] = messageToken;

        add(StoreEvent(channel.copyWith(RimeChannel(readMap: readMap))));
      }
    }
  }

  ///Retrieves an individual channel from [RimeLiveState]
  RimeChannel retireveChannel(String channel) {
    assert(state is RimeLiveState);
    Map<String, RimeChannel> storedChannels =
        (state as RimeLiveState).storedChannels;
    return storedChannels[channel];
  }
}
