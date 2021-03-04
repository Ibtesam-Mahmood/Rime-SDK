import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/state/RimeRepository.dart';

class RimeApi {
  static Future<List<RimeChannel>> getChannels(String loginID,
      {int timeToken}) {}

  static Future<void> createChannel(List<String> users) async {
    PubNub client = RimeRepository().client;

    String channelID = 'rime-' + (await client.time()).toString();
    List<ChannelMemberMetadataInput> members = [];

    for (String userID in users) {
      members.add(ChannelMemberMetadataInput(userID));
    }

    await client.objects.setChannelMembers(channelID, members);

    for (String userID in users) {
      // TODO: Keep track of what int to use at the end
      String groupID = 'cg_' + userID + '_1';

      await client.channelGroups.addChannels(groupID, Set.from([channelID]));
    }
  }

  static RimeChannel getChannel(String channel) {}

  static void sendMessage(
      String loginID, BaseMessage message, String channel) {}

  static bool deleteChannel(String loginID, String channel) {}

  static bool leaveChannel(String loginID, String channel) {}

  static Future<List<String>> getChannelGroups(String loginID) async {
    Set<String> channelGroups = RimeRepository()
        .client
        .getSubscribedChannelGroupsForUUID(UUID(loginID));

    return channelGroups.toList();
  }
}
