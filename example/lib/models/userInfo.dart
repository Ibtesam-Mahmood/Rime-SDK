import 'dart:convert';

import '../state/store/storable.dart';
import 'follow.dart';
import 'post.dart';
import 'topics.dart';
import 'trust.dart';

class UserInfo extends Storable<UserInfo> {
  String userMainId;
  String firstName;
  String lastName;
  String gender;
  String profilePicture;
  String modTopic;
  List<Post> posts;
  List<Topic> subscribedTopic;
  List<Follow> followers;
  List<Follow> following;
  List<Trust> whoITrust;
  List<Trust> whoTrustsMe;
  String username;

  UserInfo(
      {String id,
      this.userMainId,
      this.firstName,
      this.lastName,
      this.gender,
      this.posts, //TODO: add to json calls after backend implementation
      this.subscribedTopic,
      this.profilePicture,
      this.followers,
      this.following,
      this.whoITrust,
      this.whoTrustsMe,
      this.modTopic,
      this.username})
      : super(id);

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
        id: json['_id'],
        userMainId: json['userMainId'],
        firstName: json['firstName'],
        username: json['username'],
        lastName: json['lastName'],
        gender: json['gender'],
        profilePicture: json['profilePicture']);
  }

  ///Clears all subsiray information on a userinfo object.
  ///Retains base information
  factory UserInfo.clearInfo(UserInfo original) {
    return UserInfo(
        id: original.id,
        userMainId: original.userMainId,
        firstName: original.firstName,
        username: original.username,
        lastName: original.lastName,
        gender: original.gender,
        profilePicture: original.profilePicture);
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'userMainId': userMainId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'profilePicture': profilePicture
    };
    return jsonEncode(object);
  }

  String toEditUserInfoJson() {
    Map<String, dynamic> object = {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'gender': gender,
    };
    return jsonEncode(object);
  }

  String sendTopicJson(topic) {
    Map<String, dynamic> object = {
      'topic': topic,
    };
    return jsonEncode(object);
  }

  //Retruns a copy of the userInfo
  @override
  UserInfo copy() {
    return UserInfo(
      firstName: firstName,
      lastName: lastName,
      followers: followers,
      following: following,
      username: username,
      id: id,
      profilePicture: profilePicture,
      subscribedTopic: subscribedTopic,
      userMainId: userMainId,
      whoITrust: whoITrust,
      whoTrustsMe: whoTrustsMe,
      gender: gender,
      modTopic: modTopic,
    );
  }

  //Creates a new usermain with copied over values
  //Has null checking around new user
  //Has null checking for new user values
  @override
  UserInfo copyWith(UserInfo newUser) {
    return UserInfo(
        id: id,
        firstName: newUser?.firstName ?? firstName,
        lastName: newUser?.lastName ?? lastName,
        followers: newUser?.followers ?? followers,
        following: newUser?.following ?? following,
        username: newUser?.username ?? username,
        gender: newUser?.gender ?? gender,
        subscribedTopic: newUser?.subscribedTopic ?? subscribedTopic,
        modTopic: newUser?.modTopic ?? modTopic,
        userMainId: userMainId,
        whoITrust: newUser.whoITrust ?? whoITrust,
        whoTrustsMe: newUser.whoTrustsMe ?? whoTrustsMe,
        profilePicture: newUser.profilePicture ?? profilePicture);
  }

  ///Returns true if objects are the same
  ///Returns false if the objects are not the same
  @override
  bool compare(UserInfo comparable) {
    if (comparable == null) return true;

    bool compare = id == comparable.id &&
        firstName == comparable.firstName &&
        lastName == comparable.lastName &&
        followers?.length == comparable.followers?.length &&
        following?.length == comparable.following?.length &&
        gender == comparable.gender &&
        subscribedTopic?.length == comparable.subscribedTopic?.length &&
        userMainId == comparable.userMainId &&
        whoITrust?.length == comparable.whoITrust?.length &&
        whoTrustsMe?.length == comparable.whoTrustsMe?.length &&
        modTopic == comparable.modTopic &&
        username == comparable.username &&
        profilePicture == comparable.profilePicture;

    return compare;
  }

  ///Validates the object for errors
  @override
  bool validate() {
    return !(firstName == null ||
        lastName == null ||
        username == null ||
        userMainId == null);
  }

  //Determines if a user follows another user
  //user2 - user that is checked for following status
  // bool follows(UserInfo user2){
  //   for(var id in followers)
  //     if(val == user2.id) return true;
  //   }
  //   return false;
  // }
}
