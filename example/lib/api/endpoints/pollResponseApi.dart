import 'package:pollar/api/request.dart';
import 'package:pollar/models/poll.dart';
import 'package:pollar/models/pollResponse.dart';
import 'package:pollar/models/story.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';

class PollResponseApi {
  static Future<List<PollResponse>> getPollResponses() async {
    List<PollResponse> pollResponses = [];
    List<dynamic> pollResponseMap =
        (await request.get('/pollResponses'))['pollResponses'];
    for (Map<String, dynamic> post in pollResponseMap) {
      pollResponses.add(PollResponse.fromJson(post));
    }
    return pollResponses;
  }

  static Future<List<PollResponse>> getPollResponseByPollId(
      String pollId) async {
    List<PollResponse> pollResponses = [];
    dynamic pollResponseMap = (await request
        .get('/pollresponses/?pollId=' + pollId))['pollResponses'];
    for (Map<String, dynamic> post in pollResponseMap) {
      pollResponses.add(PollResponse.fromJson(post));
    }
    return pollResponses;
  }

  static Future<PollResponse> getPollResponseById(String responseId) async {
    dynamic objectJson =
        (await request.get('/pollresponses/' + responseId))['pollResponse'];
    return (objectJson == null ? null : PollResponse.fromJson(objectJson));
  }

  static Future<PollResponse> getPollResponseForStory(String id) async {
    Story story = PollarStoreBloc().retreive<Story>(id);
    PollResponse pr;
    if (story != null) {
      pr = await getPollResponseById(story.pollResponseId);
      if (pr != null) {
        story.pollRes = pr;
        PollarStoreBloc().store(story);
      }
    }

    return pr;
  }

  static Future<PollResponse> editPollResponse(PollResponse pollRes) async {
    dynamic objectJson = (await request.put(
        '/pollresponses/' + pollRes.id + '/edit',
        body: pollRes.toEditPollResponseJson(),
        contentType: 'application/json'))['pollResponse'];
    return (PollResponse.fromJson(objectJson));
  }

  static Future<PollResponse> deletePollResponse(String id) async {
    dynamic objectJson = (await request.delete('/pollresponses/' + id));
    return (PollResponse.fromJson(objectJson));
  }

  static Future<String> vote(PollResponse pollRes, [int trustCount = 0]) async {
    Poll currentPoll = PollarStoreBloc().retreive<Poll>(pollRes.pollId);

    if (currentPoll != null &&
        currentPoll.agrees != null &&
        currentPoll.disagrees != null) {
      //Adds created at tag
      pollRes.createdAt = currentPoll.yourVote?.createdAt ?? DateTime.now();

      //Store vote
      Poll copyPoll = Poll(
          agrees: currentPoll.agrees,
          disagrees: currentPoll.disagrees,
          yourVote: pollRes);
      int voteWeight = 0;

      //Chnage vote percentage
      if (currentPoll.yourVote == null) {
        voteWeight = 1 + trustCount;
      } else {
        //Move only 1 vote over
        voteWeight = 1;
      }

      if (pollRes.vote) {
        //add to agrees
        copyPoll.agrees += voteWeight;
        //Remove votes from disagrees
        if (currentPoll.yourVote != null) {
          copyPoll.disagrees -= voteWeight;
          copyPoll.disagrees = copyPoll.disagrees >= 0 ? copyPoll.disagrees : 0;
        }
      } else {
        //add to disagrees
        copyPoll.disagrees += voteWeight;
        //Remove votes from agrees
        if (currentPoll.yourVote != null) {
          copyPoll.agrees -= voteWeight;
          copyPoll.agrees = copyPoll.agrees >= 0 ? copyPoll.agrees : 0;
        }
      }

      PollarStoreBloc().store(currentPoll.copyWith(copyPoll));
    }

    String message = (await request.put('/pollresponses/' + pollRes.pollId,
        body: pollRes.voteJson(), contentType: 'application/json'))['message'];
    return message;
  }

  static Future<String> skipVote(PollResponse pollRes) async {
    String message = (await request.put('/pollresponses/skip/' + pollRes.pollId, body: pollRes.voteJson(), contentType: 'application/json'))['message'];
    return message;
  }

  static Future<String> unvote(PollResponse pollRes) async {
    Poll currentPoll = PollarStoreBloc().retreive<Poll>(pollRes.pollId);

    if (currentPoll != null) {
      //Remove vote
      PollarStoreBloc().store(currentPoll.copy()..yourVote = null);
    }

    String message = (await request.delete('/pollresponses/' + pollRes.pollId,
        body: pollRes.voteJson(), contentType: 'application/json'))['message'];
    return message;
  }
}
