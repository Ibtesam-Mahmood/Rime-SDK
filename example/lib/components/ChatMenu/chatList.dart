import 'package:flutter/material.dart';
import 'chatTile.dart';
import 'chatTileAction.dart';
import 'chatSpacer.dart';

class ChatList extends StatelessWidget {

  final Widget tile;
  final Widget spacer;
  final int childCount;

  ChatList({this.tile, this.spacer, @required this.childCount}) : 
  assert(childCount != null);

  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index){
          return Column(
            children: [
              tile ?? ChatTile(
                //TODO: Add id of chat to ValueKey
                key: ValueKey('chatTile - '),
                actions: [
                  ChatTileAction(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.07),
                      shape: BoxShape.circle
                    ), 
                    icon: Icon(Icons.access_time),
                    onTap: (){
                      //TODO: Implement onTap
                    },
                  ),
                  ChatTileAction(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle
                    ),
                    icon: Icon(Icons.access_alarm),
                    onTap: (){
                      //TODO: Implement onTap
                    },
                  ),
                ],
              ),
              spacer ?? ChatSpacer(padding: EdgeInsets.only(left: 77)),
            ],
          );
        },
        childCount: childCount
      ),
    );
  }
}