import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as bloc;
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/rime.dart';
import 'package:rime/state/RimeRepository.dart';
import './pages/MainBody.dart';
import 'state/login/loginBloc.dart';
import 'state/login/loginBloc.dart';
import 'util/colorProvider.dart';
import './util/config_reader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

void main(List<String> args) async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await ConfigReader.initialize();

  print('Initializing');
  await DotEnv.load(fileName: '.env');
  await Rime.initialize(DotEnv.env);
  print('Initialized');

  runApp(Pollar());
}

class Pollar extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _PollarState createState() => _PollarState();
}

class _PollarState extends State<Pollar> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pollar',
      theme: ThemeData(
        splashColor: Colors.transparent,
        dividerColor: Colors.transparent,

        //Definitions for text themes to be used within the application.
        //Colors will be defualted and added in a case-by-case scenario
        textTheme: TextTheme(
          headline1: TextStyle(
              fontSize: 36,
              letterSpacing: 0.4,
              height: 1.194,
              fontWeight: FontWeight.bold),
          headline2: TextStyle(
              fontSize: 36,
              letterSpacing: -0.7,
              height: 1.194,
              fontWeight: FontWeight.bold),
          headline3: TextStyle(
              fontSize: 24,
              letterSpacing: 0.27,
              height: 1.208,
              fontWeight: FontWeight.bold),
          headline4: TextStyle(
              fontSize: 21,
              letterSpacing: 0.36,
              height: 1.238,
              fontWeight: FontWeight.w300),
          headline5: TextStyle(
              fontSize: 17,
              letterSpacing: -0.41,
              height: 1.294,
              fontWeight: FontWeight.bold),
          bodyText1: TextStyle(
              fontSize: 16,
              letterSpacing: -0.32,
              height: 1.313,
              fontWeight: FontWeight.normal),
          bodyText2: TextStyle(
              fontSize: 15,
              letterSpacing: -0.24,
              height: 1.333,
              fontWeight: FontWeight.w600),
          button: TextStyle(
              fontSize: 14,
              letterSpacing: -0.16,
              height: 1.143,
              fontWeight: FontWeight.bold),
          subtitle1: TextStyle(
              fontSize: 14,
              letterSpacing: -0.16,
              height: 1.286,
              fontWeight: FontWeight.normal),
          overline: TextStyle(
              fontSize: 13,
              letterSpacing: 0.15,
              height: 1.462,
              fontWeight: FontWeight.w600),
          caption: TextStyle(
              fontSize: 13,
              letterSpacing: 0.15,
              height: 1.154,
              fontWeight: FontWeight.normal),
          headline6: TextStyle(
              fontSize: 12,
              letterSpacing: -0.2,
              height: 1.333,
              fontWeight: FontWeight.bold), //Will replace Button2 theme
          subtitle2: TextStyle(
              fontSize: 12,
              letterSpacing: 0,
              height: 1.333,
              fontWeight: FontWeight.normal),
        ),
      ),
      //Base route for the application
      //creates the base application in a modal page route to enable supertino modals
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
            settings: settings,
            builder: (context) {
              return bloc.BlocProvider<LoginBloc>(
                  //Implemented to retreive login bloc infromation from anypoint ih the app
                  create: (_) => LoginBloc(),
                  child: AppColorThemeController(
                      child: MainPage(GlobalKey<MainPageState>())));
            });
      },
    );
  }
}
