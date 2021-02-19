

import 'dart:convert';

import 'package:pollar/api/request.dart';
import 'package:pollar/models/userInfo.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';

class ModeratorApi {

  static const String NotModerator = 'NoTopic';

  ///Returns a list of user Info IDs that moderate on a topic
  static Future<List<String>> getModeratorsOnTopic(String topicId) async {

    List<String> moderators = [];
    List<dynamic> objectJsons = (await request.get('/moderator/getModerators?topicId=$topicId'))['moderators'];
    
    moderators = objectJsons.map<String>((m) => m['userInfoId'] ?? null).toList();

    return moderators;

  }

  ///Allows the user to moderate on a topic
  ///if the user is already moderating it does not change the moderating topic unless override is passed
  ///Returns null if override is false is user is already moderating
  static Future<String> moderate(String topicId, [bool override = false]) async {

    //User is now moderator
    PollarStoreBloc().store(PollarStoreBloc().loginUser.copyWith(UserInfo(modTopic: topicId)));

    dynamic object = await request.put('/moderator/becomeModerator/$topicId', body: jsonEncode({'override': override}), contentType: 'application/json');

    if(object['error'] == true) {return null;}
    else {return topicId;}

  }

  ///Removes the current logged in users moderation value
  static Future<void> unmoderate(String topicId) async {

    String loginUserId = PollarStoreBloc().loggedInUserID;

    //Set mod value to null
    PollarStoreBloc().store(PollarStoreBloc().loginUser.copyWith(UserInfo(modTopic: ModeratorApi.NotModerator)));

    dynamic object = await request.delete('/moderator/user/$loginUserId');

    if(object['error'] == true){ return null;}
    else {return topicId;}

  }

  ///Retreives the moderating topic the user is moderating
  ///Returns null if the user is not moderating a topic
  static Future<String> getUserModeration(String userId) async {

    //Retreives the user from the store
    UserInfo cachedUser = PollarStoreBloc().retreive<UserInfo>(userId);

    if(cachedUser?.modTopic != null){
      return cachedUser.modTopic;
    }

    dynamic object = await request.get('/moderator/user/$userId');

    //The topic for the user moderation
    String moderatorTopic = object['moderator'] != null ? object['moderator']['topicId'] : ModeratorApi.NotModerator;

    //Re-Retreives the user from the store
    cachedUser = PollarStoreBloc().retreive<UserInfo>(userId);

    if(cachedUser != null){
      //Set mod value to null
      PollarStoreBloc().store(cachedUser.copyWith(UserInfo(modTopic: moderatorTopic ?? ModeratorApi.NotModerator)));
    }

    return moderatorTopic;

  }

}