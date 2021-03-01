import 'dart:ui';

import 'package:flutter/material.dart';

///Wraps an animated frosted effect around a widget and clips to the desired shape
class FrostedEffect extends StatelessWidget {

  static const double FROSTED_BLUR_MAX = 20;

  ///Animates the frosted effect when toggled
  final bool frost;

  ///The widget that the frost is applied to
  final Widget child;

  ///Defines the blur for the frosted effect. 
  ///Defauled to [FROSTED_BLUR_MAX]
  final double blur;

  ///The type of clip around the frosted effect
  final ClipShape shape;

  ///Hides the widget when enabled and `frost = false`
  final bool animateOpacity;

  ///The animated builder is a overriding child. 
  ///It builds the child by connecting it to the frosting animation
  ///Overrides the [child]
  final Widget Function(BuildContext context, double frost) animatedBuilder;

  const FrostedEffect({Key key, @required this.frost, this.shape = ClipShape.rect, this.child, this.animateOpacity = false, this.blur, this.animatedBuilder}) 
    : assert(frost != null),
      assert(shape != null),
      super(key: key);

  ///Getter for max blur
  double get maxBlur => blur ?? FROSTED_BLUR_MAX;

  @override
  Widget build(BuildContext context) {

    ShapeBorder clipShape;

    //Wraps the frosted effect in required clipper
    //Cliper shape is determined through the shape property
    switch (shape.shape) {
      case ClipShape.ROUNDED_RECTANGLE_CLIP:
        //Rounded rect clip
        clipShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(shape.amount));
        break;
      case ClipShape.CIRCLE_CLIP:
        clipShape = CircleBorder();
        break;
      default:
        clipShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(0));
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300),
      curve: Curves.decelerate,
      tween: Tween<double>(begin: 0, end: frost ? maxBlur : 0),
      builder: (context, frost, tweenChild) {
        return ClipPath(
          clipper: ShapeBorderClipper(shape: clipShape),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: frost, sigmaY: frost),
            child: Opacity(
              opacity: animateOpacity ? (frost / maxBlur) : 1,
              child: animatedBuilder != null ? animatedBuilder(context, frost) : tweenChild,
            ),
          ),
        );
      },
      child: child,
    );
  }

}

///The type of clip
class ClipShape {

  static const String RECTANGLE_CLIP = 'rect';
  static const String ROUNDED_RECTANGLE_CLIP = 'r-rect';
  static const String CIRCLE_CLIP = 'circ';

  ///The type of shape: [rectangle], [rounded rectangle] or [circle]
  final String shape;

  ///The intensity for the shape. 
  ///For a [Rounded Rectangle] this is the border radius
  final double amount;

  ///Private constructor
  const ClipShape._internal(this.shape, this.amount);
  
  ///Default Circle
  static const ClipShape circle = ClipShape._internal(CIRCLE_CLIP, 0);

  ///Default Rounded rectangle
  factory ClipShape.rRect(double borderRadius) => ClipShape._internal(ROUNDED_RECTANGLE_CLIP, borderRadius);

  ///Default Rectangle constrctor
  static const ClipShape rect = ClipShape._internal(RECTANGLE_CLIP, 0);

}