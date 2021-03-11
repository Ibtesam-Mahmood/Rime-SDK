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

class RimeBloc extends Bloc<RimeEvent, RimeState> {
  /// Maps the innitial state for the RimeBloc
  RimeBloc._(RimeState initialState) : super(initialState);

  /// Primary contructor for the RimeBloc singleton
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

  /// Getter for initial state
  static RimeState get initialState => RimeEmptyState();

  @override
  Stream<RimeState> mapEventToState(RimeEvent event) async* {
    if (event is InitializeRime) {
      yield* _mapInitializeToState(event.userID);
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

  /// Initializes the pubnub service and requests channels
  Stream<RimeState> _mapInitializeToState(String userID) async* {
    // Initialize rime state
    await RimeRepository().initializeRime(userID);

    RimeRepository().addListener('rime-bloc-listener', onMessageCallBack);

    yield RimeLiveState.initial();

    //Load in first batch of channels
    add(GetChannelsEvent());
  }

  ///Retreives more channels based on a starting time token
  Stream<RimeState> _mapChannelsToState() async* {
    //Previous page token for retreiving channels
    String pageToken = (state as RimeLiveState).pageToken;

    Tuple2<List<RimeChannel>, String> pagenatedResponse =
        await RimeApi.getMostRecentChannels(limit: 50, start: pageToken);

    RimeLiveState newState = (state as RimeLiveState).addChannelsBatch(
        pagenatedResponse.item1, (await RimeRepository().client.time()).value, pagenatedResponse.item2);

    yield newState;
  }

  Stream<RimeState> _mapCreateChannelToState(List<String> users, Function(RimeChannel) onSuccess) async* {
    //Create channel
    RimeChannel channel = await RimeApi.createChannel(users);
    //Map channel to state
    yield* _mapStoreToState(channel);
    //Successfully added
    onSuccess(channel);
  }

  Stream<RimeState> _mapMessageToState(Map<String, dynamic> message, String channel, String type) async* {
    RimeChannel rimeChannel = retireveChannel(channel);

    //Create Rime message
    Map<String, dynamic> encodedRimeMessage = RimeMessage.toRimeMesageEncoding(RimeRepository().userID, type, message);

    //Send Message request
    Tuple2<ChannelMetadataDetails, RimeMessage> res = await RimeApi.sendMessage(channel, encodedRimeMessage);

    rimeChannel =
        rimeChannel.copyWith(RimeChannel(subtitle: res.item2.content, lastUpdated: res.item2.publishedAt.value));

    _mapStoreToState(rimeChannel);
  }

  Stream<RimeState> _mapDeleteToState(String channel) async* {
    //get channels from state
    Map<String, RimeChannel> storedChannels = (state as RimeLiveState).storedChannels;
    //get specific channel
    RimeChannel currentChannel = storedChannels[channel];
    //Api call to delete channel on PubNub
    RimeApi.deleteChannel(channel);
    //Delete channel from state
    yield RimeLiveState.initial().removeChannel(currentChannel, (await RimeRepository().client.time()).value);
  }

  Stream<RimeState> _mapLeaveToState(String channel) async* {
    //get channels from state
    Map<String, RimeChannel> storedChannels = (state as RimeLiveState).storedChannels;
    //get specific channel
    RimeChannel currentChannel = storedChannels[channel];
    //Api call to leave channel on PubNub
    RimeApi.leaveChannel(RimeRepository().userID, channel);
    //Delete channel from state
    yield RimeLiveState.initial().removeChannel(currentChannel, (await RimeRepository().client.time()).value);
  }

  /// Map a channel to state
  Stream<RimeState> _mapStoreToState(RimeChannel channel) async* {
    try {
      //new channel
      yield (state as RimeLiveState).addChannel(channel, (await RimeRepository().client.time()).value);
    } catch (e) {
      //update channel with info
      yield (state as RimeLiveState).modifyChannel(channel, (await RimeRepository().client.time()).value);
    }
  }

  Stream<RimeState> _mapClearToState() async* {
    Map<String, RimeChannel> storedChannels = (state as RimeLiveState).storedChannels;

    for (String channel in (state as RimeLiveState).orgainizedChannels) {
      storedChannels[channel].dispose();
    }

    RimeRepository().removeListener('rime-bloc-listener');

    yield initialState;
  }

  // ~~~~~~~~~~~~~~~~~~~~~ Helper Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  void onMessageCallBack(Envelope en) async {
    // Updates the lastUpdated time for the channel and subititle of the channel
    if (en.messageType == MessageType.normal) {
      RimeMessage message = RimeMessage.fromBaseMessage(en);

      //Check if state has channel
      RimeChannel channel = retireveChannel(en.channel);
      if (retireveChannel(en.channel) == null) {
        channel = await RimeApi.getChannel(en.channel);
      }

      // Modify the primary content
      channel.subtitle = message.encode();

      // modify the time token
      channel.lastUpdated = message.publishedAt.value;

      add(StoreEvent(channel));
    }

    /// Updates the metadata within a membershit to [read = true]
    else if (en.messageType == MessageType.messageAction) {
      //Edit metadata

      //Check if state has channel
      RimeChannel channel = retireveChannel(en.channel);
      if (channel != null) {
        //Get userID for read action
        String readUserID;

        //Get value for read action
        int messageToken;

        Map<String, int> readMap = channel?.readMap;
        readMap[readUserID] = messageToken;

        add(StoreEvent(channel.copyWith(RimeChannel(readMap: readMap))));
      }
    }
  }

  RimeChannel retireveChannel(String channel) {
    assert(state is RimeLiveState);
    Map<String, RimeChannel> storedChannels = (state as RimeLiveState).storedChannels;
    return storedChannels[channel];
  }
}
