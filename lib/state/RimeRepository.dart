
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
  String _userID;

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
    if(_client == null) throw Exception('Client not iniitlaized');
    return _client;
  }

  //Returns a userID if initialized
  String get userID{
    if(_userID == null) throw Exception('Client not iniitlaized');
    return _userID;
  }

  /// Used to initialize the repository.
  ///
  /// Must be called to initialize the pubnub service.
  ///
  /// !!! Must be run after authentication
  Future<void> initializeRime(String userID) async {
    assert(Rime.INITIALIZED);

    //Build keyset from dot env
    final pubnubKeySet = Keyset(
        subscribeKey: Rime.env['RIME_SUB_KEY'],
        publishKey: Rime.env['RIME_PUB_KEY'],
        uuid: UUID(userID));

    //Assign the userID
    _userID = userID;

    // Initialize the pubnub client
    _client = PubNub(defaultKeyset: pubnubKeySet);

    // Populates the group subscriptions
    refresh();

  }

  ///Subscribes to a specifc group ID if not already subscribed 
  Future<void> addChannelGroup(String groupID) async {
    if(!_subscriptions.containsKey(groupID)){
      Subscription temp = await client.subscribe(channelGroups: Set.from([groupID]));
      _subscriptions[groupID] = temp;
      _subscriptions[groupID].messages.listen(onMessageCallBack);
    }
  }

  /// Refreshes subscriptions for rime.
  /// 
  /// Reloads all possible user channel groups. 
  /// Subscribes to any new channel groups
  Future<void> refresh() async {
    
    //Retreive all user channel groups
    List<String> channelGroups = await RimeApi.getChannelGroups(userID);

    //Subscribe to new channel groups
    //Store into subscriptions
    for (String group in channelGroups) {
      await addChannelGroup(group);
    }

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

  // ~~~~~~~~~~~~~~~~~~ On Messeage Binding Functions ~~~~~~~~~~~~~~~~~~~~~~~

  ///Adding a listner to the rimeCallBack
  void addListener(String id, RimeCallBack callBack) {
    assert(!_callBackSubscriptions.containsKey(id));
    _callBackSubscriptions[id] = callBack;
  }

  ///Removes a listner from the rimeCallBack
  void removeListener(String id) {
    _callBackSubscriptions.remove(id);
  }

  // ~~~~~~~~~~~~~~~~~~~~ Interal Helpers ~~~~~~~~~~~~~~~~~~~~

  /// Calls all the lisnsters
  ///
  /// Primary message receive logic
  void onMessageCallBack(Envelope en) {

    //Runs the callback function for the subscribed listeners
    for (RimeCallBack sub in _callBackSubscriptions.values) {
      sub(en);
    }
  }

}
