import 'package:flutter/material.dart';
import 'package:rime/model/channel.dart';
import 'chatTile.dart';
import 'chatTileAction.dart';
import 'chatSpacer.dart';

class ChatList extends StatelessWidget {

  final Widget tile;
  final Widget spacer;
  final List<RimeChannel> children;

  ChatList({this.tile, this.spacer, @required this.children}) : 
  assert(children != null);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index){
          return Column(
            children: [
              tile ?? ChatTile(
                //TODO: Add id of chat to ValueKey
                key: ValueKey('chatTile - '),
                rimeChannel: children[index],
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
        childCount: children.length
      ),
    );
  }
}