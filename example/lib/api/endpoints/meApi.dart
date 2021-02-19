import 'dart:convert';
import 'package:pollar/api/request.dart';
import 'package:pollar/models/poll.dart';
import 'package:pollar/models/subscription.dart';
import 'package:pollar/models/userInfo.dart';
import 'package:pollar/models/userMain.dart';
import 'package:tuple/tuple.dart';

class MeApi {
  static Future<Tuple2<UserMain, UserInfo>> getMyUser({queryString = ''}) async {

    final dynamic response = await request.get('/trust/trusts' + queryString);

    dynamic userMainJson = (response)['userMain'];
    dynamic userInfoJson = (response)['userInfo'];
    
    return Tuple2<UserMain, UserInfo>(UserMain.fromJson(userMainJson), UserInfo.fromJson(userInfoJson));
  }

  static Future<List<Subscription>> getMySubscriptions() async {
    List<Subscription> list = [];
    dynamic map = (await request.get('/me/subscriptions'))['subscripions'];
    for (Map<String, dynamic> object in map) {
      list.add(Subscription.fromJson(object));
    }
    return list;
  }

  static Future<List<Poll>> pollsFromPeopleIFollow() async {
    List<Poll> list = [];
    dynamic map = (await request.get('/me/pollsFromFollowers'))['polls'];
    for (Map<String, dynamic> object in map) {
      list.add(Poll.fromJson(object));
    }
    return list;
  }

  static Future<UserInfo> editMyUserInfo(UserInfo userInfo, {String username}) async {
     if (username != null) {
      userInfo.username = username;
    }
    final dynamic response = await request.put('/me/userInfo/edit', body: userInfo.toJson(),
      contentType: 'application/json'
    );
    dynamic objectJson = (response)['userInfo'];
    return (UserInfo.fromJson(objectJson));
  }
  
  //todo test findFriends
  static Future<List<UserInfo>> findFriends(List<String> phoneNumbers) async {
    final dynamic response = await request.post('/me/findFriends', body: jsonEncode({
      'phoneNumbers': phoneNumbers
    }),
      contentType: 'application/json'
    );
    if(response['statusCode'] == 200){
      dynamic friends = (response)['friends'];
    
      List<UserInfo> list = [];
      for (Map<String, dynamic> object in friends) {
        list.add(UserInfo.fromJson(object));
      }
      return list;
    }
    return Future.error(response['message'].toString());
  }

  static Future<UserInfo> setProfilePicture(String fileName, String encoded) async {
    final dynamic response = await request.put('/users/setProfilePicture', 
      body: jsonEncode({'fileName': fileName, 'base64': encoded}), contentType: 'application/json');
    return UserInfo.fromJson(response['userInfo']);

  }



}
