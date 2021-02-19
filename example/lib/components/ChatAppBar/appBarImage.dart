import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_widget/photo_widget.dart';
import 'package:pollar/pages/chatSDK/ChatPage.dart';
import 'package:pollar/util/pollar_icons.dart';

class AppBarImage extends StatelessWidget {

  final List<AssetEntity> images;

  final ChatPageController controller;

  AppBarImage({this.images, this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: controller.images.length,
      itemBuilder: (context, i){
        
        double aspectRatio = controller.images[i].width/controller.images[i].height;

          return Padding(
            padding: const EdgeInsets.only(left: 5, top: 5),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    height: 154,
                    width: 154*aspectRatio,
                    child: Image(
                      image: AssetEntityThumbImage(entity: controller.images[i]),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
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
                    onTap: (){
                      controller.removeImage(i);
                    },
                  ),
                )
              ],
            ),
          );
        }
    );
  }
}