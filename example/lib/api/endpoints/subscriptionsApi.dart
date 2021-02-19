import 'package:pollar/api/request.dart';
import 'package:pollar/models/subscription.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';

class SubscriptionsApi {
  //example of query string String q = 'userInfoId=id&ect=123&w=5'
  static Future<List<Subscription>> getAllSubscriptions(
      {queryString= ''}) async {
    List<Subscription> objects = [];
    queryString = queryString != '' ? '?' + queryString : queryString;

    final dynamic response =
        await request.get('/subscription/subscriptions' + queryString);
    List<dynamic> objectsJson = (response)['subscriptions'];
    for (Map<String, dynamic> objectJson in objectsJson) {
      objects.add(Subscription.fromJson(objectJson));
    }
    return objects;
  }

  static Future<List<Subscription>> getUserSubscriptions(String userId) async {
    String user = PollarStoreBloc().loggedInUserID;
    if (userId == user &&
        PollarStoreBloc().state.storedSubs.length != 0) {
      //Stores subscriptions in pollar store bloc if the loaded subscriptions are for the loggedInUser
      return PollarStoreBloc().state.storedSubs.toList;
    }
    List<Subscription> userSubs =
        await getAllSubscriptions(queryString: 'userInfoId=' + userId);

    if (userId == user) {
      //Stores subscriptions in pollar store bloc if the loaded subscriptions are for the loggedInUser
      PollarStoreBloc().batchStore<Subscription>(userSubs);
    }

    return userSubs;
  }

  static Future<List<Subscription>> getSubScriptionsByTopic(
      String topicID) async {
    List<Subscription> loaded =
        await getAllSubscriptions(queryString: 'topicId=$topicID');
    return loaded;
  }

  static Future<Subscription> getSubscriptionFromId(String id) async {
    final dynamic response =
        await request.get('/subscription/subscriptions/' + id);
    dynamic objectJson = (response)['subscription'];
    return (Subscription.fromJson(objectJson));
  }

  static Future<Subscription> deleteSubscriptionFromId(String id) async {
    final dynamic response =
        await request.delete('/subscription/subscriptions/' + id);
    dynamic objectJson = (response)['subscription'];
    return (Subscription.fromJson(objectJson));
  }

  static Future<String> subscribe(String topic, [String topicName = '']) async {
    //Adds a subscription to improve response time
    Subscription newSub = Subscription(topicId: topic, userInfoId: PollarStoreBloc().loggedInUserID, topic: topicName);
    PollarStoreBloc().store(newSub);

    final dynamic response =
        await request.put('/subscription/subscribe/' + topic);
    return (response)['message'] as String;
  }

  static Future<String> unsubscribe(String topic) async {
    //Removes a subscription to improve response time
    PollarStoreBloc().remove<Subscription>(topic);

    final dynamic response =
        await request.delete('/subscription/subscribe/' + topic);
    String message = (response)['message'];
    return message;
  }
}
