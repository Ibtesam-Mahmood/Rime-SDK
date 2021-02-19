import 'dart:convert';
import 'package:pollar/api/request.dart';
import 'package:pollar/models/userInfo.dart';
import 'package:pollar/models/userMain.dart';
import 'package:pollar/models/userSettings.dart';
import 'package:tuple/tuple.dart';

class UserMainApi {
  static Future<List<UserMain>> getAllUserMain() async {
    List<UserMain> objects = [];
    Map response = (await request.get('/users/userMain'));

    if (response['statusCode'] == 200) {
      List<dynamic> objectsJson = response['users'];
      for (Map<String, dynamic> objectJson in objectsJson) {
        objects.add(UserMain.fromJson(objectJson));
      }
      return objects;
    }
    return Future.error(response['message']);
  }

  static Future<UserMain> getUserMainFromId(String id) async {
    Map response = (await request.get('/users/userMain/' + id));
    if (response['statusCode'] == 200) {
      dynamic objectJson = ['userMain'];
      return UserMain.fromJson(objectJson);
    }
    return Future.error(response['message']);
  }

  static Future<UserMain> editUserMain(UserMain userMain,
      {password, phone, email}) async {
    //Nulls out the user password to avoid double hashing
    userMain.password = null;
   
    if (password != null) {
      userMain.password = password;
    }
    if (phone != null) {
      userMain.phone = phone;
    }
    if (email != null) {
      userMain.email = email;
    }

    Map response = (await request.put(
        '/users/userMain/' + userMain.id + '/edit',
        body: userMain.toEditUserJson(),
        contentType: 'application/json'));
    if (response['statusCode'] == 200) {
      dynamic objectJson = response['userMain'];
      return UserMain.fromJson(objectJson);
    }
    return Future.error(response['message']);
  }

  static Future<UserMain> deleteUserMain(UserMain userMain) async {
    Map response = await request.delete('/users/userMain/' + userMain.id);
    if (response['statusCode'] == 200) {
      dynamic objectJson = response;
      return UserMain.fromJson(objectJson);
    }
    return Future.error(response['message']);
  }

  static Future<UserMain> deleteUserMainById(String id) async {
    Map response = await request.delete('/users/userMain/' + id);
    if (response['statusCode'] == 200) {
      dynamic objectJson = response;
      return UserMain.fromJson(objectJson);
    }
    return Future.error(response['message']);
  }

  static Future<Tuple3<UserMain, UserInfo, UserSettings>> login(
      String usernameOrEmail, String password) async {
    Map response = await request.put('/login',
        body: jsonEncode({'login': usernameOrEmail, 'password': password}),
        contentType: 'application/json');
    if (response['statusCode'] == 200) {
      return Tuple3(
        UserMain.fromJson(response['userMain']),
        UserInfo.fromJson(response['userInfo']),
        UserSettings.fromJSON({'settings': response['userSetting'], 'blocked': response['blockedUsers'], 'notif': response['notificationSettings']})
      );
    }
    return Future.error(response['message']);
  }

  static Future<bool> checkPassword(String password) async {
    Map response = await request.put('/users/auth/checkPassword',
        body: jsonEncode({'password': password}),
        contentType: 'application/json');
    if (response['statusCode'] == 200) {
      bool objectJson = response['match'];
      return objectJson;
    }
    return Future.error(response['message']);
  }

  ///When called deactivates the users account
  static Future<bool> deactivateAccount() async {
    Map response = await request.put('/users/userMain/deactivate');
    return response['statusCode'] == 200;
  }

  ///Updates the user setting value for the logged in user
  static Future<bool> editUserSettings(UserSettings settings) async {
    var requestBody = settings.toJson();
    Map response = await request.put('/users/userSetting',
        body: jsonEncode(requestBody),
        contentType: 'application/json');
    if (response['statusCode'] == 200) {
      return true;
    }
    return Future.error(response['message']);
  }

  static Future<bool> editNotificationSettings(NotificationSettings notifSet) async {
    var requestBody = notifSet.toJson();
    Map response = await request.put('/notificationSettings/${notifSet.id}',
        body: jsonEncode(requestBody),
        contentType: 'application/json');
    if (response['statusCode'] == 200) {
      return true;
    }
    return Future.error(response['message']);
  }


}
