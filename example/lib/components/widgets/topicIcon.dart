import 'package:flutter/material.dart';

import '../../models/topics.dart';
import 'fadeUserImage.dart';


///Displays a topic display picture with the stated topic name and sizes
///Default sizes are set at 84x84
class TopicIcon extends StatelessWidget {

  final Topic topic;
  final double height, width;

  const TopicIcon({
    Key key,
    @required this.topic, this.height = 84, this.width = 84,
  }) : super(key: key);

  ///Formats the topic image name
  String get formatImageUrl{
    return topic.image
      .replaceAll("'", '’')
      .replaceAll('+', '%2B');
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        height: height,
        width: width,
        child: topic == null ? null : FadeInUserImage(profileImg: formatImageUrl, fit: BoxFit.contain,),
      ),
    );
  }
}