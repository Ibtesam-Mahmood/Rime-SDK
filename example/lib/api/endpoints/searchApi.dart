
import 'dart:collection';

import 'package:pollar/api/request.dart';
import 'package:pollar/models/userInfo.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';
import 'package:pollar/util/globalFunctions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

///Endpoint for all search requests
class SearchApi {

  ///Performs a search that loads a list of users from a search redex
  static Future<List<UserInfo>> searchUser(String redex) async{

    List<UserInfo> searchedUsers = [];
    final dynamic response = await request.get('/search/users?input=$redex');
    List<dynamic> objectJsons = (response)['users'];
    for (var json in objectJsons) {
      searchedUsers.add(UserInfo.fromJson(json));
    }

    return searchedUsers;
    
  }

  static Future<Tuple2<List<String>, List<String>>> getRecentSearches() async {

    Tuple2<Queue<String>, Queue<String>> loadedSearches = PollarStoreBloc().state.recentSearches;

    if(loadedSearches != null) return Tuple2(loadedSearches.item1.toList(), loadedSearches.item2.toList());

    ///TODO: Migrate to secure storage
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    
    //Retreives the recent searche state for the logged in user
    List<String> storedSearchesUsers = localStorage.getStringList('${PollarStoreBloc().loggedInUserID}-recentSearches-user');
    List<String> storedSearchedTopics = localStorage.getStringList('${PollarStoreBloc().loggedInUserID}-recentSearches-topic');

    if(storedSearchedTopics != null || storedSearchesUsers != null){
      //Stores the recent searches in the pollar store if any are found
      PollarStoreBloc().add(EditPollarStoreState(recentSearches: Tuple2(Queue<String>.from(storedSearchesUsers ?? []), Queue<String>.from(storedSearchedTopics ?? []))));
    }

    return Tuple2(storedSearchesUsers ?? [], storedSearchedTopics ?? []);

  }

  ///If typeTopic is triggered the recent search is added the topic list, if not its added to the user list
  static Future<String> addRecentSearch(String search, {bool typeTopic = false}) async {

    if(search == null || search.isEmpty) return search;

    Tuple2<Queue<String>, Queue<String>> loadedSearches = PollarStoreBloc().state.recentSearches ?? Tuple2(Queue<String>(), Queue<String>());

    //Removes object refrence
    Queue<String> storedSearches = Queue<String>.from((typeTopic ? loadedSearches.item2 : loadedSearches.item1).toList());

    //Removes a duplicate search before adding this one
    storedSearches.remove(search);

    storedSearches.add(search);

    //List of recent searhces has a max length of 10
    if(storedSearches.length > PollarConstants.RECENT_SEARCH_LIMIT){
      storedSearches.removeFirst();
    }
    
    //Updated searches queue
    Tuple2<Queue<String>, Queue<String>> updatedSearches = typeTopic ? Tuple2(loadedSearches.item1, storedSearches) : Tuple2(storedSearches, loadedSearches.item2);

    //Stores the new recent search to the list
    PollarStoreBloc().add(EditPollarStoreState(recentSearches: updatedSearches));

    SharedPreferences localStorage = await SharedPreferences.getInstance();

    //Stores the recent search to the local storage for the logged in user
    localStorage.setStringList('${PollarStoreBloc().loggedInUserID}-recentSearches-${typeTopic ? 'topic' : 'user'}', storedSearches.toList());
    
    return search;

  }

  ///If typeTopic is triggered the recent search is added the topic list, if not its added to the user list
  static Future<String> removeRecentSearch(String search, {bool typeTopic = false}) async {

    if(search == null || search.isEmpty) return search;

    Tuple2<Queue<String>, Queue<String>> loadedSearches = PollarStoreBloc().state.recentSearches ?? Tuple2(Queue<String>(), Queue<String>());

    //Removes object refrence
    Queue<String> storedSearches = Queue<String>.from((typeTopic ? loadedSearches.item2 : loadedSearches.item1).toList());

    //Removes search
    storedSearches.remove(search);
    
    //Updated searches queue
    Tuple2<Queue<String>, Queue<String>> updatedSearches = typeTopic ? Tuple2(loadedSearches.item1, storedSearches) : Tuple2(storedSearches, loadedSearches.item2);

    //Stores the new recent search to the list
    PollarStoreBloc().add(EditPollarStoreState(recentSearches: updatedSearches));

    SharedPreferences localStorage = await SharedPreferences.getInstance();

    //Stores the recent search to the local storage for the logged in user
    localStorage.setStringList('${PollarStoreBloc().loggedInUserID}-recentSearches-${typeTopic ? 'topic' : 'user'}', storedSearches.toList());
    
    return search;

  }

  ///If typeTopic is triggered the recent search is added the topic list, if not its added to the user list
  static Future<Queue<String>> clearRecentSearch({bool typeTopic = false}) async {

    Tuple2<Queue<String>, Queue<String>> loadedSearches = PollarStoreBloc().state.recentSearches ?? Tuple2(Queue<String>(), Queue<String>());

    //Removes object refrence
    Queue<String> storedSearches = Queue<String>.from((typeTopic ? loadedSearches.item2 : loadedSearches.item1).toList());

    //Clear search
    storedSearches.clear();
    
    //Updated searches queue
    Tuple2<Queue<String>, Queue<String>> updatedSearches = typeTopic ? Tuple2(loadedSearches.item1, storedSearches) : Tuple2(storedSearches, loadedSearches.item2);

    //Stores the new recent search to the list
    PollarStoreBloc().add(EditPollarStoreState(recentSearches: updatedSearches));

    SharedPreferences localStorage = await SharedPreferences.getInstance();

    //Stores the recent search to the local storage for the logged in user
    localStorage.setStringList('${PollarStoreBloc().loggedInUserID}-recentSearches-${typeTopic ? 'topic' : 'user'}', storedSearches.toList());
    
    return storedSearches;

  }

}