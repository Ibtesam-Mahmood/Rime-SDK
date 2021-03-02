import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:rime/components/wrappedListTile.dart';

class ChatTile extends StatefulWidget {


  final List<Widget> actions;

  //TODO: Insert chat object
  const ChatTile({Key key, this.actions}) : super(key: key);

  @override
  _ChatTileState createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  @override
  Widget build(BuildContext context) {
    //TODO: Add chat ID
    return Slidable(
      key: Key('Slidable - ChatTile'),
      actionExtentRatio: 0.13,
      actionPane: SlidableScrollActionPane(),
      secondaryActions: widget.actions,
      child: WrappedListTile(),
    );
  }
}