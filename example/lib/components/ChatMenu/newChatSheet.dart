import 'package:example/api/endpoints/searchApi.dart';
import 'package:example/api/endpoints/userInfoApi.dart';
import 'package:example/components/widgets/buttons/PollarRoundedButton.dart';
import 'package:example/components/widgets/pollarLoading.dart';
import 'package:example/components/widgets/profileCard.dart';
import 'package:example/models/userInfo.dart';
import 'package:example/state/loadingState.dart';
import 'package:example/state/store/pollarStoreBloc.dart';
import 'package:example/util/colorProvider.dart';
import 'package:example/util/pollar_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/model/channel.dart';

import 'horizontalBar.dart';

class NewChatSheet extends StatefulWidget {

  ///The function that runs when the user pressed [chat]. 
  ///This function returns the new chat object and if it is new or exsisting
  final Function(RimeChannel, bool) onCreate;

  ///List of users removed from the search
  final List<String> removedUsers;

  ///Future confirmation callback that allows the parent to verify the user chat to be created. 
  ///Returns true if chat is confirmed to be created
  final Future<bool> Function(List<String> users) confirmation;

  const NewChatSheet({Key key, this.onCreate, this.removedUsers = const [], this.confirmation}) : assert(removedUsers != null), super(key: key);

  @override
  _NewChatSheetState createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {


  //Load state for the search
  final LoadBloc<List<UserInfo>> searchBloc = LoadBloc<List<UserInfo>>(null, innitialLoad: false);

  //Controls search text field
  TextEditingController _controller;

  //Selected user in the users list
  int userIndex = -1;
  
  //Holds all the users in the chat
  List<UserInfo> users = [];

  @override
  void initState() {
    super.initState();

    //Defines the search controller
    _controller = TextEditingController()
      ..addListener((){
        String redex = _controller.value.text;
        //When the user types on the search field
        if(redex.isNotEmpty){
          //Automatically performs search when the length is 1
          searchBloc.add(LoadThis<List<UserInfo>>(() async {
            List<UserInfo> loadedUsers = await SearchApi.searchUser(redex);

            //Removes any removed users
            loadedUsers.removeWhere((u) => widget.removedUsers.contains(u.id) || u.id == PollarStoreBloc().loggedInUserID);
            return loadedUsers;
          }));
        }
        else if(redex.isEmpty){
          //Resets to display the selected users
          searchBloc.add(LoadThis<List<UserInfo>>(() async {
            List<UserInfo> baseUserList = [...users, ...(await UserInfoApi.getAllUserInfos())];
            
            //Removes any removed users
            baseUserList.removeWhere((u) => widget.removedUsers.contains(u.id) || u.id == PollarStoreBloc().loggedInUserID);
            return baseUserList;
          }));
        }
      });

  }

  @override
  void dispose() {

    _controller.dispose();

    super.dispose();
  }

  ///Function that runs when the users are confirmed
  void onConfirm() async {
    RimeChannel newChat = await RimeApi.createChannel(users.map<String>((u) => u.id).toList());

    //Call the call back function
    if(widget.onCreate != null){
      widget.onCreate(newChat, true);}
  }

  ///Adds or removes the suer from the list of selected users
   void updateChatUsers(UserInfo user){
    setState(() {
      if(users.where((u) => u.id == user.id).isNotEmpty) {users.removeWhere((u) => u.id == user.id);}
      else {users = [...users, user];}
    });
  }

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 35),
        child: Container(
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[

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

              //Text field area
              Container(
                height: 70,
                child: ListView(
                  reverse: true,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * ((users?.length ?? 0) == 0 ? 1 : 0.7),
                      child: Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[

                            //To header only displays when no users are selected
                            users.isEmpty ? Padding(
                              padding: const EdgeInsets.only(bottom: 8, right: 8, left: 8),
                              child: Text('To:', style: textStyles.headline4.copyWith(color: appColors.onBackground, fontWeight: FontWeight.bold)),
                            ) : Container(),

                            //Search feild
                            Container(
                              height: 70,
                              width: MediaQuery.of(context).size.width*0.5,
                              child: TextField(
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.only(top: 14),
                                  border: InputBorder.none,
                                  hintText: 'Search...',
                                  hintStyle: textStyles.headline4.copyWith(color: appColors.grey.withOpacity(0.25), fontWeight: FontWeight.bold)
                                ),
                                style: textStyles.headline4.copyWith(color: appColors.onBackground, fontWeight: FontWeight.bold),
                                controller: _controller,
                                autofocus: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    //List of selected users
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: users.length,
                        separatorBuilder: (_, __) => Container(width: 8,),
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: (){
                              //On first tap selects the item
                              if(userIndex != i){
                                setState(() {
                                  userIndex = i;
                                });
                              }

                              //on second tap removes the user
                              else{
                                setState(() {
                                  userIndex = -1;
                                  users.removeAt(i);
                                });
                              }
                            },
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: appColors.blue.withOpacity(userIndex == i ? 0.8 : 0.2),
                                  borderRadius: BorderRadius.all(Radius.circular(12))
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                child: Text(
                                  users[i].firstName + ' ' + users[i].lastName, 
                                  textAlign: TextAlign.center, 
                                  style: textStyles.button.copyWith(color: userIndex == i ? Colors.white : appColors.blue.withOpacity(0.8)),
                                )
                              ),
                            ),
                          );
                        }
                      ),
                    ),

                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: HorizontalBar(
                  color: appColors.grey.withOpacity(0.1),
                  width: 0.5,
                ),
              ),

              Expanded(
                child: BlocBuilder< LoadBloc<List<UserInfo>>, LoadState<List<UserInfo>> >(
                  cubit: searchBloc,
                  builder: (context, st) {
                    if(st is Loading){
                      //Shows the loading symbol while loading
                      return Center(
                        child: PollarLoading(),
                      );
                    }
                    else if (st is Loaded< List<UserInfo> >){
                      //Search is loaded
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: st.content.length,
                        itemBuilder: (context, i){
                          return ProfileCard(
                            user: st.content[i],
                            trailing: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: users.where((u) => u.id == st.content[i].id).isEmpty ? Icon(PollarIcons.empty_selection, color: appColors.grey.withOpacity(0.2),)
                                : Icon(PollarIcons.selected, color: appColors.blue,)
                            ),
                            onTap: (_) {
                              setState((){
                                updateChatUsers(st.content[i]);
                              }); 
                            },
                          );
                        },
                      );
                    }
                    else{
                      //Empty screen
                      return Container();
                    }
                    
                  }
                ),
              ),

              Container(
                color: appColors.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: PollarRoundedButton(
                          borderRadius: 12,
                          color: appColors.grey.withOpacity(0.07),
                          text: 'Cancel',
                          sizeVariation: SizeVariation.MEDIUM,
                          textColor: appColors.onBackground,
                          onPressed: (){
                            //Close modal sheet
                            Navigator.of(context).pop();
                          },
                        ),
                      ),

                      Container(width: 16,),

                      Expanded(
                        child: PollarRoundedButton(
                          borderRadius: 12,
                          color: appColors.blue,
                          text: 'Chat',
                          sizeVariation: SizeVariation.MEDIUM,
                          textColor: Colors.white,
                          disabledColor: appColors.grey.withOpacity(0.07),
                          onPressed: users.isNotEmpty ? () async {
                            //Create chat, runs a confirmation function to check with parent
                            bool confirm = widget.confirmation != null ? await widget.confirmation(users.map<String>((e) => e.id).toList()) : true; 
                            if(confirm){
                              Navigator.of(context).pop();
                              onConfirm();

                            }
                          } : null,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              
            ],
          ),
        ),
      ),
    );
  }
}