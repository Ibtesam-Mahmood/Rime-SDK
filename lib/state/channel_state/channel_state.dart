import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/model/rimeMessage.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:rime/state/rime_bloc/rime_bloc.dart';
import 'package:rime/state/rime_bloc/rime_bloc_events.dart';
import 'package:rime/state/rime_bloc/rime_bloc_state.dart';

///The type of builder for the channel provider
typedef ChannelStateBuilder = Widget Function(
    BuildContext context, RimeChannel channel, List<BaseMessage> history);

///The type of the listener for the channel provider
typedef ChannelStateListener = void Function(
    BuildContext context, RimeChannel channel, List<BaseMessage> history);

/// Provides a state for subscribing to messages and properties for a single channel
///
/// Subscribes to the [RimeBloc] to provide channel state.
/// If the channel is not loaded into [RimeBloc] loads into state
class ChannelStateProvider extends StatefulWidget {
  static const int MESSAGE_CHUNK_SIZE = 5;

  ///Channel to be refrenced
  final String channelId;

  /// Builder for the channel state provider
  final ChannelStateBuilder builder;

  /// Listener for the channel state provider
  final ChannelStateListener listener;

  /// The amount of messages loaded in every load more request
  final int loadSize;

  /// The controller for the channel
  final ChannelProviderController controller;

  const ChannelStateProvider(
      {Key key,
      @required this.channelId,
      this.builder,
      this.listener,
      this.loadSize = MESSAGE_CHUNK_SIZE,
      this.controller})
      : assert(channelId != null),
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
  List<RimeMessage> messages = [];

  // ~~~~~~~~~~~~~~ Life Cycle ~~~~~~~~~~~~~~~~~~

  @override
  void initState() {
    super.initState();

    //Retreive channel from Rime
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Binds the controller
    widget.controller?._bind(this);
  }

  @override
  void dispose() {
    //Dispose the on message callBack
    RimeRepository().removeListener(widget.channelId);

    super.dispose();
  }

  // ~~~~~~~~~~~~~~ Functions ~~~~~~~~~~~~~~~~~~

  /// Life cycle event.
  /// Ensures channel is present within rimebloc.
  ///
  /// Subscribes to channel and starts history channel.
  void _initialize() async {
    //Get channel from bloc
    RimeChannel channel = RimeBloc().retireveChannel(widget.channelId);

    //Checks if the channel exsists
    //Retreives the channel from api
    if (channel == null) {
      RimeChannel retreivedChannel = await RimeAPI.getChannel(widget.channelId);

      RimeBloc().add(StoreEvent(retreivedChannel));
    }

    //Subscribe to the RimeRepository
    RimeRepository().addListener(widget.channelId, onMessageCallback);

    history = RimeRepository()
        .client
        .channel(widget.channelId)
        .history(chunkSize: widget.loadSize);

    //Loads the innitial batch of messages
    await resetLoad();
  }

  ///State listsner for message events
  void onMessageCallback(Envelope en) {
    //Ignores changes from other channels
    if (en.channel != widget.channelId) return;

    switch (en.messageType) {
      case MessageType.normal:
        setState(() {
          messages.add(RimeMessage.fromBaseMessage(en));
        });
        break;
      default:
        break;
    }
  }

  /// Loads the innitial batch of messages
  Future<bool> resetLoad() async {
    history.reset();

    return loadMore();
  }

  /// Loads more messages into the history
  Future<bool> loadMore() async {
    //The length of the list
    //Used to add new messages to the list
    int index = messages.length;

    await history.more();

    setState(() {
      List<BaseMessage> baseMessages = history.messages.sublist(index);
      for (BaseMessage message in baseMessages.reversed) {
        try {
          messages.insert(0, RimeMessage.fromBaseMessage(message));
        } catch (e) {
          print('corrupt mesage');
        }
      }
    });

    return history.hasMore;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RimeBloc, RimeState>(
      cubit: RimeBloc(),
      buildWhen: (previous, current) {
        //Does nothing if new state is RimeEmptyState
        if (current is RimeEmptyState) return false;

        //Updates if previous is current state is now RimeLiveState
        if (previous is RimeEmptyState && current is RimeLiveState) return true;

        //Conditionally builds if the past channel is different from the new channel
        return (previous as RimeLiveState).storedChannels[widget.channelId] !=
            (current as RimeLiveState).storedChannels[widget.channelId];
      },
      builder: (context, state) {
        if (!(state is RimeLiveState)) return Container();

        //Retreive channel from state
        RimeChannel channel =
            (state as RimeLiveState).storedChannels[widget.channelId];

        if (widget.listener != null) {
          widget.listener(context, channel, messages);
        }

        ///Returns the messages and the channel properties
        return widget.builder != null
            ? widget.builder(context, channel, messages)
            : Container();
      },
    );
  }
}

///Controller for the channel provider
class ChannelProviderController extends ChangeNotifier {
  _ChannelStateProviderState _state;

  ///Binds the state
  void _bind(_ChannelStateProviderState bind) => _state = bind;

  //Called to notify all listeners
  //void _update() => notifyListeners();

  /// Loads more from state
  Future<bool> loadMore() async =>
      _state != null ? await _state.loadMore() : null;

  /// Refreshes the history cursor to the beginning
  Future<bool> refresh() async =>
      _state != null ? await _state.resetLoad() : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}
