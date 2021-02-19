import 'dart:convert';
import 'package:pollar/api/request.dart';
import 'package:pollar/models/poll.dart';
import 'package:pollar/models/pollResponse.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';
import 'package:tuple/tuple.dart';

class PollApi {
  static Future<List<Poll>> getPolls([String query = '']) async {
    List<Poll> polls = [];
    List<dynamic> pollMap = (await request.get('/polls?${query ?? ''}'))['polls'];
    for (Map<String, dynamic> poll in pollMap) {
      polls.add(Poll.fromJson(poll));
    }
    PollarStoreBloc().batchStore(polls);
    return polls;
  }

  static Future<Poll> getPollById(String pollId) async {
    Poll cachedPoll = PollarStoreBloc().retreive<Poll>(pollId);

    //Load cached poll if already loaded
    if (cachedPoll != null) return cachedPoll;

    dynamic objectJson = (await request.get('/polls/' + pollId));
    Poll newPoll;

    if (objectJson['statusCode'] == 200) {
      newPoll = Poll.fromJson(objectJson['poll']);
    } else {
      //Poll not found, non valid poll created for error handling
      newPoll = Poll(id: pollId);
    }

    //Stores the loaded poll
    PollarStoreBloc().store(newPoll);

    return newPoll;
  }

  static Future<List<Poll>> getPollsByUserId(String userInfoId, [int size = 4, DateTime timeSubmitted]) async {
    return await getPolls('size=$size&userInfoId=$userInfoId&date=${timeSubmitted.toString()}');
  }

  static Future<Poll> editPoll(Poll poll,
      {String content, String title}) async {
    if (content != null) {
      poll.content = content;
    }
    if (title != null) {
      poll.title = title;
    }
    dynamic objectJson = (await request.put('/polls/' + poll.id + '/edit',
        body: poll.toEditPollJson(), contentType: 'application/json'))['poll'];
    return (Poll.fromJson(objectJson));
  }

  static Future<Poll> createPoll(Poll poll) async {
    dynamic objectJson = (await request.post('/polls/Poll',
        body: poll.toCreatePollJson(),
        contentType: 'application/json'))['poll'];
    return (Poll.fromJson(objectJson));
  }

  static Future<Poll> deletePoll(String pollId) async {
    dynamic objectJson = (await request.delete('/polls/' + pollId));
    return (Poll.fromJson(objectJson));
  }

  static Future<List<Poll>> getPollsByTopicSelection(List<String> topicIDs,
      [int length = 30,
      List<String> removedPolls,
      bool removeNone = false]) async {
    List<Poll> polls = [];

    dynamic objectJsons = (await request.post('/batch/polls?size=$length',
        body: jsonEncode({
          'topics': topicIDs,
          'removePolls': removedPolls,
          'removeNone': removeNone
        }),
        contentType: 'application/json'));

    for (var object in objectJsons['polls']) {
      polls.add(Poll.fromJson(object, objectJsons['voteMap']['${object['_id']}']));
    }

    //Validates list of polls and removes invalid posts
    polls.removeWhere((p) => !p.validate());

    //Batch stores the list of polls
    PollarStoreBloc().batchStore<Poll>(polls);

    return polls;
  }

  static Future<Tuple2<List<Poll>, bool>> getArchivePolls(List<String> topicIDs, {int size = 10}) async {
    List<Poll> polls = [];

    dynamic objectJsons = (await request.post('/archived/polls/voted?size=$size',
        body: jsonEncode({
          'topics': topicIDs,
        }),
        contentType: 'application/json'));

    for (var object in objectJsons['polls']) {
      polls.add(Poll.fromJson(object));
    }

    //Validates list of polls and removes invalid posts
    polls.removeWhere((p) => !p.validate());

    //Batch stores the list of polls
    PollarStoreBloc().batchStore<Poll>(polls);

    return Tuple2<List<Poll>, bool>(polls, objectJsons['newPolls']);
  }

  static Future<List<Poll>> getPollsByTopic(String topicId,
      {int size = 10}) async {
    // if ((topicId ?? '').isEmpty) {
    //   return [];
    // }
    List<Poll> polls = [];
    dynamic objectJson = await request.get('/topic/$topicId/polls?size=$size');
    List<dynamic> pollMap = objectJson['polls'];

    //Adds the poll to the list
    for (Map<String, dynamic> poll in pollMap) {
      Poll newPoll = Poll.fromJson(poll);

      polls.add(newPoll);
    }

    //Validates list of posts and removes invalid posts
    polls.removeWhere((p) => !p.validate());

    //Batch stores the list of posts
    PollarStoreBloc().batchStore<Poll>(polls);

    //Returns the list of posts
    return polls;
  }

  static Future<Poll> getAllPollResponsesForPoll(String pollId) async {
    var response = await request.get('/polls/' + pollId + '/pollresponses');
    List<PollResponse> pollResponses = [];
    int agrees = response['agrees'];
    int disagrees = response['disagrees'];
    PollResponse voted;
    List<dynamic> pollResponseMap = response['pollResponses'];

    for (Map<String, dynamic> pollResponse in pollResponseMap) {
      PollResponse pollR = PollResponse.fromJson(pollResponse);
      pollResponses.add(pollR);
      if (pollR.userInfoId == PollarStoreBloc().loggedInUserID) {
        voted = pollR;
      }
    }
    Poll cachePoll = PollarStoreBloc().retreive<Poll>(pollId);
    if (cachePoll != null) {
      PollarStoreBloc().store(cachePoll.copyWith(
          Poll(agrees: agrees, disagrees: disagrees, yourVote: voted)));
    }

    return cachePoll
        .copyWith(Poll(agrees: agrees, disagrees: disagrees, yourVote: voted));
  }

  ///Retrevies a list of unmoderated polls on the tooic the logged in user moderates
  static Future<List<Poll>> getUnModeratedPollsByTopic({int size = 10}) async {
    List<Poll> polls = [];
    dynamic objectJson = await request.get('/moderator/getModeratorPolls/');
    List<dynamic> pollMap = objectJson['polls'];

    //Adds the poll to the list
    for (Map<String, dynamic> poll in pollMap) {
      Poll newPoll = Poll.fromJson(poll);

      polls.add(newPoll);
    }

    //Validates list of posts and removes invalid posts
    polls.removeWhere((p) => !p.validate());

    //Batch stores the list of posts
    PollarStoreBloc().batchStore<Poll>(polls);

    //Returns the list of posts
    return polls;
  }

  static Future<List<Poll>> getModeratedPollsForTopic(String topicId, String type,{int size = 10, List<String> removedPolls}) async {
    List<Poll> polls = [];
    Map<dynamic, dynamic> pollMap = await request.get('/moderator/getModeratorPolls?size=$size&type=$type',);
    for (Map<String, dynamic> poll in pollMap['polls']) {
      polls.add(Poll.fromJson(poll, pollMap['voteMap']['${poll['_id']}']));
    }
    //Batch stores the list of posts
    PollarStoreBloc().batchStore<Poll>(polls);
    return polls;
  }

  ///List of topics returned from topic ids
  static Future<Tuple2<Map<String, Poll>, Map<String, Tuple3<List<PollResponse>, int, int>>>> getBatchPollsWithResponses(List<String> pollIds,{bool getRes = false}) async {
    Map<String, Poll> polls = Map();
    Map<String, Tuple3<List<PollResponse>, int, int>> resps = Map();

    dynamic objectJson = (await request.post('/polls/batch',
        body: jsonEncode({'pollIds': pollIds, 'pollResponseAttached': getRes}),
        contentType: 'application/json'));

    if (objectJson['statusCode'] == 200) {
      for (Map<String, dynamic> poll in objectJson['polls']) {
        Poll temp = Poll.fromJson(poll);
        PollarStoreBloc().store(temp);
        polls[temp.id] = temp;
      }
      Map temmp = Map.from(objectJson['pollResponseMap']);
      temmp.forEach((k, v) {
        resps[k.toString()] = Tuple3(getReses(v), v['agrees'], v['disagrees']);
      });

      Tuple2<Map<String, Poll>,
              Map<String, Tuple3<List<PollResponse>, int, int>>> ret =
          Tuple2(polls, resps);
      return ret;
    }
    return Future.error(objectJson['message']);
  }

  static List<PollResponse> getReses(dynamic value) {
    List<PollResponse> list = List();
    for (var val in (value['pollResponses']).toList()) {
      list.add(PollResponse.fromJson(val));
    }
    return list;
  }
}
