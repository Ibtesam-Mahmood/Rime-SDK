import 'package:flutter/material.dart';

///The defualt loading symbol for pollar
class PollarLoading extends StatelessWidget {

  final double width;

  const PollarLoading({Key key, this.width = 24}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //TODO: Finish and implement final loader
    return SizedBox(
      height: width,
      width: width,
      child: CircularProgressIndicator(
        backgroundColor: Colors.blue,
      ),
    );
  }
}