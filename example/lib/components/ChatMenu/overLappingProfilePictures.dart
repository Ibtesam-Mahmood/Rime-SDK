import 'package:flutter/material.dart';
import 'fadeInUserImage.dart';

class OverlappingProfilePicture extends StatelessWidget {

final String topImage;
final String bottomImage;

///Size of the image
final double imageSize;

///Hiehght on the wrapping contianer, also defualt image dimension
final double height;

///Width of the wrapping container
final double width;

const OverlappingProfilePicture({Key key, this.topImage = '', this.bottomImage = '', this.height, this.width, this.imageSize}) : super(key: key);

  ///Returns the primary size of the image
  double get _mainSize {
    return topImage == null || topImage.isEmpty || bottomImage.isEmpty ? height : imageSize ?? height;
  }

  ///Returns the size of each circle
  double get _imageSize {
    return imageSize ?? height;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: topImage == null ? height : width,
      height: height,
      child: Stack(
        children: <Widget> [
          Positioned(
            top: 0,
            left: 0,
            child: ClipPath(
              clipper: OverlapClipper((topImage?.isNotEmpty??false) && topImage != null ? _imageSize : null, height, width),
              child: Container(
                height: _mainSize,
                width: _mainSize,
                child: FadeInUserImage(
                  profileImg: bottomImage?.isNotEmpty != true ? null : bottomImage,
                  fit: BoxFit.cover,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle
                ),
              ),
            ),
          ),
          (topImage?.isNotEmpty??false) && topImage != null ? Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              height: _imageSize,
              width: _imageSize,
              child: ClipOval(
                child: FadeInUserImage(
                  profileImg: topImage.isEmpty ? null : topImage,
                  fit: BoxFit.cover,
                ),
              ),

              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle
              ),
            ),
          ) : Container(),
        ],
      ),
    );
  }
}

///Masks a circle into a clip circle
class OverlapClipper extends CustomClipper<Path> {

  ///Size of the image
  final double imageSize;

  ///Hiehght on the wrapping contianer, also defualt image dimension
  final double height;

  ///Width of the wrapping container
  final double width;

  OverlapClipper(this.imageSize, this.height, this.width);

  @override
  Path getClip(Size size) {
    if(imageSize == null) {return Path()
      ..addOval(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.height / 2));}

    return Path.combine(
      PathOperation.difference, 
      Path()..addOval(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.height / 2)), 
      Path()..addOval(Rect.fromCircle(center: Offset(width - (size.width / 2) , height - (size.height / 2)), radius: (size.height / 2) + 2))
    );
  }

  @override
  bool shouldReclip(OverlapClipper oldClipper) => true;


}