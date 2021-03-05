import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide BuildContext;
import 'package:progress_dialog/progress_dialog.dart';

import '../../../components/widgets/buttons/PollarBackButton.dart';
import '../../../components/widgets/buttons/PollarRoundedButton.dart';
import '../../../components/widgets/horizontalBar.dart';
import '../../../components/widgets/input_fields/hiddenTextField.dart';
import '../../../state/login/loginBloc.dart';
import '../../../state/login/loginEvents.dart';
import '../../../state/login/loginState.dart';
import '../../../util/colorProvider.dart';
import '../../../util/paddingProvider.dart';


///main login page when app opens
class MainLoginPage extends StatefulWidget {
  //this is the main login form for the app (first screen)
  @override
  _MainLoginPageState createState() => _MainLoginPageState();
}

class _MainLoginPageState extends State<MainLoginPage> {

  ///Login credentials used, either username, phone or email
  String credentials = 'befy';

  ///Password the user enters to attempt login
  String password = 'password';

  ///Getter used to define if the login button is enabled
  bool get enableLogin {
    //Credential must not be empty
    //Min password length is 8 characters
    return credentials.isNotEmpty && password.length >= 8;
  }

  @override
  Widget build(BuildContext context) {
    
    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    //Padding values provider
    final paddingValues = PaddingProvider.of(context);
                
    return Scaffold(
      backgroundColor: appColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: PollarBackButton()
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            
            //Primary header for the page.
            Padding(
              padding: EdgeInsets.only(bottom: paddingValues.large),
              child: Text('Enter your login information', style: textStyles.headline2.copyWith(color: appColors.onBackground),),
            ),
            
            //Username text field
            //Auto focus is enabled to allow instant typing when on the current page
            TextField(
              autofocus: true,
              style: textStyles.headline4.copyWith(color: appColors.onBackground, decoration: TextDecoration.none),
              decoration: InputDecoration(
                hintText: 'Username, mobile or email',

                hintStyle: textStyles.headline4.copyWith(color: appColors.grey),
                border: InputBorder.none
              ),
              onChanged: (val){
                //Updates the login credentails
                setState(() {
                  credentials = val;
                });
              },
            ),

            //Horizontal bar used for styling, seperated the 2 fields
            HorizontalBar(color: appColors.grey.withAlpha(25), width: 1,),
            
            //Password text field
            //Values are ommitted until the icon on the left is used to display the text
            HiddenTextField(
              
              hintText: 'Password',
              onChanged: (val){
                //Updates the login password
                setState(() {
                  password = val;
                });
              },
            ),
            
            //Error text display
            //Used to display when login has failed
            BlocBuilder<LoginBloc, LoginState>(
              cubit: LoginBloc(),
              buildWhen: (o, n) => n is LoggedOutState,
              builder: (context, state) {

                String error = state is LoggedOutState ? state.error : null;

                return Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: paddingValues.small),
                    child: error != null ? Text(error, style: textStyles.overline.copyWith(color: appColors.red)) : Container(),
                  ),
                );
              }
            ),

            //Dynamic sizing spacer
            //Shrinks when keyboard is opened
            Spacer(),

            Padding(
              padding: EdgeInsets.only(top: paddingValues.small, bottom: paddingValues.small, right: 24),
              child: PollarRoundedButton(
                color: appColors.blue,
                disabledColor: appColors.grey.withAlpha(18),
                child: Text('Login', style: textStyles.headline5.copyWith(color: enableLogin ? Colors.white : appColors.grey.withAlpha(51))),
                onPressed: enableLogin ? (){
                  //Shows a progress indicator while authenticating
                  ProgressDialog loading = ProgressDialog(context,
                      type: ProgressDialogType.Normal,
                      isDismissible: false,
                      showLogs: false);

                  //ProgressDialog style
                  loading.style(message: 'Authentication...');

                  //Sends the login event to the bloc
                  BlocProvider.of<LoginBloc>(context).add(
                      Login(credentials.toLowerCase(), password, callback: () {
                      loading.hide();
                  }));

                  loading.show(); //Displays the loading dialog
                } : null,
              ),
            ),
          ],
        ),
      ));
  }
}
