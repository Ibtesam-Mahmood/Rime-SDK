

import 'package:flutter/material.dart';

///Padding values is a dynamic padding size container that holds 3 values. 
///Holds a breakpoint representing differend padding sizes
class PaddingValues {

  ///Large padding value
  final double large;

  ///Medium padding value
  final double medium;

  ///Small padding value
  final double small;

  PaddingValues({this.large, this.medium, this.small});

}

//Padding set for large phones
PaddingValues largeSet = PaddingValues(
  large: 32,
  medium: 24,
  small: 16
);

//Padding set for small phones
PaddingValues mediumSet = PaddingValues(
  large: 16,
  medium: 16,
  small: 16
);

//Padding set for small phones
PaddingValues smallSet = PaddingValues(
  large: 16,
  medium: 10,
  small: 12
);

///The inherited widget that can be accessed application wide and holds the padding values. 
///Holds breakpoints to toggle between padding values. 
///Updates when the provided height is provided.
class PaddingProvider extends InheritedWidget with WidgetsBindingObserver {

  final double height;
  final PaddingValues padding;

  ///The breakpoint for height padding changes
  static const double HEIGHT_BREAKPOINT_MEDIUM = 740; 
  static const double HEIGHT_BREAKPOINT_SMALL = 640; 

  PaddingProvider({Key key, Widget child, @required this.height}) :
   padding = height < HEIGHT_BREAKPOINT_SMALL ? smallSet : height < HEIGHT_BREAKPOINT_MEDIUM ? mediumSet : largeSet , 
   super(key: key, child: child);

  

  static PaddingValues of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PaddingProvider>().padding;
  }

  ///Updates if the height updates
  @override
  bool updateShouldNotify(PaddingProvider oldWidget) => height != oldWidget.height;

}

