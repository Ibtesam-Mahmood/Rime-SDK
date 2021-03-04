// ───────────▄██████████████▄
// ───────▄████░░░░░░░░█▀────█▄
// ──────██░░░░░░░░░░░█▀──────█▄
// ─────██░░░░░░░░░░░█▀────────█▄
// ────██░░░░░░░░░░░░█──────────██
// ───██░░░░░░░░░░░░░█──────██──██
// ──██░░░░░░░░░░░░░░█▄─────██──██
// ─████████████░░░░░░██────────██
// ██░░░░░░░░░░░██░░░░░█████████████
// ██░░░░░░░░░░░██░░░░█▓▓▓▓▓▓▓▓▓▓▓▓▓█
// ██░░░░░░░░░░░██░░░█▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
// ─▀███████████▒▒▒▒█▓▓▓███████████▀
// ────██▒▒▒▒▒▒▒▒▒▒▒▒█▓▓▓▓▓▓▓▓▓▓▓▓█
// ─────██▒▒▒▒▒▒▒▒▒▒▒▒██▓▓▓▓▓▓▓▓▓▓█
// ──────█████▒▒▒▒▒▒▒▒▒▒██████████
// ─────────▀███████████▀

import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/model/channel.dart';
import '../rime.dart';

typedef RimeCallBack = void Function(Envelope);

/// Base extendable repository for Rime.
///
/// Hold information about userIDs and channels.
/// Both of these are held in seperate hive cointainers
class RimeRepository {
  /// Meta data box name
  static const String META_DATA_BOX = 'rime-meta';

  /// Box name that stores all channels
  static const String CHANNEL_BOX = 'rime-channel';

  /// The root pubnub client
  PubNub _client;

  /// Logged in user ID
  String userID;

  /// All pubnub subscriptions
  final Map<String, Subscription> _subscriptions = {};

  /// Subscription functions
  /// Run when something is subscribed to the
  final Map<String, RimeCallBack> _callBackSubscriptions = {};

  RimeRepository.internal();

  factory RimeRepository() {
    RimeRepository rime;

    try {
      rime = GetIt.instance.get<RimeRepository>();
    } catch (e) {
      GetIt.instance.registerSingleton(RimeRepository.internal());
      rime = GetIt.instance.get<RimeRepository>();
    }

    return rime;
  }

  /// Getter for the pubnub client.
  /// Ensures that client is initialized
  PubNub get client {
    assert(_client != null);
    return _client;
  }

  /// Used to initialize the repository.
  ///
  /// Must be called to initialize the pubnub service.
  ///
  Future<void> initializeRime(String userID) async {
    assert(Rime.INITIALIZED);

    //Build keyset from dot env
    final pubnubKeySet = Keyset(
        subscribeKey: Rime.env['RIME_SUB_KEY'],
        publishKey: Rime.env['RIME_PUB_KEY'],
        uuid: UUID(userID));

    //Assign the userID
    this.userID = userID;

    // Initialize the pubnub client
    _client = PubNub(defaultKeyset: pubnubKeySet);

    //Channel groups
    List<String> channelGroups = await RimeApi.getChannelGroups(userID);

    //Subscribe to all channel groups
    //Store into subscriptions
    for (String s in channelGroups) {
      Subscription temp = client.subscribe(channelGroups: Set.from([s]));
      _subscriptions[s] = temp;
      _subscriptions[s].messages.listen(onMessageCallBack);
    }

    //Subscribe to the memebership channel
    Subscription memebership = client.subscribe(channels: Set.from([userID]));
    //Store into subscriptions
    _subscriptions['memebership'] = memebership;
    _subscriptions['memebership'].messages.listen(onMembershipEvent);
  }

  /// Disposes the rime instance and all server connections
  void disposeRime() {
    //Unsubscribes from all instances
    for (Subscription sub in _subscriptions.values) {
      sub.cancel();
    }

    // Disposes the pubnub instance
    _client = null;
  }

  ///Adding a listner to the rimeCallBack
  void addListener(String id, RimeCallBack callBack) {
    _callBackSubscriptions[id] = callBack;
  }

  ///Removes a listner from the rimeCallBack
  void removeListener(String id) {
    _callBackSubscriptions[id] = null;
  }

  // ~~~~~~~~~~~~~~~~~~~~ Interal Helpers ~~~~~~~~~~~~~~~~~~~~

  /// Calls all the lisnsters
  ///
  /// Primaryu message receive logic
  void onMessageCallBack(Envelope en) {
    //Runs the callback function for the subscribed listeners
    for (RimeCallBack sub in _callBackSubscriptions.values) {
      sub(en);
    }
  }

  /// Run when a membership event is reveived
  void onMembershipEvent(Envelope en) {
    print(en.toString());

    //Check last cahnnel group to see if full
  }
}
