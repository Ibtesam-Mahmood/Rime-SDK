import 'dart:convert';

import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/model/rimeMessage.dart';
import 'package:rime/rime.dart';
import 'package:rime/state/RimeFunctions.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:tuple/tuple.dart';

/// The RimeAPI class holds a set of functions that directly interface with the internal PubNub client
///
/// Sending requests through this API will successfully modify your PubNub instance with Rime attributes.
/// However, these requests will **not** modify the RimeState.
///
/// The functions defined in this class are 1-to-1 with [RimeEvent]s which **do** modify the state.
class RimeAPI {
    /// Creates a channel containing [users]
  ///
  /// This function creates a channel and will automatically create memberships for all [users]
  /// then add the newly created channel to each users' subscribed channel groups
  ///
  /// * [List]<[String]> [users]: the userIds for the users joining the newly created channel
  ///
  /// * returns [RimeChannel]: The RimeChannel state object for the PubNub channel that was just created
  static Future<RimeChannel> createChannel(List<String> users) async {
    //Checks if the user iD's are unique
    if (users.length != users.toSet().length) {
      return Future.error("Duplicate user's within channel creation");
    }

    //Access Pubnub Client
    PubNub client = RimeRepository().client;

    //Creates a unique channel Id
    Timetoken time = await client.time();
    String channelId = 'rime_${RimeRepository().userId}_${time.toString()}';
    List<ChannelMemberMetadataInput> members = [];

    //The readMap being created for channel metadata
    Map<String, int> readMap = {};

    // Group Id for the loggedIn user
    String userGroupId;

    // Memmebership for the user
    RimeChannelMembership userMembership;

    // Creates memberships for a channel
    for (String userId in users) {
      readMap[userId] = 0;

      //Create a channel membership
      RimeChannelMembership membership = RimeChannelMembership(
          notifications: true,
          readAction: true,
          accepted: Rime.functions.chatAccepted(RimeRepository().userId, users),
          deleted: 0);

      //Create membership data
      members.add(ChannelMemberMetadataInput(userId, custom: membership.toJson()));

      //Add the channel to the user's specific channel group
      String groupId = await RimeFunctions.getAvailableChannelGroup(userId);
      // ignore: unused_local_variable
      ChannelGroupChangeChannelsResult addGroup =
          await client.channelGroups.addChannels(groupId, Set.from([channelId]));

      // retreive data for login user
      if (userId == RimeRepository().userId) {
        userGroupId = groupId;
        userMembership = membership;
      }
    }

    // Set the memberships
    await client.objects.setChannelMembers(channelId, members);

    //Create channel metadata
    // ignore: unused_local_variable
    SetChannelMetadataResult setMemRes = await client.objects.setChannelMetadata(
        channelId, ChannelMetadataInput(custom: {'read': jsonEncode(readMap), 'lastUpdated': time.value}),
        includeCustomFields: true);

    //No channel made for the loggedIn user
    if (userGroupId == null || userMembership == null) {
      return null;
    }

    //Verifies request
    return await getChannel(channelId);
  }

  /// Soft Deletes a Channel for the current user
  ///
  /// Sets the custom membership metadata 'Deleted' to the current PubNub time.
  /// This **does not** leave or unsubscribe from the channel
  ///
  /// * [String] [channelId]: the id of the channel you want to soft-delete
  ///
  /// * returns [bool]: A bool specifying if the 'Deleted' metadata was successfully updated
  static Future<bool> deleteChannel(String channelId) async {
    //Get the membership metadata for the specified channel
    String filter = 'channel.id == \"$channelId\"';
    MembershipsResult currentMembership = await RimeRepository().client.objects.getMemberships(
        limit: 1,
        includeCustomFields: true,
        includeChannelFields: true,
        includeChannelCustomFields: true,
        includeCount: true,
        filter: filter);

    if (currentMembership.totalCount == 0) {
      throw Exception('The user is not part of $channelId');
    }

    //Edit the deleted custom metadata
    Map<String, dynamic> currentCustom = {...(currentMembership.metadataList?.first?.custom ?? Map())};
    currentCustom['Deleted'] = (await RimeRepository().client.time()).value;
    MembershipMetadataInput membershipInput = MembershipMetadataInput(channelId, custom: currentCustom);

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

  /// Gets a RimeChannel object for the specified channel
  ///
  /// * [String] [channelId]: The id for the channel you are looking for
  ///
  /// * returns [Future]<[RimeChannel]>: A populated RimeChannel object corresponding to the given channel
  static Future<RimeChannel> getChannel(String channelId) async {
    String filterCondition = 'channel.id == \"$channelId\"';
    MembershipsResult currentMembership = await RimeRepository().client.objects.getMemberships(
        uuid: RimeRepository().userId,
        limit: 1,
        includeChannelCustomFields: true,
        includeChannelFields: true,
        includeCustomFields: true,
        filter: filterCondition);

    if (currentMembership.metadataList.isEmpty) return Future.error('Channel not found');

    RimeChannel rimeChannel = await RimeFunctions.hydrate(currentMembership.metadataList.first);

    return rimeChannel;
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
      rimeChannels.add(await RimeFunctions.hydrate(memMD));
    }
    String nextPage = memRes.next;
    return Tuple2(rimeChannels, nextPage);
  }

  /// Leaves and Unsubscribes from the specified channel
  ///
  /// This function will remove the channel from the user's subscribed channel group and
  /// will delete the user's channel membership for the channel
  ///
  /// * [String] [userId]: The userId for the user that is leaving the channel
  /// * [String] [channelId]: The channelId for the channel that the user is leaving
  static Future<void> leaveChannel(String userId, String channelId) async {
    // Remove this channel from the user's channel groups
    String groupId = await RimeFunctions.getGroupIdFromChannelId(userId, channelId);
    await RimeRepository().client.channelGroups.removeChannels(groupId, Set.from([channelId]));

    // Delete the user's membership for this channel
    await RimeRepository().client.objects.removeChannelMembers(channelId, Set<String>.from([userId]));
  }

  /// Sends a message to the specified channel
  ///
  /// Along with sending a message, this also updates the channel 'lastUpdated' metadata
  /// This will enable getMemberships to sort on the channel with the most recent message
  ///
  /// * [String] [channelId]: the channelId for the channel being published to
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
      String channelId, Map<String, dynamic> message) async {
    //Get the current channel metadata
    GetChannelMetadataResult cmRes =
        await RimeRepository().client.objects.getChannelMetadata(channelId, includeCustomFields: true);

    // Send the message
    PublishResult publish = await RimeRepository().client.publish(channelId, message, storeMessage: true);

    //Update the lastUpdated metadata
    Map customMetaData = cmRes.metadata?.custom ?? Map();
    customMetaData['lastUpdated'] = publish.timetoken;

    //Re-Set the channel metadata
    ChannelMetadataInput channelMetadataInput = ChannelMetadataInput(
        name: cmRes.metadata.name, description: cmRes.metadata.description, custom: customMetaData);

    SetChannelMetadataResult smRes = await RimeRepository()
        .client
        .objects
        .setChannelMetadata(channelId, channelMetadataInput, includeCustomFields: true);

    //Create time message from sent message
    RimeMessage messageResult = RimeMessage.fromBaseMessage(
        BaseMessage(content: message, originalMessage: message, publishedAt: Timetoken(publish.timetoken)));

    return Tuple2<ChannelMetadataDetails, RimeMessage>(smRes.metadata, messageResult);
  }
}
