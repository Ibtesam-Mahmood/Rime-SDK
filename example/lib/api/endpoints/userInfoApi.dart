import 'dart:convert';

import 'package:tuple/tuple.dart';

import '../../models/userInfo.dart';
import '../../state/store/pollarStoreBloc.dart';
import '../request.dart';

class UserInfoApi {
  static Future<List<UserInfo>> getAllUserInfos({int size = 5}) async {
    List<UserInfo> objects = [];
    List<dynamic> objectsJson = (await request.get('/users/userInfo'))['users'];
    for (Map<String, dynamic> objectJson in objectsJson) {
      if (objects.length >= size) break;
      objects.add(UserInfo.fromJson(objectJson));
    }
    return objects;
  }

  ///If build contezxt is defined the function checks if the logged user is user being queried for
  static Future<UserInfo> getUserInfoFromId(String id) async {
    if (id == null) return null;

    //Checks the store for exsistance of the stored user
    UserInfo user = PollarStoreBloc().retreive<UserInfo>(id);

    if (user == null) {
      //User does not exsist in the cache so it must be retreived
      final dynamic response = await request.get('/users/userInfo/' + id);
      dynamic objectJson = (response)['userInfo'];

      if (response['statusCode'] == 200) {
        //User if parsed from json if request is successful
        user = UserInfo.fromJson(objectJson);
      } else {
        //Null user created to be refrenced in the store
        return null;
      }

      //Saves the user in the store
      PollarStoreBloc().store(user);
    }

    return user;
  }

  static Future<UserInfo> editUserInfo(UserInfo user) async {
    final dynamic response = await request.put(
        '/users/userInfo/' + user.id + '/edit',
        body: user.toEditUserInfoJson(),
        contentType: 'application/json');
    dynamic objectJson = (response)['userInfo'];
    return (UserInfo.fromJson(objectJson));
  }

  ///Returns a group of user infos from a group of user info ids
  static Future<List<UserInfo>> getBatchUserInfoById(List<String> ids) async {
    //Removes duplicates
    List<String> userIds = ids.toSet().toList();

    //List of users to be returned
    List<UserInfo> userList = [];

    //Return empty list of the ids list is empty
    if (userIds.isEmpty) {return userList;}

    //Checks to see if user is already cached for each user ID
    //If cached removes the id from the list
    for (String id in userIds) {
      UserInfo storedUser = PollarStoreBloc().retreive<UserInfo>(id);
      if (storedUser != null) {
        //cached user added to the list
        userList.add(storedUser);
      }
    }

    //Remove all used ids from the list
    for (UserInfo user in userList) {
      if (userIds.contains(user.id)) userIds.remove(user.id);
    }

    ///Removes the non valid users
    userList.removeWhere((user) => !user.validate());

    //Return user list of the ids list is empty
    if (userIds.isEmpty) return userList;

    //Gets userInfos from user ids from server
    final dynamic response = await request.post('/batch/users/userInfo',
        body: jsonEncode({'userInfoIds': userIds}),
        contentType: 'application/json');
    List<dynamic> objectJsons = (response)['users'];

    //Parses list of userInfo JSONs into userInfo models
    for (var object in objectJsons) {
      UserInfo parsedUser = UserInfo.fromJson(object);
      if (parsedUser.validate()) {
        userList.add(parsedUser);
        //Stores the retreived user
        PollarStoreBloc().store(parsedUser);
      }
    }

    return userList;
  }

  static Future<bool> isUsernameUnique(String name) async {
    Map response = await request.get('/isUsernameTaken/' + name);
    if (response['statusCode'] == 200) {
      dynamic objectJson = response['taken'];
      return objectJson;
    }
    return Future.error(response['message'].toString());
  }

  /// Gets the amount of polls and posts from user ID
  static Future<Tuple2<int, int>> getPostAmount(String userID, String topicID) async {
    Map response = await request.post('/feed/count');
    Tuple2<int, int> amount = Tuple2<int, int>(response['pollCount'], response['postCount']);
    return amount;
  }
}
