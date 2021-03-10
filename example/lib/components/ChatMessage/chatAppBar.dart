import 'dart:ui';

import 'package:example/components/Picker/picker.dart';
import 'package:example/components/widgets/frosted_effect.dart';
import 'package:example/pages/Chat/ChatPage.dart';
import 'package:example/util/colorProvider.dart';
import 'package:example/util/pollar_icons.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:rime/model/channel.dart';

import 'appBarGif.dart';
import 'appBarImage.dart';

class ChatAppBar extends StatefulWidget {
  ///Open Image picker
  final Function() openImages;

  ///Open Gif Picker
  final Function() openGif;

  ///Tap of textField
  final Function() onTap;

  ///Swap a gif
  final Function() onSwap;

  ///Runs when a chat is created
  final Function(RimeChannel) onCreate;

  ///Adds information to ChatViewMenu
  final ChatPageController controller;

  ///Picker Controller
  final PickerController pickerController;

  ///Focus on TextField
  final FocusNode focusNode;

  ///Chat model
  final RimeChannel chat;

  ///Contains expandable TextField that contains Images and Gifs
  ///Contains Picker which opens up Image picker or GifPicker
  ChatAppBar(
      {this.openImages,
      this.openGif,
      this.onTap,
      this.onSwap,
      this.controller,
      this.focusNode,
      this.chat,
      this.onCreate,
      this.pickerController});

  @override
  _ChatAppBarState createState() => _ChatAppBarState();
}

class _ChatAppBarState extends State<ChatAppBar> {
  TextEditingController controller;

  /// Number of lines in the textField
  int numLines = 0;

  /// Chat model
  RimeChannel chat;

  /// List of images or videos
  List<AssetEntity> images = [];

  /// How many emoji's are in the textfield
  int emojiCounter = 0;

  double get maxHeight {
    if (emojiCounter >= 1 && emojiCounter <= 3) {
      if (widget.controller.images.isEmpty && widget.controller.gif.isEmpty) {
        return 170;
      } else {
        return 90;
      }
    } else {
      if (numLines == 1) {
        return 44;
      } else {
        if (widget.controller.images.isEmpty && widget.controller.gif.isEmpty) {
          return 170;
        } else {
          return 90;
        }
      }
    }
  }

  ///Hides the options to add gif and images when toggled.
  bool hideOptions = false;

  // Emoji detection
  static final RegExp regex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');

  @override
  void initState() {
    super.initState();

    controller = TextEditingController()..addListener(() => setState(() {}));

    controller.buildTextSpan(withComposing: true);

    chat = widget.chat;
  }

  @override
  void dispose() {
    controller.dispose();
    // Implement send presense
    // sendPresence(false);

    super.dispose();
  }

  ///Sends an image to the backend
  // Future<List<String>> sendImage(List<AssetEntity> images) async {
  //   List<String> imageLinks = [];

  //   for (AssetEntity image in images) {
  //     Uint8List buffer =
  //         await image.thumbDataWithSize(image.width, image.height);

  //     String newTitle = '';

  //     if (image.title == '') {
  //       newTitle = DateTime.now().toString() + PollarStoreBloc().loggedInUserID;
  //       imageLinks.add(
  //           await ChatApi.sendImage(base64Encode(buffer), newTitle + '.png'));
  //     } else {
  //       imageLinks.add(await ChatApi.sendImage(base64Encode(buffer),
  //           image.title.split('.')[0].replaceAll(RegExp(r'_'), '') + '.png'));
  //     }
  //   }
  //   return imageLinks;
  // }

  // Future<Tuple2<String, String>> sendVideo(AssetEntity video) async {
  //   Tuple2<String, String> videoLink;

  //   String encodedVideo = jsonEncode({
  //     'base64': base64Encode(await video.originBytes),
  //     'fileName': video.title
  //   });

  //   print('Encoded Video');

  //   String encodedImage = jsonEncode({
  //     'base64': base64Encode(
  //         await video.thumbDataWithSize(video.width, video.height)),
  //     'fileName': 'thumbData - ' +
  //         video.title.split('.')[0].replaceAll('_', '') +
  //         '.png'
  //   });

  //   print('Awaiting...');

  //   videoLink = await ChatApi.sendVideo(encodedVideo, encodedImage);

  //   print(videoLink);

  //   return videoLink;
  // }

  ///Creates a chat if its not created already
  ///Sends a message if its already created
  // void createChat() async {
  //   // 1. Create chat if it has not been created
  //   // 2. Send message
  //   if (chat.id == 'DUMMY-${PollarStoreBloc().loggedInUserID}') {
  //     ChatBloc().add(CreateChatEvent(chat, onSuccess: (newChat) {
  //       //Grab new chat
  //       chat = newChat;

  //       if (widget.onCreate != null) {
  //         widget.onCreate(chat);
  //       }
  //       setState(() {});

  //       //Publish message
  //       sendMessage(chat);
  //     }));
  //   } else {
  //     //Publish message
  //     sendMessage(chat);
  //   }
  // }

  ///Sends a message
  // void sendMessage(Chat chatModel) async {
  //   setState(() {
  //     hideOptions = false;
  //     numLines = 1;
  //   });

  //   sendPresence(false);

  //   if (controller.text != '') {
  //     //Create Text Message
  //     ChatMessage message = TextMessage(
  //         clientID: PollarStoreBloc().loggedInUserID,
  //         timeToken: DateTime.now(),
  //         delivered: false,
  //         text: controller.text);

  //     //Publish message
  //     ChatBloc().add(MessageEvent(chatModel.id, message));

  //     //Clear the textField
  //     setState(() {
  //       controller.clear();
  //     });
  //   }

  //   if (widget.controller.images.length == 1 &&
  //       widget.controller.images[0].duration > 0) {
  //     images = [...widget.controller.images];

  //     setState(() {});

  //     DateTime time = DateTime.now();

  //     widget.controller.removeAll();

  //     LocalVideoMessage localVideo = LocalVideoMessage(
  //         clientID: PollarStoreBloc().loggedInUserID,
  //         timeToken: time,
  //         delivered: false,
  //         video: images[0]);

  //     chatModel.messages.add(localVideo);

  //     ChatBloc().add(StoreChatEvent(chat));

  //     print(images[0].title);

  //     Tuple2<String, String> video = await sendVideo(images[0]);

  //     VideoMessage videoMessage = VideoMessage(
  //         clientID: PollarStoreBloc().loggedInUserID,
  //         timeToken: time,
  //         delivered: false,
  //         video: video.item2,
  //         thumbNail: video.item1);

  //     ChatBloc().add(MessageEvent(chatModel.id, videoMessage));
  //   } else if (widget.controller.images.isNotEmpty) {
  //     images = [...widget.controller.images];

  //     setState(() {});

  //     DateTime time = DateTime.now();

  //     widget.controller.removeAll();

  //     LocalImage localImage = LocalImage(
  //         clientID: PollarStoreBloc().loggedInUserID,
  //         timeToken: time,
  //         delivered: false,
  //         link: images);

  //     chatModel.messages.add(localImage);

  //     ChatBloc().add(StoreChatEvent(chatModel));

  //     List<String> imageLinks = await sendImage(images);

  //     //Create image message
  //     ImageMessage image = ImageMessage(
  //         clientID: PollarStoreBloc().loggedInUserID,
  //         timeToken: time,
  //         delivered: false,
  //         link: imageLinks);

  //     //Publish image message
  //     ChatBloc().add(MessageEvent(chatModel.id, image));
  //   } else if (widget.controller.gif.isNotEmpty) {
  //     //Create gif message
  //     GifMessage message = GifMessage(
  //         clientID: PollarStoreBloc().loggedInUserID,
  //         timeToken: DateTime.now(),
  //         delivered: false,
  //         link: widget.controller.gif);

  //     widget.controller.removeGif();

  //     //Publish gif message
  //     ChatBloc().add(MessageEvent(chatModel.id, message));
  //   }
  // }

  TextSpan textSpan(String message, TextTheme textStyles) {
    return TextSpan(
      text: message ?? '',
      style: textStyles.headline5
          .copyWith(color: Colors.black, fontWeight: FontWeight.normal),
    );
  }

  ///Updates the number of lines and spacing on the message field
  void setNumLines(String value, TextTheme textStyle) {
    var width = MediaQuery.of(context).size.width;

    TextPainter tp = TextPainter(
        text: textSpan(value, textStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr);
    if (!hideOptions) {
      tp.layout(maxWidth: width - 180);
    } else {
      tp.layout(maxWidth: width - 125);
    }
    if (tp.didExceedMaxLines) {
      setState(() {
        numLines = 2;
      });
    } else {
      setState(() {
        numLines = 1;
      });
    }
  }

  ///Sends a presence event for typing or not typing
  // void sendPresence(bool pres) {
  //   if (pres) {
  //     ChatBloc().state.chatClient.signal(widget.chat.id, 'typing1');
  //   } else {
  //     ChatBloc().state.chatClient.signal(widget.chat.id, 'typing0');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    //Color provider
    final appColors = ColorProvider.of(context);

    return FrostedEffect(
      frost: true,
      child: Container(
        color: appColors.surface.withOpacity(0.7),
        child: Padding(
          padding: const EdgeInsets.only(left: 0, top: 5, bottom: 5, right: 16),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                                parent: animation,
                                curve:
                                    Interval(0.75, 1, curve: Curves.easeIn))),
                        child: SizeTransition(
                          sizeFactor: animation,
                          axis: Axis.horizontal,
                          axisAlignment: 1,
                          child: child,
                        ),
                      );
                    },
                    child: hideOptions
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 16),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  hideOptions = false;
                                  setNumLines(controller.text, textStyles);
                                });
                              },
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: appColors.grey, width: 1.5)),
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Icon(
                                    PollarIcons.add,
                                    color: appColors.grey,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : widget.controller.images.isEmpty &&
                                widget.controller.gif.isEmpty
                            ? Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16, bottom: 5),
                                    child: GestureDetector(
                                      child: Icon(
                                        PollarIcons.gif,
                                        color: widget.pickerController?.type !=
                                                    PickerType
                                                        .GiphyPickerView ||
                                                widget.pickerController
                                                        ?.gifController ==
                                                    null
                                            ? appColors.grey
                                            : appColors.primary,
                                        size: 34,
                                      ),
                                      onTap: widget.openGif,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 5, left: 16),
                                    child: GestureDetector(
                                        child: Icon(
                                          PollarIcons.multimedia,
                                          color: widget.pickerController
                                                          ?.type !=
                                                      PickerType.ImagePicker ||
                                                  widget.pickerController
                                                          ?.imageController ==
                                                      null
                                              ? appColors.grey
                                              : appColors.primary,
                                          size: 34,
                                        ),
                                        onTap: widget.openImages),
                                  )
                                ],
                              )
                            : Container(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: appColors.grey.withOpacity(0.2),
                                width: 1),
                            borderRadius: BorderRadius.circular(24)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  height: widget.controller.images.isNotEmpty ||
                                          widget.controller.gif.isNotEmpty
                                      ? 137
                                      : 0,
                                  child: widget.controller.images.isNotEmpty
                                      ? Row(
                                          children: [
                                            widget.controller.images.isNotEmpty
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 11,
                                                            left: 16),
                                                    child: GestureDetector(
                                                        child: Container(
                                                            height: 35,
                                                            width: 35,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30),
                                                              color: appColors
                                                                  .grey
                                                                  .withOpacity(
                                                                      0.07),
                                                            ),
                                                            child: Icon(
                                                                PollarIcons.add,
                                                                size: 35,
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.8))),
                                                        onTap:
                                                            widget.openImages),
                                                  )
                                                : Container(),
                                            Expanded(
                                                child: AppBarImage(
                                                    images: widget
                                                        .controller.images,
                                                    controller:
                                                        widget.controller)),
                                          ],
                                        )
                                      : widget.controller.gif.isNotEmpty
                                          ? AppBarGif(
                                              controller: widget.controller,
                                              onSwap: widget.onSwap)
                                          : Container()),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: maxHeight,
                                  minHeight: 44,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          strutStyle: StrutStyle(
                                            forceStrutHeight: true,
                                          ),
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          keyboardType: TextInputType.multiline,
                                          maxLines: null,
                                          focusNode: widget.focusNode,
                                          controller: controller,
                                          autocorrect: true,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          onTap: widget.onTap,
                                          style: textStyles.headline5.copyWith(
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                              fontSize: (emojiCounter >= 1 &&
                                                      emojiCounter <= 3)
                                                  ? 48
                                                  : 17),
                                          onChanged: (value) {
                                            if (value.isEmpty) emojiCounter = 0;
                                            emojiCounter = regex
                                                .allMatches(value)
                                                .toList()
                                                .length;
                                            value.splitMapJoin(regex,
                                                onNonMatch: (n) {
                                              if (n != '') {
                                                emojiCounter = 0;
                                              }
                                              return '';
                                            });
                                            setState(() {
                                              if (value.isNotEmpty) {
                                                hideOptions = true;
                                                //TODO: Implement send presense
                                                // sendPresence(true);
                                              } else {
                                                hideOptions = false;
                                                //TODO: Implement send presense
                                                // sendPresence(false);
                                              }
                                              setNumLines(value, textStyles);
                                            });
                                          },
                                          decoration: InputDecoration(
                                              contentPadding: numLines >= 2
                                                  ? EdgeInsets.zero
                                                  : EdgeInsets.only(
                                                      bottom: 14, top: 9),
                                              border: InputBorder.none,
                                              hintText: 'Message...',
                                              hintStyle: textStyles.headline5
                                                  .copyWith(
                                                      color: appColors.grey,
                                                      fontWeight:
                                                          FontWeight.normal)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10, top: 5, bottom: 5),
                                        child: GestureDetector(
                                          child: Icon(
                                            PollarIcons.send,
                                            color: widget.controller.images
                                                        .isNotEmpty ||
                                                    widget.controller.gif
                                                        .isNotEmpty ||
                                                    controller.text != ''
                                                ? appColors.blue
                                                : appColors.grey,
                                            size: 34,
                                          ),
                                          onTap: () {
                                            setState(() {
                                              emojiCounter = 0;
                                            });
                                            // Implement create chat
                                            // createChat();
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
