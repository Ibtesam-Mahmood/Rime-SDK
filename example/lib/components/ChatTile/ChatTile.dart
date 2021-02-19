import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../api/endpoints/pollApi.dart';
import '../../api/endpoints/postApi.dart';
import '../../api/endpoints/topicApi.dart';
import '../../api/endpoints/userInfoApi.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../models/poll.dart';
import '../../models/post.dart';
import '../../models/topics.dart';
import '../../models/userInfo.dart';
import '../../pages/chatSDK/ChatPage.dart';
import '../../state/chat/chatBloc.dart';
import '../../state/chat/chatState.dart';
import '../../state/store/pollarStoreBloc.dart';
import '../../util/colorProvider.dart';
import '../../util/globalFunctions.dart';
import '../../util/pollar_icons.dart';
import '../widgets/wrapped_list_tile.dart';

class ChatTile extends StatefulWidget {
  const ChatTile({
    Key key,
    @required this.chat, this.actions = const [],
  }) : super(key: key);

  final Chat chat;
  final List<Widget> actions;

  @override
  _ChatTileState createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  List<UserInfo> loadedChatUsers;
//TextPainer
  TextPainter tp;

  ///The chat name
  String get chatName{

    if(widget.chat?.chatName?.isNotEmpty == true){
      return widget.chat.chatName;
    }

    else if((loadedChatUsers?.length ?? 0) == 1){
      return '${loadedChatUsers[0].firstName} ${loadedChatUsers[0].lastName}';
    }

    else if((loadedChatUsers?.length ?? 0) >= 2){
      return '${loadedChatUsers[0].firstName} and ${loadedChatUsers.length - 1} other';
    }

    return '';

  }

  @override
  void initState() {
    super.initState();

    UserInfoApi.getBatchUserInfoById(widget.chat.users).then((users) {
      if (mounted)
        {setState(() {
          loadedChatUsers = users;
          
        });}
    });
  }

  Future<String> findMessagePreview(List<ChatMessage> messages, int mIndex) async {

    //Empty message
    if (mIndex == -1) {
      return '';
    }

    String preview =
        ' · ' + PollarFunctions.formatTime(messages[mIndex].timeToken);

    //TextMessage preview
    if (messages[mIndex] is TextMessage) {
      if ((messages[mIndex] as TextMessage).text.length >= 31) {
        //Long message
        return (messages[mIndex] as TextMessage).text.substring(0, 31) +
            '...' +
            preview;
      } else {
        //Short message
        return (messages[mIndex] as TextMessage).text + preview;
      }
    }

    //Image message preview
    else if (messages[mIndex] is ImageMessage &&
        messages[mIndex].clientID != PollarStoreBloc().loggedInUserID) {
      //Sent by chat user
      return 'Sent a photo' + preview;
    } else if (messages[mIndex] is ImageMessage &&
        messages[mIndex].clientID == PollarStoreBloc().loggedInUserID) {
      //Sent by you
      return 'You sent a photo' + preview;
    }

    //Gif message preview
    else if (messages[mIndex] is GifMessage &&
        messages[mIndex].clientID != PollarStoreBloc().loggedInUserID) {
      //Sent by chat user
      return 'Sent a GIF' + preview;
    } else if (messages[mIndex] is GifMessage &&
        messages[mIndex].clientID == PollarStoreBloc().loggedInUserID) {
      //Sent by you
      return 'You sent a GIF' + preview;
    }

    //Story Message preview
    else if (messages[mIndex] is StoryMessage) {
      Poll loadedPoll =
          await PollApi.getPollById((messages[mIndex] as StoryMessage).pollID);
      UserInfo pollUser =
          await UserInfoApi.getUserInfoFromId(loadedPoll.userInfoId);

      preview =
          ' Poll by ${pollUser?.firstName ?? ''} ${pollUser?.lastName ?? ''}' +
              preview;

      if (messages[mIndex].clientID != PollarStoreBloc().loggedInUserID) {
        //Other user
        preview = 'Sent a' + preview;
      } else {
        //Your user
        preview = 'You sent a' + preview;
      }

      return preview;
    }

    //Post Message preview
    else if (messages[mIndex] is PostMessage) {
      Post loadedPost =
          await PostApi.getPostById((messages[mIndex] as PostMessage).postID);
      UserInfo postUser =
          await UserInfoApi.getUserInfoFromId(loadedPost.userInfoId);

      preview =
          ' Post by ${postUser?.firstName ?? ''} ${postUser?.lastName ?? ''}' +
              preview;

      if (messages[mIndex].clientID != PollarStoreBloc().loggedInUserID) {
        //Other user
        preview = 'Sent a' + preview;
      } else {
        //Your user
        preview = 'You sent a' + preview;
      }

      return preview;
    }

    //Poll Message preview
    else if (messages[mIndex] is PollMessage) {
      Poll loadedPoll =
          await PollApi.getPollById((messages[mIndex] as PollMessage).pollID);
      UserInfo pollUser =
          await UserInfoApi.getUserInfoFromId(loadedPoll.userInfoId);

      preview =
          ' Poll by ${pollUser?.firstName ?? ''} ${pollUser?.lastName ?? ''}' +
              preview;

      if (messages[mIndex].clientID != PollarStoreBloc().loggedInUserID) {
        //Other user
        preview = 'Sent a' + preview;
      } else {
        //Your user
        preview = 'You sent a' + preview;
      }

      return preview;
    }

    //Profile Message View
    else if (messages[mIndex] is ProfileMessage) {
      UserInfo profileUser = await UserInfoApi.getUserInfoFromId(
          (messages[mIndex] as ProfileMessage).userID);

      preview =
          " ${profileUser?.firstName ?? ''} ${profileUser?.lastName ?? ''}'s profile" +
              preview;

      if (messages[mIndex].clientID != PollarStoreBloc().loggedInUserID) {
        //Other user
        preview = 'Sent' + preview;
      } else {
        //Your user
        preview = 'You sent' + preview;
      }

      return preview;
    }

    //Topic Message View
    else if (messages[mIndex] is TopicMessage) {
      Topic topic = await TopicApi.getTopicById(
          (messages[mIndex] as TopicMessage).topicID);

      preview = ' the topic ${topic?.name ?? ''}' + preview;

      if (messages[mIndex].clientID != PollarStoreBloc().loggedInUserID) {
        //Other user
        preview = 'Sent' + preview;
      } else {
        //Your user
        preview = 'You sent' + preview;
      }

      return preview;
    }

    //If the last message wasn't one of those for example a delete message or a read message then find the next nearest message
    //That contains content
    else {
      return await findMessagePreview(messages, mIndex - 1);
    }
  }

  Future<Topic> loadTopic(String topicID) async {
    return await TopicApi.getTopicById(topicID);
  }

  

  @override
  Widget build(BuildContext context) {
    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    //App color styles
    final appColor = ColorProvider.of(context);

    return BlocBuilder<ChatBloc, ChatState>(
      bloc: ChatBloc(),
      builder: (context, state){
        return Slidable(
          actionExtentRatio: 0.13,
          actionPane: SlidableScrollActionPane(),
          key: Key('Slidable - ChatTile - ${widget.chat.id}'),
          secondaryActions: widget.actions,
          child: WrappedListTile(

            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

            //On Tapped
            onTap: () {
              if(widget.chat != null){
                Chat currentChat = state[widget.chat.id];
                // NavStack().push(ChatPage(key: UniqueKey(), chatModel: currentChat));
              }
            },

            //Leading image
            // leading: loadedChatUsers != null ? OverlappingProfilePicture(
            //   bottomImage: widget.chat.chatImage?.isEmpty == false ? widget.chat.chatImage : loadedChatUsers[0]?.profilePicture,
            //   topImage: loadedChatUsers.length > 1 && widget.chat.chatImage?.isEmpty != false ? loadedChatUsers[1]?.profilePicture : null,
            //   imageSize: 40,
            //   height: 50,
            //   width: 50,
            // ) : SizedBox.shrink(),

            //Chat title
            title: chatName,

            //Message preview
            subtitle: widget.chat.messages != null ? FutureBuilder<String>(
              future: findMessagePreview(widget.chat.messages, widget.chat.messages.length-1),
              builder: (context, snapshot) {
                return Text(
                  snapshot?.data ?? '',
                  style: textStyles.subtitle1.copyWith(
                    fontWeight: widget.chat.read ? FontWeight.normal : FontWeight.w600,
                    color: widget.chat.read ? appColor.grey : appColor.onBackground
                  ),
                );
              }
            ) : SizedBox.shrink(),

            //Read bubble/ mute icon
            trailing: SizedBox(
              height: 12,
              width: 12,
              child: Stack(
                children: [

                  if(!widget.chat.read && widget.chat.muteChat[PollarStoreBloc().loggedInUserID])
                    Container(
                      decoration: BoxDecoration(
                        color: appColor.blue,
                        shape: BoxShape.circle
                      ),
                    ),

                  if(!widget.chat.read && !widget.chat.muteChat[PollarStoreBloc().loggedInUserID])
                    FittedBox(
                      fit: BoxFit.contain,
                      child: Icon(
                        PollarIcons.chat_muted_notification,
                        color: appColor.blue,
                      ),
                    ),

                  if(widget.chat.read && !widget.chat.muteChat[PollarStoreBloc().loggedInUserID])
                    FittedBox(
                      fit: BoxFit.contain,
                      child: Icon(
                        PollarIcons.chat_muted,
                        color: appColor.dark,
                      ),
                    )
                ],
              ),
            ),
        ),
        );
      }
    );
  }
}
