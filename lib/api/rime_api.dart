import 'dart:convert';

import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/model/rimeMessage.dart';
import 'package:rime/rime.dart';
import 'package:rime/state/RimeFunctions.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:tuple/tuple.dart';

/// The RimeApi class holds a set of functions that directly interface with the internal PubNub client
///
/// Sending requests through this Api will successfully modify your PubNub instance with Rime attributes.
/// However, these requests will **not** modify the RimeState.
///
/// The functions defined in this class are 1-to-1 with [RimeEvent]s which **do** modify the state.
class RimeApi {
  /// Creates a channel containing [users]
  ///
  /// This function creates a channel and will automatically create memberships for all [users]
  /// then add the newly created channel to each users' subscribed channel groups
  ///
  /// * [List]<[String]> [users]: the userIDs for the users joining the newly created channel
  ///
  /// * returns [RimeChannel]: The RimeChannel state object for the PubNub channel that was just created
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

    //The readMap being created for channel metadata
    Map<String, int> readMap = {};

    // Group ID for the loggedIn user
    String userGroupID;

    // Memmebership for the user
    RimeChannelMemebership userMembership;

    // Creates memeberships for a channel
    for (String userID in users) {
      readMap[userID] = 0;

      //Create a channel memebership
      RimeChannelMemebership membership = RimeChannelMemebership(
          notifications: true,
          readAction: true,
          accepted: Rime.functions.chatAccepted(RimeRepository().userID, users),
          deleted: 0);

      //Create memebership data
      members.add(ChannelMemberMetadataInput(userID, custom: membership.toJson()));

      //Add the channel to the user's specific channel group
      String groupID = await RimeFunctions.getAvailableChannelGroup(userID);
      // ignore: unused_local_variable
      ChannelGroupChangeChannelsResult addGroup =
          await client.channelGroups.addChannels(groupID, Set.from([channelID]));

      // retreive data for login user
      if (userID == RimeRepository().userID) {
        userGroupID = groupID;
        userMembership = membership;
      }
    }

    // Set the memeberships
    await client.objects.setChannelMembers(channelID, members);

    //Create channel metadata
    // ignore: unused_local_variable
    SetChannelMetadataResult setMemRes = await client.objects.setChannelMetadata(
        channelID, ChannelMetadataInput(custom: {'read': jsonEncode(readMap), 'lastUpdated': time.value}),
        includeCustomFields: true);

    //No channel made for the loggedIn user
    if (userGroupID == null || userMembership == null) {
      return null;
    }

    //Verifies request
    return await getChannel(channelID);
  }

  /// Gets a RimeChannel object for the specified channel
  ///
  /// * [String] [channelID]: The id for the channel you are looking for
  ///
  /// * returns [Future]<[RimeChannel]>: A populated RimeChannel object corresponding to the given channel
  static Future<RimeChannel> getChannel(String channelID) async {
    String filterCondition = 'channel.id == \"$channelID\"';
    MembershipsResult currentMembership = await RimeRepository().client.objects.getMemberships(
        uuid: RimeRepository().userID,
        limit: 1,
        includeChannelCustomFields: true,
        includeChannelFields: true,
        includeCustomFields: true,
        filter: filterCondition);

    if (currentMembership.metadataList.isEmpty) return Future.error('Channel not found');

    RimeChannel rimeChannel = await _hydrate(currentMembership.metadataList.first);

    return rimeChannel;
  }

  /// Soft Deletes a Channel for the current user
  ///
  /// Sets the custom membership metadata 'Deleted' to the current PubNub time.
  /// This **does not** leave or unsubscribe from the channel
  ///
  /// * [String] [channelID]: the id of the channel you want to soft-delete
  ///
  /// * returns [bool]: A bool specifying if the 'Deleted' metadata was successfully updated
  static Future<bool> deleteChannel(String channelID) async {
    //Get the membership metadata for the specified channel
    String filter = 'channel.id == \"$channelID\"';
    MembershipsResult currentMembership = await RimeRepository().client.objects.getMemberships(
        limit: 1,
        includeCustomFields: true,
        includeChannelFields: true,
        includeChannelCustomFields: true,
        includeCount: true,
        filter: filter);

    if (currentMembership.totalCount == 0) {
      throw Exception('The user is not part of $channelID');
    }

    //Edit the deleted custom metadata
    Map<String, dynamic> currentCustom = {...(currentMembership.metadataList?.first?.custom ?? Map())};
    currentCustom['Deleted'] = (await RimeRepository().client.time()).value;
    MembershipMetadataInput membershipInput = MembershipMetadataInput(channelID, custom: currentCustom);

    //Re-Set the membership metadata for the specified channel
    List<MembershipMetadataInput> setMetadata = [membershipInput];
    MembershipsResult memRes = await RimeRepository().client.objects.setMemberships(setMetadata,
        limit: 1,
        includeCustomFields: true,
        includeChannelFields: true,
        includeChannelCustomFields: true,
        includeCount: true,
        filter: filter);

    return currentMembership.metadataList.first.custom['Deleted'] != memRes.metadataList.first.custom['Deleted'];
  }

  /// Leaves and Unsubscribes from the specified channel
  ///
  /// This function will remove the channel from the user's subscribed channel group and
  /// will delete the user's channel membership for the channel
  ///
  /// * [String] [userID]: The userID for the user that is leaving the channel
  /// * [String] [channelID]: The channelID for the channel that the user is leaving
  static Future<void> leaveChannel(String userID, String channelID) async {
    // Remove this channel from the user's channel groups
    String groupID = await RimeApi.getGroupIDFromChannelID(userID, channelID);
    await RimeRepository().client.channelGroups.removeChannels(groupID, Set.from([channelID]));

    // Delete the user's membership for this channel
    await RimeRepository().client.objects.removeChannelMembers(channelID, Set<String>.from([userID]));
  }

  /// Sends a message to the specified channel
  ///
  /// Along with sending a message, this also updates the channel 'lastUpdated' metadata
  /// This will enable getMemberships to sort on the channel with the most recent message
  ///
  /// * [String] [channelID]: the channelID for the channel being published to
  /// * [Map]<[String], [dynamic]> [message]: the message that you want to send, it can include custom fields
  ///
  /// When using the [RimeEvent]s some of the custom fields are needed and will defined for you
  ///
  /// * returns: [Tuple2]<[ChannelMetadataDetails], [RimeMessage]>
  ///   * [ChannelMetadataDetails] : The ChannelMetadata of the channel that was sent to
  ///   * [RimeMessage] : The RimeMessage object corresponding to the message that was just sent
  ///
  /// The RimeMessage can be used to update the local state immediately after sending the message
  static Future<Tuple2<ChannelMetadataDetails, RimeMessage>> sendMessage(
      String channelID, Map<String, dynamic> message) async {
    //Get the current channel metadata
    GetChannelMetadataResult cmRes =
        await RimeRepository().client.objects.getChannelMetadata(channelID, includeCustomFields: true);

    // Send the message
    PublishResult publish = await RimeRepository().client.publish(channelID, message, storeMessage: true);

    //Update the lastUpdated metadata
    Map customMetaData = cmRes.metadata?.custom ?? Map();
    customMetaData['lastUpdated'] = publish.timetoken;

    //Re-Set the channel metadata
    ChannelMetadataInput channelMetadataInput = ChannelMetadataInput(
        name: cmRes.metadata.name, description: cmRes.metadata.description, custom: customMetaData);

    SetChannelMetadataResult smRes = await RimeRepository()
        .client
        .objects
        .setChannelMetadata(channelID, channelMetadataInput, includeCustomFields: true);

    //Create time message from sent message
    RimeMessage messageResult = RimeMessage.fromBaseMessage(
        BaseMessage(content: message, originalMessage: message, publishedAt: Timetoken(publish.timetoken)));

    return Tuple2<ChannelMetadataDetails, RimeMessage>(smRes.metadata, messageResult);
  }

  /// Gets one page of channels sorted by last updated
  ///
  /// * [int] [limit]: the number of channels on the page
  /// * [String] [start]: the name of the page that you want to grab
  ///
  /// * returns: [Tuple2]<[List]<[String]>, [String]>
  ///   * [List]<[String]>: list of channel ids
  ///   * [String]: name of the next page
  static Future<Tuple2<List<RimeChannel>, String>> getMostRecentChannels({int limit = 50, String start}) async {
    MembershipsResult memRes = await RimeRepository().client.objects.getMemberships(
        includeChannelCustomFields: true,
        includeChannelFields: true,
        includeCustomFields: true,
        sort: Set.from(['channel.updated:desc']),
        limit: limit,
        start: start);

    List<RimeChannel> rimeChannels = [];
    for (MembershipMetadata memMD in memRes.metadataList) {
      rimeChannels.add(await _hydrate(memMD));
    }
    String nextPage = memRes.next;
    return Tuple2(rimeChannels, nextPage);
  }

  /// Populates the channel and membership data
  ///
  /// Takes a [MemberShipMetatdata] so it can be used with both [getMostRecentChannels()] and [getChannel()]
  ///
  /// * [MembershipMetadata] [data]: the metadata for the channel you'd like to hydrate
  ///
  /// * returns [Future]<[RimeChannel]>: a populated [RimeChannel] object
  static Future<RimeChannel> _hydrate(MembershipMetadata data) async {
    //Retreives the latest message
    BaseMessage baseMessage;
    PaginatedChannelHistory history = RimeRepository().client.channel(data.channel.id).history(chunkSize: 1);
    await history.more();
    baseMessage = history.messages.isEmpty ? null : history.messages.first;

    //Retreives channel meta data
    ChannelMetadataDetails cmRes = data.channel;
    List<String> uuids = (await getChannelMemebers(cmRes.id)).map<String>((mem) => mem.uuid.id).toList();

    //Retreives channel memebership meta data
    Map<String, int> readMap = Map<String, int>.from(jsonDecode(cmRes.custom['read']));
    RimeChannelMemebership memebership = RimeChannelMemebership.fromJson(data.custom);

    RimeChannel channel = RimeChannel(
        channel: data.channel.id,
        lastUpdated: cmRes.custom['lastUpdated'],
        title: data.channel.name,
        readMap: readMap,
        membership: memebership,
        uuids: uuids);
    if (baseMessage != null) {
      channel =
          channel.copyWith(RimeChannel(subtitle: baseMessage.content, lastUpdated: baseMessage.publishedAt.value));
    }
    return channel;
  }

  /// Gets the membership metadata for all users in a channel
  ///
  /// * [String] [channelID]: The channelID of the channel you want to get the memberships for
  ///
  /// * returns [Future]<[List]<[ChannelMemberMetadata]>>: a list of the membership metadata for all users in that channel
  static Future<List<ChannelMemberMetadata>> getChannelMemebers(String channelID) async {
    //Retreive memeberships
    ChannelMembersResult result = await RimeRepository()
        .client
        .objects
        .getChannelMembers(channelID, includeUUIDFields: true, includeCustomFields: true);

    return result.metadataList;
  }

  /// Finds the channel group that the given channel is part of
  ///
  /// * [String] [userID]: The user whose channel group you are looking for
  /// * [String] [channelID]: The channelID of the channel whose channel group you are looking for
  ///
  /// * returns [Future]<[String]>: The Id of the channel group that contains the given channel
  ///   or [null] if user does not have that channel in any of their channel groups
  static Future<String> getGroupIDFromChannelID(String userID, String channelID) async {
    // Gets all non-empty channel groups
    List<String> channelGroups = await RimeFunctions.getChannelGroups(userID);
    // Loop through every channel group and see if it contains the channel
    for (String groupId in channelGroups) {
      ChannelGroupListChannelsResult channelGroupList =
          await RimeRepository().client.channelGroups.listChannels(groupId);
      if (channelGroupList.channels.contains(channelID)) {
        return groupId;
      }
    }
    return null;
  }
}
