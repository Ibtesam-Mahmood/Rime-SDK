import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pollar/pages/chatSDK/ChatPage.dart';
import 'package:pollar/util/colorProvider.dart';
import 'package:pollar/util/pollar_icons.dart';

class AppBarGif extends StatefulWidget {

  final ChatPageController controller;

  final void Function() onSwap;

  final void Function() removeGif;

  AppBarGif({this.controller, this.onSwap, this.removeGif});

  @override
  _AppBarGifState createState() => _AppBarGifState();
}

class _AppBarGifState extends State<AppBarGif> {

  ///The size of the image
  Completer<ui.Image> _imageConstraints;

  @override
  void initState(){
    super.initState();

    _imageConstraints = _getImageSize(widget.controller.gif);

  }



  ///Retreives the box constraints of the first image
  ///Retrives how many lines of text are displayed based off of the aspect ratio of the image
  Completer<ui.Image> _getImageSize(String url) {
    Completer<ui.Image> completer =  Completer<ui.Image>();
       CachedNetworkImageProvider(url)
      .resolve( ImageConfiguration())
      .addListener(ImageStreamListener((ImageInfo info, bool _) {
        if(!completer.isCompleted){
          completer.complete(info.image);}
      }));

    //Image data
    return completer;
  }
  
  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints){
                return FutureBuilder<ui.Image>(
                  future: _imageConstraints.future,
                  builder: (context, snapshot){

                    ui.Image imageData = snapshot?.data;

                    double aspectRatio = 1;

                    if (imageData != null){
                      aspectRatio = imageData.width/imageData.height;
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        height: 154,
                        width: aspectRatio*154,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(widget.controller.gif),
                            fit: BoxFit.fitWidth
                          )
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                child: Container(
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Icon(PollarIcons.cancel, color: Colors.white.withOpacity(0.8), size: 10,)
                ),
                onTap: () {
                  widget.controller.removeGif();
                }
              ),
            ),
            Positioned(
              bottom: 7,
              right: 7,
              child: GestureDetector(
                child: Opacity(
                  opacity: 0.7,
                  child: Container(
                    width: 52,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: appColors.blue,
                    ),
                    child: Center(
                      child: Text('Swap', style: textStyles.headline6.copyWith(color: Colors.white),),
                    ),
                  ),
                ),
                onTap: widget.onSwap
              ),
            )
          ],
        ),
      ),
    );
  }
}