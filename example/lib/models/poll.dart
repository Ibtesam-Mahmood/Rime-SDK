import 'dart:convert';

import '../state/store/storable.dart';
import 'pollResponse.dart';
import 'rule.dart';

class Report {}

class Poll extends Storable<Poll> {
  String userInfoId;
  DateTime timeSubmitted;
  String topicId;
  List<dynamic> posts;
  List<dynamic> pollResponses;
  String title;
  String content;
  int agrees;
  int disagrees;
  List<String> links;
  PollResponse yourVote;
  List<String> images;
  Type type;
  String status;
  String gifUrl;
  bool anonymous;
  String videoUrl;

  Poll(
      {String id,
      this.userInfoId,
      this.timeSubmitted,
      this.topicId,
      this.posts,
      this.pollResponses,
      this.title,
      this.links,
      this.content,
      this.images,
      this.agrees,
      this.disagrees,
      this.yourVote,
      this.status,
      this.type,
      this.gifUrl,
      this.anonymous,
      this.videoUrl})
      : super(id);

  factory Poll.fromJson(Map<String, dynamic> json, [Map<String, dynamic> voteJson]) {
    if (json == null) return Poll();
    List<String> images;
    if (json['images'] != null) {
      images = json['images'].cast<String>();
    } else {
      images = [];
    }
    DateTime dt;
    if (json['timeSubmitted'] != null) {
      dt = DateTime.parse(json['timeSubmitted']);
    } else {
      dt = null;
    }
    List<String> links = (json['links']??[]).cast<String>();
    links.removeWhere((e) => e?.isEmpty != false);
    return Poll(
        posts: json['posts'],
        pollResponses: json['pollResponses'],
        id: json['_id'],
        userInfoId: json['userInfoId'],
        timeSubmitted: dt, //json['timeSubmitted'], //todo convert to date time
        topicId: json['topicId'],
        title: json['title'],
        links: links,
        agrees: voteJson == null ? null : voteJson['agree'] ?? 0,
        disagrees: voteJson == null ? null : voteJson['disagree'] ?? 0,
        content: json['content'],
        images: images,
        status: json['status'],
        gifUrl: json['gif'],
        type: json['type'] == 'Rule'
            ? Rule
            : json['type'] == 'Report' ? Report : Poll,
        anonymous: json['anonymous'] == true,
        videoUrl: json['video']
      );
            
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'userInfoId': userInfoId,
      'timeSubmitted': timeSubmitted.toIso8601String(),
      'topicId': topicId,
      'posts': posts,
      'pollResponses': pollResponses,
      'title': title,
      'links': links,
      'content': content,
      'status': status,
      'images': images,
      'video': videoUrl
    };
    return jsonEncode(object);
  }

  String toCreatePollJson() {
    Map<String, dynamic> object = {
      'userInfoId': userInfoId,
      'topicId': topicId,
      'title': title,
      'links': links,
      'content': content,
      'status': status,
      'gif': gifUrl,
      'anonymous': anonymous,
      'images': images.map((img) => jsonDecode(img)).toList(),
      'video': videoUrl == null ? null : jsonDecode(videoUrl)
    };
    return jsonEncode(object);
  }

  String toEditPollJson() {
    Map<String, dynamic> object = {
      'title': title,
      'content': content,
      'links': links,
    };
    return jsonEncode(object);
  }

  //Converts rule typed polls into a rule
  Rule get toRule {
    if (type == Poll) return null; //Not a rule type poll
    return Rule(content: content, title: title, topicId: topicId, pollId: id);
  }

  @override
  Poll copy() {
    return Poll(
        id: id,
        content: content,
        posts: posts,
        pollResponses: pollResponses,
        timeSubmitted: timeSubmitted,
        title: title,
        topicId: topicId,
        userInfoId: userInfoId,
        agrees: agrees,
        disagrees: disagrees,
        yourVote: yourVote,
        images: images,
        status: status,
        links: links,
        type: type,
        gifUrl: gifUrl, anonymous: anonymous, videoUrl: videoUrl);
  }

  @override
  Poll copyWith(Poll other) {
    if (other == null) return this;

    return Poll(
        id: id,
        content: other.content ?? content,
        posts: other.posts ?? posts,
        pollResponses: other.pollResponses ?? pollResponses,
        timeSubmitted: other.timeSubmitted ?? timeSubmitted,
        title: other.title ?? title,
        topicId: other.topicId ?? topicId,
        userInfoId: other.userInfoId ?? userInfoId,
        agrees: other.agrees ?? agrees,
        disagrees: other.disagrees ?? disagrees,
        yourVote: other.yourVote ?? yourVote,
        links: other.links ?? links,
        status: other.status?? status,
        images: other.images ?? images,
        type: other.type ?? type,
        gifUrl: other.gifUrl ?? gifUrl,
        anonymous: other.anonymous ?? anonymous,
        videoUrl: other.videoUrl ?? videoUrl 
    );
  }

  //Used to validate if this is a valid poll model or not
  @override
  bool validate() {
    return !(id == null ||
        topicId == null ||
        content == null ||
        userInfoId == null);
  }

  ///Returns true if objects are the same
  ///Returns false if the objects are not the same
  @override
  bool compare(Poll comparable) {
    if (comparable == null) return false;

    bool compare = id == comparable.id &&
        content == comparable.content &&
        posts?.length == comparable.posts?.length &&
        pollResponses?.length == comparable.pollResponses?.length &&
        timeSubmitted == comparable.timeSubmitted &&
        title == comparable.title &&
        topicId == comparable.topicId &&
        yourVote?.vote == comparable.yourVote?.vote &&
        userInfoId == comparable.userInfoId &&
        images == comparable.images &&
        type == comparable.type &&
        agrees == comparable.agrees &&
        status == comparable.status &&
        links == comparable.links &&
        disagrees == comparable.disagrees &&
        gifUrl == comparable.gifUrl &&
        anonymous == comparable.anonymous &&
        videoUrl == comparable.videoUrl;

    return compare;
  }

  @override
  bool operator==(other) {
    if(other is Poll) 
      {return other.id == id;}
    else
      {return false;}
  }

  @override
  int get hashCode => super.hashCode;


}
