import 'dart:convert';

class PollResponse {
  String id;
  String pollId;
  String userInfoId;
  bool vote;
  DateTime createdAt;

  PollResponse({this.id, this.pollId, this.userInfoId, this.vote, this.createdAt});

  factory PollResponse.fromJson(Map<String, dynamic> json) {
    return PollResponse(
      id: json['_id'],
      pollId: json['pollId'],
      userInfoId: json['userInfoId'],
      vote: json['vote'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()
    );
  }
  

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'pollId': pollId,
      'userInfoId': userInfoId,
      'vote': vote
    };
    return jsonEncode(object);
  }

  String voteJson() {
    Map<String, dynamic> object = {'vote': vote};
    return jsonEncode(object);
  }
  String toEditPollResponseJson() {
    Map<String, dynamic> object = {'vote': vote};
    return jsonEncode(object);
  }

  PollResponse copy(){
    return PollResponse(
      id: id,
      pollId: pollId,
      userInfoId: userInfoId,
      vote: vote,
      createdAt: createdAt
    );
  }
}
