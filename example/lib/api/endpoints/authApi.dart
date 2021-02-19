import 'dart:convert';
import 'package:pollar/api/endpoints/likesApi.dart';
import 'package:pollar/api/request.dart';

class UserPhoneNumber {
  String code;
  String phoneNumber;
  UserPhoneNumber(this.phoneNumber, this.code);
}

class UserEmail {
  String code;
  String email;
  UserEmail(this.email, this.code);
}

class AuthApi {


  static Future<bool> sendForgotPasswordText(String phoneNumber) async {
    Map response = await request.put('/forgotPassword', body: jsonEncode({'phone': phoneNumber}) , contentType: 'application/json');

    if (response['statusCode'] == 200) {
      // return UserPhoneNumber(phoneNumber.substring(1), phoneNumber.substring(0, 1));
      return true;
      // return objectJson.toString();
    }
    return Future.error(response['message'].toString());
  }

  static Future<String> verifyForgotPasswordText(String phoneNumber, String code) async {
    Map response = await request.put('/checkAuthCode', body: jsonEncode({'phone': phoneNumber, 'code': code}) , contentType: 'application/json');

    if (response['statusCode'] == 200) {
      // return UserPhoneNumber(phoneNumber.substring(1), phoneNumber.substring(0, 1));
      return response['userMainId'];
      // return objectJson.toString();
    }
    return Future.error(response['message'].toString());
  }

  ///Phone Authentication for new users
  static Future<bool> sendVerifyText(String phoneNumber) async {

    Map response = await request.post('/auth/phone/sendText/$phoneNumber', contentType: 'application/json');

    if (response['statusCode'] == 200) {
      // return UserPhoneNumber(phoneNumber.substring(1), phoneNumber.substring(0, 1));
      return true;
      // return objectJson.toString();
    }
    return Future.error(response['message'].toString());
  }

  ///Verifies the new user's text message
  static Future<bool> verifyNewPhoneCode(
      String phoneNumber, String code) async {
    Map response = await request.put('/auth/phone/verify/$phoneNumber/$code',
        contentType: 'application/json');
    if (response['statusCode'] == 200) {
      /* dynamic objectJson = response['userPhoneNumber'];
      return objectJson.toString(); */
      return true;
    }
    return false;
    // return Future.error(response['message'].toString());
  }

  //Phone Authentication for exsisting users
  static Future<bool> sendAuthCodeText(String phoneNumber) async {
    Map response = await request.put('/auth/update/phone',
        body: jsonEncode({'phoneNumber': phoneNumber}),
        contentType: 'application/json');
    if (response['statusCode'] == 200) {
      // return UserPhoneNumber(phoneNumber.substring(1), phoneNumber.substring(0, 1));
      return true;
      // return objectJson.toString();
    }
    return Future.error(response['message'].toString());
  }

  static Future<bool> verifyUserPhoneCode(
      String phoneNumber, String code) async {
    Map response = await request.put('/users/userMain/changePhone',
        body: jsonEncode({'code': code, 'phoneNumber': phoneNumber}),
        contentType: 'application/json');
    if (response['statusCode'] == 200) {
      /* dynamic objectJson = response['userPhoneNumber'];
      return objectJson.toString(); */
      return true;
    }
    return false;
    // return Future.error(response['message'].toString());
  }

  static Future<String> getAllUserPhoneNumbers() async {
    Map response = await request.get('/auth/phone/all/');
    if (response['statusCode'] == 200) {
      dynamic objectJson = response['userPhoneNumbers'];
      return objectJson.toString();
    }
    return Future.error(response['message'].toString());
  }

  //Email Authentication
  static Future<bool> sendAuthCodeEmail(String email) async {
    Map response = await request.put('/auth/update/email',
        body: jsonEncode({'email': email}), contentType: 'application/json');
    if (response['statusCode'] == 200) {
      //dynamic objectJson = response['userEmail'];
      //return UserEmail(objectJson['email'], objectJson['code']);
      return true;
      // return objectJson.toString();
    }
    return false;
    // return Future.error(response['message'].toString());
  }

  static Future<bool> verifyEmailAuthCode(String email, String code) async {
    // Map response = await request.post('/auth/phone/verify/', body: jsonEncode({'code': code}), contentType: 'application/json' );
    Map response = await request.put('/users/userMain/changeEmail',
        body: jsonEncode({'email': email, 'code': code}),
        contentType: 'application/json');
    if (response['statusCode'] == 200) {
      //dynamic objectJson = response['userEmail'];
      //return objectJson.toString();
      return true;
    }
    return Future.error(response['message'].toString());
  }

  static Future<String> getAllUserEmails() async {
    Map response = await request.get('/auth/email/all/');
    if (response['statusCode'] == 200) {
      dynamic objectJson = response['userEmails'];
      return objectJson.toString();
    }
    return Future.error(response['message'].toString());
  }

}
