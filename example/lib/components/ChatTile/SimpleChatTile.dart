import 'package:flutter/material.dart';

import '../../api/endpoints/userInfoApi.dart';
import '../../models/chat.dart';
import '../../models/userInfo.dart';
import '../../util/colorProvider.dart';


///SimpleChatTile displays the chat name, the user names in the chat and the chat picture
class SimpleChatTile extends StatefulWidget {
  ///The chat to be displayed
  final Chat chat;

  ///Custom trailing widget
  final Widget trailing;

  ///Optional onpressed clal back function
  final Function() onPressed;

  const SimpleChatTile(
      {Key key, @required this.chat, this.trailing, this.onPressed})
      : assert(chat != null),
        super(key: key);

  @override
  _SimpleChatTileState createState() => _SimpleChatTileState();
}

class _SimpleChatTileState extends State<SimpleChatTile> {
  ///List of users in the chat
  List<UserInfo> chatUsers;
//TextPainer
  TextPainter tp;

  ///Resolves the chat name
  String get chatName {
    if (widget.chat.chatName?.isNotEmpty == true) {
      //Use chat name
      return widget.chat.chatName;
    } else if (chatUsers != null) {
      if (chatUsers.length == 1) {
        //Single user, use user's name
        return '${chatUsers[0].firstName ?? ''} ${chatUsers[0].lastName ?? ''}';
      } else if (chatUsers.length > 1) {
        //Combine user names
        String chatName = '';
        for (UserInfo user in chatUsers) {
          chatName += '${user.firstName ?? ''} ${user.lastName ?? ''}';
          if (chatUsers.indexOf(user) < chatUsers.length - 1) {
            chatName += ',';
          }
          chatName += ' ';
        }
        return chatName;
      }
    }

    //Default empty
    return '';
  }

  String chatUserNames(
      BuildContext context, AppColor appColors, TextTheme textStyles) {
    if (chatUsers != null) {
      if (chatUsers.length == 1) {
        //Single user, use user's name
        return '${chatUsers[0].username ?? ''}';
      } else if (chatUsers.length > 1) {
        double width = MediaQuery.of(context).size.width * .5;
        //Combine user names
        String temp = '';
        String temp2 = '';
        String chatName = temp;

        for (int i = 0; i < chatUsers.length; i++) {
          temp +=
              '${chatUsers[i].username ?? ''}${i == chatUsers.length - 1 ? '' : ','} ';
          temp2 = temp + ('and ${chatUsers.length - i - 1} more');
          
          TextSpan span = TextSpan(
            text: temp2,
            style: textStyles.caption.copyWith(color: appColors.grey),
          );
          tp = TextPainter(
            text: span,
            maxLines: 1,
            textDirection: TextDirection.ltr,
          );
          //Calculates max lines based off the width of the screen
          tp.layout(maxWidth: width, minWidth: width);
          if (tp.didExceedMaxLines) {
            return chatName;
          } else {
            chatName = temp2;
          }
        }
        return chatName;
      }
    }
    //Default empty
    return '';
  }

  @override
  void initState() {
    super.initState();

    //Retreives the chat users to display any info
    UserInfoApi.getBatchUserInfoById(widget.chat.users).then((value) {
      if (mounted)
       { setState(() {
          chatUsers = value;
        });}
    });
  }

  @override
  Widget build(BuildContext context) {
    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return ListTile(
      //Chat picture
      // leading: chatUsers == null
      //     ? null
      //     : OverlappingProfilePicture(
      //         bottomImage: widget.chat.chatImage?.isEmpty == false
      //             ? widget.chat.chatImage
      //             : chatUsers[0]?.profilePicture,
      //         topImage: chatUsers.length > 1 &&
      //                 widget.chat.chatImage?.isEmpty != false
      //             ? chatUsers[1]?.profilePicture
      //             : null,
      //         imageSize: 40,
      //         width: 50,
      //         height: 50,
      //       ),

      //Chat name
      title: Text(
        chatName,
        style: textStyles.bodyText2.copyWith(color: appColors.onBackground),
      ),

      subtitle: Text(
        chatUserNames(context, appColors, textStyles),
        maxLines: 1,
        style: textStyles.caption.copyWith(color: appColors.grey),
      ),

      //Custom trailing
      trailing: widget.trailing,

      //On tap
      onTap: widget.onPressed,
    );
  }
}
