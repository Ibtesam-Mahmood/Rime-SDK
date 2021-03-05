import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:rime/state/rime_bloc/rime_bloc_events.dart';
import 'package:rime/state/rime_bloc/rime_bloc_state.dart';

class RimeBloc extends Bloc<RimeEvent, RimeState> {
  /// Instance of rime that connects to the microservices
  final RimeRepository rime;

  /// Maps the innitial state for the RimeBloc
  RimeBloc._(RimeState initialState)
      : rime = RimeRepository(),
        super(initialState);

  /// Primary contructor for the RimeBloc singleton
  factory RimeBloc() {
    //Binds singleton if not bound
    if (GetIt.I.get<RimeBloc>() == null) {
      GetIt.I.registerSingleton<RimeBloc>(RimeBloc._(RimeBloc.initialState));
    }

    return GetIt.I.get<RimeBloc>();
  }

  /// Getter for initial state
  static RimeState get initialState => RimeEmptyState();

  @override
  Stream<RimeState> mapEventToState(RimeEvent event) async* {
    if (event is GetChannelsEvent) {
      yield* _mapChannelsToState(event.userID);
    } else if (event is CreateChannelEvent) {
      yield* _mapCreateChannelToState(
          event.channel, event.users, event.onSuccess);
    } else if (event is MessageEvent) {
      yield* _mapMessageToState(event.message, event.channel);
    } else if (event is DeleteEvent) {
      yield* _mapDeleteToState(event.channel);
    } else if (event is LeaveEvent) {
      yield* _mapLeaveToState(event.channel);
    } else if (event is StoreEvent) {
      yield* _mapStoreToState(event.channel);
    } else if (event is ClearRimeEvent) {
      yield* _mapClearToState();
    }
  }

  /// Initializes the pubnub service and requests channels
  Stream<RimeState> _mapChannelsToState(String userID) async* {
    // Initialize rime state
    rime.initializeRime(userID);

    // Retreive channels by userID
    // TODO: API Call for getting more channels
    // TODO: Make sure channels come in chronologically
    // TODO: uncomment List<RimeChannel> moreChannels = RimeApi().

    // Get more channels
    // TODO: uncomment following
    /* for(RimeChannel chan in moreChannels){
      _mapChannelToState(chan);
    } */
  }

  Stream<RimeState> _mapCreateChannelToState(RimeChannel channel,
      List<String> users, Function(RimeChannel) onSuccess) async* {
    //Get users and create title so what is title ??
    channel = channel.copyWith(RimeChannel(
        title: "Hello",
        channel: DateTime.now().toString(),
        lastUpdated: DateTime.now()));

    yield* _mapStoreToState(channel);

    onSuccess(channel);

    await RimeApi.createChannel(users);
  }

  Stream<RimeState> _mapMessageToState(
      BaseMessage message, String channel) async* {
    //get channels from state
    List<RimeChannel> storedChannels = (state as RimeLiveState).channels;
    //get specific channel
    RimeChannel currentChannel = storedChannels.firstWhere(
        (element) => element.channel == channel,
        orElse: () => null);
    //Remove channel from list to add to top
    storedChannels.remove(currentChannel);
    //update with content and new timestamp
    currentChannel = currentChannel.copyWith(
        RimeChannel(subtitle: message.content, lastUpdated: DateTime.now()));

    _mapStoreToState(currentChannel);
  }

  Stream<RimeState> _mapDeleteToState(String channel) async* {
    //get channels from state
    List<RimeChannel> storedChannels = (state as RimeLiveState).channels;
    //get specific channel
    RimeChannel currentChannel = storedChannels.firstWhere(
        (element) => element.channel == channel,
        orElse: () => null);
    //remove channel from stored
    if (currentChannel != null) {
      storedChannels
          .removeWhere((element) => element.channel == currentChannel.channel);
    }
    //Api call to delete channel on PubNub
    RimeApi.deleteChannel(channel);
    yield RimeLiveState.editState((state as RimeLiveState),
        channels: storedChannels);
  }

  Stream<RimeState> _mapLeaveToState(String channel) async* {
    //get channels from state
    List<RimeChannel> storedChannels = (state as RimeLiveState).channels;
    //get specific channel
    RimeChannel currentChannel = storedChannels.firstWhere(
        (element) => element.channel == channel,
        orElse: () => null);
    //remove channel from stored
    if (currentChannel != null) {
      storedChannels
          .removeWhere((element) => element.channel == currentChannel.channel);
    }
    //Api call to leave channel on PubNub
    RimeApi.leaveChannel(RimeRepository().userID, channel);
    yield RimeLiveState.editState((state as RimeLiveState),
        channels: storedChannels);
  }

  /// Map a channel to state
  Stream<RimeState> _mapStoreToState(RimeChannel channel) async* {
    //get channels from state
    List<RimeChannel> storedChannels = (state as RimeLiveState).channels;
    //get specific channel
    RimeChannel currentChannel = storedChannels.firstWhere(
        (element) => element.channel == channel.channel,
        orElse: () => null);
    //get channel index
    int index = storedChannels
        .indexWhere((element) => element.channel == channel.channel);

    if (currentChannel != null) {
      //update channel with info
      currentChannel = currentChannel.copyWith(channel);
      storedChannels[index] = currentChannel;
    } else {
      //new channel
      currentChannel = channel;
      storedChannels.insert(0, currentChannel);
    }

    yield RimeLiveState.editState((state as RimeLiveState),
        channels: storedChannels);
  }

  Stream<RimeState> _mapClearToState() async* {
    for (RimeChannel channel in (state as RimeLiveState).channels) {
      channel.dispose();
    }

    yield initialState;
  }
}
