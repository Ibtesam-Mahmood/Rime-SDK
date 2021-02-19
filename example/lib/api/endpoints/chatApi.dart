import 'dart:convert';
import 'package:pollar/api/request.dart';
import 'package:pollar/models/chat.dart';
import 'package:pollar/state/chat/chatBloc.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';
import 'package:tuple/tuple.dart';

class ChatApi {
  static Future<List<Chat>> getAllChats() async {
    //Stores all chats that user currently has
    List<Chat> chats = List<Chat>();

    //Response from http request
    Map response;

    try {
      response = await request.get('/chats');
    } catch (e) {
      return [];
    }

    dynamic objectJson = (response)['chatsAccepted'];

    //Stores every chat in the pollar cache so it doesn't have to be reloaded
    for (var chatJson in objectJson) {
      Chat newChat = Chat.fromJson(chatJson);
      chats.add(newChat);
    }

    objectJson = (response)['chatsRequested'];

    for (var chatJson in objectJson) {
      Chat newChat = Chat.fromJson(chatJson);
      chats.add(newChat);
    }

    //Returns all chats
    return chats;
  }

  static Future createChat(List<String> user, String id) async {
    Map response = await request.post('/chats',
        contentType: 'application/json',
        body: jsonEncode({
          'users': [...user, PollarStoreBloc().loggedInUserID],
          'channel': id,
          'viewed': false
        }));
    dynamic objectJson = response;
    return Chat.fromJson(objectJson['chat']);
  }

  static Future<Chat> editChat(String chatID,
      {List<String> users,
      String chatName,
      Map<String, dynamic> chatAccepted,
      Map<String, dynamic> sendReadReceipts,
      String encoding,
      String fileName,
      String time,
      Map<String, bool> muteChat}) async {
    dynamic response;
    if (users != null) {
      response = await request.put('/chats/chat/' + chatID,
          contentType: 'application/json',
          body: jsonEncode({
            'users': [...users, PollarStoreBloc().loginUser.id],
            'chatName': chatName,
            'chatAccepted': chatAccepted
          }));
    }
    if (chatName != null) {
      response = await request.put('/chats/chat/' + chatID,
          contentType: 'application/json',
          body: jsonEncode({'chatName': chatName}));
    }
    if (chatAccepted != null) {
      response = await request.put('/chats/chat/' + chatID,
          contentType: 'application/json',
          body: jsonEncode({'chatAccepted': chatAccepted}));
    }
    if (encoding != null && fileName != null) {
      response = await request.put('/chats/chat/' + chatID,
          contentType: 'application/json',
          body: jsonEncode({
            'images': [
              {'base64': encoding, 'fileName': fileName}
            ]
          }));
    } else if (sendReadReceipts != null) {
      response = await request.put('/chats/chat/' + chatID,
          contentType: 'application/json',
          body: jsonEncode({'sendReadReceipts': sendReadReceipts}));
    } else if (time != null) {
      response = await request.put('/chats/chat/' + chatID,
          contentType: 'application/json', body: jsonEncode({'time': time}));
    } else if (muteChat != null) {
      response = await request.put('/chats/chat/' + chatID,
          contentType: 'application/json',
          body: jsonEncode({'notificationsEnabled': muteChat}));
    }
    if (response['error'] == false) {
      return Chat.fromJson(response['chat']);
    } else {
      return Future.error(response['message']);
    }
  }

  static Future leaveChat(String chatID, List<String> users) async {
    await request.put('/chats/chat/' + chatID,
        contentType: 'application/json', body: jsonEncode({'users': users}));
  }

  //upload uses property names image and fileName
  //upload batch uses images: {[{base64:~, fileName:~},...]}
  static Future<String> sendImage(String encoding, String fileName) async {
    String url;
    dynamic response = await request.post('/s3/upload',
        body: jsonEncode({'fileName': fileName, 'image': encoding}),
        contentType: 'application/json');
    url = response['asset']['urls'][0];
    return url;
  }

  static Future<Tuple2<String, String>> sendVideo(
      String encodedVideo, String encodedImage) async {
    print('Sending...');
    dynamic response = await request.post('/s3/uploadData',
        body: jsonEncode({
          'images': [jsonDecode(encodedImage)],
          'video': jsonDecode(encodedVideo)
        }),
        contentType: 'application/json');

    return Tuple2(response['dataUploaded']['images'][0],
        response['dataUploaded']['video']);
  }

  static Future sendNotification(String chatID, String message) async {
    dynamic response = await request.put('/chats/notify',
        contentType: 'application/json',
        body: jsonEncode({'channel': chatID, 'message': message}));
  }

  static Future<Chat> getChat(String chatID) async {
    Map response;

    Chat newChat = ChatBloc().state[chatID];

    if (newChat != null) return newChat;

    try {
      response = await request.get('chats/$chatID');
    } catch (e) {
      return Future.error('request broke');
    }

    dynamic objectJson = response['chat'];

    newChat = Chat.fromJson(objectJson);

    return newChat;
  }
}
