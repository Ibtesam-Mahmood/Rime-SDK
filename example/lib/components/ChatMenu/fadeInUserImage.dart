import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

///The defualt user image or user network profile picture is loaded in. 
///Fade in effect added
class FadeInUserImage extends StatelessWidget {

  ///Users profile image. 
  ///When `profileImage == null` [profile place holder] is displayed
  final String profileImg;

  ///The box fit for the image
  final BoxFit fit;

  const FadeInUserImage({Key key, this.profileImg, this.fit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeInImage(
      image: profileImg != null && profileImg.isNotEmpty ? CachedNetworkImageProvider(profileImg) : AssetImage('assets/profile_placeholder.png'),
      placeholder: AssetImage('assets/blank_grey.png'),
      fit: BoxFit.cover,
    );
  }
}