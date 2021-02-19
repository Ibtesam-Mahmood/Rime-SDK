import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pollar/api/request.dart';
import 'package:pollar/models/notifications.dart';

final String serverToken =
    'AAAAYcAQtP4:APA91bHsLz3ikWB56rDd1W98oG262dTK33Mu6O168DxyqaLLefs7nV0oFflY3peihWKdcqt5dn31Y97z6zo9l6W2l9kwj4JrEP7nlc3EcSd9X224Snr-vxwCQUM4LlBGWXdr0hJsmY0K';

class NotificationApi {
  static void sendUserDeviceToken(String token) {
    request.post('/users/userDevices',
        contentType: 'application/json', body: jsonEncode({'token': token}));
  }

  ///Returns a list of notifications for the logged in user.
  ///Limitted by the size of the request and only before the requested date
  static Future<List<PollarNotification>> getNotifications(
      {int size = 10, DateTime date}) async {
    List<PollarNotification> notifications = [];

    //Date defaulted to current time
    if (date == null) date = DateTime.now();

    dynamic response = await request
        .get('/notifications?size=$size&date=${date.toUtc().toString()}');

    if (response['statusCode'] == 200) {
      List<dynamic> objectJsons =
          response['notifications']; //List of encoded notification jsons

      //Parse into notification models
      for (var json in objectJsons) {
        notifications.add(PollarNotification.fromJson(json));
      }

      //TODO: store in pollar store

      return notifications;
    }

    return Future.error(response['message'].toString());
  }

  static void sendChatNotification(
      {String title = '', String body = '', String token}) async {
    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{'body': body, 'title': title},
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done'
          },
          'to': token
        },
      ),
    );
  }

  static void seen({List<PollarNotification> notifs = const []}) async {
    if (notifs?.isNotEmpty ?? false) {
      Map<String, dynamic> object = {
        'notifications': notifs.map((e) => e).toList(),
      };
      await request.put('/notifications/seen',
          body: jsonEncode(object), contentType: 'application/json');
    }
  }
}
