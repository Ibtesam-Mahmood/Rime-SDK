import 'package:flutter_test/flutter_test.dart';

import 'package:rime/rime.dart';
import 'package:rime/state/RimeRepository.dart';

// ignore: library_prefixes
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

void main() async {
  // test('adds one to input values', () {
  //   final calculator = Calculator();
  //   expect(calculator.addOne(2), 3);
  //   expect(calculator.addOne(-7), -6);
  //   expect(calculator.addOne(0), 1);
  //   expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  // });
  TestWidgetsFlutterBinding.ensureInitialized();

  await DotEnv.load();
  await Rime.initialize(DotEnv.env);
  await RimeRepository().initializeRime('testUser1');
  print('Initialized');

  // testCreateChannel('creates channel for user', () {
  //     expect(() => true == true)

  // });
}
