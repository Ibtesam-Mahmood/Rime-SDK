import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/chat.dart';
import '../../models/message.dart';
import '../../models/userInfo.dart';
import '../../state/chat/chatBloc.dart';
import '../../state/chat/chatEvent.dart';
import '../../state/chat/chatState.dart';
import '../../state/store/pollarStoreBloc.dart';
import '../../util/colorProvider.dart';
import '../../util/globalFunctions.dart';
import '../widgets/horizontalBar.dart';
import '../widgets/notch.dart';
import 'NewChatSheet.dart';

class EditGroupChat extends StatefulWidget {
  //Chat opject passed in when EditGroupChat is opened
  final Chat chat;
  //List of users corresponding to the chat
  final List<UserInfo> users;

  EditGroupChat({this.chat, this.users});
  @override
  _EditGroupChatState createState() => _EditGroupChatState();
}



class _EditGroupChatState extends State<EditGroupChat> {

  ///Focus scope for the text field
  ///On un focus saves the group chat name
  FocusNode _fn;

  ///The text editting controller for textfield
  TextEditingController _textController;

  String text = '';

  @override
  void initState(){
    super.initState();

    //Sets the innital text to the chat name
    _textController = TextEditingController(text: chatName(widget.chat));

    //adds a litener to the focus node
    _fn = FocusNode()
      ..addListener(() {
        if(!_fn.hasFocus){
          //Update group chat name on unfocus
          updateGroupChatName();
        }
        setState(() {});
      });
  }

  @override
  void dispose(){

    _textController.dispose();
    _fn.dispose();

    super.dispose();
  }

  ///Updates the group chat name when the text field is filled out
  void updateGroupChatName(){
    
    //new group chat name
    String newName = _textController.text;

    if(newName.isNotEmpty){
      //Set name
      ChatBloc().add(EditChatEvent(widget.chat.id, Chat(
        chatName: newName
      )));

      if(text != _textController.text){
        ChatMessage message = SettingMessage(
          clientID: PollarStoreBloc().loggedInUserID,
          timeToken: DateTime.now(),
          delivered: false,
          settingMessage: 'named the group $newName'
        );

        ChatBloc().add(MessageEvent(widget.chat.id, message));

        setState(() {
          text = _textController.text;
        });
        
      }

    }
    else{
      //Reset name to previous
      setState(() {
        _textController.text = chatName(ChatBloc().state[widget.chat.id]);
      });
    }

  }

  ///Opens the `New Chat Sheet` to create a dummy chat and add those users to the group chat
  void addUserToChat(Chat currentChat, final textStyles, final appColors){

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NewChatSheet(
        removedUsers: currentChat.users,
        confirmation: (_) async => await PollarDisplay.showConfirmDialog(
          context,
          title: Text('Add Users to Group', style: textStyles.headline4.copyWith(fontWeight: FontWeight.bold),),
          description: 'Add the following users to this group chat?',
          confirmButton: 'Add',
          cancelButton: 'Cancel',
          confirmButtonColor: appColors.blue,
          cancelButtonColor: appColors.surface,
          confirmButtonTextColor: Colors.white,
          cancelButtonTextColor: Colors.black
        ),
        onCreate: (chat, _){
          //Retreive the users from the dummy chat and add them to the group
          ChatBloc().add(EditChatEvent(currentChat.id, Chat(
            users: currentChat.users..addAll(chat.users)
          )));
        },
      ),
    );

  }

  ///Resolves the chat name
  String chatName(Chat stateChat) {
    if(stateChat.chatName?.isNotEmpty == true){
      //Use chat name
      return stateChat.chatName;
    }

    //Default
    return 'Group Name';
  }

  
  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),

      child: BlocBuilder<ChatBloc, ChatState>(
        bloc: ChatBloc(),
        builder: (context, state) {
          
          //Current chat streamed from chat state
          Chat currentChat = state[widget.chat.id];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              //Draggable notch
              DragNotch(),

              //Chat name bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    //Chat name
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: TextField(
                          controller: _textController,
                          focusNode: _fn,
                          style: textStyles.headline3.copyWith(color: appColors.onBackground),
                          onSubmitted: (_) => updateGroupChatName(),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: chatName(currentChat),
                            hintStyle: textStyles.headline3.copyWith(color: appColors.grey.withOpacity(0.24))
                          ),
                        ),
                      ),
                    ),

                    // PollarFixButton(
                    //   text: 'Edit picture',
                    //   color: appColors.grey.withOpacity(0.07),
                    //   textColor: appColors.onBackground,
                    //   onPress: (){
                    //     //edit group chat image
                    //     NavStack().push(ChangePicturePage(onConfirm: (image, asset) async {

                    //       //Convert asset into byte data
                    //       if(asset != null && image != null){
                    //         String encodedImage = jsonEncode({
                    //           'file': 'thumbnail-' + asset.title,
                    //           'encoding': base64Encode(image.readAsBytesSync())
                    //         });
                    //         // foo() async {
                    //         ChatBloc().add(EditChatEvent(widget.chat.id, Chat(
                    //           chatImage: encodedImage
                    //         )));
                    //         // }

                    //         // foo();
                    //       }

                    //     },));

                    //     ChatMessage message = SettingMessage(
                    //       clientID: PollarStoreBloc().loggedInUserID,
                    //       timeToken: DateTime.now(),
                    //       delivered: false,
                    //       settingMessage: 'changed the group photo'
                    //     );

                    //     ChatBloc().add(MessageEvent(widget.chat.id, message));
                    //   },
                    // )

                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 19),
                child: HorizontalBar(color: appColors.grey.withOpacity(0.07), width: 0.5,),
              ),

              // Expanded(
              //   child: ListView.builder(
              //     itemCount: currentChat.users.length + 1,
              //     scrollDirection: Axis.horizontal,
              //     itemBuilder: (context, index) {
              //       //Initial widget is an add button
              //       if(index == 0){
              //         return Padding(
              //           padding: const EdgeInsets.symmetric(horizontal: 24),
              //           child: NeuFloatingActionButton(
              //             color: appColors.surface,
              //             child: Icon(PollarIcons.add, color: appColors.blue,),
              //             onPressed: (){
              //               //open new chat sheet to retreive new users
              //               addUserToChat(currentChat, textStyles, appColors);
              //             },
              //           ),
              //         );
              //       }

              //       return Padding(
              //         padding: const EdgeInsets.only(right: 10.0),
              //         child: ProfileCardBuilder(
              //           userId: currentChat.users[index - 1],
              //           mode: ProfileCardMode.FOLLOW,
              //           onOptionsPress: (user){
              //             //open profile options
              //             showModalBottomSheet(
              //               context: context,
              //               builder: (context) => SimpleProfileOptions(user: user,),
              //               backgroundColor: Colors.transparent,
              //               isScrollControlled: true
              //             );
              //           },
              //         ),
              //       );
              //     },
              //   ),
              // ),

              // //TODO: mute chat
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: SettingsTile(
              //     toggle: true,
              //     title: 'Mute conversation',
              //     value: !state[widget.chat.id].muteChat[PollarStoreBloc().loggedInUserID],
              //     onToggle: (val){
              //       //toggle chat mute
              //       ChatBloc().add(EditChatEvent(widget.chat.id, Chat(
              //         channelID: widget.chat.id,
              //         muteChat: state[widget.chat.id].muteChat..[PollarStoreBloc().loggedInUserID] = !val
              //       )));
              //     },
              //   ),
              // ),

              // //Toggle send read receipts
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: SettingsTile(
              //     toggle: true,
              //     title: 'Send read receipts',
              //     value: currentChat.sendReadReceipts[PollarStoreBloc().loggedInUserID],
              //     onToggle: (toggle){
              //       //toggle send read receipts
              //       ChatBloc().add(EditChatEvent(widget.chat.id, Chat(
              //         sendReadReceipts: state[widget.chat.id].sendReadReceipts..[PollarStoreBloc().loggedInUserID] = toggle
              //       )));
              //     },
              //   ),
              // ),

              // Padding(
              //   padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              //   child: PollarRoundedButtonBar(
              //     firstSpec: PollarRoundedButtonSpec(
              //       text: 'Leave',
              //       color: appColors.grey.withOpacity(0.07),
              //       textColor: appColors.onBackground,
              //       onPressed: () async {
              //         //Shows confirmation to leave group
              //         bool confirm  = await PollarDisplay.showConfirmDialog(
              //           context,
              //           title: Text('Leave conversion?', style: textStyles.headline4.copyWith(fontWeight: FontWeight.bold),),
              //           description: "You won't get messages from this group unless someone adds you back to the conversation.",
              //           confirmButton: 'Leave',
              //           cancelButton: 'Cancel',
              //           confirmButtonColor: appColors.red,
              //           cancelButtonColor: appColors.surface,
              //           confirmButtonTextColor: Colors.white,
              //           cancelButtonTextColor: Colors.black
              //         );

              //         if(confirm){
              //           //leave group
              //           ChatBloc().add(LeaveEvent(widget.chat.id));
              //           Navigator.pop(context, true);
              //         }
              //       }
              //     ),
              //     secondSpec: PollarRoundedButtonSpec(
              //       text: 'Delete',
              //       color: appColors.red,
              //       textColor: Colors.white,
              //       onPressed: () async {
              //         //Shows confirmation to delete chat
              //         bool confirm  = await PollarDisplay.showConfirmDialog(
              //           context,
              //           title: Text('Delete conversation?'),
              //           description: "Deleting removes the conversation from your inbox, but no one else's inbox.",
              //           confirmButton: 'Delete',
              //           cancelButton: 'Cancel',
              //           confirmButtonColor: appColors.red,
              //           cancelButtonColor: appColors.surface,
              //           confirmButtonTextColor: Colors.white,
              //           cancelButtonTextColor: Colors.black
              //         );

              //         if(confirm){
              //           //Deletes chat messages
              //           ChatBloc().add(DeleteEvent(widget.chat.id));
              //           Navigator.pop(context, true);
              //         }
              //       }
              //     ),
              //   ),
              // ),

            ],
          );
        }
      ),
    );
  }
}