import 'dart:convert';

import '../state/store/storable.dart';
import 'poll.dart';
import 'story.dart';
import 'topics.dart';
import 'userInfo.dart';

class StoryResponse extends Storable<StoryResponse> {
  bool isDifferent;
  String pollId;
  String trustedUserInfoId;
  String userInfoId;
  DateTime date;
  String topicId;
  Topic topic;
  Poll poll;
  bool seen;
  String storyId;
  Story story;
  bool vote;
  UserInfo trustedUser;

  StoryResponse({
    String id,
    this.userInfoId,
    this.trustedUserInfoId,
    this.pollId,
    this.date,
    this.isDifferent,
    this.topic,
    this.topicId,
    this.poll,
    this.storyId,
    this.seen,
    this.vote,
    this.trustedUser,
    this.story,
  }) : super(id);

  factory StoryResponse.fromJson(Map<String, dynamic> json) {
    try {
      return StoryResponse(
        id: json['_id'],
        userInfoId: json['userInfoId'],
        trustedUserInfoId: json['trustedUser'],
        pollId: json['pollId'],
        storyId: json['storyId'],
        topicId: json['topicId'],
        isDifferent: json['isDifferent'],
        date: DateTime.parse(json['date']),
        seen: json['seen'],
      );
    } catch (e) {
      return null;
    }
  }
  String seeStoryResponse() {
    Map<String, dynamic> object = {
      'seen': seen,
    };
    return jsonEncode(object);
  }

  //Used to validate if this is a valid Story model or not
  @override
  bool validate() {
    return !(id == null ||
        userInfoId == null ||
        trustedUserInfoId == null ||
        pollId == null ||
        storyId == null);
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'userInfoId': userInfoId,
      'trustedUser': trustedUserInfoId,
      'pollId': pollId,
      'storyId': storyId,
      'topicId': topicId,
      'isDifferent': isDifferent,
      'date': date.toIso8601String(),
      'seen': seen,
    };
    return jsonEncode(object);
  }

  @override
  StoryResponse copy() {
    return StoryResponse(
      id: id,
      userInfoId: userInfoId,
      trustedUserInfoId: trustedUserInfoId,
      pollId: pollId,
      storyId: storyId,
      date: date,
      isDifferent: isDifferent,
      topicId: topicId,
      topic: topic,
      vote: vote,
      poll: poll,
      trustedUser: trustedUser,
      seen: seen,
      story: story,
    );
  }

  @override
  StoryResponse copyWith(StoryResponse other) {
    if (other == null) return this;
    return StoryResponse(
      id: other.id ?? id,
      userInfoId: other.userInfoId ?? userInfoId,
      trustedUserInfoId: other.trustedUserInfoId ?? trustedUserInfoId,
      pollId: other.pollId ?? pollId,
      storyId: other.storyId ?? storyId,
      date: other.date ?? date,
      isDifferent: other.isDifferent ?? isDifferent,
      topicId: other.topicId ?? topicId,
      topic: other.topic ?? topic,
      vote: other.vote ?? vote,
      poll: other.poll ?? poll,
      trustedUser: other.trustedUser ?? trustedUser,
      seen: other.seen ?? seen,
      story: other.story ?? story,
    );
  }

  ///Returns true if objects are the same
  ///Returns false if the objects are not the same
  @override
  bool compare(StoryResponse comparable) {
    if (comparable == null) return false;

    bool compare = id == comparable.id &&
        userInfoId == comparable.userInfoId &&
        trustedUserInfoId == comparable.trustedUserInfoId &&
        pollId == comparable.pollId &&
        storyId == comparable.storyId &&
        date == comparable.date &&
        topicId == comparable.topicId &&
        seen == comparable.seen;

    return compare;
  }
}
