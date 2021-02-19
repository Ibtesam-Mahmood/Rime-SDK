import 'package:tuple/tuple.dart';

///Storable interface to determine what can be stored within the store
abstract class Storable<T> {
  //Has a unique identifier
  final String id;

  Storable(this.id);

  factory Storable.from(Storable other) => null;

  T copy();

  bool compare(T comparable);

  T copyWith(T copy);

  bool validate();
}

///Modified map class that stores a timeout and max length variable
///the maxlength variable allows the map to act in a FIFO data structure, poping the oldest enteries
///When retrevied the timeout varible automatically removes any timed out objects from the map
///Enteries with a null datetime are permanenet enteries
class StoreMap<T, S> {
  final int maxLength;
  final Duration timeout;

  //The internal map object
  //Holds the Object along with the date of recent added and subscriber count
  //If the subscriber count > 0 the object is permanenet
  final Map<T, Tuple2<DateTime, S>> _map = Map<T, Tuple2<DateTime, S>>();

  //Map of subscribers for each stored object
  final Map<T, Set<String>> _subscribers = Map<T, Set<String>>();

  ///Private innitial constructor
  StoreMap._({
    this.maxLength, 
    this.timeout,
    Map<T, Set<String>>  subscribers,
    Map<T, Tuple2<DateTime, S>> map
  // ignore: empty_constructor_bodies
  }){
    //Add all defined subscribers
    _subscribers.addAll(subscribers ?? {});

    //Add all defined map items
    _map.addAll(map ?? {});
  }

  ///Base Constructor for [StoreMap]
  factory StoreMap(Duration timeout, {int maxLength}){
    return StoreMap._(timeout: timeout, maxLength: maxLength);
  }

  ///Recreates a [StoreMap] object by copying the other
  factory StoreMap.from(StoreMap other){
    return StoreMap._(
      timeout: other.timeout,
      maxLength: other.maxLength,
      map: other._map,
      subscribers: other._subscribers
    );
  }

  ///Stores a key-value pair into the store
  ///Objects declared permanenet are not removed unless explicitly stated
  void put(T key, S value) {
    //Adds/replaces the key/value pair with 3an updated datetime
    //Makes the entery permanenet if stated or previously permanant
    _map[key] = Tuple2<DateTime, S>(DateTime.now(), value);

    //Removes the oldest object in the map if the limit is reached
    if (maxLength != null) {
      if (map.length > maxLength) {
        _map.remove(oldest);
      }
    }
  }

  ///Subscribes to a object in the map
  ///Returns the amount of subscribers
  int subscribe(T key, String subscriberKey) {
    Set<String> subs = _subscribers[key];
    if (subs == null) subs = Set<String>();
    subs.add(subscriberKey);
    return subs.length;
  }

  ///Unsubscribes to the object
  ///Returns the amount of subscribers
  ///Deletes the list if empty
  int unsubscribe(T key, String subscriberKey) {
    Set<String> subs = _subscribers[key];
    if (subs == null) return -1; //No subscribers found
    subs.remove(subscriberKey);
    int newLength = subs.length;
    if (newLength == 0)
      {_subscribers.remove(key);} //No subscribers deletes the list
    return newLength;
  }

  ///Returns true if the subkey is exsitant for a specified key
  bool isSubscribed(T key, String subscriberKey) {
    Set<String> subs = _subscribers[key];
    if (subs == null) return false; //No subscribers
    return subs.contains(subscriberKey);
  }

  ///Checks if the indexed key is permanenet
  bool isPermanent(T key) {
    return _subscribers[key] != null;
  }

  void clear() => _map.clear();

  void remove(T key) {
    _map.remove(key);
    _subscribers.remove(key);
  }

  //Finds the oldest item in the storemap
  T get oldest {
    DateTime time = DateTime.now();
    T currentOldest;
    _map.forEach((key, val) {
      //skips permanenet enteries
      if (isPermanent(key)) {
        if (val.item1.compareTo(time) < 0) {
          currentOldest = key;
        }
      }
    });
    return currentOldest;
  }

  Map<T, S> get map {
    if (timeout != null) {
      DateTime now =
          DateTime.now(); //Time for time out is determined statically
      //Removes the timed-out values from the map
      _map.removeWhere((key, value) {
        if (isPermanent(key)) return false; //Retains permanenet enteries
        return value.item1.add(timeout).compareTo(now) <= 0;
      });
    }

    return _map.map((k, v) => MapEntry(k, v.item2));
  }

  int get length => _map?.values?.length ?? 0;

  List<S> get toList {
    if (_map?.values != null) {
      return map.values.toList();
    }
    else {return [];}
  }
}
