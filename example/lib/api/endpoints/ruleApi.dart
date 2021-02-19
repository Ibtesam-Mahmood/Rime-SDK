import 'dart:async';
import 'dart:convert';

import 'package:pollar/api/request.dart';
import 'package:pollar/models/poll.dart';
import 'package:pollar/models/rule.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';

class RuleApi {
  ///Retrevies a list of rules
  static Future<List<Poll>> getRules({String query = ''}) async {
    List<Poll> rules = [];

    dynamic reponse = await request.get('/polls?type=Rule&$query');
    List<dynamic> objectJsons = reponse['polls'];

    for (var json in objectJsons) {
      Poll rule = Poll.fromJson(json);
      if (rule.validate() && rule.type == Rule) rules.add(rule);
    }

    return rules;
  }

  ///Retreives a list of rules on a topic
  ///If the approved boolean is not specified all rules are retreived
  ///if the approved boolean is set it is added into the query
  ///Size parameter can be defined to limit the size of the request
  static Future<List<Poll>> getTopicRules(String topicId,
      {bool approved, int size = 4}) async {

    //Constructs the query
    String query = 'topicId=$topicId';

    if(approved != null){
      query+='&status=${approved ? 'Approved' : 'Submitted'}';
    }
    if(size != null){
      query+='&size=$size';
    }

    List<Poll> rules = await getRules(query: query);

    //Stores the rules in pollar store
    PollarStoreBloc().batchStore<Poll>(rules);

    return rules;
  }

  ///Returns a list of accepted rules on a topic
  static Future<List<Rule>> getSimpleTopicRules(String topicID) async {
    return (await getTopicRules(topicID, approved: true))
        .map<Rule>((p) => p.toRule)
        .toList();
  }

  ///Suggests a rule in the form of a poll to a topic
  static Future<Poll> suggestRule(String topicId,
      {String content = '', String title = ''}) async {
    //Checks for valid properties for this request
    assert((topicId ?? '').isNotEmpty);
    assert((title ?? '').isNotEmpty);

    //Suggests the rule to the server
    dynamic response = await request.put('/rule/createRule/$topicId',
        body: jsonEncode({'content': content, 'title': title}),
        contentType: 'application/json');

    if (response['error'] == false) {
      //Rule suggested

      //Parse rule from response
      Poll rule = Poll.fromJson(response['poll']);

      //Store rule poll in pollar store
      PollarStoreBloc().store(rule);

      //Suggested rule returned
      return rule;
    }

    //Rule not suggested, error
    return null;
  }
}
