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

  /// Maps the innitial state for the RimeBloc
  RimeBloc._(RimeState initialState)
      : super(initialState);

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
    if(event is InitializeRime){

    }
    if (event is GetChannelsEvent) {
      yield* _mapChannelsToState(event.userID);
    } else if (event is CreateChannelEvent) {
      yield* _mapCreateChannelToState(event.channel, event.users, event.onSuccess);
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
  Stream<RimeState> _mapInitializeToState(String userID) async* {
    // Initialize rime state
    RimeRepository().initializeRime(userID);

    RimeRepository().addListener('rime-bloc-listener', onMessageCallBack);
    
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

  Stream<RimeState> _mapChannelsToState(String userID) async* {

  }


  Stream<RimeState> _mapCreateChannelToState(RimeChannel channel, List<String> users, Function(RimeChannel) onSuccess) async* {
    //Map channel to state
    yield* _mapStoreToState(channel);
    //Successfully added
    onSuccess(channel);
    //Create channel
    await RimeApi.createChannel(users);
  }

  Stream<RimeState> _mapMessageToState(BaseMessage message, String channel) async* {
    //get channels from state
    Map<String, RimeChannel> storedChannels = (state as RimeLiveState).storedChannels;
    List<String> organizedChannels = (state as RimeLiveState).orgainizedChannels;
    //get specific channel
    RimeChannel currentChannel = storedChannels[channel];
    //Remove channel from list to add to top
    organizedChannels.remove(currentChannel);
    //update with content and new timestamp
    currentChannel = currentChannel.copyWith(
      RimeChannel(
        subtitle: message.content,
        lastUpdated: message.publishedAt.value
      )
    );

    _mapStoreToState(currentChannel);
  }

  Stream<RimeState> _mapDeleteToState(String channel) async* {
    //get channels from state
    Map<String, RimeChannel> storedChannels = (state as RimeLiveState).storedChannels;
    //get specific channel
    RimeChannel currentChannel = storedChannels[channel];
    //Api call to delete channel on PubNub
    RimeApi.deleteChannel(RimeRepository().userID, channel);
    //Delete channel from state
    yield RimeLiveState.initial().removeChannel(currentChannel, DateTime.now().toTimetoken().value);
  }

  Stream<RimeState> _mapLeaveToState(String channel) async* {
    //get channels from state
    Map<String, RimeChannel> storedChannels = (state as RimeLiveState).storedChannels;
    //get specific channel
    RimeChannel currentChannel = storedChannels[channel];
    //Api call to leave channel on PubNub
    RimeApi.leaveChannel(RimeRepository().userID, channel);
    //Delete channel from state
    yield RimeLiveState.initial().removeChannel(currentChannel, DateTime.now().toTimetoken().value);
  }

  /// Map a channel to state
  Stream<RimeState> _mapStoreToState(RimeChannel channel) async* {
    try{
      //new channel
      yield RimeLiveState.initial().addChannel(channel, DateTime.now().toTimetoken().value);
    }
    catch(e){
      //update channel with info
      yield RimeLiveState.initial().modifyChannel(channel, DateTime.now().toTimetoken().value);
    }
  }

  Stream<RimeState> _mapClearToState() async* {
    Map<String, RimeChannel> storedChannels = (state as RimeLiveState).storedChannels;

    for(String channel in (state as RimeLiveState).orgainizedChannels){
      storedChannels[channel].dispose();
    }

    RimeRepository().removeListener('rime-bloc-listener');

    yield initialState;
  }

  // ~~~~~~~~~~~~~~~~~~~~~ Helper Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  void onMessageCallBack(Envelope en) async {

    // Updates the lastUpdated time for the channel and subititle of the channel
    if(en.messageType == MessageType.normal){

      //Check if state has channel
      RimeChannel channel = retireveChannel(en.channel);
      if(retireveChannel(en.channel) == null){
        channel = await RimeApi.getChannel(en.channel);
      }

      // Modify the primary content
      channel.subtitle = en.content;

      // modify the time token
      channel.lastUpdated = en.publishedAt.value;

      add(StoreEvent(channel));
    }
    /// Updates the metadata within a membershit to [read = true]
    else if(en.messageType == MessageType.messageAction){
      //Edit metadata

      //Check if state has channel
      RimeChannel channel = retireveChannel(en.channel);
      if(channel != null){

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

  RimeChannel retireveChannel(String channel){
    assert(state is RimeLiveState);
    Map<String, RimeChannel> storedChannels = (state as RimeLiveState).storedChannels;
    return storedChannels[channel];
  }
}
