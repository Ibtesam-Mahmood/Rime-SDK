import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:rime/state/rime_bloc/rime_bloc_state.dart';

class RimeChannel extends Comparable<RimeChannel> with EquatableMixin {
  String channel;
  String groupId;
  String title;
  String subtitle;
  int lastUpdated;
  String image;
  bool isGroup;
  Map<String, int> readMap;
  RimeChannelMemebership membership;

  RimeChannel(
    {
      this.groupId,
      this.channel,
      this.title,
      this.subtitle,
      this.lastUpdated,
      this.image,
      this.isGroup,
      this.membership,
      this.readMap = const {}
    });

  RimeChannel copyWith(RimeChannel copy) {
    if (copy == null) return this;

    return RimeChannel(
      channel: copy.channel ?? channel,
      title: copy.title ?? title,
      subtitle: copy.subtitle ?? subtitle,
      lastUpdated: copy.lastUpdated ?? lastUpdated,
      image: copy.image ?? image,
      isGroup: copy.isGroup ?? isGroup,
      readMap: copy.readMap ?? readMap ?? {}
    );
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
        readMap: readMap
      );

      return copyChat;
    }

    return this;
  }

  @override
  int compareTo(other) {
    if(other is RimeChannel){
      return (this?.lastUpdated ?? 0).compareTo(other?.lastUpdated ?? 0);
    } 
    return -1;
  }

  //Hashes the read map
  String get _hashReadMap{

    //If read map is not defined
    String hash = ''; 
    if(readMap == null) return hash;

    //Maps the keys and values into a combined string
    for (MapEntry<String, int> item in readMap.entries) {
      hash = item.key + '-' + item.value.toString();
    }
    return hash;
  }

  @override
  // TODO: implement props
  List<Object> get props => [channel, title, subtitle, image, isGroup, _hashReadMap, membership];
}

class RimeChannelMemebership with EquatableMixin {
  bool notifications;
  bool readAction;
  bool accepted;
  int deleted;

  RimeChannelMemebership({
    this.notifications,
    this.readAction,
    this.accepted,
    this.deleted
  });

  RimeChannelMemebership copyWith(RimeChannelMemebership copy) {
    if (copy == null) return this;

    return RimeChannelMemebership(
      notifications: copy.notifications ?? notifications,
      readAction: copy.readAction ?? readAction,
      accepted: copy.accepted ?? accepted,
      deleted: copy.deleted ?? deleted
    );
  }

  @override
  Map<String, dynamic> toJson(){
    return {
      'notifications': notifications,
      'readAction': readAction,
      'accepted': accepted,
      'deleted': deleted
    };
  }

  factory RimeChannelMemebership.fromJson(Map<String, dynamic> json){
    return RimeChannelMemebership(
      notifications: json['notifications'],
      readAction: json['readAction'],
      accepted: json['accepted'],
      deleted: json['deleted']
    );
  }

  @override
  // TODO: implement props
  List<Object> get props => [notifications, readAction, accepted, deleted];
}
