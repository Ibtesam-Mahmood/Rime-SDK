import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import '../ChatMenu/fadeInUserImage.dart';
import '../ChatMenu/loading.dart';
import '../Messages/textMessage.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {

  ///Messages list
  List<String> messages = [];

  ///Controller for the easy refresh
  EasyRefreshController _refreshController;

  ///Controls the easyRefresh widget
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    messages = ['hello', 'Whats good'];
    print(messages.length);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: EasyRefresh.custom(
          controller: _refreshController,
          scrollController: _scrollController,
          reverse: true,
          footer: CustomFooter(
          extent: 40.0,
          triggerDistance: 50.0,
          footerBuilder: (context,
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
            return Stack(
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
            );
          }),
          //Build messages
          slivers: [
            SliverToBoxAdapter(
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                physics: BouncingScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, i){
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10, left: 16, bottom: 9),
                        child: Container(
                          height: 32,
                          width: 32,
                          child: ClipOval(
                            child: FadeInUserImage(
                              
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 12, bottom: 5),
                            child: Text('Killua'),
                          ),
                          TextMessage(message: messages[i])
                        ],
                      )
                    ],
                  );
                },
              )
            )
          ],
          //TODO: Implement onLoad
        //   onLoad: () async {
        //   if (mounted) {
        //     Completer _onSuccess = Completer();
        //     ChatBloc().add(LoadMoreMessages(widget.chatID, (){
        //       _onSuccess.complete(null);
        //     }));
        //     await _onSuccess.future;
        //   }
        // }
      ),
      //TODO: Implement time message was sent animation
      //Swipe left animation
      // onPanUpdate: (value){
      //   if(25>value.delta.dx){
      //     setState(() {
      //       xOffset = 50;
      //     });
      //   }
      // },
      // //On swipe end
      // onPanEnd: (value){
      //   setState(() {
      //     xOffset = 0;
      //   });
      // },
    );
  }
}