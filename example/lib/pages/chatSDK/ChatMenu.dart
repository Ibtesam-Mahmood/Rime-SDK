import 'dart:ui';
import 'dart:async';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:dashed_container/dashed_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../api/endpoints/followApi.dart';
import '../../api/endpoints/searchApi.dart';
import '../../api/endpoints/storyApi.dart';
import '../../api/endpoints/topicApi.dart';
import '../../components/ChatTile/ChatTile.dart';
import '../../components/ChatTile/SimpleChatTile.dart';
import '../../components/StoryCard/storyCard.dart';
import '../../components/widgets/horizontalBar.dart';
import '../../components/widgets/input_fields/search_field.dart';
import '../../components/widgets/pollarLoading.dart';
import '../../models/chat.dart';
import '../../models/story.dart';
import '../../models/storyResponse.dart';
import '../../models/topics.dart';
import '../../models/userInfo.dart';
import '../../state/chat/chatBloc.dart';
import '../../state/chat/chatEvent.dart';
import '../../state/chat/chatState.dart';
import '../../state/loadingState.dart';
import '../../state/store/pollarStoreBloc.dart';
import '../../util/colorProvider.dart';
import '../../util/globalFunctions.dart';
import '../../util/inner_shadow.dart';
import '../../util/pollar_icons.dart';
import 'ChatRequests.dart';

///Display a list of chats the user currently has in the form of `Chat Tile` widgets.
///Displays a list fo `Story Reply Cards`. allows routing to chat requests page and creating or searching a chat.
class ChatMenuPage extends StatefulWidget {
  final ChatViewMessageController controller;

  const ChatMenuPage({Key key, this.controller}) : super(key: key);
  @override
  _ChatMenuPageState createState() => _ChatMenuPageState();
}

class _ChatMenuPageState extends State<ChatMenuPage>
    with AutomaticKeepAliveClientMixin {
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CONSTANCTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///The duration of the search animation
  static const Duration SEARCH_TRANSITION_DURATION =
      Duration(milliseconds: 400);

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ STATE VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  //Load state for the search
  final LoadBloc<List<Chat>> searchBloc = LoadBloc(null, innitialLoad: false);

  //List of unordered story replies
  List<List<StoryResponse>> myStoryResponses = [];

  //List of unordered stories
  List<List<Story>> listsOfStories = [];

  ///Search text
  ///Used to avoid researching when onChanged is double triggered
  String searchText = '';

  ///The current chat state
  ChatState chatState;

  //Map of orignal votes
  Map<String, bool> voteMap;

  ScrollController _refreshController;

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///Retrevieves a list of chats organized by userID.
  ///[Warning: Expensive to call]
  Map<String, List<Chat>> get userChats {
    Map<String, List<Chat>> oraganizedChats = {};

    if (chatState != null) {
      for (Chat chat in chatState.allChats) {
        for (String userID in chat.users) {
          List<Chat> uChats = oraganizedChats[userID] ?? [];
          uChats.add(chat);
          oraganizedChats[userID] = uChats;
        }
      }
    }

    return oraganizedChats;
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ LIFECYLE EVENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  //Manges when a message is received
  //Controls the search field and intialzes a listener so when the value changes it can research other users in the searchfield
  @override
  void initState() {
    super.initState();

    _refreshController = ScrollController();

    chatState = ChatBloc().state;

    getRes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Binds the trust controller to the page
    if (widget.controller != null) {
      widget.controller._bind(this);
    }
  }

  @override
  void dispose() {
    searchBloc.drain();

    super.dispose();
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///Performs a search for a user.
  ///Every user is associated to a chat or group chats
  void search(String redex) {
    //Adds a search event to the search bloc
    searchBloc.add(LoadThis(() async {
      if (redex.isNotEmpty) {
        //Perform search
        List<UserInfo> searchedUsers = await SearchApi.searchUser(redex);

        //Gets chats for searched users
        List<Chat> searchedChats =
            getChatList(searchedUsers.map<String>((u) => u.id).toList(), true);

        //Sort the searched chats to display single chats first
        searchedChats.sort(
            (a, b) => a.groupChat != b.groupChat ? a.groupChat ? 1 : -1 : 0);

        return searchedChats;
      } else {
        //Suggest defualt, chats with followers
        final followers = (await FollowApi.getFollwersByUserId(
                PollarStoreBloc().loggedInUserID))
            .map<String>((f) => f.userInfoId)
            .toList();

        //Gets chat list from followers id
        return getChatList(followers);
      }
    }));
  }

  ///Builds a list of chats based on a list of userIDs.
  ///If chat found adds, if not found creates dummy
  ///
  ///[noGroups] - Avoids groups when building the chat list
  List<Chat> getChatList(List<String> userIds, [bool noGroups = true]) {
    //All chats with users by ID
    Map<String, List<Chat>> orgnaizedChats = userChats;

    //Maps chat id's to avoid dulicates
    Map<String, Chat> chatList = {};

    //Loops through users to find chats if exsist, if none exsist create one
    for (String id in userIds) {
      //If no chats found always include single user chat
      List<Chat> userCurrentChats = orgnaizedChats[id];

      //If single user chat was included
      bool singleChatIncluded = false;

      for (Chat chat in userCurrentChats ?? []) {
        if (chat.groupChat == false) {
          //Single chat found
          singleChatIncluded = true;
        }
        //Skips groups if defined
        else if (noGroups) continue;

        //Adds the chat to the list
        chatList[chat.id] = chat;
      }

      if (singleChatIncluded == false) {
        //Create dummy chat
        chatList['DUMMY-${PollarStoreBloc().loggedInUserID}'] = Chat(
          channelID: 'DUMMY-${PollarStoreBloc().loggedInUserID}',
          users: [id],
          muteChat: {PollarStoreBloc().loggedInUserID: false},
          timeToken: DateTime.now(),
          chatAccepted: {PollarStoreBloc().loggedInUserID: true},
          sendReadReceipts: {PollarStoreBloc().loggedInUserID: true},
          read: true,
          hidden: false,
          messages: [],
        );
      }
    }

    return chatList.values.toList();
  }

  void getRes() async {
    List<StoryResponse> temp;
    await StoryApi.myStoryResponses().then((value) {
      temp = value.item1;
      voteMap = value.item2;
    });
    Map<String, List<StoryResponse>> sorted = {};
    //sorts by userid
    temp.forEach((sr) {
      if (sorted[sr.userInfoId] != null) {
        sorted[sr.userInfoId].add(sr);
      } else {
        sorted[sr.userInfoId] = [sr];
      }
    });
    if (myStoryResponses == null) {
      myStoryResponses = [];
    }
    List<String> tpsIds = List();
    sorted.forEach((key, value) {
      tpsIds.addAll(value.map((e) => e.topicId));
    });
    List<Topic> tps = await TopicApi.getBatchTopics(tpsIds);
    for (int i = 0; i < sorted.values.length; i++) {
      for (int j = 0; j < sorted.values.elementAt(i).length; j++) {
        sorted.values.elementAt(i)[j].topic = tps.firstWhere((e) {
          return e.id == sorted.values.elementAt(i)[j].topicId;
        });
      }
      myStoryResponses.add(sorted.values.elementAt(i));
    }
    if (mounted) {
      setState(() {});
    }
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ BUILD ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  @override
  Widget build(BuildContext context) {
    super.build(context);

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return ColorfulSafeArea(
      top: true,
      color: appColors.background,
      child: BlocListener<ChatBloc, ChatState>(
          bloc: ChatBloc(),
          condition: (o, n) => true,
          listener: (context, state) {
            setState(() {
              chatState = state;
            });

            //Notifies the listners for the chat controller if defined
            if (widget.controller != null) {
              widget.controller._update();
            }
          },
          child: BlocBuilder<LoadBloc<List<Chat>>, LoadState<List<Chat>>>(
              bloc: searchBloc,
              builder: (context, searchState) {
                return Scaffold(
                  resizeToAvoidBottomPadding: false,

                  backgroundColor: appColors.surface,

                  //Page app bar
                  appBar: PreferredSize(
                    preferredSize: Size.fromHeight(kToolbarHeight),
                    child: SafeArea(
                      top: true,
                      child: AnimatedContainer(
                        duration: SEARCH_TRANSITION_DURATION,
                        height: kToolbarHeight,
                        width: double.infinity,
                        color: searchState is Loading || searchState is Loaded
                            ? appColors.surface
                            : appColors.background,
                      ),
                    ),
                  ),

                  //Page body
                  body: EasyRefresh(
                    bottomBouncing: false,header: CustomHeader(
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
                          color: appColors.background,
                          child: Stack(
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
                          ),
                        );
                      }),
                    scrollController: _refreshController,
                    child: CustomScrollView(
                      slivers: [

                      //List of story replies
                      SliverToBoxAdapter(
                        child: Container(
                          color: appColors.background,
                          child: AnimatedSwitcher(
                            duration: SEARCH_TRANSITION_DURATION,
                            transitionBuilder: (child, animation) {
                              return SizeTransition(
                                child: child,
                                sizeFactor: animation,
                                axis: Axis.vertical,
                              );
                            },
                            child: searchState is Loading || searchState is Loaded
                                ? Container() : Container()
                                // : Column(
                                //     mainAxisSize: MainAxisSize.min,
                                //     crossAxisAlignment: CrossAxisAlignment.start,
                                //     children: [
                                //       myStoryResponses?.isNotEmpty ?? true ? Padding(
                                //         padding: const EdgeInsets.only(
                                //             left: 16, top: 15),
                                //         child: Text(
                                //           'Trusts',
                                //           style: textStyles.headline5.copyWith(
                                //               color: appColors.onBackground,
                                //               fontWeight: FontWeight.w600),
                                //         ),
                                //       ) : Container(),
                                //       AnimatedContainer(
                                //         duration: Duration(milliseconds: 500),
                                //         height:
                                //             (myStoryResponses?.isNotEmpty ?? true)
                                //                 ? 175
                                //                 : 0,
                                //         curve: Curves.fastOutSlowIn,
                                //         child: myStoryResponses == null
                                //             ? _storyTiles(appColors)
                                //             : myStoryResponses.isNotEmpty
                                //                 ? _storyTiles(appColors)
                                //                 : Container(),
                                //       ),
                                //     ],
                                //   ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                          child: Container(
                            color: appColors.background,
                            child: AnimatedSwitcher(
                                duration: SEARCH_TRANSITION_DURATION,
                                transitionBuilder: (child, animation) {
                                  return SizeTransition(
                                    child: child,
                                    sizeFactor: animation,
                                    axis: Axis.vertical,
                                  );
                                },
                                child: searchState is Loading || searchState is Loaded ? Container()
                                  : _headerBuilder(appColors, textStyles, chatState?.requestedChats)),
                          )),

                      _bodyBuilder(appColors, searchState),

                      ],
                    ),
                    onRefresh: () async {
                      Completer _onSuccess = Completer();
                      ChatBloc().add(RefreshChatBlocEvent((){
                        _onSuccess.complete(null);
                      }));
                      await _onSuccess.future;
                    },
                  ),

                  // //Create new chat app bar
                  // bottomNavigationBar: searchState is Loaded
                  //     ? Container(
                  //         height: 16,
                  //         color: appColors.surface,
                  //       )
                  //     : SafeArea(
                  //         bottom: true,
                  //         child: ClipRect(
                  //           child: BackdropFilter(
                  //             filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  //             child: GestureDetector(
                  //               onTap: () {
                  //                 //Opens the new chat sheet
                  //                 showModalBottomSheet(
                  //                     context: context,
                  //                     isScrollControlled: true,
                  //                     backgroundColor: Colors.transparent,
                  //                     builder: (context) {
                  //                       return NewChatSheet(
                  //                         onCreate: (chat, isNew) {
                  //                           NavStack().push(ChatPage(
                  //                               key: UniqueKey(),
                  //                               chatModel: chat));
                  //                         },
                  //                       );
                  //                     });
                  //               },
                  //               child: Container(
                  //                 height: kToolbarHeight,
                  //                 color: appColors.surface,
                  //                 child: Center(
                  //                   child: Text('New Message',
                  //                       style: textStyles.headline5.copyWith(
                  //                           color: appColors.blue,
                  //                           fontWeight: FontWeight.w600)),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                );
              })),
    );
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ BUILD HELPERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  ///Builds the body fo the page which is a list of chats.
  ///If the search is loaded dsplay a list of simple chat cards,
  ///if no search state then displays defualt list of chats.
  ///while searching displays procress indicator
  Widget _bodyBuilder(AppColor appColors, LoadState state) {
    if (state is Loading) {
      //display loading symbol
      return SliverFillRemaining(
        child: PollarLoading(),
      );
    }

    if (!(state is Loaded)) {
      //No search, display default user chats
      List<Chat> acceptedChats = chatState?.acceptedChats ?? [];
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {

            bool mutedChat = !acceptedChats[index].muteChat[PollarStoreBloc().loggedInUserID];

            //A chat tile
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChatTile(
                  chat: acceptedChats[index],
                  key: ValueKey('ChatTile - ${acceptedChats[index].id}'),
                  actions: [
                    SlideAction(
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                            color: appColors.grey.withOpacity(0.07),
                            shape: BoxShape.circle),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: Icon(
                            mutedChat ? PollarIcons.muted : PollarIcons.mute,
                            color: mutedChat ? Colors.white : Colors.black
                          ),
                        ),
                      ),
                      onTap: () {
                        //toggle chat mute
                        ChatBloc().add(EditChatEvent(acceptedChats[index].id, Chat(
                          channelID: acceptedChats[index].id,
                          muteChat: acceptedChats[index].muteChat..[PollarStoreBloc().loggedInUserID] = mutedChat
                        )));
                      },
                    ),
                    SlideAction(
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                            color: appColors.red, shape: BoxShape.circle),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: Icon(
                            PollarIcons.delete,
                            color: Colors.white,
                          ),
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

                        if (confirm) {
                          //Delets the chat messages
                          ChatBloc().add(DeleteEvent(acceptedChats[index].id));
                        }
                      },
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 77.0),
                  child: HorizontalBar(
                    color: appColors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ],
            );
          },
          childCount: acceptedChats?.length ?? 0,
        ),
      );

    }
    else {

      //Search loaded
      List<Chat> searchedChats = (state as Loaded<List<Chat>>).content;

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            Chat currentChat = searchedChats[index];

            //A chat tile
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SimpleChatTile(
                  chat: currentChat,
                  onPressed: () {
                    //Push to chat page
                    // NavStack().push(ChatPage(
                    //   key: UniqueKey(),
                    //   chatModel: currentChat,
                    // ));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 77.0),
                  child: HorizontalBar(
                    color: appColors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ],
            );
          },
          childCount: searchedChats.length,
        )
      );
    }
  }

  ///Rounded header displayed above the list of user chats.
  ///Displays the amount of chat requests
  Widget _headerBuilder(
      AppColor appColors, TextTheme textStyles, List<Chat> requestedChats) {
    return InnerShadow(
      color: Colors.white,
      offset: Offset(1, 1),
      blur: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: appColors.grey.withOpacity(0.25), width: 0.1)),
        ),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
              color: appColors.surface,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                    offset: Offset(1, 1),
                    blurRadius: 1,
                    color: Color(0xFF92ACC4).withOpacity(0.14),
                    spreadRadius: 0),
                BoxShadow(
                    offset: Offset(2, 2),
                    blurRadius: 1,
                    color: Color(0xFF92ACC4).withOpacity(0.12),
                    spreadRadius: -1),
                BoxShadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Color(0xFF92ACC4).withOpacity(0.20),
                    spreadRadius: 0),
              ]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Messages', style: textStyles.headline5.copyWith(color: appColors.onBackground, fontWeight: FontWeight.w600)),
                (requestedChats?.length ?? 0) > 0 ? GestureDetector(
                  child: Text(
                      requestedChats.length.toString() + ' Requests',
                      style: textStyles.button.copyWith(color: appColors.blue)),
                  onTap: () {
                    // NavStack().push(ChatRequests());
                  },
                )
                : Container()
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ChatViewMessageController extends ChangeNotifier {
  _ChatMenuPageState _state;

  ///Binds the rule page state
  void _bind(_ChatMenuPageState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  ///Retreives the list of all chats
  List<Chat> get chats => _state == null ? null : _state.chatState.allChats;

  ///Retreives the list of all accepted chats
  List<Chat> get acceptedChats =>
      _state == null ? null : _state.chatState.acceptedChats;

  ///Retreives the list of all requested chats
  List<Chat> get requestedChats =>
      _state == null ? null : _state.chatState.requestedChats;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}
