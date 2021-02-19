import 'package:flutter/material.dart';

import '../../models/userInfo.dart';
import '../../models/userMain.dart';
import '../store/pollarStoreBloc.dart';

//Parent state class
abstract class LoginState{
  LoginState();

  @override
  String toString() => 'Login State';
}

//Log out state
//Pushes application to the login page
class LoggedOutState extends LoginState {
  String error;
  LoggedOutState({this.error});

  @override
  String toString() => 'LoggedOutState';
}

//Authenticates the user, if passed the user is logged in
//Used to display a loading overlay
class LoginAuthState extends LoginState {
  LoginAuthState();

  @override
  String toString() => 'LoginAuthState';
}

///The state that holds the users information when they are logged in
///This state is reupdated again when the login is successful to retreive application information
class LoggedInState extends LoginState {
  final UserInfo fullUser;
  final UserMain userMain;
  static String loginStateId = UniqueKey().toString();

  LoggedInState(this.fullUser, this.userMain){
    PollarStoreBloc().store(fullUser, loginStateId); //Saves the user permanantly to the store
  }

  @override
  String toString() => 'LoggedInState';
}