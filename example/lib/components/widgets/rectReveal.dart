import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

@immutable
class RectClipper extends CustomClipper<Path> {
  final double fraction;
  final double minHeight;
  final double maxHeight;

  RectClipper({
    @required this.fraction,
    this.minHeight,
    this.maxHeight,
  });

  @override
  Path getClip(Size size) {
    final minHeight = this.minHeight ?? 0;
    final maxHeight = this.maxHeight ?? size.height;

    return Path()
      ..addRect(
        Rect.fromLTWH(0, 0, size.width, lerpDouble(minHeight, maxHeight, fraction))
      );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}