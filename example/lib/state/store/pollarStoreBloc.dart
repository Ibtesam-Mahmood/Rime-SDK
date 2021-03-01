import 'dart:collection';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tuple/tuple.dart';

import '../../models/poll.dart';
import '../../models/post.dart';
import '../../models/story.dart';
import '../../models/storyResponse.dart';
import '../../models/subscription.dart';
import '../../models/topics.dart';
import '../../models/userInfo.dart';
import '../../models/userSettings.dart';
import 'storable.dart';


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ STATES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class PollarStoreState {
  //----- POLLAR STORE STATE VALUES -----
  final String loggedInUserID;
  final List<Topic>
      loadedTopics; //Stores the list of loaded topics from the server

  ///Stores a list of userInfoIds and topicIds that are recent searches. 
  ///The list is organized as `<UserInfo, Topic>`
  final Tuple2<Queue<String>, Queue<String>> recentSearches; 
  final UserSettings loginSettings;

  ///A unique id for the recent refresh pushed to the state;
  final String refreshId;

  //----- STORE TIMEOUTS -----
  static const Duration USER_STORE_TIMEOUT = Duration(minutes: 5);
  static const Duration POST_STORE_TIMEOUT = Duration(minutes: 5);
  static const Duration POLL_STORE_TIMEOUT = Duration(minutes: 5);

  //User Store
  final StoreMap<String, UserInfo> storedUsers;
  final StoreMap<String, Post> storedPosts;
  final StoreMap<String, Poll> storedPolls;
  final StoreMap<String, Subscription> storedSubs;
  final StoreMap<String, Story> storedStories;
  final StoreMap<String, StoryResponse> storedStoryResponses;

  //Constructor
  PollarStoreState(
      this.storedUsers,
      this.storedPosts,
      this.storedPolls,
      this.storedSubs,
      this.storedStories,
      this.storedStoryResponses,
      {this.loggedInUserID = '',
      this.loadedTopics = const [],
      this.recentSearches,
      this.loginSettings,
      this.refreshId});

  //Innitial state
  factory PollarStoreState.innitial() {
    // _getTopics();

    return PollarStoreState(
      StoreMap<String, UserInfo>(USER_STORE_TIMEOUT), //Innitial user store
      StoreMap<String, Post>(POST_STORE_TIMEOUT), //Innitial post store
      StoreMap<String, Poll>(POLL_STORE_TIMEOUT), //Innitial poll store
      StoreMap<String, Subscription>(null),
      StoreMap<String, Story>(null),
      StoreMap<String, StoryResponse>(null),
    );
  }

  ///Creates a clone of the old pollar state to remove refrence
  factory PollarStoreState.clone(PollarStoreState oldState, [String refreshId]) {
    return PollarStoreState(
      //Stores
      oldState.storedUsers,
      oldState.storedPosts,
      oldState.storedPolls,
      oldState.storedSubs,
      oldState.storedStories,
      oldState.storedStoryResponses,

      //States
      loggedInUserID: oldState.loggedInUserID,
      loadedTopics: oldState.loadedTopics,
      recentSearches: oldState.recentSearches,
      loginSettings: oldState.loginSettings,
      refreshId: refreshId,
    );
  }

  ///Creates a new PollarStoreState with copied over defined state values
  factory PollarStoreState.editState(
    PollarStoreState original, {
    StoreMap<String, UserInfo> newStoredUsers,
    StoreMap<String, Post> newStoredPosts,
    StoreMap<String, Poll> newStoredPolls,
    StoreMap<String, Subscription> newStoredSubs,
    String newLoginUserID,
    List<Topic> loadedTopics,
    Tuple2<Queue<String>, Queue<String>> newRecentSearches,
    StoreMap<String, Story> newStoredStories,
    UserSettings newLoginSettings,
    StoreMap<String, StoryResponse> newStoredStoryResponses,
  }) {
    return PollarStoreState(
        //Stores
        newStoredUsers ?? original.storedUsers,
        newStoredPosts ?? original.storedPosts,
        newStoredPolls ?? original.storedPolls,
        newStoredSubs ?? original.storedSubs,
        newStoredStories ?? original.storedStories,
        newStoredStoryResponses ?? original.storedStoryResponses,

        //States
        loggedInUserID: newLoginUserID ?? original.loggedInUserID,
        loadedTopics: loadedTopics ?? original.loadedTopics,
        recentSearches: newRecentSearches ?? original.recentSearches,
        loginSettings: newLoginSettings ?? original.loginSettings);
  }

  ///Returns a cloned store builder, and removes all state values and store values.
  ///Retains loaded topics statevalue and users store value
  factory PollarStoreState.clearState(PollarStoreState original) {
    return PollarStoreState(
        //Stores
        original.storedUsers,
        StoreMap<String, Post>(POST_STORE_TIMEOUT), //Innitial post store
        StoreMap<String, Poll>(POLL_STORE_TIMEOUT), //Innitial poll store
        StoreMap<String, Subscription>(null),
        StoreMap<String, Story>(null),
        StoreMap<String, StoryResponse>(null),

        //States
        loadedTopics: original.loadedTopics);
  }

  //Saves the topics map in the local storage
  static void setTopics(List<Topic> topics) async {
    List<String> topicsJsonList =
        topics.map<String>((t) => jsonEncode(t.toJson())).toList();

    final localStorage = FlutterSecureStorage();

    await localStorage.write(
        key: 'topics', value: jsonEncode({'topics': topicsJsonList}));

    PollarStoreBloc().add(EditPollarStoreState(topics: topics));
  }

  //Gets the topics from the local storage and updates the pollar bloc state
  static void _getTopics() async {
    List<Topic> topics = [];

    final localStorage = FlutterSecureStorage();

    try {
      List<String> storedTopics =
          (jsonDecode(await localStorage.read(key: 'topics'))['topics'] as List)
              .cast<String>();

      topics = storedTopics
          .map<Topic>((t) => Topic.fromJson(jsonDecode(t)))
          .toList();

      // if (topics.isNotEmpty && topics != null) {
      //   PollarStoreBloc().add(EditPollarStoreState(topics: topics));
      // }
    } catch (e) {print(e);}

    //Breaks and exits if no instance found
  }

  ///Takes [Topic] id to retreive subscriptions
  ///Compares user [Subscription]
  bool isSub(String id)=> retreive<Subscription>(id) != null;

  ///Takes [Topic] id to compare [UserInfo] modTopic
  ///Retireves [loggedInUserInfo] through [PollarStoreBloc]
  bool isMod(String id) => retreive<UserInfo>(loggedInUserID)?.modTopic == id;

  ///Checks the typed store for isSubscribed
  bool isSubscribed<T>(String id, String subKey) {
    StoreMap store;

    if (T == UserInfo) {
      store = storedUsers;
    } else if (T == Post) {
      store = storedPosts;
    } else if (T == Poll) {
      store = storedPolls;
    } else if (T == Subscription) {
      store = storedSubs;
    } else if (T == Story) {
      store = storedStories;
    } else if (T == StoryResponse) {
      store = storedStoryResponses;
    } else {
      throw ("'T' is not a type of stored object");
    }

    return store.isSubscribed(id, subKey);
  }

  ///Retreives an object with the entered id from the typed store
  ///Returns null if the object does not exsist in the store
  T retreive<T extends Storable>(String id) {
    StoreMap store;

    if (T == UserInfo) {
      store = storedUsers;
    } else if (T == Post) {
      store = storedPosts;
    } else if (T == Poll) {
      store = storedPolls;
    } else if (T == Subscription) {
      store = storedSubs;
    } else if (T == Story) {
      store = storedStories;
    } else if (T == StoryResponse) {
      store = storedStoryResponses;
    } else {
      throw ("'T' is not a type of stored object");
    }

    //Returns the object if it exsists in map
    Map internalMap = store.map;

    if (internalMap.containsKey(id)) return internalMap[id].copy();

    //Object does not exsist in the store
    return null;
  }
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ EVENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class PollarStoreEvent {}

///Interface to store objects into the pollar store
class Store extends PollarStoreEvent {
  final Storable storable;
  final String
      subKey; //Allows an object to also subscribe to the key afterwards

  Store(this.storable, [this.subKey]);
}

///Interface to store objects into the pollar store
class BatchStore extends PollarStoreEvent {
  final List<Storable> storable;
  final String subKey; //Allows an object to also subscribe to the key afterwards

  BatchStore(this.storable, [this.subKey]);
}

///Used to reload the state to refresh any inactive listeners
class Refresh extends PollarStoreEvent {
  static int refreshCounter = 0; //The refresh counter to get the refresh id
  String refreshID;
  Refresh() {
    refreshID = 'refreshNo.' + refreshCounter.toString();
    refreshCounter++;
  }
}

///Used to remove a storable by id
///The type of storable is defined by the type of the remove
///The type of the remove must be a valid stoable object
class Remove<T> extends PollarStoreEvent {
  final String id;
  final Type t = T;
  Remove(this.id);
}

///Used to load important state values in pollar store state
///Only need to use once
class LoadPollarState extends PollarStoreEvent {
  String userInfoId;
  LoadPollarState(this.userInfoId);
}

///Used to load topics into the state
class EditPollarStoreState extends PollarStoreEvent {
  final List<Topic> topics;
  final String loginUserId;
  final Tuple2<Queue<String>, Queue<String>> recentSearches;
  final UserSettings loginSettings;
  EditPollarStoreState(
      {this.loginSettings, this.topics, this.loginUserId, this.recentSearches});
}

///Adds a subscriber to an object within the pollar store
class SubscribeToSubject<T> extends PollarStoreEvent {
  final String id;
  final String subId;
  final Type t = T;

  SubscribeToSubject(this.id, this.subId);
}

///Removes the subscriber from an object in the pollar store
class UnSubscribeToSubject<T> extends PollarStoreEvent {
  final String id;
  final String subId;
  final Type t = T;

  UnSubscribeToSubject(this.id, this.subId);
}

///Used to clear the loaded state of the pollar store
class ClearStoreState extends PollarStoreEvent {}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ BLOC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class PollarStoreBloc extends Bloc<PollarStoreEvent, PollarStoreState> {
  //Pollar store singleton
  static final PollarStoreBloc _store = PollarStoreBloc._internal();

  //Private constructor to innitialize the singleton
  PollarStoreBloc._internal() : super(initialState);

  //Factory constructor to access the store singleton
  factory PollarStoreBloc() {
    return _store;
  }

  static PollarStoreState get initialState => PollarStoreState.innitial();

  @override
  Stream<PollarStoreState> mapEventToState(PollarStoreEvent event) async* {
    if (event is Store) {
      yield* _mapStoreToState(event.storable, event.subKey);
    } else if(event is BatchStore){
      yield* _mapBatchStoreToState(event.storable, event.subKey);
    } else if (event is SubscribeToSubject) {
      yield* _mapSubscribeToState(true, event.id, event.subId, event.t);
    } else if (event is UnSubscribeToSubject) {
      yield* _mapSubscribeToState(false, event.id, event.subId, event.t);
    } else if (event is Refresh) {
      yield PollarStoreState.clone(state, event.refreshID);
    } else if (event is Remove) {
      yield* _mapRemoveToState(event.id, event.t);
    } else if (event is ClearStoreState) {
      //clears the chat store state
      //TODO: Clear Chta Bloc

      yield PollarStoreState.clearState(state);
    } else if (event is EditPollarStoreState) {
      yield PollarStoreState.editState(state,
          loadedTopics: event.topics,
          newLoginUserID: _validateNewLoginUserId(event.loginUserId),
          newRecentSearches: event.recentSearches,
          newLoginSettings: event.loginSettings);
    } else if (event is LoadPollarState) {
      //Loads important state information

      //Loads chat state
      //TODO: Initialize chat state

      // PollarStoreState.setTopics(await TopicApi.getTopics());
    }
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Stream Output Helpers Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Stream<PollarStoreState> _mapSubscribeToState(
      bool subscribe, String id, String subId, Type t) async* {
    if (id != null && subId != null) {
      StoreMap store;

      //Retrevies the refrenced store based on the type
      if (t == UserInfo) {
        store = _store.state.storedUsers;
      } else if (t == Post) {
        store = _store.state.storedPosts;
      } else if (t == Poll) {
        store = _store.state.storedPolls;
      } else if (t == Subscription) {
        store = _store.state.storedSubs;
      } else if (t == Story) {
        store = _store.state.storedStories;
      } else if (t == StoryResponse) {
        store = _store.state.storedStoryResponses;
      }

      //Subscribes to the id if store is found
      if (store != null) {
        if (subscribe == true) {
          store.subscribe(id, subId);
        } else {
          store.unsubscribe(id, subId);
        }
      }

      if (t == UserInfo) {
        yield PollarStoreState.editState(_store.state, newStoredUsers: store);
      } else if (t == Post) {
        yield PollarStoreState.editState(_store.state, newStoredPosts: store);
      } else if (t == Poll) {
        yield PollarStoreState.editState(_store.state, newStoredPolls: store);
      } else if (t == Subscription) {
        yield PollarStoreState.editState(_store.state, newStoredSubs: store);
      } else if (t == Story) {
        yield PollarStoreState.editState(_store.state, newStoredStories: store);
      } else if (t == StoryResponse) {
        yield PollarStoreState.editState(_store.state,
            newStoredStoryResponses: store);
      } else {
        //No type found
        yield _store.state;
      }
    }
  }

  Stream<PollarStoreState> _mapRemoveToState(String removeID, Type t) async* {
    //Does not perform if id is empty or null
    if (removeID == null || removeID.isEmpty) {
      yield _store.state;
    } else {
      StoreMap store;

      //Retrevies the corrent store based on the type of storable object
      if (t == UserInfo) {
        store = StoreMap<String, UserInfo>.from(_store.state.storedUsers);
      } else if (t == Post) {
        store = StoreMap<String, Post>.from(_store.state.storedPosts);
      } else if (t == Poll) {
        store = StoreMap<String, Poll>.from(_store.state.storedPolls);
      } else if (t == Subscription) {
        store = StoreMap<String, Subscription>.from(_store.state.storedSubs);
      } else if (t == Story) {
        store = StoreMap<String, Story>.from(_store.state.storedStories);
      } else if (t == StoryResponse) {
        store = StoreMap<String, StoryResponse>.from(_store.state.storedStoryResponses);
      }

      //Removes the storable object from the correct store if a store is found
      if (store != null) {
        if (t == UserInfo) {
          //Users are not entirely removed, due to sensitive subscription with login user
          //Instead only subsidary information on a user is removed
          UserInfo user = store.map[removeID];
          if (user != null) {
            //Clears the user and updates the store
            UserInfo clearedUser = UserInfo.clearInfo(user);
            store.put(clearedUser.id, clearedUser);
          }
        } else {
          store.remove(removeID);
        }
      }

      if (t == UserInfo) {
        yield PollarStoreState.editState(_store.state, newStoredUsers: store);
      } else if (t == Post) {
        yield PollarStoreState.editState(_store.state, newStoredPosts: store);
      } else if (t == Poll) {
        yield PollarStoreState.editState(_store.state, newStoredPolls: store);
      } else if (t == Subscription) {
        yield PollarStoreState.editState(_store.state, newStoredSubs: store);
      } else if (t == Story) {
        yield PollarStoreState.editState(_store.state, newStoredStories: store);
      } else if (t == StoryResponse) {
        yield PollarStoreState.editState(_store.state,
            newStoredStoryResponses: store);
      } else {
        //No type found
        yield _store.state;
      }
    }
  }

  Stream<PollarStoreState> _mapBatchStoreToState(List<Storable> storables, String subKey) async* {
    PollarStoreState _currentState = _store.state;

    //yield store event multiple times into the current start state
    for (var storable in storables) {
      _currentState = _storeHelper(_currentState, storable, subKey);
    } 

    yield _currentState;

  }

  Stream<PollarStoreState> _mapStoreToState(Storable storable, String subKey) async* {
    yield _storeHelper(_store.state, storable, subKey);
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Helpers Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  String _validateNewLoginUserId(String newID) {
    if (newID != _store.state.loggedInUserID &&
        newID != null &&
        newID.isNotEmpty) {
      return newID;
    } else
      {return _store.state.loggedInUserID;}
  }
  
  ///Returns a modified [PollarStoreState] containing the stored value. 
  ///Takes a [PollarStoreState] as an innitial state.
  PollarStoreState _storeHelper(PollarStoreState currentState, Storable storable, String subKey){
    //Does not perform if the object is not storable
    if (storable == null || storable.id == null || storable.id.isEmpty) {
      return currentState;
    } else {
      StoreMap store;

      //Retrevies the corrent store based on the type of storable object
      if (storable is UserInfo) {
        store = currentState.storedUsers;
        //Finds a cached user and copies over null values
        UserInfo cachedUser = store.map[storable.id];
        if (cachedUser != null) {
          storable = cachedUser.copyWith(storable as UserInfo);
        }
      } else if (storable is Post) {
        store = StoreMap<String, Post>.from(currentState.storedPosts);
      } else if (storable is Poll) {
        store = StoreMap<String, Poll>.from(currentState.storedPolls);
      } else if (storable is Subscription) {
        store = StoreMap<String, Subscription>.from(currentState.storedSubs);
      } else if (storable is Story) {
        store = StoreMap<String, Story>.from(currentState.storedStories);
      } else if (storable is StoryResponse) {
        store = StoreMap<String, StoryResponse>.from(currentState.storedStoryResponses);
      }

      //Adds the storable object to the correct store if a store is found
      if (store != null) {

        store.put(storable.id, storable);

        //Adds a subscriber to the object if defined
        if (subKey != null) {
          store.subscribe(storable.id, subKey);
        }
      }

      if (storable is UserInfo) {
        return PollarStoreState.editState(currentState, newStoredUsers: store);
      } else if (storable is Post) {
        return PollarStoreState.editState(currentState, newStoredPosts: store);
      } else if (storable is Poll) {
        return PollarStoreState.editState(currentState, newStoredPolls: store);
      } else if (storable is Subscription) {
        return PollarStoreState.editState(currentState, newStoredSubs: store);
      } else if (storable is Story) {
        return PollarStoreState.editState(currentState, newStoredStories: store);
      } else if (storable is StoryResponse) {
        return PollarStoreState.editState(currentState,
            newStoredStoryResponses: store);
      } else {
        //No type found
        return currentState;
      }
    }
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Singleton Bloc Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Easy interface to store an object in the pollar store
  void store(Storable storable, [String subKey]) async {

    _store.add(Store(storable, subKey));

  }

  ///Easy interface for storing a list
  ///Batch store does not allow for overwriting information and removes all exsisting elements
  void batchStore<T extends Storable>(List<T> storables,
      [String subKey]) async {
    List<T> storing = [];
    //Removes exsisting elements before modifying the state
    for (T s in storables) {
      if (retreive<T>(s.id) == null) storing.add(s);
    }
     _store.add(BatchStore(storables, subKey));
  }

  ///Easy interface to remove an object from the pollar store
  void remove<T>(String id) {
    _store.add(Remove<T>(id));
  }

  ///Store dispose functions
  void drainStore() {
    _store.drain();
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Singleton Static Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Retreives an object with the entered id from the typed store
  ///Returns null if the object does not exsist in the store
  ///Statically served retreive
  T retreive<T extends Storable>(String id) {
    return _store.state.retreive<T>(id);
  }
  
  ///If user is Subscribed to a topic
  bool isSub(String id) => _store.state.isSub(id);

  ///If user is moderating a topic
  bool isMod(String id) => _store.state.isMod(id);

  ///Retruns the logged in userinfo
  UserInfo get loginUser => _store.retreive(_store.loggedInUserID);

  ///Statically retreives the loggedIn userID from the state
  String get loggedInUserID => _store.state.loggedInUserID;

  ///Statically retreives the settings associated to the login user
  UserSettings get loginSettings => _store.state.loginSettings;

  //Statically retreives the topic list from the state
  List<Topic> get topicList =>
      _store.state.loadedTopics.isEmpty ? null : [..._store.state.loadedTopics];
}
