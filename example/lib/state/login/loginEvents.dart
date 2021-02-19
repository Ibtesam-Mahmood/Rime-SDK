//Parent event class


import '../../models/userInfo.dart';
import '../../models/userMain.dart';
import '../../models/userSettings.dart';

abstract class LoginEvent {
  LoginEvent();
}

//Event passed through to login the user
class Login extends LoginEvent {
  final String usernameOrEmail, password;
  final Function() callbackSuccess, callBackFail, callback; //Functions that are called when suceeded or failed
  Login(this.usernameOrEmail, this.password, {this.callbackSuccess, this.callBackFail, this.callback});
}

///Called to update the state of the loggedin user
///Can only be called if the bloc is LoggedInState
class UpdateLogin extends LoginEvent{
  final UserInfo userInfo; //User info with updated feilds
  final UserMain userMain; //User main with updated feilds

  UpdateLogin([this.userInfo, this.userMain]);

}

//Logs out the user
class Logout extends LoginEvent {
  final Function() callback;
  Logout({this.callback});
}

//Pushes the state to the login state with a full user
class LoginSuccessful extends LoginEvent {
  final UserInfo user; //Full user
  final UserMain userMain; //User user main
  final UserSettings settings; 
  LoginSuccessful(this.user, this.userMain, {this.settings});

  ///Used to store the login details in local storage
  ///
  ///[loginEvent] - Associated login event that lead to the successful login
  Map<String, dynamic> toJson(Login loginEvent){
    return {
      'id': user.id,
      'login': loginEvent.usernameOrEmail,
      'pass': loginEvent.password,
      'fname': user.firstName,
      'lname': user.lastName,
      'pic': user.profilePicture,
      'user': user.username
    };
  }
}

//Pushes the state back to the Logged out screen
class LoginFailed extends LoginEvent {
  final String errorMessage;
  LoginFailed(this.errorMessage);
}