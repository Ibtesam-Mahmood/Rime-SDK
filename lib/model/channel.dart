import 'package:equatable/equatable.dart';

/// An object to encapsulate information related to PubNub channels and Rime attributes
///
/// This class includes information like user membership metadata, last updated time, and the channel title
class RimeChannel extends Comparable<RimeChannel> with EquatableMixin {
  /// The PubNub channel Id
  String channel;

  /// The Id for the channel group that the current user has this channel in
  String groupId; // Unused, both unread and unwritten
  /// The title of the channel
  String title;

  /// The most recent message sent in the channel
  /// In the form of [RimeMessage.encode()]
  dynamic subtitle;

  /// The PubNub TimeToken for the last update to the channel
  int lastUpdated;

  /// The image for the channel stored as a hosted url
  String image;

  /// Is this a group chat or individual channel
  bool isGroup;

  /// A map containing channel members and the time token of when they last read a message
  Map<String, int> readMap;

  /// The current user's membership metadata for this channel
  RimeChannelMembership membership;

  /// A list of userIds for the current members of this channel
  List<String> uuids;

  RimeChannel(
      {this.groupId,
      this.channel,
      this.title,
      this.subtitle,
      this.lastUpdated,
      this.image,
      this.isGroup,
      this.membership,
      this.readMap,
      this.uuids});

  /// A copy constructor for [RimeChannel]
  RimeChannel copyWith(RimeChannel copy) {
    if (copy == null) return this;

    return RimeChannel(
        channel: copy.channel ?? channel,
        title: copy.title ?? title,
        subtitle: copy.subtitle ?? subtitle,
        lastUpdated: copy.lastUpdated ?? lastUpdated,
        image: copy.image ?? image,
        isGroup: copy.isGroup ?? isGroup,
        readMap: copy.readMap ?? readMap ?? {},
        uuids: copy.uuids ?? uuids ?? []);
  }

  ///Disposes the RimeChannel connection
  RimeChannel dispose() {
    if (channel != null) {
      //Channel defined, dipose channel
      RimeChannel copyChat = RimeChannel(
          channel: channel,
          title: title,
          subtitle: subtitle,
          lastUpdated: lastUpdated,
          image: image,
          isGroup: isGroup,
          readMap: readMap,
          groupId: groupId,
          membership: membership,
          uuids: uuids);

      return copyChat;
    }

    return this;
  }

  @override
  int compareTo(other) {
    if (other is RimeChannel) {
      return (other?.lastUpdated ?? 0).compareTo(this?.lastUpdated ?? 0);
    }
    return -1;
  }

  //Hashes the read map
  String get _hashReadMap {
    //If read map is not defined
    String hash = '';
    if (readMap == null) return hash;

    //Maps the keys and values into a combined string
    for (MapEntry<String, int> item in readMap.entries) {
      hash = item.key + '-' + item.value.toString();
    }
    return hash;
  }

  @override
  List<Object> get props => [
        channel,
        title,
        subtitle,
        image,
        isGroup,
        _hashReadMap,
        membership,
        uuids
      ];
}

/// An object to encapsulate information related to PubNub memberships and Rime attributes
///
/// Includes custom metadata such as if notifications are turned on or off and is read receipts are on
class RimeChannelMembership with EquatableMixin {
  bool notifications;
  bool readAction;
  bool accepted;
  int deleted;

  RimeChannelMembership(
      {this.notifications, this.readAction, this.accepted, this.deleted});

  /// A copy constructor for [RimeChannelMembership]
  RimeChannelMembership copyWith(RimeChannelMembership copy) {
    if (copy == null) return this;

    return RimeChannelMembership(
        notifications: copy.notifications ?? notifications,
        readAction: copy.readAction ?? readAction,
        accepted: copy.accepted ?? accepted,
        deleted: copy.deleted ?? deleted);
  }

  /// Converts this object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications,
      'readAction': readAction,
      'accepted': accepted,
      'deleted': deleted
    };
  }

  /// Creates a RimeChannelMembership object from JSON format
  factory RimeChannelMembership.fromJson(Map<String, dynamic> json) {
    return RimeChannelMembership(
        notifications: json['notifications'],
        readAction: json['readAction'],
        accepted: json['accepted'],
        deleted: json['deleted']);
  }

  @override
  List<Object> get props => [notifications, readAction, accepted, deleted];
}
