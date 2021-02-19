import 'dart:convert';

import 'package:pollar/api/request.dart';
import 'package:pollar/models/post.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';
import 'package:tuple/tuple.dart';

class PostApi {
  static Future<List<Post>> getPosts({int size, String query, bool store = true}) async {
    List<Post> postResponses = [];
    List<dynamic> postMap =
        (await request.get('/post/posts?size=$size${query != null ? '&' : ''}${query ?? ''}'))['posts'];
    for (Map<String, dynamic> post in postMap) {
      Post newPost = Post.fromJson(post);
      try{
        if (newPost.validate()) {
          postResponses.add(newPost);
        }
      }
      catch(e){
        print(e);
      }
    }

    if(store){
      PollarStoreBloc().batchStore<Post>(postResponses);}

    return postResponses;
  }

  static Future<Post> getPostById(String postId) async {
    Post cachedPost = PollarStoreBloc().retreive<Post>(postId);

    //Load cached post if already loaded
    if (cachedPost != null) return cachedPost;

    dynamic objectJson = (await request.get('/post/posts/' + postId))['post'];

    Post newPost;
    if(objectJson != null){
      //Post loaded
      newPost = Post.fromJson(objectJson);
    }
    else{
      //Post not found
      newPost = Post(id: postId);
    }


    //Stores the loaded post
    PollarStoreBloc().store(newPost);

    return newPost;
  }

  static Future<Post> editPost(Post post) async {
    Future<dynamic> objectJson = (request.put('/post/posts/' + post.id,
        body: post.toEditPostJson(), contentType: 'application/json'));

    //Updates the store
    PollarStoreBloc().store(post);

    return Post.fromJson((await objectJson)['post']);
  }

  static Future<bool> deletePost(String postId) async {
    //Deletes the post from the store
    // PollarStoreBloc().remove<Post>(postId);

    dynamic objectJson = (await request.delete('/post/posts/' + postId));
    return objectJson['error'] == false;
  }

  //todo test
  static Future<List<Post>> getPostByUserId(String userInfoId, [int size = 4]) async {
    List<Post> posts = [];
    List<dynamic> postMap = (await request.get('/post/posts?size=$size&userInfoId=$userInfoId'))['posts'];
    for (Map<String, dynamic> post in postMap) {
      posts.add(Post.fromJson(post));
    }
    //Validates list of posts and removes invalid posts
    try{
      posts.removeWhere((p) => !p.validate());
    }
    catch(e){
      print(e);
    }

    //Batch stores the list of posts
    PollarStoreBloc().batchStore<Post>(posts);

    return posts;
  }

  //todo test
  static Future<Post> createPollPost(Post post, {bool hidden = false}) async {
    dynamic objectJson = (await request.post('/post/poll/' + post.parentId,
        body: post.toAddPostJson(hidden: hidden),
        contentType: 'application/json'))['post'];

    return (Post.fromJson(objectJson));
  }

  //todo test
  static Future<Post> createTopicPost(Post post) async {
    dynamic objectJson = (await request.post('/post/topic/' + post.parentId,
        body: post.toAddPostJson(), contentType: 'application/json'));
    return (Post.fromJson(objectJson['post']));
  }

  //todo test
  static Future<Tuple2<List<Post>, bool>> getPostsByPollId(String pollId,
      {int size = 10}) async {
    List<Post> posts = [];
    List<dynamic> postMap =
        (await request.get('/post/poll/' + pollId))['posts'];
    for (Map<String, dynamic> post in postMap) {
      Post newPost = Post.fromJson(post);

      Post cachedPost = PollarStoreBloc().retreive<Post>(newPost.id);

      //If cached post exsists
      if (cachedPost != null) {
        newPost.likes = cachedPost.likes;
      }

      posts.add(Post.fromJson(post));
    }

    //Validates list of posts and removes invalid posts
    posts.removeWhere((p) => !p.validate());

    //Batch stores the list of posts
    PollarStoreBloc().batchStore<Post>(posts);

    return Tuple2(posts, false);
  }

  static Future<Tuple2<List<Post>, bool>> getHomePagePosts(DateTime startTime,
    [int size = 10]) async {
    List<Post> posts = [];
    dynamic objectJson = await request.put('/content/posts?size=$size',
        body: jsonEncode({
          'date':
              startTime.toUtc().toString() ?? DateTime.now().toUtc().toString()
        }),
        contentType: 'application/json');
    List<dynamic> postMap = objectJson['posts'];

    //Adds the post to the list and updates it with cahced information
    for (Map<String, dynamic> post in postMap) {
      Post newPost = Post.fromJson(post);

      Post cachedPost = PollarStoreBloc().retreive<Post>(newPost.id);

      //If cached post exsists
      if (cachedPost != null) {
        newPost.likes = cachedPost.likes;
      }

      posts.add(newPost);
    }

    //Validates list of posts and removes invalid posts
    posts.removeWhere((p) => !p.validate());

    //Batch stores the list of posts
    PollarStoreBloc().batchStore<Post>(posts);

    //Returns the list along with a boolean representing new posts found past the start time
    return Tuple2(posts, objectJson['newPosts']);
  }

  static Future<List<Post>> getPostsByTopic(String topicId,
      {int size = 10}) async {
    if ((topicId ?? '').isEmpty) return [];

    List<Post> posts = [];
    dynamic objectJson = await request.get('/topic/$topicId/posts?size=$size');
    List<dynamic> postMap = objectJson['posts'];

    //Adds the post to the list and updates it with cahced information
    for (Map<String, dynamic> post in postMap) {
      Post newPost = Post.fromJson(post);

      Post cachedPost = PollarStoreBloc().retreive<Post>(newPost.id);

      //If cached post exsists
      if (cachedPost != null) {
        newPost.likes = cachedPost.likes;
      }

      posts.add(newPost);
    }

    //Validates list of posts and removes invalid posts
    posts.removeWhere((p) => !p.validate());

    //Batch stores the list of posts
    PollarStoreBloc().batchStore<Post>(posts);

    //Returns the list of posts
    return posts;
  }
}
