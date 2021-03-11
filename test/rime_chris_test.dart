import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ignore: library_prefixes
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:rime/model/channel.dart';

import 'package:rime/rime.dart';
import 'package:rime/state/RimeRepository.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('testUser_chris_1 Tests', () {
    // This line allows the tests to send/receive HttpRequests
    // This is so we can interact with the real PubNub API in our tests
    HttpOverrides.global = null;
    String userID = 'testUser_chris_1';
    setUp(() async {
      print('\n' 'Initializing');
      await DotEnv.load(fileName: '.env');
      await Rime.initialize(DotEnv.env);
      await RimeRepository().initializeRime(userID);
      print('Initialized');
    });

    test('Join and then leave a channel', () async {
      //Create and join a channel
      RimeChannel channel = await RimeApi.createChannel([userID]);

      String channelName = channel.channel;
      String groupId = await RimeApi.getGroupIDFromChannelID(userID, channelName);

      //Confirm that the channel is part of the channel group
      ChannelGroupListChannelsResult channelGroupList =
          await RimeRepository().client.channelGroups.listChannels(groupId);
      bool channelIsPartOfGroup = channelGroupList.channels.contains(channelName);
      expect(channelIsPartOfGroup, true, reason: 'Channel is not part of group');

      //Confirm that the user has a membership for it
      String filterCondition = 'channel.id == \"$channelName\"';
      MembershipsResult channelMembership = await RimeRepository().client.objects.getMemberships(
          uuid: RimeRepository().userID,
          limit: 1,
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          filter: filterCondition);
      bool userHasChannelMembership = channelMembership.metadataList.isNotEmpty;
      expect(userHasChannelMembership, true, reason: 'User does not have a membership for this channel');

      // Leave the channel
      await RimeApi.leaveChannel(userID, channelName);

      // Ensure that it
      //  1. Removes the channel from the channel group
      ChannelGroupListChannelsResult channelGroupList_Updated =
          await RimeRepository().client.channelGroups.listChannels(groupId);
      bool channelIsPartOfGroup_Updated = channelGroupList_Updated.channels.contains(channelName);
      expect(channelIsPartOfGroup_Updated, false, reason: 'Channel is still part of the channel group');
      //  2. Destroys the membership for that channel for that user
      MembershipsResult channelMembership_Updated = await RimeRepository().client.objects.getMemberships(
          uuid: RimeRepository().userID,
          limit: 1,
          includeChannelCustomFields: true,
          includeChannelFields: true,
          includeCustomFields: true,
          filter: filterCondition);
      bool userHasChannelMembership_Updated = channelMembership_Updated.metadataList.isNotEmpty;
      expect(userHasChannelMembership_Updated, false, reason: 'User still has membership for this channel');
    });
  });
}
