import 'package:pollar/api/request.dart';
import 'package:pollar/models/trust.dart';
import 'package:pollar/models/userInfo.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';

class TrustApi {
  //example of query string String q = 'userInfoId=id&ect=123&w=5'
  static Future<List<Trust>> getAllTrusts({queryString= ''}) async {
    List<Trust> objects = [];
    queryString = queryString != '' ? '?' + queryString : queryString;

    final dynamic response = await request.get('/trust/trusts' + queryString);
    List<dynamic> objectsJson = (response)['trusts'];
    for (Map<String, dynamic> objectJson in objectsJson) {
      objects.add(Trust.fromJson(objectJson));
    }

    return objects;
  }

  ///[Refresh] - allows for skipping of cache check
  static Future<List<Trust>> getWhoAUserTrusts(String userInfoId, [bool refresh = false]) async {

    UserInfo cachedUser = PollarStoreBloc().retreive<UserInfo>(userInfoId);

    if(cachedUser?.whoITrust != null && refresh != true){
      //Returns trusts if already loaded
      return cachedUser.whoITrust;
    }

    List<Trust> trusts = await getAllTrusts(queryString: 'userInfoId=$userInfoId');

    //If a cahced user exsists, saves trusts in the user
    //Reretreives the user for relevanecy
    cachedUser = PollarStoreBloc().retreive<UserInfo>(userInfoId);
    if(cachedUser != null){
      cachedUser.whoITrust = trusts;

      PollarStoreBloc().store(cachedUser);
    }

    return trusts;
  }

  ///[Refresh] - allows for skipping of cache check
  static Future<List<Trust>> getWhoTrustsAUser(String userInfoId, [bool refresh = false]) async {

    UserInfo cachedUser = PollarStoreBloc().retreive<UserInfo>(userInfoId);

    if(cachedUser?.whoTrustsMe != null && refresh != true){
      //Returns trusts if already loaded
      return cachedUser.whoTrustsMe;
    }


    List<Trust> trusts = await getAllTrusts(queryString: 'recipientId=$userInfoId');

    //If a cahced user exsists, saves trusts in the user
    //Reretreives the user for relevanecy
    if(cachedUser != null){
      cachedUser.whoTrustsMe = trusts;

      PollarStoreBloc().store(cachedUser);
    }

    return trusts;
  }

  static Future<Trust> getTrustFromId(String id) async {
    final dynamic response = await request.get('/trust/trusts/' + id);
    dynamic objectJson = (response)['trust'];
    return (Trust.fromJson(objectJson));
  }

  static Future<Trust> deleteTrustFromId(String id) async {
    final dynamic response = await request.delete('/trust/trusts/' + id);
    dynamic objectJson = (response)['trust'];
    return (Trust.fromJson(objectJson));
  }

  static Future<bool> trustUser(String userId, String topicId) async {
    
    //Saves the trust in the login and recipient user
    UserInfo loginUser = PollarStoreBloc().retreive<UserInfo>(PollarStoreBloc().loggedInUserID);
    UserInfo recipientUser = PollarStoreBloc().retreive<UserInfo>(userId);

    Trust newTrust = Trust(recipientId: userId, userInfoId: PollarStoreBloc().loggedInUserID, topic: topicId);

    //Stores and modifies the user if found
    if(loginUser != null){
      List<Trust> userTrusts = List<Trust>.from(loginUser.whoITrust ?? []);
      userTrusts.add(newTrust);
      PollarStoreBloc().store(loginUser.copyWith(UserInfo(whoITrust: userTrusts)));
    }
    //Stores and modifies the receipint if found
    if(recipientUser != null){
      List<Trust> userTrusts = List<Trust>.from(recipientUser.whoTrustsMe ?? []);
      userTrusts.add(newTrust);
      PollarStoreBloc().store(recipientUser.copyWith(UserInfo(whoTrustsMe: userTrusts)));
    }

    await request.put('/trust/trustUser/' + userId + '/' + topicId);
    // dynamic objectJson = (response)['trust'];
    return (true);
  }
  static Future<bool> untrustUser(String userId, String topicId) async {

    String loginUserID = PollarStoreBloc().loggedInUserID;

    //Removes the trust in the login and recipient user
    UserInfo loginUser = PollarStoreBloc().retreive<UserInfo>(loginUserID);
    UserInfo recipientUser = PollarStoreBloc().retreive<UserInfo>(userId);

    //Stores and modifies the user if found
    if(loginUser != null){
      List<Trust> userTrusts = List<Trust>.from(loginUser.whoITrust ?? []) ;
      userTrusts.removeWhere((trust) => trust.topic == topicId && trust.recipientId == userId);
      PollarStoreBloc().store(loginUser.copyWith(UserInfo(whoITrust: userTrusts)));
    }
    //Stores and modifies the receipint if found
    if(recipientUser != null){
      List<Trust> userTrusts = List<Trust>.from(recipientUser.whoTrustsMe ?? []);
      userTrusts.removeWhere((trust) => trust.topic == topicId && trust.userInfoId == loginUserID);
      PollarStoreBloc().store(recipientUser.copyWith(UserInfo(whoTrustsMe: userTrusts)));
    }

    await request.delete('/trust/trustUser/' + userId + '/' + topicId);
    // dynamic objectJson = (response)['message'];
    return (true);
  }
}
