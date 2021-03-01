library rime;

import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:get_it/get_it.dart';
import 'package:rime/state/RimeRepository.dart';


/// Primary controller for any rime based application. 
/// 
/// The Rime based application must be `INITILAIZED`.
/// ENsure this by running the [Rime.iniitalize()] function.
class Rime {

  static bool _initialized = false;

  /// Registers cruitial elemnts of Rime
  static void iniitalize() async {

    ///Ensures .env loader is binded
    await DotEnv.load(fileName: ".env");

    //Initializes singleton for Rime repository
    RimeRepository rootRepo = RimeRepository();
    GetIt.instance.registerSingleton<RimeRepository>(rootRepo);

    //Binds Hive interface
    

    Rime._initialized = true;

  }

  /// Determines if the rime application is initialized. 
  /// Used for error checks in various parts of the SDK.
  // ignore: non_constant_identifier_names
  static bool get INITIALIZED => Rime._initialized;

}