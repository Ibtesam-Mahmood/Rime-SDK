import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class TextMessage extends StatelessWidget {
  
  String message;

  TextMessage({this.message});

  @override
  Widget build(BuildContext context) {

    double width = MediaQuery.of(context).size.width;

    return Container(
      constraints: BoxConstraints(
        maxWidth: width*0.64,
        maxHeight: double.infinity
      ),
      // decoration: BoxDecoration(color: emojiCounter >= 1 && emojiCounter <= 3 ? Colors.transparent : PollarStoreBloc().loggedInUserID == widget.message?.clientID ? appColors.blue : appColors.grey.withOpacity(0.07), borderRadius: BorderRadius.all(Radius.circular(17))),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.all(Radius.circular(17))
      ),
      child: Padding(
        //TODO: Implement Emoji Counter
        padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
        child: Linkify(
          //TODO: Implement Link Style
          // linkStyle: textStyles.bodyText1.copyWith(color: !data.hasData ? Colors.white : Colors.black),
          // text: (widget.message as TextMessage).text, style: textStyles.bodyText1.copyWith(color: PollarStoreBloc().loggedInUserID == widget.message?.clientID ? Colors.white : Colors.black, fontSize: emojiCounter >= 1 && emojiCounter <= 3 ? 48 : 16),
          text: message,
        ),
      )
    );
  }
}