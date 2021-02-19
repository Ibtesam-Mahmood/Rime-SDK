import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api/endpoints/searchApi.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../models/poll.dart';
import '../../models/post.dart';
import '../../models/topics.dart';
import '../../models/userInfo.dart';
import '../../state/chat/chatBloc.dart';
import '../../state/chat/chatEvent.dart';
import '../../state/loadingState.dart';
import '../../state/store/pollarStoreBloc.dart';
import '../../util/colorProvider.dart';
import '../../util/pollar_icons.dart';
import '../ChatTile/SimpleChatTile.dart';
import '../widgets/horizontalBar.dart';
import '../widgets/pollarLoading.dart';
import 'NewChatSheet.dart';

///Sends a typed content along witha  message to a group of selected chats/groups. 
///The chats to send it to can be selected and searched. 
///If a chat does not exsist this sheet creates that chat before sending the message. 
///New groups can be created to send the message to by clicking create new group to open new chat sheet. 
///
///Current Supported Types: `Post, Poll, Topic, UserInfo`
class SendMessageSheet<T> extends StatefulWidget {

  ///The content to be sent to the selected chats
  final T content;

  ///List of userIds that are innitially selected
  final List<String> initialSelected;

  const SendMessageSheet({this.content, this.initialSelected});

  @override
  _SendMessageSheetState<T> createState() => _SendMessageSheetState<T>();
}

class _SendMessageSheetState<T> extends State<SendMessageSheet<T>> {

  ///Load state for the search
  final LoadBloc<List<Chat>> searchBloc = LoadBloc(null, innitialLoad: false);

  ///Text edditing controller for the search feield
  TextEditingController _searchController;

  ///Text controller for the message bar
  TextEditingController _messageController;

  ///If the search bar has focus or not
  bool _searchFocused = false;

  ///List of selected chats to send the message to
  List<Chat> selectedChats = [];

  ///List of users mapped to thier chats
  final Map<String, List<Chat>> userChats = {};

  ///Returns a message object encapsulating the typed content
  ChatMessage getMessageFromType(){

    if(T == Post){
      //post message
      return PostMessage(
        clientID: PollarStoreBloc().loggedInUserID,
        timeToken: DateTime.now(),
        delivered: false,
        postID: (widget.content as Post).id
      );
    }
    else if(T == Poll){
      //poll message
      return PollMessage(
        clientID: PollarStoreBloc().loggedInUserID,
        timeToken: DateTime.now(),
        delivered: false,
        pollID: (widget.content as Poll).id
      );
    }
    else if(T == Topic){
      //topic message
      return TopicMessage(
        clientID: PollarStoreBloc().loggedInUserID,
        timeToken: DateTime.now(),
        delivered: false,
        topicID: (widget.content as Topic).id
      );
    }
    else if(T == UserInfo){
      //profile message
      return ProfileMessage(
        clientID: PollarStoreBloc().loggedInUserID,
        timeToken: DateTime.now(),
        delivered: false,
        userID: (widget.content as UserInfo).id
      );
    }

    throw('Type is not a message');

  }

  @override
  void initState() {
    super.initState();

    initSheetSearch();

    //Intialize the controller to search on change
    _searchController = TextEditingController()
      ..addListener(() => _search(_searchController.value.text));
    
    _messageController = TextEditingController();

  }

  @override
  void dispose() {

    searchBloc.drain();
    _searchController.dispose();
    _messageController.dispose();

    super.dispose();
  }

  ///Allows the selecting of a chat through the New Chat Sheet
  ///The chat can be old or new, if it is a group its always new
  void selectFromChatSheet(){
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) {
      return NewChatSheet(onCreate: (chat, isNew){
        //On complete select this chat
        setState(() {
          Chat newChat = chat.copyWith(Chat(channelID: isNew ? 'DUMMY-${PollarStoreBloc().loggedInUserID}' : null));
          if(selectedChats.where((c) => c.id == newChat.id).isEmpty){
            selectedChats.add(newChat);
          }
        });

        _loadDefault();
      },);
    });
  }

  ///Inititializes the send message sheeta nd retreives all of the users chats
  void initSheetSearch(){

    ///Stores the list of users and thier chats from loaded chats
    for (Chat chat in ChatBloc().state.acceptedChats) {
      for (String userId in chat.users) {
        List<Chat> uChats = userChats[userId] ?? [];
        uChats.add(chat);
        userChats[userId] = uChats;
      }
    }

    if(widget.initialSelected != null){
      //Set inntial selected to selected users

      //Remove login user if selected
      List<String> initialSelctedUsers = widget.initialSelected..removeWhere((u) => u == PollarStoreBloc().loggedInUserID);

      //the innitial selected users
      List<Chat> initSelect = [];

      for(String userId in initialSelctedUsers){
        //Only checks for single chats if avialable or creates dummy chat
        List<Chat> chats = userChats[userId];

        if(chats != null && chats.where((c) => c.groupChat == false).toList().isNotEmpty){
          //User chat loaded
          initSelect.add(chats.where((c) => c.groupChat == false).toList()[0]);
        }
        else{
          //Create dummy chat
          initSelect.add(Chat(
            channelID: 'DUMMY-$userId',
            users: [userId],
          ));
        }
      }

      setState(() {
        selectedChats = initSelect;
      });
    }

    _loadDefault();

  }

  ///Loads in the default chats into the search state
  void _loadDefault(){
    searchBloc.add(LoadThis(() async {
      Set<Chat> loadChats = Set.from([...selectedChats, ...(ChatBloc().state.allChats)]);
      return loadChats.toList();
    }));
  }

  ///Searches for users on the system, if the user has a chat on the system return that, if not create a dummy chat
  void _search(String redex) {

    //Adds the following event to search bloc
    searchBloc.add(LoadThis(() async {

      if(redex.isNotEmpty){
        List<UserInfo> searchedUsers = (await SearchApi.searchUser(redex))..removeWhere((u) => u.id == PollarStoreBloc().loggedInUserID);

        Set<Chat> searchedChats = Set<Chat>();

        for (UserInfo user in searchedUsers) {
          //If user is present in any chats, add them to the list of chats
          //if not create a new chat for that user
          if(userChats[user.id] == null){
            //Create a new chat for the user
            searchedChats.add(Chat(
              channelID: 'DUMMY-${user.id}',
              users: [user.id],
            ));

          }
          else{
            //Add the users chats to the searched list
            searchedChats.addAll(userChats[user.id]);
          }
        }

        return searchedChats.toList();
      }

      return [];

    }));

  }

  ///Sends the typed content message to the selected chats
  ///If the chat is not yet created, then it is created now
  void _sendMessage() async {

    //No message sent if no chats selected
    if(selectedChats.isEmpty) return;

    //The message encapsulating the content
    ChatMessage contentMessage;

    try{
      contentMessage = getMessageFromType();
    } catch(e){ return; }

    //Accompanying text message if defined
    TextMessage textMessage = _messageController.value.text.isNotEmpty ? TextMessage(
      clientID: PollarStoreBloc().loggedInUserID,
      delivered: false,
      text: _messageController.value.text,
      timeToken: DateTime.now()
    ) : null;

    //Loop through each chat, if chat is fake create a proper chat, else send message
    for (Chat chat in selectedChats) {
      if(chat.id.contains('DUMMY')){

        //Create and subscribe to chat
        ChatBloc().add(CreateChatEvent(chat, onSuccess: (finalChat){
          //Send content message
          ChatBloc().add(MessageEvent(finalChat.id, contentMessage));

          //send text message if not null
          if(textMessage != null){
            ChatBloc().add(MessageEvent(finalChat.id, textMessage));
          }
        }));

      }
      else{
        //Send content message
        ChatBloc().add(MessageEvent(chat.id, contentMessage));

        //send text message if not null
        if(textMessage != null){
          ChatBloc().add(MessageEvent(chat.id, textMessage));
        }
      }

      //Pop the sheet
      Navigator.of(context).pop();
      
    }

  }

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: appColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            //Draggable notch
            SizedBox(
              height: 24,
              child: Center(
                child: Container(
                  height: 4,
                  width: 35,
                  decoration: BoxDecoration(
                    color: appColors.grey.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(10)
                  ),
                ),
              ),
            ),

            //Search field
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              // child: SearchField(
              //   controller: _searchController,
              //   style: SearchFieldType.MATERIAL,
              //   onFocus: (focus){
              //     setState(() {
              //       _searchFocused = focus;
              //       if(focus){ _search('');} //Opens a empty search on focus
              //       else if(_searchController.value.text.isEmpty){ _loadDefault();} //Opens defualt view when out of focus and not searching
              //     });
              //   },
              // ),
            ),

            Container(
              height: 340,
              child: BlocBuilder<LoadBloc<List<Chat>>, LoadState<List<Chat>>>(
                bloc: searchBloc,
                builder: (context, state) {

                  List<Chat> searchedChats;

                  if(state is Loaded<List<Chat>>){
                    searchedChats = state.content;
                  }

                  //If loading display loader
                  if(searchedChats == null){
                    return Center(
                      child: PollarLoading(),
                    );
                  }

                  return ListView.separated(
                    itemCount: (searchedChats?.length ?? 0) + (!_searchFocused ? 1 : 0),
                    separatorBuilder: (_, __) {
                      //Styalistic horizontal bar
                      return Padding(
                        padding: const EdgeInsets.only(left: 77.0),
                        child: HorizontalBar(
                          color: appColors.grey.withOpacity(0.1),
                          width: 0.5,
                        ),
                      );
                    },
                    itemBuilder: (context, index) {
                      if(index == 0 && !_searchFocused){
                        //New group tile
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            child: Icon(PollarIcons.add, color: Colors.black,),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appColors.grey.withOpacity(0.07),
                              border: Border.all(color: appColors.surface, width: 1)
                            ),
                          ),

                          title: Text('Create a new group', style: textStyles.bodyText2,),

                          trailing: Icon(PollarIcons.forward, color: appColors.grey,),

                          onTap: (){
                            // Open new chat sheet
                            selectFromChatSheet();
                          },
                        );
                      }
                      else{
                        Chat currentChat = searchedChats[index - (!_searchFocused ? 1 : 0)];
                        return SimpleChatTile(
                          chat: currentChat,
                          trailing: selectedChats.where((c) => c.id == currentChat.id).isNotEmpty ?
                            Icon(PollarIcons.selected, color: appColors.blue,)
                            : Icon(PollarIcons.empty_selection, color: appColors.grey.withOpacity(0.2),),
                          onPressed: (){
                            //Toggle adding the chat to selected chats
                            setState(() {
                              if(selectedChats.where((c) => c.id == currentChat.id).isNotEmpty){ selectedChats.removeWhere((c) => c.id == currentChat.id);}
                              else {selectedChats.add(currentChat);}
                            });
                          },
                        );
                      }
                    },
                  );
                }
              ),
            ),

            //Message bar
            Container(
              color: appColors.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Container(
                  height: 44,
                  child: TextField(
                    controller: _messageController,
                    textAlignVertical: TextAlignVertical.bottom,
                    style: textStyles.headline5.copyWith(color: appColors.onBackground, fontWeight: FontWeight.normal),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(bottom: 11, left: 16),
                      hintText: 'Message...',
                      hintStyle: textStyles.headline5.copyWith(color: appColors.grey, fontWeight: FontWeight.normal),
                      suffixIcon: GestureDetector(
                        onTap: (){
                          //Sends the message to the chats
                          _sendMessage();
                        },
                        child: Icon(PollarIcons.send, size: 34, color: selectedChats.isEmpty ? appColors.grey.withOpacity(0.25) : appColors.blue,)
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: appColors.grey.withOpacity(0.2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: appColors.grey.withOpacity(0.2), width: 1),
                      ),
                    ),
                  ),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}