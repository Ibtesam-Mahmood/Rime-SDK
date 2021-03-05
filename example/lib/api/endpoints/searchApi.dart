
import 'dart:collection';

import 'package:example/models/userInfo.dart';
import 'package:example/state/store/pollarStoreBloc.dart';
import 'package:tuple/tuple.dart';

import '../request.dart';

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

}