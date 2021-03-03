import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:rime/components/ChatMenu/chatList.dart';
import 'package:rime/components/DefaultWidgets/chatMenuHeader.dart';
import 'package:rime/components/DefaultWidgets/loading.dart';
import 'package:rime/components/DefaultWidgets/searchFiled.dart';

class ChatMenu extends StatefulWidget {

  @override
  _ChatMenuState createState() => _ChatMenuState();
}

class _ChatMenuState extends State<ChatMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          top: true,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 400),
            height: kToolbarHeight,
            width: double.infinity,
            color: Colors.white,
            //search bar
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchField(
                style: SearchFieldType.LARGE,
                onChanged: (val) {
                  //If new value is different then old value, search
                  // if (val != searchText) {
                  //   search(val);
                  //   setState(() {
                  //     searchText = val;
                  //   });
                  // }
                },
                onFocus: (focus) {
                  // print(focus);
                  // //set focus value
                  // if (focus)
                  //   {search('');}
                  // //Remove search state if no search text
                  // else if (searchText.isEmpty)
                  //   {searchBloc.add(Reset());}
                },
              ),
            ),
          ),
        ),
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
            //List of story replies
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: AnimatedSwitcher(
                  duration: Duration(microseconds: 400),
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      child: child,
                      sizeFactor: animation,
                      axis: Axis.vertical,
                    );
                  },
                  child: Container()
                ),
              ),
            ),
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
                  child: ChatMenuHeader()
                ),
            )),
            ChatList(childCount: 10)
          ],
        ),
      )
    );
  }
}