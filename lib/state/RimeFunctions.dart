import 'package:pubnub/pubnub.dart';

import 'RimeRepository.dart';

/// Group of functions to interact with pubnub
class RimeFunctions {
  /// Helper function to turn a userID and int into a channel group name
  static String channelGroupID(String userID, int groupNo) {
    return 'rime_cg_${userID}_$groupNo';
  }

  /// Retreives the next available channel group for a user.
  static Future<String> getAvailableChannelGroup(String userID) async {
    // Channel group to be constructed
    String channelGroup;
    int groupNo = 0;

    // Rettreives rime pubnub client
    PubNub client = RimeRepository().client;

    while (channelGroup == null) {
      // Max Channel Group Limit is 10
      // https://www.pubnub.com/docs/channels/subscribe#channel-groups
      if (groupNo > 9) {
        throw Exception('Max Channels Reached, sux to be you');
      }

      // Get the channel group with the given nam
      channelGroup = channelGroupID(userID, groupNo);

      // Check if the channel group is full
      // If there are less than 2000 channels then it can fit more channels
      // If the group has 0 channels then this will still work as a new channel group will be dynamically created
      ChannelGroupListChannelsResult channels =
          await client.channelGroups.listChannels(channelGroup);
      if (channels.channels.length < 2000) {
        break;
      }

      // Moves to the next groupNumber
      groupNo++;
      channelGroup = null;
    }

    //Returns the constructed channel group
    return channelGroup;
  }
}
