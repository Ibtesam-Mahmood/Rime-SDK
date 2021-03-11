import 'package:flutter/material.dart';
import 'package:rime/rime.dart';

/// Basic rime message model
class RimeMessage extends BaseMessage {
  /// PubNub UUID
  final String uuid;

  /// The type of a message
  /// Used to differenieate message types in parsing
  final String type;

  ///Base constructor for Rime message
  RimeMessage({this.uuid, this.type, dynamic content, Timetoken publishedAt, dynamic originalMessage})
      : super(publishedAt: publishedAt, content: content, originalMessage: originalMessage);

  /// Creates a rime message by parsing the provided base message content
  factory RimeMessage.fromBaseMessage(BaseMessage message) {
    //The payload within a message
    dynamic content = message.content['payload'];

    //The message user
    String uuid = message.content['uuid'];

    //The type of the message
    String type = message.content['type'];

    //Contructs the Rime message
    return RimeMessage(
        uuid: uuid,
        type: type,
        content: content,
        publishedAt: message.publishedAt,
        originalMessage: message.originalMessage);
  }

  /// Encodes a rime message into a rime message encoding
  Map<String, dynamic> encode() {
    return RimeMessage.toRimeMesageEncoding(uuid, type, content);
  }

  /// Creates JSON serlized RimeMessage
  static Map<String, dynamic> toRimeMesageEncoding(String uuid, String type, dynamic content) {
    return {'uuid': uuid, 'type': type, 'payload': content};
  }
}

/// Message only containing text
class TextMessage extends RimeMessage {
  ///The type of the message when it is a rime message
  static const String RIME_MESSAGE_TYPE = 'text-message';

  /// Content
  String text;

  ///Constructor to create a text message
  TextMessage._({@required this.text, @required RimeMessage message})
      : assert(message != null),
        assert(message.type == RIME_MESSAGE_TYPE),
        super(
            uuid: message.uuid,
            type: message.type,
            content: message.content,
            publishedAt: message.publishedAt,
            originalMessage: message.originalMessage);

  /// Parsing constructor,
  /// Converts the RimeMessage object into a textmessage object by parsing its content
  factory TextMessage.fromRimeMessage(RimeMessage message) {
    //Extract text object from content
    String text = message.content['text'];

    return TextMessage._(text: text, message: message);
  }

  /// Creates a Rime Message payload from defined inputs
  static Map<String, dynamic> toPayload(String text) {
    return {'text': text};
  }
}
