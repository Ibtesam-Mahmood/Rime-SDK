import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/model/rimeMessage.dart';

import 'package:rime/rime.dart';
import 'package:rime/state/RimeFunctions.dart';
import 'package:rime/state/RimeRepository.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart' as dot_env;

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RimeAPI Tests: ', () {
    setUp(() async {
      HttpOverrides.global = null;
      print('\n' 'Initializing');
      await dot_env.load(fileName: '.env');
      await Rime.initialize(dot_env.env);
      await RimeRepository().initializeRime('testUser12');
      print('Initialized');
    });

    test('Print all groups for testUser1', () async {
      String userId = 'testUser1';
      await printAllGroupsForUser(userId);
    }
        // , skip: "Don't want this to print everytime"
        );

    test('Print all groups and channels for testUser1', () async {
      String userId = 'testUser1';
      await printAllGroupsAndChannelsForUser(userId);
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

      test('Checks that the message on channel: $channel, at time: $timeToken exists', () async {
        PaginatedChannelHistory ch = RimeRepository().client.channel(channel).history();

        await ch.more();

        List<BaseMessage> messages = ch.messages;

        BaseMessage message = messages.firstWhere((e) => e.publishedAt.value == 16148934155829055);
        var actual = message;
        var expected = isNot(null);
        expect(actual, expected);
      });
    });

    test('Add Message Action', () async {
      //Send Message
      var channel = 'rime_testUser1_16148386848078668';
      var message = 'hello';
      PublishResult publish = await RimeRepository().client.publish(channel, message);

      //Get the TimeToken for the message that was just sent
      int time = publish.timetoken;

      //Add Test messageAction to the just sent message
      AddMessageActionResult res =
          await RimeRepository().client.addMessageAction('test', 'true', channel, Timetoken(time));

      //Confirm that it receives a successful response
      var actual = res.status;
      var expected = 200;
      expect(actual, expected);
    });

    test('Get a specific channel membership', () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.updated:desc']));

      String channelId = memRes.metadataList.first.channel.id;
      String filter = 'channel.id == "$channelId"';

      MembershipsResult currentMembership = await RimeRepository().client.objects.getMemberships(
          limit: 1,
          includeCustomFields: true,
          includeChannelFields: true,
          includeChannelCustomFields: true,
          includeCount: true,
          filter: filter);
      int totalCount = currentMembership.totalCount;
      print('Got $totalCount membership');
    });

    test('Soft Delete a Channel', () async {
      String channelId = 'rime_testUser1_16148386848078668';
      String filter = 'channel.id == "$channelId"';
      bool success = await RimeAPI.deleteChannel(channelId);

      // ignore: unused_local_variable
      MembershipsResult currentMembership = await RimeRepository().client.objects.getMemberships(
          limit: 1,
          includeCustomFields: true,
          includeChannelFields: true,
          includeChannelCustomFields: true,
          includeCount: true,
          filter: filter);

      print('Soft Deleted Success: $success');
    });

    group('Ibte Tests', () {
      test('Set memberdata for channel', () async {
        //Send Message
        var channelId = 'rime_testUser1_16148386848078668';

        int time = (await RimeRepository().client.time()).value;

        await RimeRepository()
            .client
            .objects
            .setChannelMetadata(channelId, ChannelMetadataInput(name: time.toString()));

        GetChannelMetadataResult channelMeta = await RimeRepository().client.objects.getChannelMetadata(channelId);

        expect(channelMeta.metadata.name, time.toString());
      });

      test('Ensure Channel is not updated with message action', () async {
        //Send Message
        var channelId = 'rime_testUser1_16148386848078668';
        var message = 'hello';

        GetChannelMetadataResult channelMeta = await RimeRepository().client.objects.getChannelMetadata(channelId);

        String time = channelMeta.metadata.updated;
        print('t1: ' + time);

        PublishResult publish = await RimeRepository().client.publish(channelId, message);

        channelMeta = await RimeRepository().client.objects.getChannelMetadata(channelId);

        time = channelMeta.metadata.updated;
        print('t2: ' + time);

        //Get the TimeToken for the message that was just sent
        int token = publish.timetoken;

        //Add Test messageAction to the just sent message
        // ignore: unused_local_variable
        AddMessageActionResult res =
            await RimeRepository().client.addMessageAction('test', 'true', channelId, Timetoken(token));

        channelMeta = await RimeRepository().client.objects.getChannelMetadata(channelId);

        time = channelMeta.metadata.updated;
        print('t3: ' + time);

        expect(true, true);
      });

      group('Check Channel order on paginated request for testUser1', () {
        String userId = 'testUser1';

        test('User has channel memberships', () async {
          MembershipsResult res = await RimeRepository().client.objects.getMemberships(uuid: userId, limit: 10);

          expect(res.totalCount, greaterThan(0));
        });

        test('Memberships mapped to channels', () async {
          MembershipsResult res = await RimeRepository().client.objects.getMemberships(uuid: userId, limit: 10);

          List<String> channels = res.metadataList.map<String>((meta) => meta?.channel?.id ?? '').toList();

          expect(channels.contains(''), false);
        });

        test('Reset channel metadata', () async {
          MembershipsResult res = await RimeRepository().client.objects.getMemberships(uuid: userId, limit: 10);

          List<String> channels = res.metadataList.map<String>((meta) => meta?.channel?.id ?? '').toList();

          for (var channel in channels) {
            SetChannelMetadataResult res =
                await RimeRepository().client.objects.setChannelMetadata(channel, ChannelMetadataInput(name: userId));

            expect(res.metadata.name, userId);
          }
        });
      });
    });

    group('Testing creating, hydrating, and sending message', () {
      String channel = 'rime_testUser12_16152858276361764';

      test('create a channel', () async {
        RimeChannel createdChannel = await RimeAPI.createChannel([RimeRepository().userId, 'testUser2']);

        channel = createdChannel.channel;

        print(channel);

        createdChannel = await RimeAPI.getChannel(channel);

        expect(createdChannel.readMap?.isEmpty ?? false, false);
      }, skip: 'Already created');

      test('Test message subtitle', () async {
        String message = 'hello' + DateTime.now().toString();

        await RimeRepository().client.publish(channel, message);

        RimeChannel rimeChannel = await RimeAPI.getChannel(channel);

        expect(rimeChannel.subtitle, message);
      });

      test('Check history', () async {
        PaginatedChannelHistory history = RimeRepository().client.channel(channel).history();

        await history.more();

        print('Hello');

        expect(true, true);
      });
    });
  });

  group('RimeAPI Tests - testUser3', () {
    String userId = 'testUser3';

    setUp(() async {
      HttpOverrides.global = null;
      print('\n' 'Initializing');
      await dot_env.load(fileName: '.env');
      await Rime.initialize(dot_env.env);
      await RimeRepository().initializeRime(userId);
      print('Initialized');
    });

    test('Add Message Action without editing channel metadata on testUser3 channel 2', () async {
      //Send a message
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[1].channel.id;
      String message = 'Test';

      PublishResult publish = await RimeRepository().client.publish(channelId, message);

      //Get the TimeToken for the message that was just sent
      int time = publish.timetoken;

      //Add Test messageAction to the just sent message
      AddMessageActionResult res =
          await RimeRepository().client.addMessageAction('test', 'true', channelId, Timetoken(time));

      //Confirm that it receives a successful response
      var actual = res.status;
      var expected = 200;
      expect(actual, expected);
    });

    test('Get Memberships', () async {
      // ignore: unused_local_variable
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.updated:desc']));
      print('Got em');
      // MembershipMetadata
      // 		.updated -- when the membership was created
      //		.channel
      //				.updated -- not updated when a message or messageAction is published
      //				.updated -- is updated when the channel metadata is updated
    });

    test('Get Memberships with Pagination', () async {
      // ignore: unused_local_variable
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.updated:desc']),
          limit: 1);
      print('Got em');
    });

    test('Get Memberships page names', () async {
      DateTime start = DateTime.now();
      int pageSize = 1;
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.updated:desc']),
          limit: pageSize);
      String nextPage = memRes.next;
      int totalCount = memRes.totalCount;
      int numPages = (totalCount ~/ pageSize);
      List<String> pageNames = [];
      pageNames.add(nextPage);
      for (int i = 1; i < numPages; i++) {
        MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
            includeChannelCustomFields: true,
            includeChannelFields: true,
            includeCustomFields: true,
            sort: Set.from(['channel.updated:desc']),
            limit: pageSize,
            start: nextPage);
        nextPage = memRes.next;
        pageNames.add(nextPage);
      }

      DateTime end = DateTime.now();
      Duration duration = end.difference(start);
      print(duration.inMilliseconds);
      // Allowing someone to give an int pageIndex number would probably be too long
      // Just getting the 3 1-length pages took about 750ms
    });

    test('Create a channel with just testUser3', () async {
      String channelName = (await RimeAPI.createChannel([userId, 'testUser12'])).channel;
      print(channelName);
    }, skip: "Don't want to create channels everytime");

    test("Send a test message to testUser3's Channel 1", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[0].channel.id;
      String message = 'Test';

      PublishResult publish = await publishMessageWithChannelUpdate(channelId, message);

      print(publish.timetoken);
    });

    test('Send a RimeMessage through PubNub', () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[0].channel.id;
      String userId = 'testUser1';
      String message = 'Hello';
      RimeMessage rimeMessage = RimeMessage(
          uuid: userId,
          type: message,
          content: TextMessage.toPayload('Hello'),
          publishedAt: (await RimeRepository().client.time()),
          originalMessage: message);

      // Send the message
      // ignore: unused_local_variable
      PublishResult publish = await RimeRepository().client.publish(channelId, rimeMessage);

      expect(true, true);
    });

    test("Get testUser3's Channel 1's metadata", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[0].channel.id;

      GetChannelMetadataResult cmRes =
          await RimeRepository().client.objects.getChannelMetadata(channelId, includeCustomFields: true);

      // Got a 404. No Metadata exists for this channel...
      print('Got' + cmRes.toString());
    });

    test("Set testUser3's Channel 1's metadata", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[0].channel.id;
      ChannelMetadataInput channelMetadataInput =
          ChannelMetadataInput(name: 'testUser3 Channel 1', description: 'testUser3 Channel 1 Description!');

      // ignore: unused_local_variable
      SetChannelMetadataResult smRes =
          await RimeRepository().client.objects.setChannelMetadata(channelId, channelMetadataInput);

      print('Got smRes');
    });

    test("Send a test message to testUser3's channel 2", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[1].channel.id;
      String message = 'Test';

      PublishResult publish = await publishMessageWithChannelUpdate(channelId, message);

      print(publish.timetoken);
    });

    test("Get testUser3's channel 2's metadata", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[1].channel.id;

      GetChannelMetadataResult cmRes =
          await RimeRepository().client.objects.getChannelMetadata(channelId, includeCustomFields: true);

      // Got a 404. No Metadata exists for this channel...
      print('Got' + cmRes.toString());
    });

    test("Set testUser3's Channel 2's metadata", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[1].channel.id;
      ChannelMetadataInput channelMetadataInput =
          ChannelMetadataInput(name: 'testUser3 Channel 2', description: 'testUser3 Channel 2 Description!');

      // ignore: unused_local_variable
      SetChannelMetadataResult smRes =
          await RimeRepository().client.objects.setChannelMetadata(channelId, channelMetadataInput);

      print('Got smRes');
    });

    test("Send a test message to testUser3's channel 3", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[2].channel.id;
      String message = 'Test';

      PublishResult publish = await publishMessageWithChannelUpdate(channelId, message);

      print(publish.timetoken);
    });

    test("Get testUser3's channel 3's metadata", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[2].channel.id;

      GetChannelMetadataResult cmRes =
          await RimeRepository().client.objects.getChannelMetadata(channelId, includeCustomFields: true);

      // Got a 404. No Metadata exists for this channel...
      print('Got' + cmRes.toString());
    });

    test("Set testUser3's Channel 3's metadata", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList[2].channel.id;
      ChannelMetadataInput channelMetadataInput =
          ChannelMetadataInput(name: 'testUser3 Channel 3', description: 'testUser3 Channel 3 Description!');

      // ignore: unused_local_variable
      SetChannelMetadataResult smRes =
          await RimeRepository().client.objects.setChannelMetadata(channelId, channelMetadataInput);

      print('Got smRes');
    });

    test("Send a test message to testUser3's last channel", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList.last.channel.id;
      String message = 'Test';

      PublishResult publish = await publishMessageWithChannelUpdate(channelId, message);

      print(publish.timetoken);
    });

    test("Get testUser3's last channel's metadata", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList.last.channel.id;

      GetChannelMetadataResult cmRes =
          await RimeRepository().client.objects.getChannelMetadata(channelId, includeCustomFields: true);

      // Got a 404. No Metadata exists for this channel...
      print('Got' + cmRes.toString());
    });

    test("Set testUser3's Channel 3's metadata", () async {
      MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          sort: Set.from(['channel.name']));

      String channelId = memRes.metadataList.last.channel.id;
      ChannelMetadataInput channelMetadataInput =
          ChannelMetadataInput(name: 'testUser3 Channel 3', description: 'testUser3 Channel 3 Description!');

      // ignore: unused_local_variable
      SetChannelMetadataResult smRes =
          await RimeRepository().client.objects.setChannelMetadata(channelId, channelMetadataInput);

      print('Got smRes');
    });

    test('Create sets metadata for read action', () async {
      String channelName = (await RimeAPI.createChannel(['testUser1', 'testUser2', 'testUser3'])).channel;

      print(channelName);

      GetChannelMetadataResult res =
          await RimeRepository().client.objects.getChannelMetadata(channelName, includeCustomFields: true);

      expect(res.metadata.custom.containsKey('read'), true);

      Map<String, dynamic> readActions = jsonDecode(res.metadata.custom['read'] as String);

      expect(readActions.containsKey('testUser1'), true);
    });

    test('Ensure channelMembership event is received', () async {
      String channelName = 'rime_testUser3_16149450794304603';
      String listenerId = 'listener-id';

      print('Retreiving');

      GetChannelMetadataResult res =
          await RimeRepository().client.objects.getChannelMetadata(channelName, includeCustomFields: true);

      expect(res.metadata.custom.containsKey('read'), true);

      Map<String, dynamic> readActions = jsonDecode(res.metadata.custom['read'] as String);

      RimeRepository().addListener(listenerId, (en) {
        print(en.messageType.toString());
      });

      print('Binded');

      expect(readActions.containsKey('testUser1'), true);

      readActions['testUser1'] = 100;

      print('Sending');

      await RimeRepository()
          .client
          .objects
          .setChannelMetadata(channelName, ChannelMetadataInput(custom: {'read': jsonEncode(readActions)}));

      print('Delaying');

      await Future.delayed(Duration(seconds: 10));

      RimeRepository().removeListener(listenerId);

      expect(true, true);
    });

    test('Get Channel membership associated to user and channel', () async {
      String channel = 'rime_testUser3_16149449132204146';
      String userId = 'testUser1';

      MembershipsResult currentMembership = await RimeRepository()
          .client
          .objects
          .getMemberships(uuid: userId, limit: 1, includeCustomFields: true, filter: 'channel.id == \"$channel\"');

      expect(currentMembership.metadataList.length, 1);
    });

    test('Get RimeChannel from getChannel request', () async {
      String channel = 'rime_testUser3_16149449132204146';

      RimeChannel wap = await RimeAPI.getChannel(channel);

      expect(wap, isNot(null));
    });
  });
}

// Random Test Functions for Basic Functionality

///Publish message to the channel with channelId and also update the channel metadata at the same time
Future<PublishResult> publishMessageWithChannelUpdate(String channelId, String message) async {
  PublishResult publish = await RimeRepository().client.publish(channelId, message);

  GetChannelMetadataResult cmRes =
      await RimeRepository().client.objects.getChannelMetadata(channelId, includeCustomFields: true);

  Map customMetaData = cmRes.metadata?.custom ?? Map();
  customMetaData['lastUpdated'] = DateTime.now().toString();

  ChannelMetadataInput channelMetadataInput =
      ChannelMetadataInput(name: cmRes.metadata.name, description: cmRes.metadata.description, custom: customMetaData);
  // ignore: unused_local_variable
  SetChannelMetadataResult smRes =
      await RimeRepository().client.objects.setChannelMetadata(channelId, channelMetadataInput);
  return publish;
}

Future printEveryMessageInAChannel(String channel) async {
  PaginatedChannelHistory ch = RimeRepository().client.channel(channel).history();

  await ch.more();

  List<BaseMessage> messages = ch.messages;

  BaseMessage message;
  for (message in messages) {
    print('Time: ' + message.publishedAt.toString() + '\n\t' + message.content.toString());
  }
}

Future printAllGroupsAndChannelsForUser(String userId) async {
  List<String> g = await RimeFunctions.getChannelGroups(userId);

  String groupName;
  for (groupName in g) {
    await printAllChannelsInAGroup(groupName);
  }
}

Future printAllChannelsInAGroup(String groupName) async {
  ChannelGroupListChannelsResult channelGroupList = await RimeRepository().client.channelGroups.listChannels(groupName);
  print('Group: ' + channelGroupList.name);
  print('Channels: ' + channelGroupList.channels.toList().toString());
}

Future printAllGroupsForUser(String userId) async {
  List<String> g = await RimeFunctions.getChannelGroups(userId);
  print('Groups: ' + g.toString());
}
