import 'package:pollar/api/request.dart';
import 'package:pollar/models/follow.dart';
import 'package:pollar/models/userInfo.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';

class FollowApi {
  //NOT YET IMPLEMENTED ON SERVER SO CANNOT USE YET
  //example of query string String q = 'userInfoId=id&ect=123&w=5'
  static Future<List<Follow>> getAllFollows({queryString = ''}) async {
    List<Follow> objects = [];
    queryString = queryString != '' ? '?+' + queryString : queryString;

    final dynamic response = await request.get('/follow/follows' + queryString);
    List<dynamic> objectsJson = (response)['follows'];
    for (Map<String, dynamic> objectJson in objectsJson) {
      objects.add(Follow.fromJson(objectJson));
    }
    return objects;
  }

  static Future<List<Follow>> getFollwersByUserId(String userInfoId) async {
    List<Follow> objects = [];
    String queryString = '?recipientId=' + userInfoId;

    final dynamic response = await request.get('/follow/follows' + queryString);
    List<dynamic> objectsJson = (response)['follows'];
    for (Map<String, dynamic> objectJson in objectsJson) {
      objects.add(Follow.fromJson(objectJson));
    }

    //Retrevies the user from the store and checks if its followers list is populated
    UserInfo user = PollarStoreBloc().retreive<UserInfo>(userInfoId);

    //Saves the followers to the user in the store if the user exsists
    if(user != null){
      PollarStoreBloc().store(user.copyWith(UserInfo(followers: objects)));
    }

    return objects;
  }

  static Future<List<Follow>> getFollowingByUserId(String userInfoId) async {
    List<Follow> objects = [];
    String queryString = '?userInfoId=' + userInfoId;

    final dynamic response = await request.get('/follow/follows' + queryString);
    List<dynamic> objectsJson = (response)['follows'];
    for (Map<String, dynamic> objectJson in objectsJson) {
      objects.add(Follow.fromJson(objectJson));
    }

    //Retrevies the user from the store and checks if its following list is populated
    UserInfo user = PollarStoreBloc().retreive<UserInfo>(userInfoId);
    //Saves the following list to the user in the store if the user exsists
    if(user != null){
      PollarStoreBloc().store(user.copyWith(UserInfo(following: objects)));
    }

    return objects;
  }

  static Future<Follow> getFollowFromId(String id) async {
    final dynamic response = await request.get('/follow/follows/' + id);
    dynamic objectJson = (response)['follow'];
    return (Follow.fromJson(objectJson));
  }

  static Future<Follow> followUser(String recipientUserInfoId) async {

    String loggedInUserID = PollarStoreBloc().loggedInUserID;

    //Retreives the loggedInUser and receipientUser to update the followers/following for faster response time
    UserInfo loggedInUser = PollarStoreBloc().retreive<UserInfo>(loggedInUserID);
    UserInfo recipientUser = PollarStoreBloc().retreive<UserInfo>(recipientUserInfoId);

    Follow newFollow = Follow(id: '', recipientId: recipientUserInfoId, userInfoId: loggedInUserID);

    //fast reponse time function
    if(loggedInUser != null){
      List<Follow> userFollows = List<Follow>.from(loggedInUser.following ?? []);
      userFollows.add(newFollow);
      PollarStoreBloc().store(loggedInUser.copyWith(UserInfo(following: userFollows)));
    }
    //Stores and modifies the receipint if found
    if(recipientUser != null){
      List<Follow> userFollows = List<Follow>.from(recipientUser.followers ?? []);
      userFollows.add(newFollow);
      PollarStoreBloc().store(recipientUser.copyWith(UserInfo(followers: userFollows)));
    }

    //Submits the request to the backend
    final dynamic response = await request.put('/follow/user/' + recipientUserInfoId);
    dynamic objectJson = (response)['follow'];
    return (Follow.fromJson(objectJson));
  }

  static Future<Follow> unfollowUser(String recipientUserInfoId) async {

    //Retreives the loggedInUser and receipientUser to update the followers/following for faster response time
    UserInfo loggedInUser = PollarStoreBloc().retreive<UserInfo>(PollarStoreBloc().loggedInUserID);
    UserInfo recipientUser = PollarStoreBloc().retreive<UserInfo>(recipientUserInfoId);

    //fast reponse time function
    if(loggedInUser != null){
      List<Follow> userFollows = List<Follow>.from(loggedInUser.following ?? []);
      userFollows.removeWhere((follow) => follow.recipientId == recipientUserInfoId);
      PollarStoreBloc().store(loggedInUser.copyWith(UserInfo(following: userFollows)));
    }
    //Stores and modifies the receipint if found
    if(recipientUser != null){
      List<Follow> userFollows = List<Follow>.from(recipientUser.followers ?? []);
      userFollows.removeWhere((follow) => follow.recipientId == recipientUserInfoId);
      PollarStoreBloc().store(recipientUser.copyWith(UserInfo(followers: userFollows)));
    }

    //Submits the request to the backend
    final dynamic response = await request.delete('/follow/user/' + recipientUserInfoId);
    dynamic objectJson = (response)['follow'];
    return ((objectJson));
  }

}
