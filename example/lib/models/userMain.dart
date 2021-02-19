import 'dart:convert';

import 'userInfo.dart';


class UserMain {
  String id = '';
  String email;
  String phone;
  String password;
  bool isAuth = false;

  UserMain({this.id, this.email, this.phone, this.password, this.isAuth});
  factory UserMain.fromJson(Map<String, dynamic> json) {
    return UserMain(
      id: json['_id'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      isAuth: json['isAuth'],
    );
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'email': email,
      'phone': phone,
      'password': password,
      'isAuth': isAuth
    };
    return jsonEncode(object);
  }

  String toCreateUserJson(UserInfo userInfo) {
    Map<String, dynamic> object = {
      'username': userInfo.username,
      'email': email,
      'phone': phone,
      'password': password,
      'firstName': userInfo.firstName,
      'lastName': userInfo.lastName,
      //'image' : userInfo.image,
      'gender': userInfo.gender
    };
    return jsonEncode(object);
  }

  String toEditUserJson() {
    Map<String, dynamic> object = {
      'email': email,
      'phone': phone,
      'password': password,
    };
    return jsonEncode(object);
  }

  //Retruns a copy of the userInfo
  UserMain copy() {
    return UserMain(
      email: email,
      id: id,
      isAuth: isAuth,
      password: password,
      phone: phone,
    );
  }

  //Creates a new usermain with copied over values
  //Has null checking around new user
  //Has null checking for new user values
  UserMain copyWith(UserMain newUser) {
    return UserMain(
      id: id,
      email: newUser?.email ?? email,
      phone: newUser?.phone ?? phone,
      password: password,
      isAuth: isAuth,
    );
  }

  @override
  String toString() {
    return toJson();
  }
}
