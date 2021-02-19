
import 'dart:convert';

import 'package:pollar/models/poll.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';

import '../request.dart';

class ReportApi {


  static Future<List<Poll>> getReports(String topicId, [int size = 4]) async {

    List<Poll> polls = [];
    dynamic objectJson = await request.get('/report/reports?size=$size');
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

  ///Sends in a repot on a post
  static Future<Poll> report(String postId, String ruleId) async {

    dynamic object = await request.put('/report', body: jsonEncode({'post': postId, 'rule': ruleId}), contentType: 'application/json');

    if(!object['error']){
      return Poll.fromJson(object['poll']);
    }

    return Future.error(object['message'].toString());

  }

}