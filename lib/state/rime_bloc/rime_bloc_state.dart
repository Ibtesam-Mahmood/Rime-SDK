import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/rime.dart';

/// base state for a rime application
abstract class RimeState {}

/// Innitial state for a rime appllication. 
/// Pre authentication
class RimeEmptyState extends RimeState{}

/// The populated state for rime
class RimeLiveState extends RimeState{
  /// The pubnub client for the SDK
  final PubNub _client;

  RimeLiveState._internal(this._client);

  /// Initializes the RimeState by refining a PubnubClient based
  /// on the login user ID.
  /// 
  /// TODO: retreive cache data
  factory RimeLiveState.init(String userID){
    assert(Rime.INITIALIZED);
    
    //Build keyset from dot env
    final pubnubKeySet = Keyset(
      subscribeKey: env['RIME-SUB-KEY'],
      publishKey: env['RIME-PUB-KEY'],
      uuid: UUID(userID)
    );

    // Initialize the pubnub client
    final pubnub = PubNub(defaultKeyset: pubnubKeySet);

    return RimeLiveState._internal(pubnub);
  }
}