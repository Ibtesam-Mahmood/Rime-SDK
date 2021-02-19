

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/login/loginBloc.dart';
import '../state/login/loginState.dart';
import '../util/paddingProvider.dart';
import 'Login/Login/MainLoginPage.dart';
import 'chatSDK/ChatMenu.dart';

class MainPage extends StatefulWidget {

  MainPage(Key key) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  
  ///Holds the login state of the application
  LoginState loginState;

  ///Firebase configuration
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();

    loginState = LoginBloc().state;

    // _firebaseMessaging.autoInitEnabled();
    // _firebaseMessaging.setAutoInitEnabled(true).then((_) => _firebaseMessaging
    //     .autoInitEnabled()
    //     .then((bool enabled) => print(enabled)));
    // _firebaseMessaging.configure(
    //   onMessage: (Map<String, dynamic> message) async {
    //     final parsed = jsonDecode(message['data']['notification'].toString());
    //     PollarNotification notification = PollarNotification.fromJson(parsed);

    //     if(notification.type['type'] == 'chat'){
    //       try{
    //         Chat newChat = await ChatApi.getChat(notification.typeId);

    //         if(ChatBloc().state.chats[newChat.id] == null){
    //           ChatBloc().add(InitChatEvent(newChat));
    //         }

    //         //Show message notification inapp
    //         Notifeye().showChatNotificiation(newChat, notification);

    //       }catch(e){print(e);}

    //     }
        

    //     print('onMessage: ' + message.toString());
    //   },
    //   onLaunch: (Map<String, dynamic> message) async {

    //     final parsed = jsonDecode(message['data']['notification'].toString());
    //     PollarNotification notification = PollarNotification.fromJson(parsed);
        
    //   if(notification.typeId.substring(0, 6) == 'Pollar'){
    //     Chat newChat = await ChatApi.getChat(notification.typeId);
    //     // ChatBloc().add(InitChatEvent(newChat));

    //     //TODO: route to chat page
    //   }
    //   else{

    //     //TODO: implement specific page routing and multiple account notifications

    //     //Adds the page routing to the login pipeline
    //     LoginBloc().postLoginCallBack = (){
    //       //Refrshes the notifications page 
    //       _notificationController.refresh();

    //       //Routes to the notifications page
    //       setState(() {
    //         index = 3;
    //       });
    //     };
    //   }

    //     print('onLaunch: ' + message.toString());
    //   },
    //   onResume: (Map<String, dynamic> message) async {

    //     final parsed = jsonDecode(message['data']['notification'].toString());
    //     PollarNotification notification = PollarNotification.fromJson(parsed);
    //     if(notification.typeId.substring(0, 6) == 'Pollar'){
    //       Chat newChat = await ChatApi.getChat(notification.typeId);
    //       // ChatBloc().add(InitChatEvent(newChat));

    //       //TODO: route to chat page
    //     }
    //   else{
    //     //TODO: implement specific page routing

    //     //Refrshes the notifications page 
    //     _notificationController.refresh();

    //     //Routes to the notifications page
    //     setState(() {
    //       index = 3;
    //     });
    //   }
    //     print('onResume: ' + message.toString());
    //   }
    // );

    // //Ask for the use of push notifications for ios
    // _firebaseMessaging.requestNotificationPermissions(
    //   const IosNotificationSettings(sound: true, alert: true, badge: true),
    // );

    // DynamicLinkService().handleDynamicLinks(context);

    // _navigationBarController = NavigationBarController();
  }

  @override
  Widget build(BuildContext context) {
    
    return GestureDetector(
        ///Pop the keyboard if its open [only for iOS]
        behavior: HitTestBehavior.translucent,
        onTap: (){
          ///[Currently Enabled for Android]
          // Platform.isIOS ? 
            FocusScope.of(context).unfocus();
            // : null
        },
        child: PaddingProvider(
          height: MediaQuery.of(context).size.height,
          child: BlocListener<LoginBloc, LoginState>(
            bloc: BlocProvider.of<LoginBloc>(context),
            listener: (context, state){
              //Primary listener for the application, used to initalize important elements for the application
              //Also used to dispose of those elements when logged out
              setState(() {
                loginState = state;
              });
            },
            child: _buildApplciationRoot(context, loginState), 
          ),
        ),
      );
  }

  ///Builds the root of the application depening on the current login state
  Widget _buildApplciationRoot(context, state) {

    //Moves to the main application when logged in
    //The app is shown on the LoggedInState and at any point
    //The userMain and userInfo can be retreived at any point of the application at this state
    if (state is LoggedInState) {

      return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop(); //Manages android back button popping
            return false;
          },
          child: ChatMenuPage(key: ValueKey('chat - page'))
      );
    }
  
    //Moves to the logged out page to manage all logged out events and state
    else {
      return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop(); //Manages android back button popping
            return false;
          },
          child: MainLoginPage()
      );
    }
  }

}
