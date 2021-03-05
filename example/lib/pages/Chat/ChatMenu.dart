import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import '../../components/ChatMenu/loading.dart';
import '../../components/ChatMenu/searchFiled.dart';
import '../../components/ChatMenu/chatMenuHeader.dart';
import '../../components/ChatMenu/chatList.dart';

class ChatMenu extends StatefulWidget {
  @override
  _ChatMenuState createState() => _ChatMenuState();
}

class _ChatMenuState extends State<ChatMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
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
        body: RimeMessagesMenu());
  }
}

class RimeMessagesMenu extends StatefulWidget {
  ///Widget to display while loading for `EasyRefresh`
  final Widget loading;
  ///Widget to display
  final Widget chatListHeader;
  ///`Color` for scroll view container 
  final Color scrollViewContainerCover;

  const RimeMessagesMenu({
    Key key,
    this.loading,
    this.chatListHeader, 
    this.scrollViewContainerCover = Colors.white,
  }) : super(key: key);

  @override
  _RimeMessagesMenuState createState() => _RimeMessagesMenuState();
}

class _RimeMessagesMenuState extends State<RimeMessagesMenu> {
  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      bottomBouncing: false,
      header: CustomHeader(
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
                      child: Center(child: widget.loading ?? Loading()),
                    ),
                  ),
                ],
              ),
            );
          }),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: Container(
            color: widget.scrollViewContainerCover,
            child: AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return SizeTransition(
                    child: child,
                    sizeFactor: animation,
                    axis: Axis.vertical,
                  );
                },
                child: widget.chatListHeader ?? ChatMenuHeader()),
          )),
          ChatList(childCount: 10)
        ],
      ),
    );
  }
}
