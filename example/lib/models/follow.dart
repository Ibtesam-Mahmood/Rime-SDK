import 'dart:convert';

class Follow {
  String id;
  String userInfoId;
  String recipientId;

  Follow({
    this.id,
    this.userInfoId,
    this.recipientId,
  });

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['_id'],
      userInfoId: json['userInfoId'],
      recipientId: json['recipientId'],
    );
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'userInfoId': userInfoId,
      'recipientId': recipientId,
    };
    return jsonEncode(object);
  }

  ///Search for a userInfoID from a list of follows to see if they are a follow receipient from the primary user
  static bool searchFollowingByUserID(List<Follow> following, String userID){
    for (Follow follow in following) {
      if(follow.recipientId == userID){
        return true; //User found in list
      }
    }
    return false; //User not found in list
  }

  ///Search for a userInfoID from a list of follows to see if they are a follower of the primary user
  static bool searchFollowersByUserID(List<Follow> followers, String userID){
    for (Follow follow in followers) {
      if(follow.userInfoId == userID){
        return true; //User found in list
      }
    }
    return false; //User not found in list
  }
  
}
