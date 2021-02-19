import 'dart:ui';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import '../../util/pollar_icons.dart';
import '../widgets/frosted_effect.dart';

///Max size of toolkit
const double kImageViewNavBarSize = 140;

///Swipable image viewer, displays network images in a carosel. 
///Swiping between images causes a parallax effect. 
///When closed returns a callback that for the current page
class ImageViewer extends StatefulWidget {

  ///List of image urls
  final List<String> urls;

  ///Innitial image index
  final int innitalIndex;

  ///The bar at the bottom of the page, cstomizable by parent
  final Widget bottomBar;

  const ImageViewer({Key key, @required this.urls, this.innitalIndex = 0, this.bottomBar}) : assert(urls != null), assert(urls.length != 0), super(key: key);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {

  ///The current page index
  int imageIndex;

  ///Controls the opacity of the appbar and bottom nav bar
  bool hideNav = true;

  ///Controller for the primary page view
  PageController _pageController;

  ///The scroll position of the page view
  double pageOffset = 0;

  @override
  void initState() {
    super.initState();

    //Sets the innital index
    imageIndex = widget.innitalIndex;

    _pageController = PageController(initialPage: imageIndex, viewportFraction: 1.2, keepPage: true)
      ..addListener(() {
        setState(() {
          pageOffset = _pageController.page;
        });
      });
  }

  @override
  void dispose(){

    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return ExtendedImageSlidePage(
      slideType: SlideType.wholePage,
      slideAxis: SlideAxis.both,
      child: GestureDetector(
        onTap: (){
          //Toggles the nav bar visibility
          setState(() {
            hideNav = !hideNav;
          });
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              
              ExtendedImageGesturePageView.builder(
                controller: _pageController,
                itemCount: widget.urls.length,
                onPageChanged: (index){
                  //On page swipe
                  setState(() {
                    imageIndex = index;
                  });
                },

                itemBuilder: (context, i){
                  return Hero(
                    tag: 'img-${widget.urls[i]}',
                    child: ExtendedImage(
                      image: NetworkImage(widget.urls[i]),
                      enableSlideOutPage: true,
                      mode: ExtendedImageMode.gesture,
                      initGestureConfigHandler: (state){
                        return GestureConfig(
                          minScale: 0.9,
                          initialScale: 0.9,
                          maxScale: 1.3,
                          inPageView: true,
                        );
                      },
                      // heroBuilderForSlidingPage: (),
                    ),
                  );
                },
              ),

              SafeArea(
                top: true,
                child: AnimatedContainer(
                  transform: Transform.translate(offset: hideNav ? Offset(0, -kToolbarHeight) : Offset.zero).transform,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.decelerate,
                  child: SizedBox.fromSize(
                    size: Size.fromHeight(kToolbarHeight),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: FrostedEffect(
                            frost: !hideNav,
                            animateOpacity: true,
                            shape: ClipShape.circle,
                            child: Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(38)
                              ),
                              child: GestureDetector(
                                child: Icon(PollarIcons.cancel, color: Colors.white, size: 24,),
                                onTap: Navigator.of(context).pop,
                              ),
                            ),
                          ),
                        ),
                        centerTitle: true,
                        title: FrostedEffect(
                          frost: !hideNav,
                          animateOpacity: true,
                          shape: ClipShape.rRect(19),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(19)
                            ),
                            child: Text('${imageIndex + 1} of ${widget.urls.length}', style: textStyles.headline5.copyWith(color: Colors.white))
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if(widget.bottomBar != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    bottom: true,
                    child: AnimatedContainer(
                      transform: Transform.translate(offset: hideNav ? Offset(0, kImageViewNavBarSize) : Offset.zero).transform,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.decelerate,
                      child: FrostedEffect(
                        frost: !hideNav,
                        animateOpacity: true,
                        shape: ClipShape.rect,
                        child: SizedBox.fromSize(
                          size: Size(double.infinity, kImageViewNavBarSize),
                          child: widget.bottomBar ?? Container(
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
            ],
          )
        ),
      ),
    );
  }
}