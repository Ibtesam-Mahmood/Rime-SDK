import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/rime.dart';
import 'package:rime/state/RimeFunctions.dart';
import 'package:rime/state/RimeRepository.dart';

class RimeApi {
  static Future<List<RimeChannel>> getChannels(int timeToken, [int size = 50]) {
    
  }

  static Future<RimeChannel> createChannel(List<String> users) async {
    
    //Checks if the user iD's are unique
    if (users.length != users.toSet().length) {
      return Future.error("Duplicate user's within channel creation");
    }
    
    //Access Pubnub Client
    PubNub client = RimeRepository().client;

    //Creates a unique channel ID
    Timetoken time = await client.time();
    String channelID = 'rime_${RimeRepository().userID}_${time.toString()}';
    List<ChannelMemberMetadataInput> members = [];

    // Group ID for the loggedIn user
    String userGroupID;

    // Memmebership for the user
    RimeChannelMemebership userMembership;

    // Creates memeberships for a channel
    for (String userID in users) {

      //Retreive next active group id for a user
      String groupID = await RimeFunctions.getAvailableChannelGroup(userID);

      //Create a channel memebership
      RimeChannelMemebership membership = RimeChannelMemebership(
        notifications: true,
        readAction: true,
        accepted: Rime.functions.chatAccepted(RimeRepository().userID, users),
        deleted: 0
      );

      //Create memebership data
      members.add(
        ChannelMemberMetadataInput(
          userID,
          custom: membership.toJson()
        )
      );

      //Add the channel to the user specific group
      await client.channelGroups.addChannels(groupID, Set.from([channelID]));

      // retreive data for login user
      if(userID == RimeRepository().userID){
        userGroupID = groupID;
        userMembership = membership;
      }
    }
    await client.objects.setChannelMembers(channelID, members);

    //No channel made for the loggedIn user
    if(userGroupID == null || userMembership == null){
      return null;
    }

    //Retrun channel for logged in user
    RimeChannel createdChannel = RimeChannel(
      channel: channelID,
      lastUpdated: time.value,
      membership: userMembership,
      groupId: userGroupID
    );

    return createdChannel;
  }

  static RimeChannel getChannel(String channel) {
    
  }

  static void sendMessage(String loginID, BaseMessage message, String channel) {

  }

  static bool deleteChannel(String loginID, String channel) {

  }

  static bool leaveChannel(String loginID, String channel) {

  }

  static Future<List<String>> getChannelGroups(String loginID) async {
    String availableGroup =
        await RimeFunctions.getAvailableChannelGroup(loginID);

    int groupNo = int.parse(availableGroup.split('_').last);

    return List.generate(
        groupNo + 1, (index) => RimeFunctions.channelGroupID(loginID, index));
  }
}
