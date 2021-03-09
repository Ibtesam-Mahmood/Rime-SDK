import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:rime/state/rime_bloc/rime_bloc.dart';
import 'package:rime/state/rime_bloc/rime_bloc_events.dart';
import '../../api/endpoints/userMainApi.dart';
import '../../models/userInfo.dart';
import '../../models/userMain.dart';
import '../store/pollarStoreBloc.dart';
import 'loginEvents.dart';
import 'loginState.dart';

//Manages the user login state
class LoginBloc extends Bloc<LoginEvent, LoginState> {

  //Login bloc singleton
  static final LoginBloc _store = LoginBloc._internal();

  //Private constructor to innitialize the singleton
  LoginBloc._internal() : super(initialState);

  ///Widget defined as the route that occurs when the application is logged out
  Widget postLogOutRoute;

  //Function that runs once login is complete
  Function postLoginCallBack;

  //Factory constructor to access the store singleton
  factory LoginBloc() {
    return _store;
  }

  //Drains the login bloc singleton
  static void drainSington() {
    _store.drain();
  }

  static LoginState get initialState => LoggedOutState(); //Innitial bloc state

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is Login) {
      yield* _mapLoginToState(event);
    } else if (event is Logout) {

      //clears the pollar store state
      PollarStoreBloc().add(ClearStoreState());

      yield* _mapLogoutToState();

      if(event.callback != null) event.callback();
    } else if (event is LoginSuccessful) {

      //set user to state
      PollarStoreBloc().add(EditPollarStoreState(loginUserId: event.user.id, loginSettings: event.settings));
      //load state
      PollarStoreBloc().add(LoadPollarState(event.user.id));

      //Initialize rime
      RimeBloc().add(InitializeRime(event.user.id));

      yield* _mapLoginSucessfulToState(event.user, event.userMain);

      //Calls the post login function if defined
      if(_store.postLoginCallBack != null){
        //Call back is claled after a small delay to avoid build issues
        await Future.delayed(Duration(milliseconds: 100)).then((_){
          _store.postLoginCallBack();
        });
        _store.postLoginCallBack = null;
      }
    } else if (event is LoginFailed && !(_store.state is LoginState)) {
      yield* _mapLogoutToState(event.errorMessage);
    } else if (event is UpdateLogin && state is LoggedInState) {
      //Only runs event if the user is logged in
      yield* _mapUpdateUserToState(event.userInfo, event.userMain);
    }
  }

  //Manages update user event
  //Applies user changes to state
  Stream<LoginState> _mapUpdateUserToState(
      UserInfo newUserInfo, UserMain newUserMain) async* {
    try {
      yield LoggedInState(
        (state as LoggedInState).fullUser.copyWith(newUserInfo),
        (state as LoggedInState).userMain.copyWith(newUserMain),
      );
    } catch (err) {
      throw ('UpdateLogin called when LoginBloc is not in LoggedInState');
    }
  }

  //Manages the login event
  Stream<LoginState> _mapLoginToState(Login event) async* {
    //Attempts to login the user
    UserMainApi.login(event.usernameOrEmail, event.password).then((val) async {

        LoginSuccessful loginSuccessfulEvent = LoginSuccessful(val.item2, val.item1, settings: val.item3);

        add(loginSuccessfulEvent); //If login is successful, add the LoginSuccessful Event

        if (event.callbackSuccess != null)
          {event.callbackSuccess();} //Runs the success callback function if its defined

      
      if (event.callback != null)
        {event.callback();} //Runs the callback function if its defined

    }).catchError((e) {
        if (event.callBackFail != null)
          {event.callBackFail();} //Runs the failure callback function if its defined
        if (event.callback != null)
          {event.callback();} //Runs the callback function if its defined
      add(LoginFailed(e.toString())); //If login is failed dispatch the LoginFailed event
    });

    yield LoginAuthState(); //Displatches the login auth state while the login is under process
  }

  //Manages the logout event
  Stream<LoginState> _mapLogoutToState([String error]) async* {
    yield LoggedOutState(error: error); //Dispacthes the logged out state
  }

  //Manages login successful event
  Stream<LoginState> _mapLoginSucessfulToState(
      UserInfo user, UserMain userAuth) async* {
    yield LoggedInState(user, userAuth);
  }

  //Retreives a snapshot of the current state from the bloc
  LoginState getCurrentState() {
    return state;
  }

  //Retreives the current instance of userInfo from the state
  //Only works if the state is LoggedInState
  UserInfo getUserInfo() {
    if (getCurrentState() is LoggedInState) {
      return (getCurrentState() as LoggedInState).fullUser;
    } else
      {throw ('Cannot get userInfo from ' + getCurrentState().toString());}
  }

  //Retreives the current instance of userInfo from the state
  //Only works if the state is LoggedInState
  UserMain getUserMain() {
    if (getCurrentState() is LoggedInState) {
      return (getCurrentState() as LoggedInState).userMain;
    } else
      {throw ('Cannot get userInfo from ' + getCurrentState().toString());}
  }

}
