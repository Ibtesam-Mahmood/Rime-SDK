import 'package:pollar/api/endpoints/followApi.dart';
import 'package:pollar/api/request.dart';
import 'package:pollar/models/like.dart';
import 'package:pollar/models/post.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';

class LikeApi {
  ///Retreives all likes under a post
  static Future<List<Like>> getLikesByPostId(String postId) async {
    List<Like> likes = [];

    //Adds likes to a cachedPost if it exists
    Post cachedPost = PollarStoreBloc().retreive<Post>(postId);

    //Avoids making the likes request if information exsists
    if (cachedPost.likes != null) return cachedPost.likes;

    dynamic objectJson =
        (await request.get('/like/likes?postId=$postId'))['likes'];
    for (var json in objectJson) {
      likes.add(Like.fromJson(json));
    }

    //If stored post isnt null updates and resaves it
    if (cachedPost != null) {
      //Updates the likes
      cachedPost.likes = likes;
      cachedPost.cachedLikeCount = likes.length;

      PollarStoreBloc().store(cachedPost);
    }

    return likes;
  }

  //Retreives the like count for a post, faster call
  static Future<int> getLikeCount(String postId) async {
    dynamic objectJson = (await request.get('/like/post/likeCount/$postId'));

    //Adds likes to a cachedPost if it exsists
    Post cachedPost = PollarStoreBloc().retreive<Post>(postId);

    if (cachedPost != null) {
      cachedPost.cachedLikeCount = objectJson['count'];

      PollarStoreBloc().store(cachedPost);
    }

    return objectJson['count'];
  }

  ///Likes a post for the logged in user
  static Future<int> like(String postId) async {
    //Adds likes to a cachedPost if it exsists
    Post cachedPost = PollarStoreBloc().retreive<Post>(postId);

    if (cachedPost != null) {
      Like newLike = Like(PollarStoreBloc().loggedInUserID, postId);

      //Adds the like
      List<Like> postLikes = List<Like>.from(cachedPost.likes ?? []);
      postLikes.add(newLike);
      PollarStoreBloc().store(cachedPost.copyWith(Post(likes: postLikes)));
    }

    dynamic objectJson = (await request.put('/like/post/$postId'));

    return objectJson['count'];
  }

  ///Unlikes a post for the logged in user
  static Future<int> unlike(String postId) async {
    //Adds likes to a cachedPost if it exsists
    Post cachedPost = PollarStoreBloc().retreive<Post>(postId);

    if (cachedPost != null) {
      //Removes a like
      List<Like> postLikes = List<Like>.from(cachedPost.likes ?? []);

      postLikes.removeWhere(
          (like) => like.userInfoId == PollarStoreBloc().loggedInUserID);

      PollarStoreBloc().store(cachedPost.copyWith(Post(likes: postLikes)));
    }

    dynamic objectJson = (await request.delete('/like/post/$postId'));

    return objectJson['count'];
  }
}
