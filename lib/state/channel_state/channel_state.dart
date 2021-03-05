import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:rime/state/rime_bloc/rime_bloc.dart';
import 'package:rime/state/rime_bloc/rime_bloc_events.dart';
import 'package:rime/state/rime_bloc/rime_bloc_state.dart';
import 'package:pubnub/src/dx/_endpoints/history.dart';

///The type of builder for the channel provider
typedef ChannelStateBuilder = Widget Function(BuildContext context, RimeChannel channel, List<BaseMessage> history);

///The type of the listner for the channel provider
typedef ChannelStateListener = void Function(BuildContext context, RimeChannel channel, List<BaseMessage> history);

/// Provides a state for subscribing to messages and properties for a single channel
/// 
/// Subscribes to the [RimeBloc] to provide channel state. 
/// If the channel is not loaded into [RimeBloc] loads into state
class ChannelStateProvider extends StatefulWidget {

  static const int MESSAGE_CHUNK_SIZE = 100;

  ///Channel to be refrenced
  final String channelID;

  /// Builder for the channel state provider
  final ChannelStateBuilder builder;

  /// Listener for the channel state provider
  final ChannelStateListener listner;

  /// The amount of messages loaded in every load more request
  final int loadSize;

  /// The controller for the channel 
  final ChannelProviderController controller;

  const ChannelStateProvider({
    Key key, 
    @required this.channelID, 
    this.builder, 
    this.listner, 
    this.loadSize = MESSAGE_CHUNK_SIZE, 
    this.controller
  }) : assert(channelID != null),
    assert(loadSize != null),
    super(key: key);

  @override
  _ChannelStateProviderState createState() => _ChannelStateProviderState();
}

class _ChannelStateProviderState extends State<ChannelStateProvider> {

  // ~~~~~~~~~~~~~~ State Properties ~~~~~~~~~~~~~~

  ///The history within the channel
  PaginatedChannelHistory history;

  ///Storage for messages from this channel
  List<BaseMessage> messages;

  // ~~~~~~~~~~~~~~ Life Cycle ~~~~~~~~~~~~~~~~~~

  @override
  void initState() {
    super.initState();

    //Retreive channel from Rime
    _initialize();
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();

    //Binds the controller
    widget.controller?._bind(this);
  }

  @override
  void dispose(){

    //Dispose the on message callBack
    RimeRepository().removeListener(widget.channelID);

    super.dispose();

  }

  // ~~~~~~~~~~~~~~ Functions ~~~~~~~~~~~~~~~~~~

  /// Life cycle event.
  /// Ensures channel is present within rimebloc.
  /// 
  /// Subscribes to channel and starts history channel.
  void _initialize() async {
    
    //Get channel from bloc
    RimeChannel channel = RimeBloc().retireveChannel(widget.channelID);
    
    //Checks if the channel exsists
    //Retreives the channel from api
    if(channel == null){
      RimeChannel retreivedChannel =  await RimeApi.getChannel(widget.channelID);

      RimeBloc().add(StoreEvent(retreivedChannel));
    }

    //Subscribe to the RimeRepository
    RimeRepository().addListener(widget.channelID, onMessageCallback);

    history = RimeRepository().client.channel(widget.channelID).history(chunkSize: widget.loadSize);
  }

  ///State listsner for message events
  void onMessageCallback(Envelope en){
    
    //Ignores changes from other channels
    if(en.channel != widget.channelID) return;

    switch (en.messageType) {
      case MessageType.normal:
        setState(() {
          messages.insert(0, en);
        });
        break;
      default:
        break;
    }

  }

  /// Loads more messages into the history
  Future<bool> loadMore() async {
    
    //The length of the list
    //Used to add new messages to the list
    int index = history.messages.length;

    await history.more();

    setState(() {
      messages.addAll(history.messages.sublist(index));
    });

    return history.hasMore;

  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RimeBloc, RimeState>(
      cubit: RimeBloc(),
      buildWhen: (previous, current) {
        //Does nothing if new state is RimeEmptyState
        if(current is RimeEmptyState) return false;

        //Updates if previous is current state is now RimeLiveState
        if(previous is RimeEmptyState && current is RimeLiveState) return true;

        //Conditionally builds if the past channel is different from the new channel
        return (previous as RimeLiveState).storedChannels[widget.channelID] != 
          (current as RimeLiveState).storedChannels[widget.channelID];
        
      },
      builder: (context, state) {

        if(!(state is RimeLiveState)) return Container();
        
        //Retreive channel from state
        RimeChannel channel = (state as RimeLiveState).storedChannels[widget.channelID];

        if(widget.listner != null){
          widget.listner(context, channel, messages);
        }
        
        ///Returns the messages and the channel properties
        return widget.builder != null ? widget.builder(context, channel, messages) : Container();
      },
    );
  }
}

///Controller for the channel provider
class ChannelProviderController extends ChangeNotifier {
  _ChannelStateProviderState _state;

  ///Binds the state
  void _bind(_ChannelStateProviderState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  // Loads more from state
  void loadMore() => _state != null ? _state.loadMore() : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}