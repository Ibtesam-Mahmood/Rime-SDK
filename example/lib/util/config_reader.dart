import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

class ConfigReader{
  static Map<String, dynamic> _config;

  static Future<void> initialize() async {
    final configString = await rootBundle.loadString('config/app_config.json');
    _config = json.decode(configString) as Map<String, dynamic>;
  }

  static String getDevelopmentURL(){
    return _config['devURL'] as String;
  }

  static String getAWSBaseURL(){
    return _config['awsBase'] as String;
  }

  static String getEnvironment(){
    var env = utf8.encode((_config['env'] as String) ?? '');
    var convert = sha256.convert(env);
    return convert.toString();
  }

  static String getPublishKey(){
    return _config['pubNubPublush'] as String;
  }

  static String getSubscribeKey(){
    return _config['pubNubSubscribe'] as String;
  } 
}