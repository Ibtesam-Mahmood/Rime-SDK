import 'dart:convert';
import 'package:pollar/api/request.dart';
import 'package:pollar/models/story.dart';
import 'package:pollar/models/storyResponse.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';
import 'package:tuple/tuple.dart';

class StoryApi {
  static Future<List<Story>> getStories() async {
    List<Story> storyResponses = [];
    List<dynamic> storyMap =
        (await request.get('/story/getStories'))['stories'];
    storyMap.forEach((s) async {
      Story newStory = Story.fromJson(s);

      if (newStory.validate()) {
        storyResponses.add(newStory);

        PollarStoreBloc().store(newStory);
      }
    });

    return storyResponses;
  }


  static Future<Story> getStoryById(String storyId) async {
    Story s = PollarStoreBloc().retreive<Story>(storyId);
    if (s != null) {
      return s;
    }
    dynamic response = (await request.get('/story/getStory/$storyId'));

    Story newStory = Story();
    if (response['statusCode'] == 200) {
      newStory = Story.fromJson(response['story']);
      if (newStory.validate()) {
        s = newStory;
      }
    } else {
      //Poll not found, non valid poll created for error handling
      newStory = Story(id: storyId);
    }

    PollarStoreBloc().store(newStory);

    return s;
  }

  static Future<List<Story>> myStories() async {
    List<Story> storyResponses = [];
    List<dynamic> storyMap = (await request.get('/story/myStories'))['stories'];
    for (Map<String, dynamic> story in storyMap) {
      Story newStory = Story.fromJson(story);

      if (newStory.validate()) {
        // Future<PollResponse> pr =
        //     PollResponseApi.getPollResponseById(newStory.pollResponseId)?? PollResponse();
        // Future<Poll> pl = PollApi.getPollById(newStory.pollId);
        // newStory.poll = await pl;
        // newStory.pollRes = await pr;
        //
        storyResponses.add(newStory);
      }
    }

    PollarStoreBloc().batchStore<Story>(storyResponses);

    return storyResponses;
  }

  static Future<bool> seen(String storyId) async {
    Story cacheStory = PollarStoreBloc().retreive<Story>(storyId);
    if (cacheStory == null) {
      cacheStory = Story(seen: true);
    } else {
      cacheStory = cacheStory.copyWith(Story(seen: true));
      PollarStoreBloc().store(cacheStory);
    }

    await request.put('/story/seen/$storyId',
        body: cacheStory.seeStory(), contentType: 'application/json');
    // dynamic objectJson = (response)['trust'];
    return (true);
  }

  static Future<bool> sendReply(String storyId, String pollId,
      String trustedUserId, bool isDifferent) async {
    Map<String, dynamic> object = {
      'isDifferent': isDifferent,
      'pollId': pollId,
      'trustedUser': trustedUserId,
      'storyId': storyId
    };
    await request.put('/storyResponse',
        body: jsonEncode(object), contentType: 'application/json');
    // dynamic objectJson = (response)['trust'];
    return (true);
  }

  static Future<void> seenResponse(String storyResponseId,
      {bool seen = true}) async {
    Map<String, dynamic> object = {
      'seen': seen,
    };
    await request.put('/storyResponse/$storyResponseId',
        body: jsonEncode(object), contentType: 'application/json');
  }

  static Future<Tuple2<List<StoryResponse>, Map<String, bool>>>
      myStoryResponses() async {
    List<StoryResponse> storyResponses = [];
    Map<dynamic, dynamic> response = await request.get('/storyResponse');
    List<dynamic> storyResMap = response['storyResponses'];
    Map<String, bool> voteMap = Map.from(response['voteMap']);
    for (Map<String, dynamic> storyRes in storyResMap) {
      StoryResponse newStoryRes = StoryResponse.fromJson(storyRes);
      if (newStoryRes.validate()) {
        storyResponses.add(newStoryRes);
      }
    }
    PollarStoreBloc().batchStore<StoryResponse>(storyResponses);
    Tuple2<List<StoryResponse>, Map<String, bool>> returnList =
        Tuple2(storyResponses, voteMap);
    return returnList;
  }

  static Future<StoryResponse> getStoryResponseById(
      String storyResponseId) async {
    StoryResponse s =
        PollarStoreBloc().retreive<StoryResponse>(storyResponseId);
    if (s != null) {
      return s;
    }
    dynamic response = (await request
        .get('/storyResponses/storyResponse/$storyResponseId'));
    StoryResponse newStory;
    if (response['statusCode'] == 200) {
      newStory = StoryResponse.fromJson(response['storyResponse']);
      if (newStory.validate()) {
        s = newStory;

        PollarStoreBloc().store(newStory);
      }
      return s;
    } else {
      return s;
    }
  }
}
