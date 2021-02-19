import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

import '../../models/chat.dart';
import '../../models/message.dart';
import '../../models/userInfo.dart';
import '../../state/chat/chatBloc.dart';
import '../../state/chat/chatEvent.dart';
import '../../state/chat/chatState.dart';
import '../../state/store/pollarStoreBloc.dart';
import '../../util/colorProvider.dart';
import '../widgets/pollarLoading.dart';

class MessageScreen extends StatefulWidget {
  MessageScreen({
    Key key,
    @required this.user,
    @required this.chatID,

  }) : super(key: key);

  final List<UserInfo> user;
  final String chatID;

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> with TickerProviderStateMixin {

  //Duration of chatMessage sending
  final Duration sendMessageDuration = Duration(milliseconds: 200);

  //Controls the easyRefresh widget
  final ScrollController _scrollController = ScrollController();

  //If the delivered tag should be displayed or not
  ChatMessage delivered;

  //Initial offset in the x direction for messages
  double xOffset = 0;

  ///The chat model
  Chat chat;

  ///Messages list
  List<ChatMessage> messages = [];

  //If the read message has already been displayed
  ChatMessage read;

  //Incoming messages to be animated
  final Map<int, Tuple2<ChatMessage, AnimationController>> _incomingMessages = {};

  ///Animation for the typing message
  AnimationController typingAnimation;

  ///The current typing user
  String typingUser;

  ///Controller for the easy refresh
  EasyRefreshController _refreshController;

  @override
  void initState(){
    super.initState();

    _refreshController = EasyRefreshController();

    typingAnimation = AnimationController(
      vsync: this,
      duration: sendMessageDuration
    );

    //Initial messages
    chat = ChatBloc().state[widget.chatID];

    //Populate messages
    compareAdd([...(chat?.messages ?? [])]);

    //Set delivered tag
    delivered = findDeliveredTag(ChatBloc().state[widget.chatID]?.messages);

    //Set read message tag
    read = findReadMessageTag(ChatBloc().state[widget.chatID]?.messages);
  }

  @override
  void dispose() {

    _refreshController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  ///Updates the typing state of the chat screen based on the chat object and current state
  void updateTypingPresence(Chat chat){
    if(chat.typing.isNotEmpty && typingUser == null){
      typingAnimation.forward();
      setState(() {
        typingUser = chat.typing.first;
      });
    }
    else if(chat.typing.isNotEmpty){
      setState(() {
        typingUser = chat.typing.first;
      });
    }
    else if(typingUser != null && chat.typing.isEmpty){
      typingAnimation.reverse().then((_){
        setState(() {
          typingUser = null;
        });
      });
    }
  }

  ///Adds new or old items to the list
  void compareAdd(List<ChatMessage> other){
    if(other.isNotEmpty && _incomingMessages.containsKey(other.last.hashCode)){
      return;
    }
    else if(other.length > messages.length){
      if(messages.isNotEmpty && other.last.id != messages.last.id){
        //defines the new animation controller
        AnimationController controller = AnimationController(
          duration: sendMessageDuration,
          vsync: this
        );
        final tuple = Tuple2(other.last, controller);
        messages = [...other];
        _incomingMessages[tuple.item1.hashCode] = tuple;
        controller.forward().then<void>((_){
          controller.dispose();
          _incomingMessages.remove(tuple.item1.hashCode);
          if(mounted) setState((){});
        });
      }
      else{
        messages = [...other];
      }
    }
  }
    
  //Used to split the text Message up into individual words so a link can be verified
  dynamic _verifyLink(TextMessage msg){
    final words = msg.text.split(' ');
    var wordHolder;
    words.forEach((word) async{
      if(_isLink(word)){
        wordHolder = word;
      }
    });
    return wordHolder;
  }

  //Used to verify a link in the chat
  bool _isLink(String input) {
    final matcher =  RegExp(
        r'(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)');
    return matcher.hasMatch(input);
  }

  ChatMessage findDeliveredTag(List<ChatMessage> messages){
    if(messages != null){
      for(int i = messages.length - 1; i >= 0; i--){
        if(messages[i] is ReadMessage ){
          return null;
        }
        else if(!(messages[i] is ReadMessage) && !(messages[i] is SettingMessage) && !(messages[i] is DeleteMessage) && messages[i].clientID == PollarStoreBloc().loggedInUserID && i == messages.length - 1 && messages[i].delivered){
          return messages[i];
        }
        else if(i != messages.length - 1){
          if(!(messages[i] is ReadMessage) && !(messages[i] is SettingMessage) && !(messages[i] is DeleteMessage) && messages[i].clientID == PollarStoreBloc().loggedInUserID && !(messages[i + 1] is ReadMessage) && messages[i].delivered == true){
            return messages[i];
        }
        }
      }
    }
    return null;
  }

  ChatMessage findReadMessageTag(List<ChatMessage> messages){
    if(messages != null){
      for(int i = messages.length - 1; i > 0; i--){
        if(messages[i] is ReadMessage && messages[i].clientID != PollarStoreBloc().loggedInUserID){
          return messages[i - 1];
        }
      }
    }
    return null;
  }

  //Builds the appropriate message depending on the type of message received
  Widget buildMessage(ChatMessage message, int index, bool isGroup, double dx, Animation<double> animation){

    //Color provider
    final appColors = ColorProvider.of(context);

    //Custom text style
    TextStyle textStyle = TextStyle(fontSize: 11, letterSpacing: 0.1, height: 1.182, color: appColors.grey, fontWeight: FontWeight.normal);

    //WordHolder
    var wordHolder;

    //Finds out if the message is a link so it can be displayed properly on the chat screen
    if(message is TextMessage){
        wordHolder = _verifyLink(message);
    }

    bool displayDeliveredTag = false;

    bool displayReadMessage = false;

    if(delivered == message){
      displayDeliveredTag = true;
    }

    if(message == read){
      setState(() {
        displayDeliveredTag = false;
        displayReadMessage = true;
      });
    }

    if(!(message is ReadMessage)){
      if(index != messages.length - 1 && index != 0 ){
        return Column(
          children:[ Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: decodeWidget(message, messages[index + 1], messages[index - 1], displayReadMessage ? messages[index + 1] : null, isGroup, wordHolder, displayDeliveredTag, animation)
              ),
              !(message is DateMessage) && !(message is SettingMessage) ? Padding(
                padding: EdgeInsets.only(bottom: displayDeliveredTag || displayReadMessage ? 26 : 0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 10,
                    maxHeight: 10,
                  ),
                  child: AnimatedContainer(
                    curve: Curves.easeOutQuad,
                    duration: Duration(milliseconds: 300),
                    width: dx.abs() > 0 ? dx.abs() + 10 : dx.abs(),
                    child: !(message is ReadMessage) ? Text(DateFormat('h:mm a').format(message.timeToken), overflow: TextOverflow.visible, softWrap: false, style: textStyle) : Container(),
                  ),
                ),
              ) : Container()
            ],
          ),] 
        );
      }
      else if(index == 0){
        return Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: messages.length > 1 ? decodeWidget(message, messages[index + 1], null, null, isGroup, wordHolder, displayDeliveredTag, animation) : decodeWidget(message, null, null, null, isGroup, wordHolder, displayDeliveredTag, animation)
                ),
                !(message is DateMessage) && !(message is SettingMessage) ? Padding(
                  padding: EdgeInsets.only(bottom: displayDeliveredTag || displayReadMessage ? 26 : 0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 10,
                      maxHeight: 10
                    ),
                    child: AnimatedContainer(
                      curve: Curves.easeOutQuad,
                      duration: Duration(milliseconds: 300),
                      width: dx.abs() > 0 ? dx.abs() + 10 : dx.abs(),
                      child: !(message is ReadMessage) ? Text(DateFormat('h:mm a').format(message.timeToken), overflow: TextOverflow.visible, softWrap: false, style: textStyle,) : Container(),
                    ),
                  ),
                ) : Container()
              ],
            ),
          ],
        );
      }
      else if(index == messages.length - 1){
        return Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: decodeWidget(message, null, messages[index - 1], displayReadMessage ? messages[index - 1] : null, isGroup, wordHolder, displayDeliveredTag, animation)
                ),
                !(message is DateMessage) && !(message is SettingMessage) ? Padding(
                  padding: EdgeInsets.only(bottom: displayDeliveredTag || displayReadMessage ? 26 : 0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 10,
                      maxHeight: 10,
                    ),
                      child: AnimatedContainer(
                      curve: Curves.easeOutQuad,
                      duration: Duration(milliseconds: 300),
                      width: dx.abs() > 0 ? dx.abs() + 10 : dx.abs(),
                      child: !(message is ReadMessage) ? Text(DateFormat('h:mm a').format(message.timeToken), overflow: TextOverflow.visible, softWrap: false, style: textStyle) : Container(),
                    ),
                  ),
                ) : Container()
              ],
            ),
          ],
        );
      }
      else{
        return Container();
      }
    }
    else{
      return Container();
    }
  }


  // Widget decodeWidget(ChatMessage message, ChatMessage nextMessage, ChatMessage previousMessage, ChatMessage readMessage, bool isGroup, dynamic wordHolder, bool delivered, Animation<double> animation) {
  //   if(message is TextMessage){
  //     return TextMessageView(key: Key('text - message - ${message.timeToken.toString()} - ${message.clientID}'), wordHolder: wordHolder, message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation);}
  //   else if(message is ImageMessage){
  //     return ImageMessageView(key: Key('image - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation);}
  //   else if(message is LocalImage){
  //     return LocalImageMessageView(key: Key('localImage - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation,);}
  //   else if(message is GifMessage){
  //     return GifMessageView(key: Key('gif - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation,);}
  //   else if(message is PollMessage){
  //     return PollMessageView(key: Key('poll - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation,);}
  //   else if(message is PostMessage){
  //     return PostMessageView(key: Key('post - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation,);}
  //   else if(message is StoryMessage){
  //     return StoryMessageView(key: Key('story - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation);}
  //   else if(message is TopicMessage){
  //     return TopicMessageView(key: Key('topic - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation,);}
  //   else if(message is ProfileMessage){
  //     return ProfileMessageView(key: Key('profile - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation,);}
  //   else if(message is DateMessage){
  //     return DateMessageView(key: Key('date - message - ${message.timeToken.toString()} - ${message.clientID}'), dateTime: message.timeToken);}
  //   else if(message is ReadMessage){
  //     return ReadMessageView(key: Key('read - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, animation: animation,);}
  //   else if(message is SettingMessage){
  //     return SettingMessageView(key: Key('setting - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message);}
  //   else if(message is VideoMessage){
  //     return VideoMessageView(key:  Key('video - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation);}
  //   else if(message is LocalVideoMessage){
  //     return LocalVideoView(key:  Key('localVideo - message - ${message.timeToken.toString()} - ${message.clientID}'), message: message, nextMessage: nextMessage, previousMessage: previousMessage, readMessage: readMessage, isGroup: isGroup, delivered: delivered, animation: animation);}
  //   else{ return null;}
    
  // }

  @override
  Widget build(BuildContext context) {

    return BlocListener<ChatBloc, ChatState>(
        bloc: ChatBloc(),
        condition: (o, n) {
          return true;
        },
        listener: (context, state){

          // Send readMessage if the chat has not been read
          if(widget.chatID != 'DUMMY-${PollarStoreBloc().loggedInUserID}'){
            if(!state.chats[widget.chatID].read){
              ChatBloc().add(MessageEvent(widget.chatID, ReadMessage(clientID: PollarStoreBloc().loggedInUserID, enabled: state.chats[widget.chatID].sendReadReceipts[PollarStoreBloc().loggedInUserID], delivered: false, timeToken: DateTime.now())));
            }
          }

          // Find the delivered message tag
          if((state[widget.chatID]?.messages?.length ?? 0) != 0){
            delivered = findDeliveredTag(state[widget.chatID]?.messages);
          }

          // Find the read message tag
          if((state[widget.chatID]?.messages?.last is ReadMessage) && state[widget.chatID]?.messages?.last?.clientID != PollarStoreBloc().loggedInUserID){
            setState(() {
              read = findReadMessageTag(state[widget.chatID]?.messages);
            });
          }

          // updates the messages and chat model
          if(state[widget.chatID]?.messages?.length != messages?.length){
            setState(() {
              compareAdd(state[widget.chatID]?.messages);
            });
          }
          
          //Update chat object
          if(state[widget.chatID] != null){
            setState(() {
              chat = state[widget.chatID];
            });
            updateTypingPresence(state[widget.chatID]);
          }

        },
        child: GestureDetector(
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
                          child: PollarLoading()
                        ),
                      ),
                    ),
                  ],
                );
              }),
              //Build messages
              slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        for(int i = 0; i < messages.length; i++)
                          buildMessage(messages[i], i, chat.groupChat, xOffset, _incomingMessages[messages[i].hashCode]?.item2?.view ?? kAlwaysCompleteAnimation),
                        if(typingUser != null) TypingMessageView(user: typingUser, animation: typingAnimation)
                      ],
                    )
                  )
                ],
              onLoad: () async {
              if (mounted) {
                Completer _onSuccess = Completer();
                ChatBloc().add(LoadMoreMessages(widget.chatID, (){
                  _onSuccess.complete(null);
                }));
                await _onSuccess.future;
              }
            }
      ),
      //Swipe left animation
      onPanUpdate: (value){
        if(25>value.delta.dx){
          setState(() {
            xOffset = 50;
          });
        }
      },
      //On swipe end
      onPanEnd: (value){
        setState(() {
          xOffset = 0;
        });
      },
    ),
    );
  }
} 