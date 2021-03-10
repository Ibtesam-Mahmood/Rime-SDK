import 'dart:ui';

import 'package:example/components/ChatMessage/chatAppBar.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:rime/state/channel_state/channel_state.dart';

import '../../components/ChatMessage/messageScreen.dart';
import '../../components/Picker/picker.dart';
import '../../components/widgets/frosted_effect.dart';
import '../../util/colorProvider.dart';

class ChatPage extends StatefulWidget {
  final String rimeChannelID;
  
  ChatPage({Key key, this.rimeChannelID}) : super(key: key);
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  //Stores url for gifs
  String gif = '';

  //Unfocus if picker is open
  FocusNode focusNode;

  //Holds list of images in ChatAppBar
  List<AssetEntity> images = List<AssetEntity>();

  //Opens image and gif picker
  PickerController pickerController;


  //Gets gifs from GifPicker
  ChatPageController chatViewMenuController;

  ///previous state of keyBoard
  bool keyBoardOpen = false;

  ChannelProviderController _channelStateProviderController;

  //Loads in all messages of a specific chat
  //Responsible for receiving new messages as well (onMessageReceived)
  //Responsible for getting all the users of a specific chat
  @override
  void initState() {
    super.initState();

    chatViewMenuController = ChatPageController();

    _channelStateProviderController = ChannelProviderController();

    pickerController = PickerController(
      onImageReceived: (value){
        setState(() {
          images = value;
        });
      },
      onGiphyReceived: (value){
        setState(() {
          if(value != null)
            {gif = value;}
        });
      }
    );

    focusNode = FocusNode();
  }

  @override
  void dispose() {
    chatViewMenuController?.dispose();
    _channelStateProviderController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (chatViewMenuController != null) {
      //Binds the controller to this state
      chatViewMenuController._bind(this);
    }
  }

  //Remove an image from AppBar
  void removeImage(int index){
    setState(() {
      images.removeAt(index);
    });
  }

  //Remove all images from AppBar
  void removeAll(){
    setState(() {
      images.clear();
      gif = '';
    });
  }

  void removeGif(){
    setState(() {
      gif = '';
    });
  }

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;


    return ChannelStateProvider(
      channelID: widget.rimeChannelID,
      controller: _channelStateProviderController,
      builder: (context, channel, messages) {
        return Picker(
          controller: pickerController,
          backgroundColor: appColors.surface,
          initialExtent: 0.4,
          expandedExtent: 1.0,
          child: Scaffold(

            resizeToAvoidBottomInset: false,
            backgroundColor: appColors.surface,

            appBar: PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: FrostedEffect(
                frost: true,
                child: Container(
                  color: appColors.surface.withOpacity(0.7),
                  height: 88,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          onPressed: (){
                            Navigator.pop(context);
                          },
                        ),
                        channel?.title != null ? Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(channel.title, style: textStyles.headline3.copyWith(color: appColors.onBackground)),
                        ) : Container(),
                        Spacer(),
                        // TODO: Implement edit chat
                        // Padding(
                        //   padding: const EdgeInsets.only(right: 20),
                        //   child: id != 'DUMMY-${PollarStoreBloc().loggedInUserID}' ? GestureDetector(
                        //     child: Icon(PollarIcons.more_options, color: appColors.grey),
                        //     onTap: (){
                        //       if(user.length == 1){
                        //         showModalBottomSheet(
                        //           context: context, 
                        //           backgroundColor: Colors.transparent,
                        //           builder: (context){
                        //             // return EditSingleChat(user: user[0], chatID: id);
                        //           }
                        //         );
                        //       }
                        //       else{
                        //         showModalBottomSheet(
                        //           context: context, 
                        //           backgroundColor: Colors.transparent,
                        //           builder: (context){
                        //             // return EditGroupChat(users: user, chat: widget.chatModel);
                        //           }
                        //         );
                        //       }
                        //     },
                        //   ) : Container(),
                        // )
                      ],
                    ),
                  )
                ),
              ),
            ),
            body: Container(
              color: appColors.surface,
              height: double.infinity,
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification){
                  if(scrollNotification.metrics.extentBefore > 100){
                    setState(() {
                      if(pickerController.type == PickerType.ImagePicker){
                        pickerController.closeImagePicker();
                        keyBoardOpen = false;
                      }
                      else if(pickerController.type == PickerType.GiphyPickerView){
                        pickerController.closeGiphyPicker();
                        keyBoardOpen = false;
                      }
                      else{
                        focusNode.unfocus();
                        keyBoardOpen = false;
                      }
                    });
                  }
                  return false;
                },
                child: MessageScreen(messages: messages, channelProviderController: _channelStateProviderController),
              ),
            ),
            bottomNavigationBar: ChatAppBar(
              controller: chatViewMenuController,
              pickerController: pickerController,
              focusNode: focusNode,
              openImages: (){

                //Close or open accordingly
                if(pickerController?.type != PickerType.ImagePicker){
                  pickerController.openImagePicker();
                  setState(() {
                    focusNode.unfocus();
                  });
                }
                else if(keyBoardOpen){
                  pickerController.closeImagePicker();
                  setState(() {
                    focusNode.requestFocus();
                  });
                }
                else{
                  pickerController.closeImagePicker();
                  setState(() {
                    focusNode.unfocus();
                  });
                }

              },
              openGif: (){
                //Close or open accordingly
                if(pickerController?.type != PickerType.GiphyPickerView){
                  pickerController.openGiphyPicker();
                  setState(() {
                    focusNode.unfocus();
                  });
                }
                else if(keyBoardOpen){
                  pickerController.closeGiphyPicker();
                  setState(() {
                    focusNode.requestFocus();
                  });
                }
                else{
                  pickerController.closeGiphyPicker();
                  setState(() {
                    focusNode.unfocus();
                  });
                }
              },
              onTap: () {
                setState(() {

                  if(pickerController?.type == PickerType.GiphyPickerView)
                    {pickerController.closeGiphyPicker();}
                  else if(pickerController?.type == PickerType.ImagePicker)
                    {pickerController.closeImagePicker();}

                  keyBoardOpen = true;
                });
              },
              onCreate: (newChat){
                setState((){
                  channel = newChat;
                });
              },
              onSwap: (){
                pickerController.openGiphyPicker();
                setState(() {
                  focusNode.unfocus();
                });
              },
              // Pass in RimeModel
              channel: channel,
            ),
            ),
          );
      }
    );
  }
}


class ChatPageController extends ChangeNotifier{

  _ChatPageState _state;

  void _bind(_ChatPageState bind) => _state = bind;

  List<AssetEntity> get images => _state != null ? _state.images : null;

  String get gif => _state != null ? _state.gif : null;

  void removeGif() => _state.removeGif();

  void removeImage(int index) => _state.removeImage(index);

  void removeAll() => _state.removeAll();

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }

}