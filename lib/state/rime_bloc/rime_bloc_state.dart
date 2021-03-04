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

  final List<RimeChannel> channels;

  RimeLiveState({this.timeToken, this.channels});

  factory RimeLiveState.internal(){
    return RimeLiveState();
  }

  ///Edits an exsisting chat state
  @override
  factory RimeLiveState.editState(RimeLiveState original, {List<RimeChannel> channels, int timeToken}){
    return RimeLiveState(
      timeToken: timeToken ?? original.timeToken,
      channels: channels ?? original.channels
    );
  }


  /// Initializes the RimeState by connecting a repository
  static Future<RimeLiveState> fromRepo(RimeRepository rime) async {
    assert(Rime.INITIALIZED);    
    //get channels from api
    List<RimeChannel> channels = await RimeApi.getChannels('change this');
    //get time token from PubNub
    Timetoken time = await rime.client.time();

    return RimeLiveState(timeToken: time.value, channels: channels);
  }

  @override
  List<Object> get props => [timeToken, channels];
}
