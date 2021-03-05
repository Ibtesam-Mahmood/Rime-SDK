import 'package:flutter/material.dart';

///A list tile widget that does not have extra content padding.
///Simplfies the interface for listtile to 6 variables
class WrappedListTile extends StatelessWidget {
  ///The widget displayed before the title.
  ///If not deifned title is pushed to the front
  final Widget leading;

  ///The title text.
  ///Default textStyle is `textStyles.bodyText1, onBackground, Semibold`
  final String title;

  ///The style for the title, overides default style.
  final TextStyle titleStyle;

  ///The widget displayed under the title.
  final Widget subtitle;

  ///The widget to be displayed at the end
  final Widget trailing;

  ///The function that runs when this is pressed
  final Function() onTap;

  ///Function that runs when the title, leader or subtitle is tapped
  final Function() titleOnTap;

  ///The padding around the list tile items,
  ///defualted to `EdgeInsets.zero`
  final EdgeInsets contentPadding;

  const WrappedListTile(
      {Key key,
      this.leading,
      this.title = '',
      this.subtitle,
      this.trailing,
      this.onTap,
      this.contentPadding = EdgeInsets.zero,
      this.titleOnTap,
      this.titleStyle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? ()=>{},
        child: Padding(
          padding: contentPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              //leading widget
              if (leading != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: titleOnTap ?? ()=>{},
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(child: leading),
                  ),
                ),

              //title and subtitle
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: titleOnTap,
                      //TODO: Add textStyle
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subtitle != null)
                      Flexible(fit: FlexFit.loose, child: subtitle)
                  ],
                ),
              ),

              trailing ?? SizedBox.shrink()
            ],
          ),
        ));
  }
}
