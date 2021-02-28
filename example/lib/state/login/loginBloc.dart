import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/endpoints/userMainApi.dart';
import '../../models/topics.dart';
import '../../models/userInfo.dart';
import '../../models/userMain.dart';
import '../store/pollarStoreBloc.dart';
import 'loginEvents.dart';
import 'loginState.dart';

//Manages the user login state
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  //Login bloc singleton
  static final LoginBloc _store = LoginBloc._internal();

  //FirebaseMessaging initialization
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  //Private constructor to innitialize the singleton
  LoginBloc._internal();

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

  @override //TODO: make innitial state dynamic
  LoginState get initialState => LoggedOutState(); //Innitial bloc state

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is Login) {
      yield* _mapLoginToState(event);
    } else if (event is Logout) {

      //clears the pollar store state
      PollarStoreBloc().add(ClearStoreState());

      //Deletes the stored autologin key
      deleteAutoLogin();

      yield* _mapLogoutToState();

      if(event.callback != null) event.callback();
    } else if (event is LoginSuccessful) {

      //Login
      String token = await _firebaseMessaging.getToken();
      //set user to state
      PollarStoreBloc().add(EditPollarStoreState(loginUserId: event.user.id, loginSettings: event.settings));
      //load state
      PollarStoreBloc().add(LoadPollarState(event.user.id));

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

        //Store the loginData as the current auto login
        storeAutoLogin(loginSuccessfulEvent.toJson(event));

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

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ STATIC FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Stores auto login data into local storage
  static void storeAutoLogin(Map<String, dynamic> loginData) async {
    
    final localStorage = FlutterSecureStorage();

    localStorage.write(key: 'autolog', value: jsonEncode(loginData));

  }

  ///Stores auto login data into local storage
  static void deleteAutoLogin() async {
    
    final localStorage = FlutterSecureStorage();

    localStorage.delete(key: 'autolog');

  }

  ///Retreives auto login data from the local storage
  static Future<Map<String, dynamic>> getAutoLoginData() async {

    final localStorage = FlutterSecureStorage();
    String autoLoginKey;
    try{
      autoLoginKey = await localStorage.read(key: 'autolog');
    }catch(e){
      return null;
    }

    if(autoLoginKey == null) {return null;} //No stored key
    else {return jsonDecode(autoLoginKey);}

  }

  ///Returns the list of stored logins. 
  ///If empty creates a new list.
  static Future<List<Map<String, dynamic>>> getSavedLogins() async {

    final localStorage = FlutterSecureStorage();

    String encodedLogins;
    try{
      encodedLogins = await localStorage.read(key: 'savedlog');
    }catch(e){
      //No saved object found, create new
      localStorage.write(key: 'savedlog', value: jsonEncode({'savedlog': []}));
      return [];
    }
     

    if(encodedLogins == null){
      //No saved object found, create new
      localStorage.write(key: 'savedlog', value: jsonEncode({'savedlog': []}));
      return [];
    }
    else{
      //Saved log found, decode and return
      List<Map<String, dynamic>> decodedLogins = (jsonDecode(encodedLogins)['savedlog'] as List).cast<String>().map<Map<String, dynamic>>((l) => jsonDecode(l)).toList();
      return decodedLogins;
    }
  }

  ///Stores the currently stored auto login key into the stored logins list. 
  ///Adds to the start of the list. 
  ///Max 10 logins, removes oldest. 
  ///Removes duplicates. 
  static Future<List<Map<String, dynamic>>> saveLogin() async {

    //List of saved logins
    List<Map<String, dynamic>> logins = await getSavedLogins();

    //Current login user
    Map<String, dynamic> autologin = await getAutoLoginData();

    //Removes previous logins that match the current login
    logins.removeWhere((l) => l['id'] == autologin['id']);

    //Adds the auto login value
    logins.insert(0, autologin);

    if(logins.length > 10){
      //remove last value
      logins.removeLast();
    }

    //Save the list to local storage
    final localStorage = FlutterSecureStorage();

    List<String> encodedLogins = logins.map<String>((l) => jsonEncode(l)).toList();

    localStorage.write(key: 'savedlog', value: jsonEncode({'savedlog': encodedLogins}));

    //Returns the updated list
    return logins;
  }

  ///Removes a saved login by id
  static Future<List<Map<String, dynamic>>> removeSavedLogin(String id) async {

    //List of saved logins
    List<Map<String, dynamic>> logins = await getSavedLogins();

    //Removes the login by id
    logins.removeWhere((l) => l['id'] == id);

    //Save the list to local storage
    final localStorage = FlutterSecureStorage();

    List<String> encodedLogins = logins.map<String>((l) => jsonEncode(l)).toList();

    localStorage.write(key: 'savedlog', value: jsonEncode({'savedlog': encodedLogins}));

    //Returns the updated list
    return logins;
  }
}
