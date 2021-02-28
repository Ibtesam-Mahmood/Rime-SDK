import 'dart:io';
import 'package:flutter/material.dart';

import '../../../util/colorProvider.dart';
import '../../../util/pollar_icons.dart';


///The back button used to navigate to the previous page. When pressed calls
///`NavStack().pop()`
///
///This widget is platform dpeendant and chnages on iOS and Android.
///
///[onTap] - Can be used to override the defined onTap function
class PollarBackButton extends StatelessWidget {
  
  ///Ontap function that runs when the icon is pressed. If defined overrides the defualt onTap
  final Function onTap;

  const PollarBackButton({Key key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Icon(Platform.isIOS ? PollarIcons.back : PollarIcons.android_back, color: appColors.grey,),
    );
  }
}