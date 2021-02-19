import 'package:photo_manager/photo_manager.dart';
import 'package:pubnub/pubnub.dart';

abstract class ChatMessage{

  String clientID;
  DateTime timeToken;
  bool lastMessage;
  bool delivered;

  ChatMessage({this.clientID, this.timeToken, this.lastMessage = false, this.delivered = false});


  static ChatMessage decodeMessage(Message message){
    if(message.contents['message']['type'] == 'text'){
      return TextMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'image'){
      return ImageMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'post'){
      return PostMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'poll'){
      return PollMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'delete'){
      return DeleteMessage.fromJson(message);
    }
    else if (message.contents['message']['type'] == 'read'){
      return ReadMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'profile'){
      return ProfileMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'topic'){
      return TopicMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'story'){
      return StoryMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'gif'){
      return GifMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'setting'){
      return SettingMessage.fromJson(message);
    }
    else if(message.contents['message']['type'] == 'video'){
      return VideoMessage.fromJson(message);
    }
    else{
      return null;
    }
  }

  Map<String, dynamic> toJson();

  String get notificationMessage;


  String get id => '$clientID - ${timeToken.toString()}';

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(dynamic other) {

    if(!(other is ChatMessage)) return false;
    // ignore: test_types_in_equals
    String compare = '${(other as ChatMessage).timeToken.toString()} - ${(other as ChatMessage).clientID}';
    // TODO: implement ==
    return '${timeToken.toString()} - $clientID' == compare;
  }

}

class ImageMessage extends ChatMessage {

  List<dynamic> link;

  ImageMessage({String clientID, DateTime timeToken, bool delivered, this.link}) : super(clientID: clientID, timeToken: timeToken, delivered: delivered);


  factory ImageMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    List<dynamic> link = message.contents['message']['content']['image'];
    DateTime timeToken = message.timetoken.toDateTime();
    return ImageMessage(clientID: clientID, timeToken: timeToken, link: link, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'image', 
        'content': {
          'image': link, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => 'Sent an Image';
}

  class LocalImage extends ChatMessage{

    List<AssetEntity> link;

    LocalImage({String clientID, DateTime timeToken, bool delivered, this.link}) : super(clientID: clientID, timeToken: timeToken, delivered: delivered);

    factory LocalImage.fromJson(Message message){
      bool delivered = message.contents['message']['content']['delivered'];
      String clientID = message.contents['message']['content']['client'];
      List<dynamic> link = message.contents['message']['content']['image'];
      DateTime timeToken = message.timetoken.toDateTime();
      return LocalImage(clientID: clientID, timeToken: timeToken, link: link, delivered: delivered);
    }

  @override
  // TODO: implement notificationMessage
  String get notificationMessage => 'Sent an Image';

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'image', 
        'content': {
          'image': link, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }
}

class TextMessage extends ChatMessage{

  String text;

  TextMessage({String clientID, DateTime timeToken, bool delivered, this.text}): super(clientID: clientID, timeToken: timeToken, delivered: delivered);


  factory TextMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    String text = message.contents['message']['content']['text'];
    DateTime timeToken = message.timetoken.toDateTime();
    return TextMessage(text: text, clientID: clientID, delivered: delivered, timeToken: timeToken);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'text',
        'content': {
          'text': text, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => text;
}

class EmojiMessage extends ChatMessage{

  String text;

  EmojiMessage({String clientID, DateTime timeToken, bool delivered, this.text}): super(clientID: clientID, timeToken: timeToken, delivered: delivered);


  factory EmojiMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    String text = message.contents['message']['content']['text'];
    DateTime timeToken = message.timetoken.toDateTime();
    return EmojiMessage(text: text, clientID: clientID, delivered: delivered, timeToken: timeToken);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'text',
        'content': {
          'text': text, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => text;
}

class PostMessage extends ChatMessage{

  String postID;

  PostMessage({String clientID, DateTime timeToken, bool delivered, this.postID}): super(clientID: clientID, timeToken: timeToken, delivered: delivered);

  factory PostMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    String postID = message.contents['message']['content']['post'];
    DateTime timeToken = message.timetoken.toDateTime();
    return PostMessage(postID: postID, timeToken: timeToken, clientID: clientID, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'post', 
        'content': {
          'post': postID, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => 'Sent an Post';
}

class PollMessage extends ChatMessage{
  String pollID;
  String topicID;

  PollMessage({String clientID, DateTime timeToken, bool delivered, this.pollID, this.topicID}): super(clientID: clientID, timeToken: timeToken, delivered: delivered);

  factory PollMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    String pollID = message.contents['message']['content']['poll'];
    String topicID = message.contents['message']['content']['topicID'];
    DateTime timeToken = message.timetoken.toDateTime();
    return PollMessage(pollID: pollID, timeToken: timeToken, clientID: clientID, topicID: topicID, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'poll', 
        'content': {
          'poll': pollID, 
          'topic': topicID, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => 'Sent an Poll';
}

class ProfileMessage extends ChatMessage{
  String userID;

  ProfileMessage({String clientID, DateTime timeToken, bool delivered, this.userID}): super(clientID: clientID, timeToken: timeToken, delivered: delivered);

  factory ProfileMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    String userID = message.contents['message']['content']['profile'];
    DateTime timeToken = message.timetoken.toDateTime();
    return ProfileMessage(clientID: clientID, userID: userID, timeToken: timeToken, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'profile', 
        'content': {
          'profile': userID, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => 'Sent a profile';
}

class TopicMessage extends ChatMessage{
  String topicID;

  TopicMessage({String clientID, DateTime timeToken, bool delivered, this.topicID}) : super(clientID: clientID, timeToken: timeToken, delivered: delivered);

  factory TopicMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    String topicID = message.contents['message']['content']['topic'];
    DateTime timeToken = message.timetoken.toDateTime();
    return TopicMessage(clientID: clientID, topicID: topicID, timeToken: timeToken, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'topic', 
        'content': {
          'topic': topicID, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => 'Sent a topic';
}

class DeleteMessage extends ChatMessage{
  
  DeleteMessage({String clientID}) : super(clientID: clientID);

  factory DeleteMessage.fromJson(Message message){
    String clientID = message.contents['message']['content']['client'];
    return DeleteMessage(clientID: clientID);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'delete', 
        'content': {
          'client': clientID
        }
      }
    };
  }

  @override
  String get notificationMessage => null;
}

class ReadMessage extends ChatMessage{
  bool enabled;

  ReadMessage({String clientID, this.enabled, bool delivered, DateTime timeToken}) : super(clientID: clientID, timeToken: timeToken, delivered: delivered);

  factory ReadMessage.fromJson(Message message){
    String clientID = message.contents['message']['content']['client'];
    bool enabled = message.contents['message']['content']['enabled'];
    bool delivered = message.contents['message']['content']['delivered'];
    DateTime timeToken = message.timetoken.toDateTime();
    return ReadMessage(clientID: clientID, enabled: enabled, timeToken: timeToken, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'read', 
        'content': {
          'client': clientID, 
          'enabled': enabled
        }
      }
    };
  }

  @override
  String get notificationMessage => null;
}

class DateMessage extends ChatMessage{

  DateMessage({String clientID, DateTime timeToken}) : super(clientID: clientID, timeToken: timeToken);

  factory DateMessage.fromJson(Message message){
    String clientID = message.contents['message']['content']['client'];
    DateTime timeToken = message.timetoken.toDateTime();
    return DateMessage(clientID: clientID, timeToken: timeToken);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'date', 
        'content': {
          'client': clientID, 
        }
      }
    };
  }

  @override
  String get notificationMessage => null;
}

class StoryMessage extends ChatMessage{
  
  String storyID;

  String pollID;

  StoryMessage({String clientID, DateTime timeToken, bool delivered, this.storyID, this.pollID}) : super(clientID: clientID, timeToken: timeToken, delivered: delivered);

  factory StoryMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    DateTime timeToken = message.timetoken.toDateTime();
    String storyID = message.contents['message']['content']['story'];
    String pollID = message.contents['message']['content']['poll'];
    return StoryMessage(clientID: clientID, timeToken: timeToken, storyID: storyID, delivered: delivered, pollID: pollID);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'story', 
        'content': {
          'story': storyID, 
          'poll': pollID, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => 'Sent a story';
}

class GifMessage extends ChatMessage{
  String link;

  GifMessage({String clientID, DateTime timeToken, bool delivered, this.link}) : super(clientID: clientID, timeToken: timeToken, delivered: delivered);

  factory GifMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    String link = message.contents['message']['content']['image'];
    DateTime timeToken = message.timetoken.toDateTime();
    return GifMessage(clientID: clientID, timeToken: timeToken, link: link, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'gif', 
        'content': {
          'image': link, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => 'Sent an Gif';
}

class SettingMessage extends ChatMessage {

  String settingMessage;

  SettingMessage({String clientID, DateTime timeToken, bool delivered, this.settingMessage}) : super(clientID: clientID, timeToken: timeToken, delivered: delivered);

  factory SettingMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    String settingMessage = message.contents['message']['content']['setting'];
    DateTime timeToken = message.timetoken.toDateTime();
    return SettingMessage(clientID: clientID, timeToken: timeToken, settingMessage: settingMessage, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'setting', 
        'content': {
          'setting': settingMessage, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => settingMessage;
}

class VideoMessage extends ChatMessage{

  String video;

  String thumbNail;

  VideoMessage({String clientID, DateTime timeToken, bool delivered, this.video, this.thumbNail}) : super(clientID: clientID, timeToken: timeToken, delivered: delivered);


  factory VideoMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    String video = message.contents['message']['content']['video'];
    String thumbNail = message.contents['message']['content']['thumbNail'];
    DateTime timeToken = message.timetoken.toDateTime();
    return VideoMessage(clientID: clientID, timeToken: timeToken, video: video, thumbNail: thumbNail, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'video', 
        'content': {
          'video': video, 
          'thumbNail': thumbNail,
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => 'Sent a video';
}

class LocalVideoMessage extends ChatMessage{

  AssetEntity video;

  LocalVideoMessage({String clientID, DateTime timeToken, bool delivered, this.video}) : super(clientID: clientID, timeToken: timeToken, delivered: delivered);


  factory LocalVideoMessage.fromJson(Message message){
    bool delivered = message.contents['message']['content']['delivered'];
    String clientID = message.contents['message']['content']['client'];
    AssetEntity video = message.contents['message']['content']['video'];
    DateTime timeToken = message.timetoken.toDateTime();
    return LocalVideoMessage(clientID: clientID, timeToken: timeToken, video: video, delivered: delivered);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'timetoken': Timetoken.fromDateTime(timeToken).value,
      'message': {
        'type': 'localvideo', 
        'content': {
          'video': video, 
          'client': clientID, 
          'delivered': delivered
        }
      }
    };
  }

  @override
  String get notificationMessage => 'Sent a video';
}