library rime;

import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:get_it/get_it.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:rime/state/rime_bloc/rime_bloc.dart';


/// Primary controller for any rime based application. 
/// 
/// The Rime based application must be `INITILAIZED`.
/// ENsure this by running the [Rime.iniitalize()] function.
class Rime {

  static bool _initialized = false;

  /// Registers cruitial elemnts of Rime
  static void initialize() async {

    ///Ensures .env loader is binded
    await DotEnv.load(fileName: ".env");

    //Binds Hive interface
    

    Rime._initialized = true;

  }

  /// Disposes the rime bloc, called when the root is closed
  static void dispose() {
    RimeBloc().drain();
  }

  /// Determines if the rime application is initialized. 
  /// Used for error checks in various parts of the SDK.
  // ignore: non_constant_identifier_names
  static bool get INITIALIZED => Rime._initialized;

}