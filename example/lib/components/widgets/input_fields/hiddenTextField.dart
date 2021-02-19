import 'package:flutter/material.dart';

import '../../../util/colorProvider.dart';
import '../../../util/pollar_icons.dart';

///A textfield which has its text hidden by default.
///An suffex icon button allows for the toggling of the hidden text so that it can be seen.
///
///By default the textfield does not use an input border, and has headline4 grey hint text
///
///[hintText] - The defined hint text to be displayed
///
///[innitialToggle] - Defines the innitial toggle hidden value for the textfield
///
///[onChanged] - The function which is run when the textfield value is changed
class HiddenTextField extends StatefulWidget {
  ///The hint to be displayed in the textfield
  final String hintText;

  ///The vlaue of the innitial toggle for the hidden text, dafulted to `true` for hidden
  final bool innitialToggle;

  ///Callback function used which is run when the input is changed in the textfield
  final Function(String) onChanged;

  //On Tap of hidden button
  final Function(bool) onTap; 

  //Controls the onTap field
  final HiddenTextFieldController controller;


  const HiddenTextField(
      {Key key, this.hintText, this.innitialToggle = true, this.onChanged, this.controller, this.onTap})
      : assert(innitialToggle != null),
        super(key: key);

  @override
  _HiddenTextFieldState createState() => _HiddenTextFieldState();
}

class _HiddenTextFieldState extends State<HiddenTextField> {
  ///Represents the toggle value for the hidden varaible
  bool _hidden;

  @override
  void initState() {
    super.initState();

    //Defines the hidden value based on the innitalToggle
    _hidden = widget.innitialToggle;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.controller != null) {
      //Binds the controller to this state
      widget.controller._bind(this);
    }

  }

  void onTap(bool toggle){
    //Toggles the hidden value
    setState(() {
      _hidden = toggle;
    });
  }

  @override
  Widget build(BuildContext context) {
    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return TextField(
      obscureText: _hidden,
      style: textStyles.headline4.copyWith(
          color: appColors.onBackground, decoration: TextDecoration.none),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: textStyles.headline4.copyWith(color: appColors.grey),
          border: InputBorder.none,
          suffixIcon: GestureDetector(
            onTap: () {
              onTap(!_hidden);
              if(widget.onTap != null){
                widget.onTap(_hidden);
              }
            },
            child: Icon(
              _hidden ? PollarIcons.small_invisible : PollarIcons.small_visible,
              color: appColors.grey,
            ),
          )),
    );
  }
}

class HiddenTextFieldController extends ChangeNotifier{

  // State of hidden text field
  _HiddenTextFieldState _state;

  // binds the hidden text field state
  void _bind(_HiddenTextFieldState bind) => _state = bind;

  // mimics the onTap function
  void toggleTap(bool val) => _state.onTap(val);

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}
