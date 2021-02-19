import 'package:pollar/api/request.dart';
import 'package:pollar/models/poll.dart';
import 'package:pollar/models/topics.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';
import 'dart:convert';

class TopicApi {
  static Future<List<Topic>> getTopics() async {

    List<Topic> topics = PollarStoreBloc().topicList;

    //Load topics from pollar store
    if(topics != null && topics.isNotEmpty) return topics;

    topics = [];

    dynamic topicJson = await request.get('/topic/topics/');
    for (Map<String, dynamic> topic in topicJson['topics']) {
      topics.add(Topic.fromJson(topic));
    }

    if(topics.isNotEmpty){
      //Store in pollar store
      PollarStoreBloc().add(EditPollarStoreState(topics: topics));
    }

    return topics;
  }

  static Future<Topic> getTopicById(String topicId) async {
    List<Topic> loadedTopics = PollarStoreBloc().topicList;

    if (loadedTopics != null) {
      //Returns the topic early if it exsists within the memory
      for (var topic in loadedTopics) {
        if (topic.id == topicId) {
          return topic;
        }
      }
    }

    dynamic topicMap = (await request.get('/topic/topics/' + topicId))['topic'];

    if (topicMap == null) {return Topic(name: 'null');}

    return Topic.fromJson(topicMap);
  }

  ///Returns the topic for a specific poll
  static Future<Topic> getTopicByPollId(String pollId) async {
    if (pollId.isEmpty) return null;

    Poll cachedPoll = PollarStoreBloc().retreive<Poll>(pollId);

    //If the poll already exsists in cache forwards the request to get topic by id
    if (cachedPoll?.topicId != null) {
      return await getTopicById(cachedPoll?.topicId);
    }

    dynamic topicMap = (await request.get('/topic/byPoll/$pollId'))['topic'];

    Topic loadedTopic = Topic.fromJson(topicMap);

    // if (loadedTopic != null) {
    //   cachedPoll = PollarStoreBloc().retreive<Poll>(pollId);
    //   //Creates a non-valid poll to utilize to cache the topic id by poll request
    //   cachedPoll.copyWith(Poll(topicId: loadedTopic?.id));
    //   PollarStoreBloc().store(cachedPoll);
    // }

    return loadedTopic;
  }

  ///List of popular topics IDs are returned based on the limiting size
  static Future<List<String>> getPopularTopicIds({int size = 5}) async {
    dynamic objectJson = (await request.get('/topic/popularity?size=$size'));

    if (objectJson['statusCode'] == 200) {
      List<String> topicIds = [];
      for (var val in objectJson['topics']) {
        topicIds.add(val[0]);
      }
      return topicIds;
    }

    return Future.error(objectJson['message']);
  }

  ///List of topics returned from topic ids
  static Future<List<Topic>> getBatchTopics(List<String> topicsIds) async {

    List<Topic> loadedTopics = PollarStoreBloc().topicList;
    List<Topic> topics = [];
    if (loadedTopics?.isNotEmpty == true) {
      Map<String, Topic> topicMap = Topic.organizeByID(loadedTopics);

      for (int i = 0; i < topicsIds.length; i++) {
        if (topicMap[topicsIds[i]] != null) {
          topics.add(topicMap[topicsIds[i]]);
        }
      }
      for (int i = 0; i < topics.length; i++) {
        topicsIds.remove(topics[i].id);
      }
    }

    if (topicsIds.isEmpty) return topics;

    dynamic objectJson = (await request.post('/topic/batch',
        body: jsonEncode({
          'topicIds': topicsIds,
        }),
        contentType: 'application/json'));

    if (objectJson['statusCode'] == 200) {
      for (Map<String, dynamic> topic in objectJson['topics']) {
        topics.add(Topic.fromJson(topic));
      }
      return topics;
    }
    return Future.error(objectJson['message']);
  }
}
