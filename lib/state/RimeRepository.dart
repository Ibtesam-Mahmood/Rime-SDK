import 'package:get_it/get_it.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/state/RimeFunctions.dart';
import '../rime.dart';

typedef RimeCallBack = void Function(Envelope);

/// Base extendable repository for Rime.
///
/// Hold information about userIds and channels.
/// Both of these are held in seperate hive cointainers
class RimeRepository {
  /// Meta data box name
  static const String META_DATA_BOX = 'rime-meta';

  /// Box name that stores all channels
  static const String CHANNEL_BOX = 'rime-channel';

  /// The root pubnub client
  PubNub _client;

  /// Logged in user Id
  String _userId;

  /// All pubnub subscriptions
  final Map<String, Subscription> _subscriptions = {};

  /// Root subscription for recieving events
  Subscription _rootSubscription;

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
    if (_client == null) throw Exception('Client not iniitlaized');
    return _client;
  }

  //Returns a userId if initialized
  String get userId {
    if (_userId == null) throw Exception('Client not iniitlaized');
    return _userId;
  }

  /// Used to initialize the repository.
  ///
  /// Must be called to initialize the pubnub service.
  ///
  /// !!! Must be run after authentication
  Future<void> initializeRime(String userId) async {
    assert(Rime.INITIALIZED);

    //Build keyset from dot env
    final pubnubKeySet =
        Keyset(subscribeKey: Rime.env['RIME_SUB_KEY'], publishKey: Rime.env['RIME_PUB_KEY'], uuid: UUID(userId));

    //Assign the userId
    _userId = userId;

    // Initialize the pubnub client
    _client = PubNub(defaultKeyset: pubnubKeySet);

    reset();
  }

  ///Reset funtion.
  ///Subscribes to all valid channel groups
  void reset() async {
    //Retreive valid channel groups
    List<String> channelGroups = await RimeFunctions.getChannelGroups(userId);

    for (String groupId in channelGroups) {
      if (!_subscriptions.containsKey(groupId)) {
        //Subscribe
        Subscription sub = await client.subscribe(channelGroups: Set.from([groupId]));
        sub.messages.listen(onMessageCallBack);
        _subscriptions[groupId] = sub;
      }
    }
  }

  /// Disposes the rime instance and all server connections
  void disposeRime() {
    //Unsubscribes from subscriptions
    _rootSubscription.cancel();
    for (var subscription in _subscriptions.keys) {
      _subscriptions[subscription].cancel();
    }
    _subscriptions.clear();

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
