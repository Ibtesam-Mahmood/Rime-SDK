import 'package:flutter/material.dart';
import 'overLappingProfilePictures.dart';

///SimpleChatTile displays the chat name, the user names in the chat and the chat picture
class SimpleChatTile extends StatefulWidget {

  ///Custom trailing widget
  final Widget trailing;

  ///Optional onpressed clal back function
  final Function() onPressed;

  const SimpleChatTile({Key key, this.trailing, this.onPressed}) : super(key: key);

  @override
  _SimpleChatTileState createState() => _SimpleChatTileState();
}

class _SimpleChatTileState extends State<SimpleChatTile> {

  @override
  Widget build(BuildContext context) {

    return ListTile(
      leading: OverlappingProfilePicture(),
      title: Text("Markus"),
      subtitle: Text("Mark"),
      trailing: widget.trailing,
      onTap: widget.onPressed,
    );
  }
}
