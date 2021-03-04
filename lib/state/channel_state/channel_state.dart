import 'package:flutter/material.dart';

/// Provides a state for subscribing to messages and properties for a single channel
/// 
/// Subscribes to the [RimeBloc] to provide channel state. 
/// If the channel is not loaded into [RimeBloc] loads into state
class ChannelStateProvider extends StatefulWidget {

  ///Channel to be refrenced
  final String channelID;

  const ChannelStateProvider({Key key, this.channelID}) : super(key: key);

  @override
  _ChannelStateProviderState createState() => _ChannelStateProviderState();
}

class _ChannelStateProviderState extends State<ChannelStateProvider> {

  

  @override
  void initState() {
    super.initState();

    //Retreive channel from Rime
  }

  /// Life cycle event.
  /// Retreives 
  void _initialize(){

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}