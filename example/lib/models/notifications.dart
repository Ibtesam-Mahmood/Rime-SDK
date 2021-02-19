import 'dart:convert';

import '../state/store/storable.dart';

class PollarNotification extends Storable<PollarNotification> {
  String userInfoId;
  Map<String, dynamic> type;
  String typeId;
  String subject;
  DateTime date;
  List<dynamic> actorId;
  bool seen;

  PollarNotification(
      {String id,
      this.userInfoId,
      this.actorId,
      this.subject,
      this.type,
      this.typeId,
      this.date,
      this.seen})
      : super(id);

  factory PollarNotification.fromJson(Map<String, dynamic> json) {
    return PollarNotification(
      id: json['_id'],
      userInfoId: json['userInfoId'],
      type: json['type'],
      typeId: json['typeId'],
      subject: json['subject'],
      actorId: json['actorId'],
      seen: json['viewed'],
      date: DateTime.parse(json['date']),
    );
  }

  String toJson() {
    Map<String, dynamic> object = {
      '_id': id,
      'userInfoId': userInfoId,
      'type': type,
      'typeId': typeId,
      'subject': subject,
      'actorId': actorId,
      'viewed': seen,
      'date': date.toString()
    };
    return jsonEncode(object);
  }

  @override
  bool compare(PollarNotification comparable) {
    if (comparable == null) return true;

    bool compare = id == comparable.id &&
        type['child'] == comparable.type['child'] &&
        typeId == comparable.typeId &&
        subject == comparable.subject &&
        date == comparable.date &&
        seen == comparable.seen &&
        actorId[0] == comparable.actorId[0] &&
        actorId.length == comparable.actorId.length;

    return compare;
  }

  @override
  PollarNotification copy() {
    return PollarNotification(
        id: id,
        userInfoId: userInfoId,
        actorId: actorId,
        subject: subject,
        type: type,
        typeId: typeId,
        seen: seen,
        date: date);
  }

  @override
  PollarNotification copyWith(PollarNotification copy) {
    if (copy == null) return this;

    return PollarNotification(
        id: id,
        userInfoId: copy.userInfoId ?? userInfoId,
        actorId: copy.actorId ?? actorId,
        date: copy.date ?? date,
        subject: copy.subject ?? subject,
        type: copy.type ?? type,
        seen: copy.seen ?? seen,
        typeId: copy.typeId ?? typeId);
  }

  ///Validates the object for errors
  @override
  bool validate() {
    return true;
  }
}
