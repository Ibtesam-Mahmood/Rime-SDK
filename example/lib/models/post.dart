import 'dart:convert';

import '../state/store/storable.dart';
import 'like.dart';
import 'poll.dart';
import 'topics.dart';

class Post extends Storable<Post> {
  Type parentType;
  String parentId;
  String userInfoId;
  String message;
  DateTime timeSubmitted;
  int cachedLikeCount = 0;
  bool vote;
  String videoUrl;
  List<Like> likes;
  List<String> links;
  List<String> images;
  String gifUrl;
  Post(
      {String id,
      this.userInfoId,
      this.message,
      this.timeSubmitted,
      this.parentType,
      this.vote,
      this.parentId,
      this.cachedLikeCount = 0,
      this.likes,
      this.links,
      this.images,
      this.gifUrl,
      this.videoUrl})
      : super(id);
  //todo add vote - agree/disagree count

  static Post basic = Post(
      message: 'Hello Post', timeSubmitted: DateTime(2019, 11, 17, 17, 48));

  factory Post.fromJson(Map<String, dynamic> json) {
    String pt = json['parentType']??'';
    List<String> images = json['images'].cast<String>();
    List<String> links = (json['links'] ?? []).cast<String>();
    links.removeWhere((e) => e?.isEmpty != false);
    // }catch(e){images = [];}
    try {
      return Post(
          id: json['_id'],
          parentType: pt == null ? null : pt == 'topic' ? Topic : Poll,
          parentId: json['parentId'],
          userInfoId: json['userInfoId'],
          message: json['message'],
          vote: json['vote'],
          links: links,
          cachedLikeCount: json['cachedLikeCount'] ?? 0,
          timeSubmitted: DateTime.parse(json['timeSubmitted']),
          images: images,
          gifUrl: json['gif'],
          videoUrl: json['video']
        );
    } catch (e) {

      return null;
    }
  }

  //Used to validate if this is a valid post model or not
  @override
  bool validate() {
    return !(parentId == null ||
        parentType == null ||
        message == null ||
        userInfoId == null);
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'userInfoId': userInfoId,
      'parentType': parentType,
      'parentId': parentId,
      'message': message,
      'links': links,
      'vote': vote,
      'timeSubmitted': timeSubmitted.toIso8601String()
    };
    return jsonEncode(object);
  }

  String toAddPostJson({bool hidden=false}) {
    Map<String, dynamic> object = {
      'userInfoId': userInfoId,
      'message': message,
      'vote': vote,
      'links': links,
      'images':
          images != null ? images.map((img) => jsonDecode(img)).toList() : [],
      'gif': gifUrl,
      'hidden': hidden,
      'video': videoUrl != null ? jsonDecode(videoUrl) : null
    };
    return jsonEncode(object);
  }

  String toEditPostJson() {
    Map<String, dynamic> object = {
      'userInfoId': userInfoId,
      'message': message,
      'links': links,
      'vote': vote,
    };
    return jsonEncode(object);
  }

  @override
  Post copy() {
    return Post(
        id: id,
        cachedLikeCount: cachedLikeCount,
        likes: likes,
        message: message,
        parentId: parentId,
        parentType: parentType,
        vote: vote,
        links: links,
        timeSubmitted: timeSubmitted,
        userInfoId: userInfoId,
        images: images,
        gifUrl: gifUrl,
        videoUrl: videoUrl
      );
  }

  @override
  Post copyWith(Post other) {
    if (other == null) return this;
    return Post(
        id: id,
        cachedLikeCount: other.cachedLikeCount ?? cachedLikeCount,
        likes: other.likes ?? likes,
        message: other.message ?? message,
        parentId: parentId,
        parentType: parentType,
        vote: other.vote ?? vote,
        links: other.links ?? links,
        timeSubmitted: other.timeSubmitted ?? timeSubmitted,
        userInfoId: other.userInfoId ?? userInfoId,
        images: other.images ?? images,
        gifUrl: other.gifUrl ?? gifUrl,
        videoUrl: other.videoUrl ?? videoUrl
    );
  }

  ///Returns true if objects are the same
  ///Returns false if the objects are not the same
  @override
  bool compare(Post comparable) {
    if (comparable == null) return false;

    bool compare = id == comparable.id &&
        cachedLikeCount == comparable.cachedLikeCount &&
        likes == comparable.likes &&
        message == comparable.message &&
        parentId == comparable.parentId &&
        parentType == comparable.parentType &&
        vote == comparable.vote &&
        timeSubmitted == comparable.timeSubmitted &&
        userInfoId == comparable.userInfoId &&
        links == comparable.links &&
        images?.length == comparable.images?.length &&
        gifUrl == comparable.gifUrl &&
        videoUrl == comparable.videoUrl;

    return compare;
  }
}