import 'package:flutter/material.dart';
import '../../util/colorProvider.dart';

///Notch that appears above a sliding sheet to drag
class DragNotch extends StatelessWidget {

  ///If the notch is displayed
  final bool enable;

  const DragNotch([this.enable = true]);

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    return SizedBox(
      height: !enable ? 16 : 24,
      child: !enable ? SizedBox.shrink() : Center(
        child: Container(
          height: 4,
          width: 35,
          decoration: BoxDecoration(
            color: appColors.grey.withOpacity(0.24),
            borderRadius: BorderRadius.circular(10)
          ),
        ),
      ),
    );
  }
}