import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/rime.dart';
import 'package:rime/state/RimeFunctions.dart';
import 'package:rime/state/RimeRepository.dart';

class RimeApi {
  static Future<List<RimeChannel>> getChannels(String loginID,
      {int timeToken}) {}

  static Future<String> createChannel(List<String> users) async {
    //Checks if the user iD's are unique
    if (users.length != users.toSet().length) {
      return Future.error("Duplicate user's within channel creation");
    }
    
    PubNub client = RimeRepository().client;

    //Creates a unique channel ID
    Timetoken time = await client.time();
    String channelID = 'rime_${RimeRepository().userID}_${time.toString()}';
    List<ChannelMemberMetadataInput> members = [];

    // Creates memeberships for a channel
    for (String userID in users) {
      members.add(ChannelMemberMetadataInput(
        userID,
        custom: {
          //TODO: Notifications Enabled?
          // 'Notification': true,
          'readAction': true,
          'Accepted': Rime.functions.chatAccepted(RimeRepository().userID, users),
          'Deleted': 0
        }
      )
      );
    }
    await client.objects.setChannelMembers(channelID, members);

    String userGroupID;

    //Assigns channel into available groups
    for (String userID in users) {
      String groupID = await RimeFunctions.getAvailableChannelGroup(userID);
      if(userID == RimeRepository().userID){
        userGroupID = groupID;
      }
      await client.channelGroups.addChannels(groupID, Set.from([channelID]));
    }

    return userGroupID;
  }

  static RimeChannel getChannel(String channel) {
    
  }

  static void sendMessage(String loginID, BaseMessage message, String channel) {}

  static bool deleteChannel(String loginID, String channel) {}

  static bool leaveChannel(String loginID, String channel) {}

  static Future<List<String>> getChannelGroups(String loginID) async {
    String availableGroup =
        await RimeFunctions.getAvailableChannelGroup(loginID);

    int groupNo = int.parse(availableGroup.split('_').last);

    return List.generate(
        groupNo + 1, (index) => RimeFunctions.channelGroupID(loginID, index));
  }
}
