import 'package:flutter/material.dart';

import '../util/colorProvider.dart';

class UndoButtonChat extends StatefulWidget {

  ///Message request version is true
  ///Chat request version is false
  final bool messageRequest;

  //If it should be visible on the chat page
  final bool visible;

  UndoButtonChat({this.messageRequest, this.visible});

  @override
  _UndoButtonChatState createState() => _UndoButtonChatState();
}

class _UndoButtonChatState extends State<UndoButtonChat> {
  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return widget.visible ? Container(
      height: 48,
      width: 344,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 48,
          width: 276,
          child: Text('Accepted message request', style: textStyles.button.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          decoration: BoxDecoration(
            color: appColors.blue,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))
          ),
        ),
        Container(
          height: 48,
          color: Colors.white,
          width: 1
        ),
        Container(
          height: 48,
          width: 67,
          child: Text('Undo', style: textStyles.button.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          decoration: BoxDecoration(
            color: appColors.blue,
            borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16))
            ),
          )
        ],
      ),
    ) : Container();
  }
}