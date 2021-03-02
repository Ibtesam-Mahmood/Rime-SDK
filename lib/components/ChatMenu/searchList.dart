import 'package:flutter/material.dart';
import 'package:rime/components/DefaultWidgets/SimpleChatTile.dart';
import 'package:rime/components/DefaultWidgets/horizontalBar.dart';

class SearchList extends StatelessWidget {

  final Widget spacer;
  final Widget tile;
  final int childCount;

  SearchList({this.spacer, this.tile, @required this.childCount}) :
  assert(childCount != null);

  @override
  Widget build(BuildContext context) {
    return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            //A chat tile
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SimpleChatTile(
                  onPressed: () {
                    //TODO: Implement onPressed
                  },
                ),
                spacer ?? Padding(
                  padding: const EdgeInsets.only(left: 77.0),
                  child: HorizontalBar(
                    color: Colors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ],
            );
          },
          childCount: childCount,
        )
      );
  }
}