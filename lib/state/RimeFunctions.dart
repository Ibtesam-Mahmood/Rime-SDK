import 'package:pubnub/pubnub.dart';

import 'RimeRepository.dart';

import 'package:intl/intl.dart';

/// Group of functions to interact with pubnub
class RimeFunctions {
  /// Retreives all the non-empty channel groups for the given user
  ///
  /// loginID : the loginID for the user in question
  static Future<List<String>> getChannelGroups(String loginID) async {
    List possibleChannelGroupIDs = List.generate(10, (index) => RimeFunctions.channelGroupID(loginID, index));
    List<String> nonEmptyChannelGroups = [];

    for (String groupID in possibleChannelGroupIDs) {
      int channelCount = await getChannelGroupCount(groupID);
      if (channelCount > 0) {
        nonEmptyChannelGroups.add(groupID);
      }
    }

    return nonEmptyChannelGroups;
  }

  /// Helper function to turn a userID and int into a channel group name
  static String channelGroupID(String userID, int groupNo) {
    return 'rime_cg_${userID}_$groupNo';
  }

  /// Retreives the next channel group with room for a new channel for the given user.
  static Future<String> getAvailableChannelGroup(String userID) async {
    // Channel group to be constructed
    String channelGroup;
    int groupNo = 0;

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
      if (await getChannelGroupCount(channelGroup) < 2000) {
        break;
      }

      // Moves to the next groupNumber
      groupNo++;
      channelGroup = null;
    }

    //Returns the constructed channel group
    return channelGroup;
  }

  static Future<int> getChannelGroupCount(String groupID) async {
    ChannelGroupListChannelsResult channels = await RimeRepository().client.channelGroups.listChannels(groupID);

    return channels.channels.length;
  }

  //Formats the time since the post was posted
  //Formats(x) xm - xh - xd
  static String formatTime(DateTime time) {
    DateTime now = DateTime.now();
    int timeDifernce = now.difference(time).inMinutes;
    if (timeDifernce / 60 > 1) {
      timeDifernce = (timeDifernce / 60).floor();
      if (timeDifernce / 24 > 1) {
        timeDifernce = (timeDifernce / 24).floor();

        if (timeDifernce >= 7) {
          return DateFormat('MMM dd, yyyy').format(now);
        }

        return '${timeDifernce}d'; //Return time in days
      } else {
        return '${timeDifernce}h';
      } //Return time in hours
    } else {
      return '${timeDifernce == 0 ? 1 : timeDifernce}m';
    } //Return time in minutes
  }
}
