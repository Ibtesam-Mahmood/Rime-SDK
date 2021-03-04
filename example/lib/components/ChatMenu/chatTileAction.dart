import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ChatTileAction extends StatelessWidget {

  final Decoration decoration;
  final Icon icon;
  final void Function() onTap;

  ChatTileAction({@required this.decoration, @required this.icon, this.onTap}) : 
  assert(decoration != null), 
  assert(icon != null);

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      child: Container(
        height: 38,
        width: 38,
        decoration: decoration,
        child: FittedBox(
          fit: BoxFit.cover,
          child: icon
        ),
      ),
      onTap: onTap
    );
  }
}