// import 'package:equatable/equatable.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/rime.dart';
import 'package:rime/state/RimeRepository.dart';

/// base state for a rime application
abstract class RimeState {}

/// Innitial state for a rime appllication.
/// Pre authentication
class RimeEmptyState extends RimeState {
  @override
  List<Object> get props => ['empty'];
}

/// The populated state for rime
class RimeLiveState extends RimeState {
  /// Represents the time stamp on the current state
  final int timeToken;

  /// Holds the channel ID in chronological order
  final List<String> orgainizedChannels;
  
  /// Holds all the stored channels [channel.channel => channel]
  final Map<String, RimeChannel> storedChannels;
  
  /// Default private consturctor
  RimeLiveState._({this.timeToken, this.storedChannels, this.orgainizedChannels});

  // ~~~~~~~~~~~~~~~~~~~ Constructers ~~~~~~~~~~~~~~~~~~~

  /// Innitial generator for rime state
  factory RimeLiveState.initial() => RimeLiveState._(timeToken: 0, storedChannels: {}, orgainizedChannels: []);

  /// Genenrator for a new state.
  /// 
  /// Adds a channel to the state.
  /// Sorts the channels
  RimeLiveState addChannel(RimeChannel channel, int timeToken){
    if(storedChannels.containsKey(channel.channel)){
      throw Exception('Channel Already added');
    }
    storedChannels[channel.channel] = channel;
    orgainizedChannels.add(channel.channel);
    orgainizedChannels.sort((a, b) => storedChannels[a].compareTo(storedChannels[b]));
    return RimeLiveState._(storedChannels: storedChannels, orgainizedChannels: orgainizedChannels, timeToken: timeToken);
  }

  /// Generator for new state
  /// 
  /// Adds all channels to the state
  /// Sorts the channels
  RimeLiveState addChannelsBatch(List<RimeChannel> channels, int timeToken){

    for (RimeChannel channel in channels) {
      if(storedChannels.containsKey(channel.channel)){
        storedChannels[channel.channel] = channel;
        orgainizedChannels.add(channel.channel);
      } 
    }
    orgainizedChannels.sort((a, b) => storedChannels[a].compareTo(storedChannels[b]));
    return RimeLiveState._(storedChannels: storedChannels, orgainizedChannels: orgainizedChannels, timeToken: timeToken);
  }
  
  /// Genenrator for a new state.
  /// 
  /// Removes a channel to the state.
  RimeLiveState removeChannel(RimeChannel channel, int timeToken){
    storedChannels.remove(channel.channel);
    orgainizedChannels.remove(channel.channel);
    return RimeLiveState._(storedChannels: storedChannels, orgainizedChannels: orgainizedChannels, timeToken: timeToken);
  }
  
  /// Genenrator for a new state.
  /// 
  /// Modifies a channel to the state.
  /// Sorts the channels.
  RimeLiveState modifyChannel(RimeChannel channel, int timeToken){
    if(!storedChannels.containsKey(channel.channel)){
      throw Exception('Channel Doesnt Exsist');
    }
    storedChannels[channel.channel] = storedChannels[channel.channel].copyWith(channel);
    orgainizedChannels.sort((a, b) => storedChannels[a].compareTo(storedChannels[b]));
    return RimeLiveState._(storedChannels: storedChannels, orgainizedChannels: orgainizedChannels, timeToken: timeToken);
  }

  

  @override
  List<Object> get props => [timeToken];
}
