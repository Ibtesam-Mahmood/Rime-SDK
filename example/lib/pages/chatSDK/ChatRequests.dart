import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../components/ChatTile/ChatTile.dart';
import '../../components/widgets/buttons/PollarBackButton.dart';
import '../../models/chat.dart';
import '../../state/chat/chatBloc.dart';
import '../../state/chat/chatEvent.dart';
import '../../state/chat/chatState.dart';
import '../../state/store/pollarStoreBloc.dart';
import '../../util/colorProvider.dart';
import '../../util/globalFunctions.dart';
import '../../util/pollar_icons.dart';

//If Edit is pressed or not
enum Edit{
  Open,
  Close
}

class ChatRequests extends StatefulWidget {

  ChatRequests();
  @override
  _ChatRequestsState createState() => _ChatRequestsState();

}

class _ChatRequestsState extends State<ChatRequests> {

  //Current chat state
  ChatState chatState;

  //Edit mode activated
  Edit edit = Edit.Close;

  //Chats accepted to accept or delete
  List<Chat> selectedChats = [];

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    void deleteAllChats(List<Chat> requestedChats){
      for(Chat chat in requestedChats){
        //Delete chat messages
        ChatBloc().add(DeleteEvent(chat.id));
      }
    }

    void acceptSelectedChats(List<Chat> selected){
      for(Chat chat in selected){
        chat.chatAccepted[PollarStoreBloc().loggedInUserID] = true;
        ChatBloc().add(EditChatEvent(chat.id, chat));
      }
      setState(() {
        selected.clear();
        edit = Edit.Close;
      });
    }

    void deleteSelectedChats(List<Chat> selected){
      for(Chat chat in selected){
        //Delete chat messages
        ChatBloc().add(DeleteEvent(chat.id));
      }
      setState(() {
        selected.clear();
        edit = Edit.Close;
      });
    }

    return BlocBuilder<ChatBloc, ChatState>(
    bloc: ChatBloc(),
    condition: (o, n) => true,
    builder: (context, state){

    return Scaffold(
      appBar: AppBar(
        leading: PollarBackButton(),
        backgroundColor: appColors.surface,
        elevation: 0,
        title: Center(
          child: Text('Requests', style: textStyles.headline5.copyWith(fontWeight: FontWeight.w600)),
        ),
        actions: <Widget>[
          GestureDetector(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(edit == Edit.Close ? 'Edit' : 'Cancel', style: textStyles.headline5.copyWith(fontWeight: FontWeight.normal))),
            ),
            onTap: (){
              setState(() {
                if(edit == Edit.Close)
                  {edit = Edit.Open;}
                else
                  {edit = Edit.Close;}
              });
            },
          )
        ],
      ),
      body: EasyRefresh.custom(
        slivers: <Widget> [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) { 
                return GestureDetector(
                  child: Container(
                    child: Row(
                      children: [
                       edit == Edit.Open ? Padding(
                         padding: const EdgeInsets.only(left: 16),
                         child: Container(
                           height: 20,
                           width: 20,
                           decoration: BoxDecoration(
                            color: selectedChats.contains(state.requestedChats[i]) ? appColors.blue : appColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(width: selectedChats.contains(state.requestedChats[i]) ? 0 : 1, color: appColors.grey.withOpacity(0.2))
                           ),
                           child: selectedChats.contains(state.requestedChats[i]) ? Center(
                             child: FittedBox(
                               child: Icon(PollarIcons.accept, size: 24, color: Colors.white))
                            ) : Container(),
                         ),
                       ) : Container(),
                        Expanded(
                          child: IgnorePointer(
                            ignoring: edit == Edit.Open ? true : false,
                            child: ChatTile(
                              chat: state.requestedChats[i], 
                              key: ValueKey('ChatTile - ${state.requestedChats[i].id}'),
                              actions: [
                                SlideAction(
                                  child: Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                      color: appColors.blue,
                                      shape: BoxShape.circle
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: Icon(PollarIcons.accept, color: Colors.white, size: 36,),
                                    ),
                                  ),
                                  onTap: (){
                                    Chat requestedChat = state.requestedChats[i];
                                    requestedChat.chatAccepted[PollarStoreBloc().loggedInUserID] = true;
                                    ChatBloc().add(EditChatEvent(requestedChat.id, requestedChat));
                                  },
                                ),

                                SlideAction(
                                  child: Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                      color: appColors.red,
                                      shape: BoxShape.circle
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: Icon(PollarIcons.decline, color: Colors.white, size: 36,),
                                    ),
                                  ),
                                  onTap: () async {
                                    //Delete chat
                                    bool confirm = await PollarDisplay.showConfirmDialog(
                                      context,
                                      title: Text('Delete conversation?'),
                                      description: "Deleting removes the conversation from your inbox, but no one else's inbox.",
                                      confirmButton: 'Delete',
                                      cancelButton: 'Cancel',
                                      confirmButtonColor: appColors.red,
                                      cancelButtonColor: appColors.surface,
                                      confirmButtonTextColor: Colors.white,
                                      cancelButtonTextColor: Colors.black,
                                      width: 270
                                    );

                                    if(confirm){
                                      //Delets the chat messages
                                      ChatBloc().add(DeleteEvent(state.requestedChats[i].id));
                                    }
                                  },
                                )
                              ],
                            )
                          )
                        ),
                      ],
                    ),
                  ),
            onTap: (){
              if(selectedChats.contains(state.requestedChats[i])){
                setState(() {
                  selectedChats.remove(state.requestedChats[i]);
                });
              }
              else{
                setState(() {
                  selectedChats.add(state.requestedChats[i]);
                });
              }
            },
                );
              },
              childCount: state.requestedChats.length,
                ),
              )
            ],
          ),

          bottomNavigationBar: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: edit == Edit.Close ? GestureDetector(
                child: Container(
                  height: kToolbarHeight,
                  color: appColors.surface,
                  child: Center(
                    child: Text('Delete All', style: textStyles.headline5.copyWith(color: appColors.red, fontWeight: FontWeight.w600)
                    ),
                  ),
                ),
                onTap: () async {
                  //Delete chat
                  bool confirm = await PollarDisplay.showConfirmDialog(
                    context,
                    title: Text('Delete requested conversations?'),
                    description: "Deleting removes the conversation from your inbox, but no one else's inbox.",
                    confirmButton: 'Delete',
                    cancelButton: 'Cancel',
                    confirmButtonColor: appColors.red,
                    cancelButtonColor: appColors.surface,
                    confirmButtonTextColor: Colors.white,
                    cancelButtonTextColor: Colors.black
                  );

                  if(confirm){
                    deleteAllChats(state.requestedChats);
                  }
                },
              ) : Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      child: Container(
                        height: kToolbarHeight,
                        color: appColors.surface,
                        child: Center(
                          child: Text('Delete', style: textStyles.headline5.copyWith(color: appColors.red, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      onTap: (){
                        deleteSelectedChats(selectedChats);
                      },
                    ),
                  ),
                  Container(
                    height: 22,
                    width: 0.5,
                    color: appColors.grey.withOpacity(0.25),
                  ),
                  Expanded(
                    child: GestureDetector(
                      child: Container(
                        height: kToolbarHeight,
                        color: appColors.surface,
                        child: Center(
                          child: Text('Accept', style: textStyles.headline5.copyWith(color: appColors.blue, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      onTap: (){
                        acceptSelectedChats(selectedChats);
                      },
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
