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
        subscribeKey: Rime.env['RIME-SUB-KEY'],
        publishKey: Rime.env['RIME-PUB-KEY'],
        uuid: UUID(userID));

    // Initialize the pubnub client
    _client = PubNub(defaultKeyset: pubnubKeySet);

    // _client.getSubscribedChannelGroupsForUUID(uuid)

    // //Channel groups
    // List<String> channelGroups;

    // //Subscribe to all channel groups
    // //Store into subscriptions
    // _client.objects.setMemberships(setMetadata)

    //Subscribe to the memebership channel
    //Store into subscriptions

    //Bind the listener
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

}
