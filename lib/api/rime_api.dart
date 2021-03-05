import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/rime.dart';
import 'package:rime/state/RimeFunctions.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:tuple/tuple.dart';

class RimeApi {

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
    Channel currentChannel = RimeRepository().client.channel(channel);
    BaseMessage message = currentChannel.history(chunkSize: 1).messages?.first ?? null;
    RimeChannel rimeChannel = RimeChannel(
      channel: channel,
      title: currentChannel.name,
      subtitle: message.content,
      lastUpdated: message.publishedAt.value,
    );
    return rimeChannel;
  }

  static bool deleteChannel(String loginID, String channel) {
    PubNub client = RimeRepository().client;


  }

  static Future<bool> leaveChannel(String loginID, String channel) async {
    RimeRepository().client.objects.manageChannelMembers(channel, [], Set<String>.from([loginID]));
    List<String> channelGroups = RimeFunctions.getChannelGroups(loginID);
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
