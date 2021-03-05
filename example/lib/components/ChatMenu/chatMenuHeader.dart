import 'package:flutter/material.dart';
import 'innerShadow.dart';

class ChatMenuHeader extends StatelessWidget {
  

  @override
  Widget build(BuildContext context) {
    return InnerShadow(
      color: Colors.white,
      offset: Offset(1, 1),
      blur: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.25), width: 0.1)),
        ),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                    offset: Offset(1, 1),
                    blurRadius: 1,
                    color: Color(0xFF92ACC4).withOpacity(0.14),
                    spreadRadius: 0),
                BoxShadow(
                    offset: Offset(2, 2),
                    blurRadius: 1,
                    color: Color(0xFF92ACC4).withOpacity(0.12),
                    spreadRadius: -1),
                BoxShadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Color(0xFF92ACC4).withOpacity(0.20),
                    spreadRadius: 0),
              ]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text('Messages'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}