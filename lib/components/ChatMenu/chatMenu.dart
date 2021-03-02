import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:rime/components/ChatMenu/chatList.dart';
import 'package:rime/components/DefaultWidgets/chatMenuHeader.dart';
import 'loading.dart';

class ChatMenu extends StatefulWidget {

  final Widget header;
  final Widget chatList;

  ChatMenu({this.chatList, this.header});

  @override
  _ChatMenuState createState() => _ChatMenuState();
}

class _ChatMenuState extends State<ChatMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      //TODO: Implement default searchbar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(),
      ),
      body: EasyRefresh(
        bottomBouncing: false,header: CustomHeader(
          extent: 40.0,
          triggerDistance: 50.0,
          headerBuilder: (context,
            loadState,
            pulledExtent,
            loadTriggerPullDistance,
            loadIndicatorExtent,
            axisDirection,
            float,
            completeDuration,
            enableInfiniteLoad,
            success,
            noMore) {
              return Container(
                color: Colors.grey,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      bottom: 0.0,
                      left: 0.0,
                      right: 0.0,
                      child: Container(
                        width: 30.0,
                        height: 30.0,
                        child: Center(
                          child: Loading()
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      child: child,
                      sizeFactor: animation,
                      axis: Axis.vertical,
                    );
                  },
                  child: widget.header ?? ChatMenuHeader()
                ),
            )),
            widget.chatList ?? ChatList(childCount: 10)
          ],
        ),
        //TODO: Implement onRefresh
        onRefresh: (){
          
        },
      )
    );
  }
}