import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:rime/components/widgets/overLappingProfilePictures.dart';
import 'package:rime/components/widgets/wrappedListTile.dart';

class ChatTile extends StatefulWidget {


  final List<Widget> actions;

  //TODO: Insert chat object
  const ChatTile({Key key, this.actions}) : super(key: key);

  @override
  _ChatTileState createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //TODO: Add chat ID
    return Slidable(
      key: Key('Slidable - ChatTile'),
      actionExtentRatio: 0.13,
      actionPane: SlidableScrollActionPane(),
      secondaryActions: widget.actions,
      child: WrappedListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //TODO: Add state to title and subtitle
        title: "Markus",
        subtitle: Text("Message from Markus"),
        leading: OverlappingProfilePicture(),
        //TODO: Implement unread and muted chats
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle
          ),
        ),
        onTap: (){
          //TODO: Implement onTap
        },
      ),
    );
  }
}