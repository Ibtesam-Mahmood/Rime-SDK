import 'package:equatable/equatable.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/rime.dart';
import 'package:rime/state/RimeRepository.dart';

/// base state for a rime application
abstract class RimeState extends Equatable {}

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

  RimeLiveState._internal(this.timeToken);

  /// Initializes the RimeState by connecting a repository
  static Future<RimeLiveState> fromRepo(RimeRepository rime) async {
    assert(Rime.INITIALIZED);

    Timetoken time = await rime.client.time();

    return RimeLiveState._internal(time.value);
  }

  @override
  List<Object> get props => [timeToken];
}
