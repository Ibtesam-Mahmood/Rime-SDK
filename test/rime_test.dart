import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';

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

  group('String test tests', () {
    test('String.split() splits the string on the delimiter', () {
      var string = 'foo,bar,baz';
      expect(string.split(','), equals(['foo', 'bar', 'baz']));
    });

    test('String.trim() removes surrounding whitespace', () {
      var string = '  foo ';
      expect(string.trim(), equals('foo'));
    });
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('String test tests', () {
    setUp(() async {
      HttpOverrides.global = null;
      print('Initializing');
      await DotEnv.load(fileName: '.env');
      await Rime.initialize(DotEnv.env);
      await RimeRepository().initializeRime('testUser1');
      print('Initialized');
    });

    test('test', () async {
      // await RimeApi.createChannel(['testUser1', 'testUser2']);

      // List<String> g = await RimeApi.getChannelGroups('testUser1');

      // print('Groups: ' + g.toString());

      // ChannelGroupListChannelsResult groups =
      //     await RimeRepository().client.channelGroups.listChannels(g[0]);
      // print('Channels: ' + groups.channels.toList().toString());

      print('hello');

      await RimeRepository().client.addMessageAction("userID", "true", "rime_testUser1_16148386848078668", Timetoken(16148575074308885));

      await Future.delayed(Duration(seconds: 10));

      expect(true, true);
    });
  });
}
