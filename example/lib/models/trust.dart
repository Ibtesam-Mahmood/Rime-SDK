import 'dart:convert';

class Trust {
  String id;
  String userInfoId;
  String topic;
  String recipientId;
  int cachedAgreeCount;
  int cachedDisagreeCount;

  Trust({
    this.id,
    this.userInfoId,
    this.topic,
    this.recipientId,
    this.cachedAgreeCount,
    this.cachedDisagreeCount
  });

  factory Trust.fromJson(Map<String, dynamic> json) {
    return Trust(
      id: json['_id'],
      userInfoId: json['userInfoId'],
      topic: json['topicId'],
      recipientId: json['recipientId'],
      cachedAgreeCount: json['cachedAgreeCount'],
      cachedDisagreeCount: json['cachedDisagreeCount']
    );
  }

  ///Search for a userInfoID from a list of trusts to see if they are a trust receipient from the primary user
  static bool searchForTrust(List<Trust> trustList, String userID, String topicId){
    for (Trust trust in trustList) {
      if(trust.userInfoId == userID && trust.topic == topicId){
        return true; //User found in list
      }
    }
    return false; //User not found in list
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'userInfoId': userInfoId,
      'topic': topic,
      'recipientId': recipientId,
    };
    return jsonEncode(object);
  }
  
}
