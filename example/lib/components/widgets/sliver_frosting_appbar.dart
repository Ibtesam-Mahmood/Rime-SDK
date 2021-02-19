import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../util/colorProvider.dart';
import '../../util/globalFunctions.dart';
import '../../util/sliverHelper.dart';
import 'frosted_effect.dart';

///[SliverFrostingAppBar] is a Sliver App Bar that is built with a [SliverPersistentHeader]. 
///This widget enfoces a [backgroundColor] on the the appbar based on [isScrolled], animating it's differences. 
///
///Intended to be used within a [NestedScrollView].
///
///Height is restricted to `46 dp`
class SliverFrostingAppBar extends StatefulWidget {

  const SliverFrostingAppBar({
    Key key, 
    this.isScrolled = false, 
    this.child, 
    
  }) : assert(isScrolled != null), super(key: key);

  ///Determines if the appbar should animated between pollar `surface` or `background` colors. 
  ///When toggled the [SliverFrostingAppBar] animates to `surface`. 
  ///When untoggled the [SliverFrostingAppBar] animates to `background`
  ///
  ///Intended to be provided by an [NestedScrollView]
  final bool isScrolled;

  ///The inner child
  final Widget child;

  @override
  _SliverFrostingAppBarState createState() => _SliverFrostingAppBarState();
}

class _SliverFrostingAppBarState extends State<SliverFrostingAppBar> with SingleTickerProviderStateMixin {

  ///Used to animate the chanages in [widget.isScrolled]. 
  ///Moves `forward` when `widget.isScrolled == true`. 
  ///Moves `backwards` when `widget.isScrolled == false`. 
  ///
  ///The animation controller is synced to [FrostedEffect]
  AnimationController animationController;

  @override
  void initState() {
    super.initState();

    ///Defines the [animationController]. 
    ///Sync controller to [FrostedEffect] animation using [PollarConstants.NORMAL_DURATION]. 
    ///Adds a listener to the [animationController] to update state when an animation is occuring
    animationController = AnimationController(vsync: this, duration: PollarConstants.NORMAL_DURATION)
      ..addListener(() => setState((){}));
  }

  @override
  void dispose() {

    //Disposes the animation controller
    animationController.dispose();

    super.dispose();
  }
  
  @override
  void didUpdateWidget(SliverFrostingAppBar oldWidget){
    super.didUpdateWidget(oldWidget);

    ///Determines if the [widget.isScrolled] parameter changed
    if(widget.isScrolled != oldWidget.isScrolled){
      
      ///Animate forward, frost, and change color to `surface`
      if(widget.isScrolled == true){
        animationController.forward();
      }

      ///Animate backwards, unfrost and chnage color to `background`
      else{
        animationController.reverse();
      }
    }
  }

  ///Retreives the background color for the [SliverFrostingAppBar]. 
  ///
  ///Linearly Interpolates between `background` and `surface` 
  ///based on the [animationController] value.
  Color getBackground(AppColor appColors){
    return Color.lerp(
      appColors.background, 
      appColors.surface.withOpacity(0.94), 
      animationController.value
    );
  }

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    return SliverPersistentHeader(
      pinned: true,

      ///Creates a persisntant header with a frosted effect
      delegate: FrostedSliverPersistantDelagate(
        frost: widget.isScrolled,

        ///Animation is applied to chnage the background color
        backgorundColor: getBackground(appColors),
        safeAreaContext: context,
        child: PreferredSize(
          preferredSize: Size.fromHeight(46),
          child: FrostedEffect(
            frost: widget.isScrolled,
            child: Container(
              child: widget.child ?? SizedBox.expand()
            ),
          ),
        )
      ),
    );
  }
}