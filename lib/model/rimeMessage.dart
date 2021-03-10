import 'package:rime/rime.dart';

abstract class RimeMessage<T> extends BaseMessage{
  /// PubNub UUID
  String uuid;

  ///Base constructor for Rime message
  RimeMessage._({
    this.uuid,
    Timetoken publishedAt,
    dynamic content,
    dynamic originalMessage,
  }) : super(publishedAt: publishedAt, content: content, originalMessage: originalMessage);

  /// Decode BaseMessage
  static RimeMessage decodeMessage(dynamic content){
    
  }

  T fromRimeMessage(RimeMessage<ConcreteRimeMessage> rimeMessage);
  
}

class ConcreteRimeMessage extends RimeMessage<ConcreteRimeMessage> {

  ConcreteRimeMessage._({
    String uuid,
    Timetoken publishedAt,
    dynamic content,
    dynamic originalMessage,
  }) : super._(uuid: uuid, publishedAt: publishedAt, content: content, originalMessage: originalMessage);

  @override
  ConcreteRimeMessage fromRimeMessage(RimeMessage<ConcreteRimeMessage> rimeMessage) {
    return rimeMessage;
  }

  

}

/// Message only containing text
class TextMessage extends RimeMessage<TextMessage>{
  
  /// Content
  String text;

  TextMessage({String uuid, this.text});

  factory TextMessage.fromJson(dynamic content){
    String uuid = content['message']['content']['uuid'];
    String text = content['message']['content']['text'];
    return TextMessage(uuid: uuid, text: text);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid, 
      'message': {
        'type': 'text',
        'content': {
          'text': text, 
        }
      }
    };
  }
}