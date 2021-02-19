import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api/endpoints/followApi.dart';
import '../../models/follow.dart';
import '../../models/userInfo.dart';
import '../../state/chat/chatBloc.dart';
import '../../state/chat/chatState.dart';
import '../../state/store/pollarStoreBloc.dart';
import '../../state/store/pollarStoreBlocBuilder.dart';
import '../../util/colorProvider.dart';
import '../widgets/fadeUserImage.dart';
import '../widgets/horizontalBar.dart';
import '../widgets/notch.dart';

class EditSingleChat extends StatefulWidget {
  //The individual user being talked to
  final UserInfo user;
  final String chatID;
  EditSingleChat({this.user, this.chatID});
  @override
  _EditSingleChatState createState() => _EditSingleChatState();
}

class _EditSingleChatState extends State<EditSingleChat> {
  //Variable relating to the cupertino button mute convo
  bool muteConvo = false;

  //If the user is blocked
  bool blocked;

  @override
  void initState() {
    super.initState();

    blocked = PollarStoreBloc().loginSettings.blocked.contains(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return BlocBuilder<ChatBloc, ChatState>(
      bloc: ChatBloc(),
      condition: (o, n) => false,
      builder: (context, state){
        return Container(
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(16)
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              
              //Draggable notch
              DragNotch(),

              //User information
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    //Profile image
                    ClipOval(
                      child: Container(
                        height: 32,
                        width: 32,
                        child: FadeInUserImage(profileImg: widget.user.profilePicture,),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text('${widget.user.firstName} ${widget.user.lastName}', style: textStyles.headline5.copyWith(color: appColors.onBackground),),
                    ),

                    Spacer(),

                    //Follow button
                    StoreBuilder<UserInfo>(
                      subjectID: PollarStoreBloc().loggedInUserID,
                      dataLoad: [(id) async => await FollowApi.getFollowingByUserId(id)],
                      determinant: [(user) => user.following != null],
                      builder: (context, user, loaded){

                        //If the user if following that user
                        bool userFollowing;

                        if(loaded[0]){
                          userFollowing = Follow.searchFollowingByUserID(user.following, widget.user.id);
                        }
                        return Container();
                        // return PollarFixButton(
                        //   color: userFollowing == true ? appColors.grey.withOpacity(0.07) : appColors.blue,
                        //   text: userFollowing == true ? 'Following' : 'Follow',
                        //   textColor: userFollowing == true ? appColors.onBackground : Colors.white,
                        //   onPress: userFollowing == null ? (){} : (){
                        //     //Toggle user following
                        //     userFollowing ? FollowApi.unfollowUser(widget.user.id) : FollowApi.followUser(widget.user.id);
                        //   },
                        // );
                      },
                    )
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 19, top: 10),
                child: HorizontalBar(color: appColors.grey.withOpacity(0.07), width: 0.5,),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // child: SettingsTile(
                //   toggle: true,
                //   title: 'Mute conversation',
                //   value: !state[widget.chatID].muteChat[PollarStoreBloc().loggedInUserID],
                //   onToggle: (val){
                //     //toggle chat mute
                //     ChatBloc().add(EditChatEvent(widget.chatID, Chat(
                //       channelID: widget.chatID,
                //       muteChat: state[widget.chatID].muteChat..[PollarStoreBloc().loggedInUserID] = !val
                //     )));
                //   },
                // ),
              ),

              //Send read receipts section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // child: SettingsTile(
                //   title: 'Send read receipts',
                //   value: state[widget.chatID].sendReadReceipts[PollarStoreBloc().loggedInUserID],
                //   onChange: (val){
                //     //Toggles the chat value
                //     ChatBloc().add(EditChatEvent(widget.chatID, Chat(
                //       sendReadReceipts: state[widget.chatID].sendReadReceipts..[PollarStoreBloc().loggedInUserID] = val
                //     )));
                //   },
                // ),
              ),

              //Deactivate and logout button
              Padding(
                padding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[

                    // //Block button
                    // Expanded(
                    //   child: PollarRoundedButton(
                    //     borderRadius: 12,
                    //     text: blocked ? 'Unblock' : 'Block',
                    //     color: blocked ? appColors.red : appColors.grey.withOpacity(0.07),
                    //     textColor: blocked ? Colors.white : appColors.onBackground,
                    //     sizeVariation: SizeVariation.MEDIUM,
                    //     onPressed: () async {

                          
                    //       //Block or unblock User
                    //       if(blocked == null) return;

                    //       if(blocked){
                    //         BlockApi.unBlockUser(widget.user.id);
                    //         setState(() {
                    //           blocked = false;
                    //         });
                    //       }
                    //       else if(!blocked){

                    //         bool confirm = await PollarDisplay.showConfirmDialog(
                    //           context,
                    //           title: Text('Block ${widget.user.firstName} ${widget.user.lastName}?'),
                    //           description: "They won't be able to see your profile or posts on Pollar. We won't let them know you blocked them.",
                    //           confirmButton: 'Block',
                    //           cancelButton: 'Cancel',
                    //           confirmButtonColor: appColors.red,
                    //           cancelButtonColor: appColors.surface,
                    //           confirmButtonTextColor: Colors.white,
                    //           cancelButtonTextColor: Colors.black,
                    //         );

                    //         if(confirm){
                    //           BlockApi.blockUser(widget.user.id);
                    //           setState(() {
                    //             blocked = true;
                    //           });
                    //         }
                    //       }
                    //     }
                    //   ),
                    // ),

                    Padding(padding: const EdgeInsets.only(left: 16),),

                    //Delete chat
                    // Expanded(
                    //   child: PollarRoundedButton(
                    //     borderRadius: 12,
                    //     text: 'Delete',
                    //     color: appColors.red,
                    //     textColor: Colors.white,
                    //     sizeVariation: SizeVariation.MEDIUM,
                    //     onPressed: () async {
                    //       //Toggle delete chat value
                    //       bool confirm = await PollarDisplay.showConfirmDialog(
                    //         context,
                    //         title: Text('Delete conversation?', style: textStyles.headline4.copyWith(fontWeight: FontWeight.bold)),
                    //         description: "Deleting removes the conversation from your inbox, but no one else's inbox",
                    //         confirmButton: 'Delete',
                    //         cancelButton: 'Cancel',
                    //         confirmButtonColor: appColors.red,
                    //         cancelButtonColor: appColors.surface,
                    //         confirmButtonTextColor: Colors.white,
                    //         cancelButtonTextColor: Colors.black
                    //       );

                    //       if(confirm){
                    //         //Delets the chat messages
                    //         ChatBloc().add(DeleteEvent(widget.chatID));
                    //         Navigator.pop(context, true);
                    //       }
                    //     },
                    //   ),
                    // ),
                  ],
                ),
              )
            ],
          ),
        );
      },
        
    );

  }
}
