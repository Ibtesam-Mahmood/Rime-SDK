import 'package:equatable/equatable.dart';

class RimeChannel extends Comparable<RimeChannel> with EquatableMixin {
  String channel;
  String groupId; // Unused, both unread and unwritten
  String title;
  dynamic subtitle;
  int lastUpdated;
  String image;
  bool isGroup;
  Map<String, int> readMap;
  RimeChannelMembership membership;
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

  ///Disposes the rime channel connection
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
  List<Object> get props => [channel, title, subtitle, image, isGroup, _hashReadMap, membership, uuids];
}

class RimeChannelMembership with EquatableMixin {
  bool notifications;
  bool readAction;
  bool accepted;
  int deleted;

  RimeChannelMembership({this.notifications, this.readAction, this.accepted, this.deleted});

  RimeChannelMembership copyWith(RimeChannelMembership copy) {
    if (copy == null) return this;

    return RimeChannelMembership(
        notifications: copy.notifications ?? notifications,
        readAction: copy.readAction ?? readAction,
        accepted: copy.accepted ?? accepted,
        deleted: copy.deleted ?? deleted);
  }

  Map<String, dynamic> toJson() {
    return {'notifications': notifications, 'readAction': readAction, 'accepted': accepted, 'deleted': deleted};
  }

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
