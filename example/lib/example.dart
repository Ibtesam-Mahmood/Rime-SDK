import 'package:rime/rime.dart';

// import 'main.dart';
import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Initializing');
  await DotEnv.load(fileName: '.env');
  await Rime.initialize(DotEnv.env);
  print('Initialized');

  // runApp(RimeApp());
  
}