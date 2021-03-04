class RimeChannel {
  String channel;
  String title;
  String subtitle;
  DateTime lastUpdated;
  String image;
  bool isGroup;

  RimeChannelMemebership membership;

  RimeChannel(
      {this.channel,
      this.title,
      this.subtitle,
      this.lastUpdated,
      this.image,
      this.isGroup});

  RimeChannel copyWith(RimeChannel copy) {
    if (copy == null) return this;

    return RimeChannel(
      channel: copy.channel ?? channel,
      title: copy.title ?? title,
      subtitle: copy.subtitle ?? subtitle,
      lastUpdated: copy.lastUpdated ?? lastUpdated,
      image: copy.image ?? image,
      isGroup: copy.isGroup ?? isGroup,
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
      );

      //dispose listener
      /* if (subscription != null) {
        subscription.unsubscribe();
        subscription.dispose();
      } */

      return copyChat;
    }

    return this;
  }
}

class RimeChannelMemebership {}
