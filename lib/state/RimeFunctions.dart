import 'dart:convert';

import 'package:rime/rime.dart';
import 'package:rime/state/RimeRepository.dart';

/// A group of helper functions
/// 
/// These functions get information and do not edit PubNub or the local state
class RimeFunctions {
  /// Turns a userId and channel group index into a valid channelGroupId (according to how Rime uses channel groups)
  /// 
  /// * [String] [userId]: The user whose channel group Ids that are being generated
  /// * [int] [groupNo]: The index of the channel group you'd like
  /// 
  /// Rime uses this function to ensure every user has consistent channel group naming.
  /// Considering the 20,000 channel limit that PubNub imposes per keyset, Rime only uses 0-9
  /// 
  /// * returns [String]: A string formatted to be a Rime channel group Id
  static String channelGroupId(String userId, int groupNo) {
    return 'rime_cg_${userId}_$groupNo';
  }
  
  /// Retreives the next channel group with room for a new channel for the given user.
  ///
  /// Channel groups can only have 2000 channels. This will get the first channel group for this user that is not full
  ///
  /// * [String] [userId]: The Id of the user whose channel groups you are looking for
  ///
  /// * returns Future<String>: The Id of the first channel group with room for another channel
  static Future<String> getAvailableChannelGroup(String userId) async {
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
      channelGroup = RimeFunctions.channelGroupId(userId, groupNo);

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

  /// Gets the number of channels in a channel group
  ///
  /// * [String] [groupId]: The Id of the channel group you are looking for
  ///
  /// * returns [Future]<[int]>: The number of channels in the given channel group
  static Future<int> getChannelGroupCount(String groupId) async {
    ChannelGroupListChannelsResult channels = await RimeRepository().client.channelGroups.listChannels(groupId);

    return channels.channels.length;
  }

  /// Retreives all the non-empty channel groups for the given user
  ///
  /// [String] [userId]: the userId for the user whose channel groups you are looking for
  ///
  /// returns [Future]<[List]<[String]>>: A list of the channel group Ids for all the user's non-empty channel groups
  static Future<List<String>> getChannelGroups(String userId) async {
    List possibleChannelGroupIds = List.generate(10, (index) => RimeFunctions.channelGroupId(userId, index));
    List<String> nonEmptyChannelGroups = [];

    for (String groupId in possibleChannelGroupIds) {
      int channelCount = await getChannelGroupCount(groupId);
      if (channelCount > 0) {
        nonEmptyChannelGroups.add(groupId);
      }
    }

    return nonEmptyChannelGroups;
  }

  /// Gets the membership metadata for all users in a channel
  ///
  /// * [String] [channelId]: The channelId of the channel you want to get the memberships for
  ///
  /// * returns [Future]<[List]<[ChannelMemberMetadata]>>: a list of the membership metadata for all users in that channel
  static Future<List<ChannelMemberMetadata>> getChannelMembers(String channelId) async {
    //Retreive memberships
    ChannelMembersResult result = await RimeRepository()
        .client
        .objects
        .getChannelMembers(channelId, includeUUIDFields: true, includeCustomFields: true);

    return result.metadataList;
  }

  /// Finds the channel group that the given channel is part of
  ///
  /// * [String] [userId]: The user whose channel group you are looking for
  /// * [String] [channelId]: The channelId of the channel whose channel group you are looking for
  ///
  /// * returns [Future]<[String]>: The Id of the channel group that contains the given channel
  ///   or [null] if user does not have that channel in any of their channel groups
  static Future<String> getGroupIdFromChannelId(String userId, String channelId) async {
    // Gets all non-empty channel groups
    List<String> channelGroups = await getChannelGroups(userId);
    // Loop through every channel group and see if it contains the channel
    for (String groupId in channelGroups) {
      ChannelGroupListChannelsResult channelGroupList =
          await RimeRepository().client.channelGroups.listChannels(groupId);
      if (channelGroupList.channels.contains(channelId)) {
        return groupId;
      }
    }
    return null;
  }

  /// Populates the channel and membership data
  ///
  /// Takes a [MemberShipMetatdata] so it can be used with both [getMostRecentChannels()] and [getChannel()]
  ///
  /// * [MembershipMetadata] [data]: the metadata for the channel you'd like to hydrate
  ///
  /// * returns [Future]<[RimeChannel]>: a populated [RimeChannel] object
  static Future<RimeChannel> hydrate(MembershipMetadata data) async {
    //Retreives the latest message
    BaseMessage baseMessage;
    PaginatedChannelHistory history = RimeRepository().client.channel(data.channel.id).history(chunkSize: 1);
    await history.more();
    baseMessage = history.messages.isEmpty ? null : history.messages.first;

    //Retreives channel meta data
    ChannelMetadataDetails cmRes = data.channel;
    List<String> uuids = (await getChannelMembers(cmRes.id)).map<String>((mem) => mem.uuid.id).toList();

    //Retreives channel membership meta data
    Map<String, int> readMap = Map<String, int>.from(jsonDecode(cmRes.custom['read']));
    RimeChannelMembership membership = RimeChannelMembership.fromJson(data.custom);

    RimeChannel channel = RimeChannel(
        channel: data.channel.id,
        lastUpdated: cmRes.custom['lastUpdated'],
        title: data.channel.name,
        readMap: readMap,
        membership: membership,
        uuids: uuids);
    if (baseMessage != null) {
      channel =
          channel.copyWith(RimeChannel(subtitle: baseMessage.content, lastUpdated: baseMessage.publishedAt.value));
    }
    return channel;
  }

}
