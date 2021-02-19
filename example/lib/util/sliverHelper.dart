

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../components/widgets/frosted_effect.dart';

///Indexed sliverlist builder used to display selected list of items on a sliver list
class SliverIndexedListDelegate extends SliverChildBuilderDelegate {


  SliverIndexedListDelegate(
    Widget Function(BuildContext, int) Function(int index) builders,
    {@required int Function(int) childCounts, int index = 0}
  ) : assert(builders != null), 
      assert(childCounts != null),
      super(builders(index), childCount: childCounts(index));



}

///Used to make a sliver a persisntant header
class SimpleSliverPersistantDelegate extends SliverPersistentHeaderDelegate{

  final PreferredSize child;
  final EdgeInsets padding;
  final Color backgorundColor;
  
  ///The height of the [SimpleSliverPersistantDelegate]
  double get height {
    return child.preferredSize.height + (padding.vertical) - 4;
  }

  SimpleSliverPersistantDelegate({
    this.child, 
    this.padding = EdgeInsets.zero, 
    this.backgorundColor = Colors.transparent
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgorundColor,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;

}


///Sliver persistent header delagate used to apply a safe area to the [SimpleSliverPersistantDelegate]. 
///This widget allows for applying a color to the [SafeArea].
class SafeAreaSliverPersistantDelagate extends SimpleSliverPersistantDelegate{

  SafeAreaSliverPersistantDelagate({
    this.safeAreaContext, 
    PreferredSize child, 
    EdgeInsets padding = EdgeInsets.zero, 
    Color backgorundColor = Colors.transparent
  }) : super(
    child: child,
    backgorundColor: backgorundColor,
    padding: padding
  );

  ///If defined, applies a safe area on the [SimpleSliverPersistantDelegate]. 
  ///Accesses the [SafeArea] top height from this context
  final BuildContext safeAreaContext;

  @override
  double get height{
    double safeAreaHeight = 0;

    //Retreive safe area height
    safeAreaHeight = MediaQuery.of(safeAreaContext).padding.top;

    ///Bases the height off the [SimpleSliverPersistantDelegate]
    return super.height + safeAreaHeight;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgorundColor,
      child: SafeArea(
        top: safeAreaContext != null,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }

}

///Extension on [SafeAreaSliverPersistantDelagate] that applies a [FrostedEffect] to the widget. 
///Frosted effect can be controlled using the [ForstedEffect] interface built in.
class FrostedSliverPersistantDelagate extends SafeAreaSliverPersistantDelagate {
  
  FrostedSliverPersistantDelagate({
    this.frost,
    BuildContext safeAreaContext, 
    PreferredSize child, 
    EdgeInsets padding = EdgeInsets.zero, 
    Color backgorundColor = Colors.transparent
  }) : super(
    safeAreaContext: safeAreaContext,
    child: child,
    backgorundColor: backgorundColor,
    padding: padding
  );

  ///Determines if a frost must be applied to the widget. 
  ///Interface for [FrostedEffect]
  final bool frost;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return FrostedEffect(
      frost: frost ?? false,
      child: super.build(context, shrinkOffset, overlapsContent),
    );
  }

}