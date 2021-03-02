import 'package:flutter/material.dart';
import 'package:rime/components/DefaultWidgets/chatTile.dart';

class ChatList extends StatefulWidget {

  final Widget tile;
  final Widget spacer;
  ChatList({this.tile, this.spacer});

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index){
          return Column(
            children: [
              widget.tile ?? ChatTile(),
              widget.spacer ?? Spacer(),
            ],
          );
        }
      ),
    );
  }
}