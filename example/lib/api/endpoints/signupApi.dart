import 'package:pollar/api/request.dart';
import 'package:pollar/models/userInfo.dart';
import 'package:pollar/models/userMain.dart';
import 'package:tuple/tuple.dart';

class SignupApi {
  static Future<Tuple2<UserMain, UserInfo>> signup(UserMain userMain, UserInfo userInfo) async {
    Map response = await request.post('/signup',
      body: userMain.toCreateUserJson(userInfo),
      contentType: 'application/json'
    );
    if (response['statusCode'] == 200) {
      dynamic userMainJson = response['userMain'];
      dynamic userInfoJson = response['userInfo'];
      return Tuple2(
          UserMain.fromJson(userMainJson), UserInfo.fromJson(userInfoJson));
    }
    return Future.error(response['message']);
  }

  static Future<bool> isEmailUnique(String email) async {
    Map response = await request.get('/signup/isEmailUnique/' + email);
    if (response['statusCode'] == 200) {
      bool objectJson = response['isUnique'];
      return objectJson;
    }
    return Future.error(response['message']);
  }

  static Future<bool> isPhoneUnique(String phoneNumber) async {
    Map response = await request.get('/signup/isPhoneNumberUnique/' + phoneNumber);
    if (response['statusCode'] == 200) {
      bool objectJson = response['isUnique'];
      return objectJson;
    }
    return Future.error(response['message']);
  }

  static Future<bool> isUsernameUnique(String username) async {
    Map response = await request.get('/signup/isUsernameUnique/' + username);
    if (response['statusCode'] == 200) {
      bool objectJson = response['isUnique'];
      return objectJson;
    }
    return Future.error(response['message']);
  }
}
