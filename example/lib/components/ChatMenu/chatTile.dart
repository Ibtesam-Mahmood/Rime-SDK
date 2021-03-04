import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../pages/Chat/ChatPage.dart';
import 'wrappedListTile.dart';
import 'overLappingProfilePictures.dart';

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
        title: "Killua",
        subtitle: Text("Message from Killua"),
        leading: OverlappingProfilePicture(
          topImage: 'https://i.pinimg.com/736x/2d/11/a3/2d11a390094c8851ec366c4742d37f1c.jpg',
          bottomImage: 'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/c73969f3-13d3-40b3-81e6-e847df80e3ca/d85u45x-d3a65754-e859-48f3-a736-07741d2b376a.png/v1/fill/w_1024,h_1211,strp/hunter_x_hunter___gon___updated_head_by_daul_d85u45x-fullview.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3siaGVpZ2h0IjoiPD0xMjExIiwicGF0aCI6IlwvZlwvYzczOTY5ZjMtMTNkMy00MGIzLTgxZTYtZTg0N2RmODBlM2NhXC9kODV1NDV4LWQzYTY1NzU0LWU4NTktNDhmMy1hNzM2LTA3NzQxZDJiMzc2YS5wbmciLCJ3aWR0aCI6Ijw9MTAyNCJ9XV0sImF1ZCI6WyJ1cm46c2VydmljZTppbWFnZS5vcGVyYXRpb25zIl19.BaaoW_E9bLMs951VPza6kcwJoxbtk1osHLK34xJe-F4',
          imageSize: 40,
          height: 50,
          width: 50,
        ),
        //TODO: Implement unread and muted chats
        trailing: SizedBox(
          height: 12,
          width: 12,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle
              ),
            ),
            ]
          ),
        ),
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage()));
        },
      ),
    );
  }
}