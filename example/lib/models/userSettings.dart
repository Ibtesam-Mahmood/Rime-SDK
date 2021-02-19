

import 'dart:async';

import '../state/store/pollarStoreBloc.dart';

class UserSettings{

  String id;
  String userID;
  bool readReceipts;
  List<String> blocked;
  NotificationSettings notifs;
  bool contactSynced;

  UserSettings({this.id, this.userID, this.notifs, this.readReceipts, this.blocked, this.contactSynced});

  factory UserSettings.fromJSON(Map<String, dynamic> json){

    //Blocked user parsing
    List<String> blockedUsers = [];
    for (var object in json['blocked']) {
      blockedUsers.add(object['userBlocked']);
    }

    //Notification setting parsing
    Map<String, dynamic> notificationSettings = json['notif'];

    return UserSettings(
      id: json['settings']['_id'],
      userID: json['settings']['userMainId'],
      readReceipts: json['settings']['sendReadReceipts'],
      contactSynced: json['settings']['contactsSynced'],
      blocked: blockedUsers,
      notifs: notificationSettings != null ? NotificationSettings.fromJson(notificationSettings) : null
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'sendReadReceipts': readReceipts,
      'contactsSynced': contactSynced
    };
  }

  //Creates an new object with the copied over values
  //Removes the refrence to the old object
  UserSettings copyWith(UserSettings newSettings){
    return UserSettings(
      id: newSettings?.id ?? id,
      userID: newSettings?.userID ?? userID,
      readReceipts: newSettings?.readReceipts ?? readReceipts,
      blocked: newSettings?.blocked ?? blocked,
      // notifs: notifs.copyWith(newSettings.notifs),
      contactSynced: newSettings?.contactSynced ?? contactSynced
    );
  }

  ///Returns true if objects are the same
  ///Returns false if the objects are not the same
  bool compare(UserSettings comparable) {
    if(comparable == null) return true;
    //TODO: compare not working around contacts synced
    bool compare = 
      id == comparable.id &&
      userID == comparable.userID &&
      readReceipts == comparable.readReceipts &&
      blocked.length == comparable.blocked.length && 
      contactSynced == comparable.contactSynced &&
      (notifs == null ? comparable.notifs == notifs : notifs.compare(comparable.notifs));

    return compare;
  }

}

enum NotificationSettingValue {
  OFF,
  FOLLOWERS,
  EVERYONE
}

class NotificationSettings{

  String id;
  String userSettingsId;

  //Post settings
  NotificationSettingValue likes;
  NotificationSettingValue newTrusts;
  NotificationSettingValue firstPosts;
  NotificationSettingValue replies;

  //Poll settings
  bool pollAccepted;
  bool pollExpires;
  bool pollResults;
  bool trendingPolls;

  //Message settings
  bool messages;
  bool messageRequests;
  bool groupRequests;

  //Follow settings
  bool followers;
  bool friendsOnPollar;

  //Trust settings
  bool trusts;
  bool trusting;

  //Pause all
  Duration paused;

  NotificationSettings({
    this.id,
    this.userSettingsId,
    this.likes, 
    this.newTrusts, 
    this.firstPosts, 
    this.replies, 
    this.pollAccepted, 
    this.pollExpires, 
    this.pollResults, 
    this.trendingPolls, 
    this.messages, 
    this.messageRequests, 
    this.groupRequests, 
    this.followers, 
    this.friendsOnPollar, 
    this.trusts, 
    this.trusting,
    this.paused,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json){
    return NotificationSettings(
      id: json['_id'],
      userSettingsId: json['userSettingId'],
      likes: NotificationSettingValue.values[json['posts']['likes']], 
      newTrusts: NotificationSettingValue.values[json['posts']['newTrusts']], 
      firstPosts: NotificationSettingValue.values[json['posts']['firstPosts']], 
      replies: NotificationSettingValue.values[json['posts']['replies']], 
      pollAccepted: json['polls']['acceptedPollSubmissions'], 
      pollExpires: json['polls']['pollsExpireSoon'], 
      pollResults: json['polls']['pollResults'], 
      trendingPolls: json['polls']['trendingPolls'], 
      messages: json['messages']['messages'], 
      messageRequests: json['messages']['messageRequests'], 
      groupRequests: json['messages']['groupRequests'], 
      followers: json['follows']['newFollowers'], 
      friendsOnPollar: json['follows']['friendsOnPollar'], 
      trusts: json['trusts']['trusts'], 
      trusting: json['trusts']['trusting']
    );
  }

  ///Transforms the object into a serialized json
  Map<String, dynamic> toJson(){
    return {
      '_id': id,
      'userSettingId': userSettingsId,
      'posts': {
        'likes': NotificationSettingValue.values.indexOf(likes),
        'newTrusts': NotificationSettingValue.values.indexOf(newTrusts),
        'firstPosts': NotificationSettingValue.values.indexOf(firstPosts),
        'replies': NotificationSettingValue.values.indexOf(replies)
      },
      'polls': {
        'acceptedPollSubmissions': pollAccepted,
        'pollsExpireSoon': pollExpires,
        'pollResults': pollResults,
        'trendingPolls': trendingPolls
      },
      'messages': {
        'messages': messages,
        'messageRequests': messageRequests,
        'groupRequests': groupRequests
      },
      'follows': {
        'newFollowers': followers,
        'friendsOnPollar': friendsOnPollar
      },
      'trusts': {
        'trusting': trusting,
        'trusts': trusts
      },
    };
  }

  void startTimer(Duration duration) {
    Timer.periodic(duration, (time) { 
      UserSettings userSettings = UserSettings(notifs: copyWith(NotificationSettings(paused: Duration(seconds: 0))));
      PollarStoreBloc().add(EditPollarStoreState(loginSettings: userSettings));
    });
  }

  NotificationSettings copyWith(NotificationSettings other){
    if(other == null) return this;
    if(other.paused != null){
      startTimer(other.paused);
    }

    return NotificationSettings(
      id: other.id ?? id,
      userSettingsId: other.userSettingsId ?? userSettingsId,
      likes: other.likes ?? likes, 
      newTrusts: other.newTrusts ?? newTrusts, 
      firstPosts: other.firstPosts ?? firstPosts, 
      replies: other.replies ?? replies, 
      pollAccepted: other.pollAccepted ?? pollAccepted, 
      pollExpires: other.pollExpires ?? pollExpires, 
      pollResults: other.pollResults ?? pollResults, 
      trendingPolls: other.trendingPolls ?? trendingPolls, 
      messages: other.messages ?? messages, 
      messageRequests: other.messageRequests ?? messageRequests, 
      groupRequests: other.groupRequests ?? groupRequests, 
      followers: other.followers ?? followers, 
      friendsOnPollar: other.friendsOnPollar ?? friendsOnPollar, 
      trusts: other.trusts ?? trusts, 
      trusting: other.trusting ?? trusting,
      paused: other.paused ?? paused
    );
  }

  bool compare(NotificationSettings other){
    if(other == null) return true;

    bool compare = 
      id == other.id &&
      userSettingsId == other.userSettingsId &&
      likes == other.likes &&
      newTrusts == other.newTrusts &&
      firstPosts == other.firstPosts &&
      replies == other.replies &&
      pollAccepted == other.pollAccepted && 
      pollExpires == other.pollExpires && 
      pollResults == other.pollResults &&
      trendingPolls == other.trendingPolls && 
      messages == other.messages && 
      messageRequests == other.messageRequests &&
      groupRequests == other.groupRequests &&
      followers == other.followers &&
      friendsOnPollar == other.friendsOnPollar &&
      trusts == other.trusts &&
      trusting == other.trusting &&
      paused == other.paused;
    
    return compare;
  }

}