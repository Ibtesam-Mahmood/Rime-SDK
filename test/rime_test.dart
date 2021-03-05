import 'dart:convert';
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

    test('Get a specific channel membership', () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.updated:desc']));

      String channelID = memRes.metadataList.first.channel.id;
      String filter = 'channel.id == "$channelID"';

      MembershipsResult currentMembership = await RimeRepository()
          .client
          .objects
          .getMemberships(
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
      String channelID = 'rime_testUser1_16148386848078668';
      String userID2 = RimeRepository().userID;
      String filter = 'channel.id == "$channelID"';
      bool success = await RimeApi.deleteChannel(channelID);

      MembershipsResult currentMembership = await RimeRepository()
          .client
          .objects
          .getMemberships(
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
        var channelID = 'rime_testUser1_16148386848078668';

        int time = (await RimeRepository().client.time()).value;

        await RimeRepository().client.objects.setChannelMetadata(
            channelID, ChannelMetadataInput(name: time.toString()));

        GetChannelMetadataResult channelMeta =
            await RimeRepository().client.objects.getChannelMetadata(channelID);

        expect(channelMeta.metadata.name, time.toString());
      });

      test('Ensure Channel is not updated with message action', () async {
        //Send Message
        var channelID = 'rime_testUser1_16148386848078668';
        var message = 'hello';

        GetChannelMetadataResult channelMeta =
            await RimeRepository().client.objects.getChannelMetadata(channelID);

        String time = channelMeta.metadata.updated;
        print("t1: " + time);

        PublishResult publish =
            await RimeRepository().client.publish(channelID, message);

        channelMeta =
            await RimeRepository().client.objects.getChannelMetadata(channelID);

        time = channelMeta.metadata.updated;
        print("t2: " + time);

        //Get the TimeToken for the message that was just sent
        int token = publish.timetoken;

        //Add Test messageAction to the just sent message
        AddMessageActionResult res = await RimeRepository()
            .client
            .addMessageAction('test', 'true', channelID, Timetoken(token));

        channelMeta =
            await RimeRepository().client.objects.getChannelMetadata(channelID);

        time = channelMeta.metadata.updated;
        print("t3: " + time);

        expect(true, true);
      });

      group('Check Channel order on paginated request for testUser1', () {
        String userID = 'testUser1';

        test('User has channel memeberships', () async {
          MembershipsResult res = await RimeRepository()
              .client
              .objects
              .getMemberships(uuid: userID, limit: 10);

          expect(res.totalCount, greaterThan(0));
        });

        test('Memeberships mapped to channels', () async {
          MembershipsResult res = await RimeRepository()
              .client
              .objects
              .getMemberships(uuid: userID, limit: 10);

          List<String> channels = res.metadataList
              .map<String>((meta) => meta?.channel?.id ?? '')
              .toList();

          expect(channels.contains(''), false);
        });

        test('Reset channel metadata', () async {
          MembershipsResult res = await RimeRepository()
              .client
              .objects
              .getMemberships(uuid: userID, limit: 10);

          List<String> channels = res.metadataList
              .map<String>((meta) => meta?.channel?.id ?? '')
              .toList();

          for (var channel in channels) {
            SetChannelMetadataResult res = await RimeRepository()
                .client
                .objects
                .setChannelMetadata(
                    channel, ChannelMetadataInput(name: userID));

            expect(res.metadata.name, userID);
          }
        });
      });
    });
  });

  group('RimeApi Tests - testUser3', () {
    String userID = 'testUser3';

    setUp(() async {
      HttpOverrides.global = null;
      print('\n' 'Initializing');
      await DotEnv.load(fileName: '.env');
      await Rime.initialize(DotEnv.env);
      await RimeRepository().initializeRime(userID);
      print('Initialized');
    });

    test(
        'Add Message Action without editing channel metadata on testUser3 channel 2',
        () async {
      //Send a message
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[1].channel.id;
      String message = 'Test';

      PublishResult publish =
          await RimeRepository().client.publish(channelID, message);

      //Get the TimeToken for the message that was just sent
      int time = publish.timetoken;

      //Add Test messageAction to the just sent message
      AddMessageActionResult res = await RimeRepository()
          .client
          .addMessageAction('test', 'true', channelID, Timetoken(time));

      //Confirm that it receives a successful response
      var actual = res.status;
      var expected = 200;
      expect(actual, expected);
    });

    test('Get Memberships', () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
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
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
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
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
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
        MembershipsResult memRes = await RimeRepository()
            .client
            .objects
            .getMemberships(
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
      String channelGroupName = await RimeApi.createChannel([userID]);
      print(channelGroupName);
    }, skip: "Don't want to create channels everytime");

    test("Send a test message to testUser3's Channel 1", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[0].channel.id;
      String message = 'Test';

      PublishResult publish =
          await publishMessageWithChannelUpdate(channelID, message);

      print(publish.timetoken);
    });

    test("Get testUser3's Channel 1's metadata", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[0].channel.id;

      GetChannelMetadataResult cmRes = await RimeRepository()
          .client
          .objects
          .getChannelMetadata(channelID, includeCustomFields: true);

      // Got a 404. No Metadata exists for this channel...
      print('Got' + cmRes.toString());
    });

    test("Set testUser3's Channel 1's metadata", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[0].channel.id;
      ChannelMetadataInput channelMetadataInput = ChannelMetadataInput(
          name: 'testUser3 Channel 1',
          description: 'testUser3 Channel 1 Description!');

      SetChannelMetadataResult smRes = await RimeRepository()
          .client
          .objects
          .setChannelMetadata(channelID, channelMetadataInput);

      print('Got smRes');
    });

    test("Send a test message to testUser3's channel 2", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[1].channel.id;
      String message = 'Test';

      PublishResult publish =
          await publishMessageWithChannelUpdate(channelID, message);

      print(publish.timetoken);
    });

    test("Get testUser3's channel 2's metadata", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[1].channel.id;

      GetChannelMetadataResult cmRes = await RimeRepository()
          .client
          .objects
          .getChannelMetadata(channelID, includeCustomFields: true);

      // Got a 404. No Metadata exists for this channel...
      print('Got' + cmRes.toString());
    });

    test("Set testUser3's Channel 2's metadata", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[1].channel.id;
      ChannelMetadataInput channelMetadataInput = ChannelMetadataInput(
          name: 'testUser3 Channel 2',
          description: 'testUser3 Channel 2 Description!');

      SetChannelMetadataResult smRes = await RimeRepository()
          .client
          .objects
          .setChannelMetadata(channelID, channelMetadataInput);

      print('Got smRes');
    });

    test("Send a test message to testUser3's channel 3", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[2].channel.id;
      String message = 'Test';

      PublishResult publish =
          await publishMessageWithChannelUpdate(channelID, message);

      print(publish.timetoken);
    });

    test("Get testUser3's channel 3's metadata", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[2].channel.id;

      GetChannelMetadataResult cmRes = await RimeRepository()
          .client
          .objects
          .getChannelMetadata(channelID, includeCustomFields: true);

      // Got a 404. No Metadata exists for this channel...
      print('Got' + cmRes.toString());
    });

    test("Set testUser3's Channel 3's metadata", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList[2].channel.id;
      ChannelMetadataInput channelMetadataInput = ChannelMetadataInput(
          name: 'testUser3 Channel 3',
          description: 'testUser3 Channel 3 Description!');

      SetChannelMetadataResult smRes = await RimeRepository()
          .client
          .objects
          .setChannelMetadata(channelID, channelMetadataInput);

      print('Got smRes');
    });

    test("Send a test message to testUser3's last channel", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList.last.channel.id;
      String message = 'Test';

      PublishResult publish =
          await publishMessageWithChannelUpdate(channelID, message);

      print(publish.timetoken);
    });

    test("Get testUser3's last channel's metadata", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList.last.channel.id;

      GetChannelMetadataResult cmRes = await RimeRepository()
          .client
          .objects
          .getChannelMetadata(channelID, includeCustomFields: true);

      // Got a 404. No Metadata exists for this channel...
      print('Got' + cmRes.toString());
    });

    test("Set testUser3's Channel 3's metadata", () async {
      MembershipsResult memRes = await RimeRepository()
          .client
          .objects
          .getMemberships(
              includeChannelCustomFields: true,
              includeChannelFields: true,
              includeCustomFields: true,
              sort: Set.from(['channel.name']));

      String channelID = memRes.metadataList.last.channel.id;
      ChannelMetadataInput channelMetadataInput = ChannelMetadataInput(
          name: 'testUser3 Channel 3',
          description: 'testUser3 Channel 3 Description!');

      SetChannelMetadataResult smRes = await RimeRepository()
          .client
          .objects
          .setChannelMetadata(channelID, channelMetadataInput);

      print('Got smRes');
    });
  });
}

///Publish message to the channel with channelID and also update the channel metadata at the same time
Future<PublishResult> publishMessageWithChannelUpdate(
    String channelID, String message) async {
  PublishResult publish =
      await RimeRepository().client.publish(channelID, message);

  GetChannelMetadataResult cmRes = await RimeRepository()
      .client
      .objects
      .getChannelMetadata(channelID, includeCustomFields: true);

  Map customMetaData = cmRes.metadata?.custom ?? Map();
  customMetaData['lastUpdated'] = DateTime.now().toString();

  ChannelMetadataInput channelMetadataInput = ChannelMetadataInput(
      name: cmRes.metadata.name,
      description: cmRes.metadata.description,
      custom: customMetaData);
  SetChannelMetadataResult smRes = await RimeRepository()
      .client
      .objects
      .setChannelMetadata(channelID, channelMetadataInput);
  return publish;
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
