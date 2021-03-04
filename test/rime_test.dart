import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';

import 'package:rime/rime.dart';
import 'package:rime/state/RimeRepository.dart';

// ignore: library_prefixes
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

void main() async {
  // I believe this was example flutter test code
  // test('adds one to input values', () {
  //   final calculator = Calculator();
  //   expect(calculator.addOne(2), 3);
  //   expect(calculator.addOne(-7), -6);
  //   expect(calculator.addOne(0), 1);
  //   expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  // });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('RimeApi Tests: ', () {
    setUp(() async {
      HttpOverrides.global = null;
      print('\n' 'Initializing');
      await DotEnv.load(fileName: '.env');
      await Rime.initialize(DotEnv.env);
      await RimeRepository().initializeRime('testUser1');
      print('Initialized');
    });

    test('Print all groups for testUser1', () async {
      String userID = 'testUser1';
      await printAllGroupsForUser(userID);
    }, skip: "Don't want this to print everytime");

    test('Print all groups and channels for testUser1', () async {
      String userID = 'testUser1';
      await printAllGroupsAndChannelsForUser(userID);
    }, skip: "Don't want this to print everytime");

    group('Specific message and channel group tests', () {
      int timeToken = 16148934155829055;
      String channel = 'rime_testUser1_16148386848078668';

      test('Print all messages from the channel: $channel ', () async {
        await printEveryMessageInAChannel(channel);
        var actual = true;
        var expected = true;
        expect(actual, expected);
      }, skip: "Don't want it to print every time");

      test(
          'Checks that the message on channel: $channel, at time: $timeToken exists',
          () async {
        PaginatedChannelHistory ch =
            RimeRepository().client.channel(channel).history();

        await ch.more();

        List<BaseMessage> messages = ch.messages;

        BaseMessage message = messages
            .firstWhere((e) => e.publishedAt.value == 16148934155829055);
        var actual = message;
        var expected = isNot(null);
        expect(actual, expected);
      });
    });

    test('Add Message Action', () async {
      //Send Message
      var channel = 'rime_testUser1_16148386848078668';
      var message = 'hello';
      PublishResult publish =
          await RimeRepository().client.publish(channel, message);

      //Get the TimeToken for the message that was just sent
      int time = publish.timetoken;

      //Add Test messageAction to the just sent message
      AddMessageActionResult res = await RimeRepository()
          .client
          .addMessageAction('test', 'true', channel, Timetoken(time));

      //Confirm that it receives a successful response
      var actual = res.status;
      var expected = 200;
      expect(actual, expected);
    });
  });
}

Future printEveryMessageInAChannel(String channel) async {
  PaginatedChannelHistory ch =
      RimeRepository().client.channel(channel).history();

  await ch.more();

  List<BaseMessage> messages = ch.messages;

  BaseMessage message;
  for (message in messages) {
    print('Time: ' +
        message.publishedAt.toString() +
        '\n\t' +
        message.content.toString());
  }
}

Future printAllGroupsAndChannelsForUser(String userID) async {
  List<String> g = await RimeApi.getChannelGroups(userID);

  String groupName;
  for (groupName in g) {
    await printAllChannelsInAGroup(groupName);
  }
}

Future printAllChannelsInAGroup(String groupName) async {
  ChannelGroupListChannelsResult channelGroupList =
      await RimeRepository().client.channelGroups.listChannels(groupName);
  print('Group: ' + channelGroupList.name);
  print('Channels: ' + channelGroupList.channels.toList().toString());
}

Future printAllGroupsForUser(String userID) async {
  List<String> g = await RimeApi.getChannelGroups(userID);
  print('Groups: ' + g.toString());
}
