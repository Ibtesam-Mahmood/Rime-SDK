import 'dart:convert';

import '../state/store/storable.dart';

class Subscription extends Storable<Subscription>{
  String subID;
  String userInfoId;
  String topicId;
  String topic;
  bool show;

  //Subscriptions base thier storeable ID on their topicID
  Subscription({
    this.subID,
    this.userInfoId,
    this.topicId,
    this.topic,
  }) : super(topicId);

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      subID: json['_id'],
      userInfoId: json['userInfoId'],
      topicId: json['topicId'],
      topic: json['topic'],
    );
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': subID,
      'userInfoId': userInfoId,
      'topicId': topicId,
      'topic': topic

    };
    return jsonEncode(object);
  }

  @override
  Subscription copy() {
    return Subscription(
      subID: subID,
      topic: topic,
      topicId: topicId,
      userInfoId: userInfoId
    );
  }

  ///Returns true if objects are the same
  ///Returns false if the objects are not the same
  @override
  bool compare(Subscription comparable) {
    
    if(comparable == null) return false;

    bool compare = 
      subID == comparable.subID &&
      topic == comparable.topic &&
      topicId == comparable.topicId &&
      userInfoId == comparable.userInfoId;

    return compare;
  }

  @override
  Subscription copyWith(Subscription copy) {
    if(copy == null) return this;

    return Subscription(
      subID: subID,
      topicId: copy.topicId ?? topicId,
      topic: copy.topic ?? topic,
      userInfoId: copy.userInfoId ?? userInfoId
    );
  }

  ///Validates the object for errors
  @override
  bool validate() {
    return true;
  }
  
}
