import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/rime.dart';
import 'package:rime/state/RimeFunctions.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:tuple/tuple.dart';

class RimeApi {
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

    // Creates memberships for a channel
    for (String userID in users) {
      members.add(ChannelMemberMetadataInput(userID, custom: {
        //TODO: Notifications Enabled?
        // 'Notification': true,
        'readAction': true,
        'Accepted': Rime.functions.chatAccepted(RimeRepository().userID, users),
        'Deleted': 0
      }));
    }
    await client.objects.setChannelMembers(channelID, members);

    String userGroupID;

    //Assigns channel into available groups
    for (String userID in users) {
      String groupID = await RimeFunctions.getAvailableChannelGroup(userID);
      if (userID == RimeRepository().userID) {
        userGroupID = groupID;
      }
      await client.channelGroups.addChannels(groupID, Set.from([channelID]));
    }

    return userGroupID;
  }

  static RimeChannel getChannel(String channel) {
    Channel currentChannel = RimeRepository().client.channel(channel);
    BaseMessage message = currentChannel.history(chunkSize: 1).messages?.first ?? null;
    RimeChannel rimeChannel = RimeChannel(
      channel: channel,
      title: currentChannel.name,
      subtitle: message.content,
      lastUpdated: message.publishedAt.toDateTime(),
    );
    return rimeChannel;
  }

  static bool deleteChannel(String loginID, String channel) {
    PubNub client = RimeRepository().client;


  }

  static Future<bool> leaveChannel(String loginID, String channel) async {
    RimeRepository().client.objects.manageChannelMembers(channel, [], Set<String>.from([loginID]));
    List<String> channelGroups = await getChannelGroups(loginID);
    for (var group in channelGroups) {
      try{
        await RimeRepository().client.channelGroups.removeChannels(group, Set.from([channel]));
        return true;
      }catch(e){
        continue;
      }
    }
    return false;
  }

  static Future<List<String>> getChannelGroups(String loginID) async {
    String availableGroup =
        await RimeFunctions.getAvailableChannelGroup(loginID);

    int groupNo = int.parse(availableGroup.split('_').last);

    return List.generate(
        groupNo + 1, (index) => RimeFunctions.channelGroupID(loginID, index));
  }

  // API Functions
  static Future<void> sendMessage(String channelID, BaseMessage message) async {
    // Send the message
    PublishResult publish = await RimeRepository().client.publish(channelID, message);

    //Get the current channel metadata
    GetChannelMetadataResult cmRes = await RimeRepository()
        .client
        .objects
        .getChannelMetadata(channelID, includeCustomFields: true);

    //Update the lastUpdated metadata
    Map customMetaData = cmRes.metadata?.custom ?? Map();
    customMetaData['lastUpdated'] = DateTime.now().toString();

    //Re-Set the channel metadata
    ChannelMetadataInput channelMetadataInput = ChannelMetadataInput(
        name: cmRes.metadata.name,
        description: cmRes.metadata.description,
        custom: customMetaData);
    SetChannelMetadataResult smRes = await RimeRepository()
        .client
        .objects
        .setChannelMetadata(channelID, channelMetadataInput);
  }

  /// Gets one page of the most recent channels
  ///
  /// int limit: the number of channels on the page
  /// String start: the name of the page that you want to grab
  ///
  /// returns: Tuple2<List<String>, String>
  /// List<String>: list of channel ids
  /// String: name of the next page
  static Future<Tuple2<List<String>, String>> getMostRecentChannels({int limit = 50, String start}) async {
    MembershipsResult memRes = await RimeRepository()
        .client
        .objects
        .getMemberships(
            includeChannelCustomFields: true,
            includeChannelFields: true,
            includeCustomFields: true,
            sort: Set.from(['channel.updated:desc']),
            limit: limit,
            start: start);

    List<String> channelIDList = [];
    MembershipMetadata memMD;
    for (memMD in memRes.metadataList) {
      channelIDList.add(memMD.channel.id);
    }
    String nextPage = memRes.next;
    return Tuple2(channelIDList, nextPage);
  }
}
