import 'package:flutter/material.dart';

import '../../util/colorProvider.dart';
import '../../util/inner_shadow.dart';

enum EECardMode {
  ///Regular EECard
  NEUMORPHIC,

  ///EECard with no outer shaodws
  THIN,

  ///EECard with no inner or outer shadows
  FLAT
}

class EECard extends StatelessWidget {

  final Widget child;
  final Color color;
  final double width;
  final BorderRadius borderRadius;

  final BoxConstraints constraints;
  
  final EECardMode mode;

  const EECard({
    this.child,
    Key key, this.color, this.width, this.borderRadius, this.mode = EECardMode.NEUMORPHIC, this.constraints
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    return Container(
      constraints: constraints ?? BoxConstraints(
        minWidth: (width ?? -1) < 0 ? double.infinity : width,
        maxWidth: double.infinity
      ),
      decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          color: color ?? Colors.white,
          boxShadow: mode != EECardMode.NEUMORPHIC ? [] : [
            BoxShadow(offset: Offset(1, 1), blurRadius: 1, color: Color(0xFF92ACC4).withOpacity(0.14), spreadRadius: 0),
            BoxShadow(offset: Offset(2, 2), blurRadius: 1, color: Color(0xFF92ACC4).withOpacity(0.12), spreadRadius: -1),
            BoxShadow(offset: Offset(1, 1), blurRadius: 3, color: Color(0xFF92ACC4).withOpacity(0.20), spreadRadius: 0),
          ]),
      child: Stack(
        children: [
          //InnerShadow layer
          Positioned.fill(
            child: InnerShadow(
              color: mode == EECardMode.FLAT ? Colors.transparent : Colors.white,
              offset: Offset(1, 1),
              blur: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius ?? BorderRadius.circular(16),
                  color: color ?? appColors.surface,
                ),
              ),
            ),
          ),

          child,

          
        ],
      ));
  }
}
