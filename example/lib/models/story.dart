import 'dart:convert';

import '../state/store/storable.dart';
import 'poll.dart';
import 'pollResponse.dart';
import 'topics.dart';

class Story extends Storable<Story> { 
  //BIG NOTE: the trusting poll response is implemented as the user who is trusted 
  String userInfoId;
  String trustingUserInfoId;
  String pollId;
  String pollResponseId;
  String trustingPollResponseId;
  DateTime timeSubmitted;
  PollResponse pollRes;
  PollResponse yourRes;
  String topicId;
  Topic topic;
  Poll poll;
  bool seen;

  Story({
    String id,
    this.userInfoId,
    this.trustingUserInfoId,
    this.pollId,
    this.pollResponseId,
    this.timeSubmitted,
    this.pollRes,
    this.yourRes,
    this.trustingPollResponseId,
    this.topicId,
    this.poll,
    this.seen,
  }) : super(id);

  factory Story.fromJson(Map<String, dynamic> json) {
    try {
      return Story(
        id: json['_id'],
        userInfoId: json['trustingUserInfoId'],
        trustingUserInfoId: json['userInfoId'],
        pollId: json['pollId'],
        pollResponseId: json['pollResponseId'],
        topicId: json['topicId'],
        trustingPollResponseId: json['trustingPollResponseId'],
        timeSubmitted: DateTime.parse(json['date']),
        seen: json['seen'],
      );
    } catch (e) {
      return null;
    }
  }
  String seeStory() {
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
        trustingUserInfoId == null ||
        pollId == null ||
        pollResponseId == null);
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'userInfoId': userInfoId,
      'trustingUserInfoId': trustingUserInfoId,
      'pollId': pollId,
      'pollResponseId': pollResponseId,
      'topicId': topicId,
      'trustingPollResponseId': trustingPollResponseId,
      'timeSubmitted': timeSubmitted.toIso8601String(),
      'seen': seen,
    };
    return jsonEncode(object);
  }

  @override
  Story copy() {
    return Story(
      id: id,
      userInfoId: userInfoId,
      trustingUserInfoId: trustingUserInfoId,
      pollId: pollId,
      pollResponseId: pollResponseId,
      timeSubmitted: timeSubmitted,
      pollRes: pollRes,
      topicId: topicId,
      yourRes: yourRes,
      trustingPollResponseId: trustingPollResponseId,
      poll: poll,
      seen: seen,
    );
  }

  @override
  Story copyWith(Story other) {
    if (other == null) return this;
    return Story(
      id: other.id ?? id,
      userInfoId: other.userInfoId ?? userInfoId,
      trustingUserInfoId: other.trustingUserInfoId ?? trustingUserInfoId,
      pollId: other.pollId ?? pollId,
      pollResponseId: other.pollResponseId ?? pollResponseId,
      timeSubmitted: other.timeSubmitted ?? timeSubmitted,
      pollRes: other.pollRes ?? pollRes,
      topicId: other.topicId ?? topicId,
      yourRes: other.yourRes?? yourRes,
      trustingPollResponseId: other.trustingPollResponseId ?? trustingPollResponseId,
      poll: other.poll ?? poll,
      seen: other.seen ?? seen,
    );
  }

  ///Returns true if objects are the same
  ///Returns false if the objects are not the same
  @override
  bool compare(Story comparable) {
    if (comparable == null) return false;

    bool compare = id == comparable.id &&
        userInfoId == comparable.userInfoId &&
        trustingUserInfoId == comparable.trustingUserInfoId &&
        pollId == comparable.pollId &&
        pollResponseId == comparable.pollResponseId &&
        timeSubmitted == comparable.timeSubmitted &&
        topicId == comparable.topicId &&
        yourRes == comparable.yourRes &&
        trustingPollResponseId == comparable.trustingPollResponseId &&
        seen == comparable.seen;

    return compare;
  }
}
