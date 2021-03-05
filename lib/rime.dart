library rime;

export 'package:pubnub/pubnub.dart';

import 'package:get_it/get_it.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:rime/state/core/rime_root_functions.dart';
import 'package:rime/state/rime_bloc/rime_bloc.dart';

/// Primary controller for any rime based application.
///
/// The Rime based application must be `INITILAIZED`.
/// ENsure this by running the [Rime.iniitalize()] function.
class Rime {
  static bool _initialized = false;

  static dynamic _env;

  static RimeDeveloperFunctions _devFunctions;

  /// Registers cruitial elemnts of Rime
  static void initialize(dynamic env, [RimeDeveloperFunctions devFunctions]) async {
    //Sets the env file
    Rime._env = env;

    //Bind developer functions
    Rime._devFunctions = devFunctions ?? RimeDeveloperFunctions();

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

  ///Retreives the environment variables
  static dynamic get env => _env;

  ///Dev functions
  static RimeDeveloperFunctions get functions {
    assert(INITIALIZED);
    return _devFunctions;
  }

}