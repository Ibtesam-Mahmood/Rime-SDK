import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/model/rimeMessage.dart';
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

    //The readMap being created for channel metadata
    Map<String, int> readMap = {};

    // Group ID for the loggedIn user
    String userGroupID;

    // Memmebership for the user
    RimeChannelMemebership userMembership;

    // Creates memeberships for a channel
    for (String userID in users) {

      readMap[userID] = 0;

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
      ChannelGroupChangeChannelsResult addGroup = await client.channelGroups.addChannels(groupID, Set.from([channelID]));

      // retreive data for login user
      if(userID == RimeRepository().userID){
        userGroupID = groupID;
        userMembership = membership;
      }
    }

    // Set the memeberships
    await client.objects.setChannelMembers(channelID, members);

    //Create channel metadata
    SetChannelMetadataResult setMemRes = await client.objects.setChannelMetadata(channelID, ChannelMetadataInput(
      custom: {
        'read': jsonEncode(readMap),
        'lastUpdated': time.value
      }
    ), includeCustomFields: true);

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

  static Future<RimeChannel> getChannel(String channel) async {

      MembershipsResult currentMembership = await RimeRepository()
        .client
        .objects.getMemberships(uuid: RimeRepository().userID, limit: 1, includeChannelCustomFields: true, includeChannelFields: true, includeCustomFields: true, filter: 'channel.id == \"$channel\"');

    if(currentMembership.metadataList.isEmpty) return Future.error('Channel not found');
  
    RimeChannel rimeChannel = await hydrate(currentMembership.metadataList.first);

    return rimeChannel;
  }

  /// Soft Deletes a Channel for the current users
  ///
  /// Sets the custom membership metadata 'Deleted' to the current time
  ///
  ///String channelID: the id of the channel you want to soft-delete
  static Future<bool> deleteChannel(String channelID) async {
    //Get the membership metadata for the specified channel
    String filter = 'channel.id == \"$channelID\"';
    MembershipsResult currentMembership = await RimeRepository()
        .client
        .objects
        .getMemberships(
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
    Map<String, dynamic> currentCustom = {
      ...(currentMembership.metadataList?.first?.custom ?? Map())
    };
    currentCustom['Deleted'] = (await RimeRepository().client.time()).value;
    MembershipMetadataInput membershipInput =
        MembershipMetadataInput(channelID, custom: currentCustom);

    //Re-Set the membership metadata for the specified channel
    List<MembershipMetadataInput> setMetadata = [membershipInput];
    MembershipsResult memRes = await RimeRepository()
        .client
        .objects
        .setMemberships(setMetadata,
            limit: 1,
            includeCustomFields: true,
            includeChannelFields: true,
            includeChannelCustomFields: true,
            includeCount: true,
            filter: filter);

    return currentMembership.metadataList.first.custom['Deleted'] !=
        memRes.metadataList.first.custom['Deleted'];
  }

  static Future<bool> leaveChannel(String loginID, String channel) async {
    RimeRepository()
        .client
        .objects
        .manageChannelMembers(channel, [], Set<String>.from([loginID]));
    List<String> channelGroups = await RimeFunctions.getChannelGroups(loginID);
    for (var group in channelGroups) {
      try {
        await RimeRepository()
            .client
            .channelGroups
            .removeChannels(group, Set.from([channel]));
        return true;
      } catch (e) {
        continue;
      }
    }
    return false;
  }

  // API Functions
  ///Sends [message] to the channel with id = [channelID]
  ///
  ///Along with sending a message, this also updates the channel 'lastUpdated' metadata
  ///This will enable getMemberships to sort on the channel with the most recent message
  ///
  ///String channelID: the id of the channel that you want to send to
  ///BaseMessage message: the message that you want to send
  static Future<Tuple2<ChannelMetadataDetails, RimeMessage>> sendMessage(String channelID, Map<String, dynamic> message) async {
    
    //Get the current channel metadata
    GetChannelMetadataResult cmRes = await RimeRepository()
        .client
        .objects
        .getChannelMetadata(channelID, includeCustomFields: true);
    
    // Send the message
    PublishResult publish =
        await RimeRepository().client.publish(channelID, message, storeMessage: true);


    //Update the lastUpdated metadata
    Map customMetaData = cmRes.metadata?.custom ?? Map();
    customMetaData['lastUpdated'] = publish.timetoken;

    //Re-Set the channel metadata
    ChannelMetadataInput channelMetadataInput = ChannelMetadataInput(
        name: cmRes.metadata.name,
        description: cmRes.metadata.description,
        custom: customMetaData);

    SetChannelMetadataResult smRes = await RimeRepository()
        .client
        .objects
        .setChannelMetadata(channelID, channelMetadataInput, includeCustomFields: true);


    //Create time message from sent message
    RimeMessage messageResult = RimeMessage.fromBaseMessage(BaseMessage(
      content: message,
      originalMessage: message,
      publishedAt: Timetoken(publish.timetoken)
    ));

    return Tuple2<ChannelMetadataDetails, RimeMessage>(smRes.metadata, messageResult);
  }

  /// Gets one page of the most recent channels
  ///
  /// int limit: the number of channels on the page
  /// String start: the name of the page that you want to grab
  ///
  /// returns: Tuple2<List<String>, String>
  /// List<String>: list of channel ids
  /// String: name of the next page
  static Future<Tuple2<List<RimeChannel>, String>> getMostRecentChannels(
      {int limit = 50, String start}) async {
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

    // print(memRes.metadataList.length);

    List<RimeChannel> rimeChannels = [];
    for (MembershipMetadata memMD in memRes.metadataList) {
      rimeChannels.add(await hydrate(memMD));
    }
    String nextPage = memRes.next;
    return Tuple2(rimeChannels, nextPage);
  }

  /// Populates the channel and membership data
  /// 
  /// Takes a MemberShipMetatdata so it can be used for both [getMostRecentChannels()] and [getChannel()]
  /// 
  /// Returns a populated Future<RimeChannel> object
  static Future<RimeChannel> hydrate(MembershipMetadata data) async {
    BaseMessage baseMessage;
    PaginatedChannelHistory history = RimeRepository().client.channel(data.channel.id).history(chunkSize: 1);
    await history.more();
    baseMessage = history.messages.isEmpty ? null : history.messages.first;
    ChannelMetadataDetails cmRes = data.channel;
    Map<String, int> readMap = Map<String, int>.from( jsonDecode(cmRes.custom['read']) );
    RimeChannelMemebership memebership = RimeChannelMemebership.fromJson(data.custom);
    RimeChannel channel = RimeChannel(
      channel: data.channel.id,
      lastUpdated: cmRes.custom['lastUpdated'],
      title: data.channel.name,
      readMap: readMap,
      membership: memebership,
    );
    if(baseMessage != null){
      channel = channel.copyWith(
        RimeChannel(
          subtitle: baseMessage.content,
          lastUpdated: baseMessage.publishedAt.value
        )
      );
    }
    return channel;
  }
}
