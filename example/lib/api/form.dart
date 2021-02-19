import 'package:flutter/material.dart';

class FormWidget extends StatefulWidget {
  final List<String> inputs;

  void _createTextField(String name) {
    _controllers[name] = TextEditingController();
    _textFields[name] = TextField(controller: _controllers[name]);
    _rows.add(Row(
      children: [
        Container(width: 50, height: 20, child: Text(name + ': ')),
        Container(width: 200, height: 20, child: _textFields[name]),
        // _textFields[name],
      ]
    ));
  }
  FormWidget(this.inputs) {
   for (String input in inputs) {
      _createTextField(input);
      print('creating form field for ' + input);
    }
  }
  
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, Widget> _textFields = {};
  final List<Widget> _rows = [];



  Map<String, TextEditingController> get controllers => _controllers;
  @override
  State<StatefulWidget> createState() {
    return FormState();
  }
}

class FormState extends State<FormWidget> {
  // TextEditingControllers


  Widget _getRows() {
    return Column(
      children: widget._rows
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _getRows(),
    );
  }
}
