import 'package:flutter/material.dart';
import 'package:rime/components/DefaultWidgets/horizontalBar.dart';

class ChatSpacer extends StatelessWidget {

  final EdgeInsets padding;
  final Widget child;

  ChatSpacer({this.padding, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding != null ? padding : EdgeInsets.zero,
      child: Container(
        child: child != null ? child : HorizontalBar(
          color: Colors.grey,
          width: 0.5,
        ),
      ),
    );
  }
}