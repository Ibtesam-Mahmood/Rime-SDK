import 'dart:ui';

import 'package:example/components/ChatMenu/newChatSheet.dart';
import 'package:example/pages/Chat/ChatPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/state/rime_bloc/rime_bloc.dart';
import 'package:rime/state/rime_bloc/rime_bloc_state.dart';
import '../../components/ChatMenu/loading.dart';
import '../../components/ChatMenu/searchFiled.dart';
import '../../components/ChatMenu/chatMenuHeader.dart';
import '../../components/ChatMenu/chatList.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      body: RimeMessagesMenu(),
      //Create new chat app bar
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: GestureDetector(
              onTap: () {
                //Opens the new chat sheet
                showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return NewChatSheet(
                        onCreate: (chat, isNew) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatPage(rimeChannelID: chat.channel,)));
                        },
                      );
                    });
              },
              child: Container(
                height: kToolbarHeight,
                color: Colors.white,
                child: Center(
                  child: Text('New Message',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class RimeMessagesMenu extends StatefulWidget {
  ///Widget to display while loading for `EasyRefresh`
  final Widget loading;
  ///Widget to display
  final Widget chatListHeader;
  ///`Color` for scroll view container 
  final Color scrollViewContainerCover;

  ///List of chats
  

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
    return BlocBuilder<RimeBloc, RimeState>(
      cubit: RimeBloc(),
      builder: (context, state) {
        
        if(state is RimeEmptyState) return Container();

        RimeLiveState liveState = state as RimeLiveState;

        //Organized channels
        List<RimeChannel> channels = liveState.orgainizedChannels.map<RimeChannel>((channel){
          return liveState.storedChannels[channel];
        }).toList();
        
        return EasyRefresh(
          bottomBouncing: false,
          onLoad: () {
            
          },
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
              ChatList(
                children: channels,
              )
            ],
          ),
        );
      });
  }
}
