import 'package:flutter/material.dart';

import 'innerShadow.dart';


///Used to define the type of search field variation to use
enum SearchFieldType{
  MATERIAL,
  NEUMORPHIC,
  LARGE,
}

///A textfield widget that is designed to be used application wide. 
///All text and color styles are implemented with accorance to the design specification. 
///When the textfield is not empty a cancel button is appended to the end to clear the values
class SearchField extends StatefulWidget {

  ///Function that returns the updated value of the textfield
  final Function(String) onChanged;

  ///The type of the seach field to display
  final SearchFieldType style;

  ///The function called when the focus value is cahed for the search field
  final Function(bool) onFocus;

  ///Allows for the controlling of the texfield
  final TextEditingController controller;

  ///The color of the neumorphic search bar, if not defined defualted to background
  final Color neumorphicBackground;

  const SearchField({Key key, this.onChanged, this.style = SearchFieldType.MATERIAL, this.onFocus, this.controller, this.neumorphicBackground}) : super(key: key);

  @override
  _SearchFieldState createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {

  ///Controller used to manipulate the textfield
  TextEditingController _textController;

  ///Controls the focus value for the text field
  FocusNode _fNode;

  ///The height of the Neumorphoic and Material textfields
  static const double TEXT_FIELD_HEIGHT = 44;

  @override
  void initState() {
    super.initState();

    _fNode = FocusNode()
      ..addListener(() {
        //If focus changes set state
        setState(() {});
        
        //Called the defined onfocus chanegd function
        if(widget.onFocus != null)
          {widget.onFocus(_fNode.hasFocus);}
      });

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Retreive controller from parent or define own
    if(widget.controller != null) {_textController = widget.controller;}
    else {_textController = TextEditingController();}
  }

  @override
  void dispose(){

    _fNode.dispose();

    if(widget.controller == null)
      {_textController.dispose();}

    super.dispose();
  }

  ///Returns the style for the text style based on the type
  TextStyle textFieldStyle(TextTheme textStyles, Color textColor) {
    switch (widget.style) {
      case SearchFieldType.LARGE:
        return textStyles.headline3.copyWith(color: textColor);
      case SearchFieldType.NEUMORPHIC:
        return textStyles.button.copyWith(color: textColor);
      default:
        return textStyles.button.copyWith(color: textColor);
    }
  }

  ///Returns the opacity of the hint type based on the type
  Color hintColor(){
    switch (widget.style) {
      case SearchFieldType.LARGE:
        return _fNode.hasFocus ? Colors.grey.withOpacity(0.25) : Colors.white;
      case SearchFieldType.NEUMORPHIC:
        return _fNode.hasFocus || _textController.value.text.isNotEmpty ? Colors.grey.withOpacity(0.25) : Colors.grey.withOpacity(0.8);
      default:
        return Colors.grey.withOpacity(0.07);
    }
  }

  ///Returns the backgorudn color of textfield type based on the type
  Color backgroundColor(){
    switch (widget.style) {
      case SearchFieldType.LARGE:
        return Colors.transparent;
      case SearchFieldType.NEUMORPHIC:
        return widget.neumorphicBackground ?? Colors.white;
      default:
        return Colors.grey.withOpacity(0.07);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      height: widget.style != SearchFieldType.LARGE ? TEXT_FIELD_HEIGHT : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          //Container for text feild 
          Expanded(
            child: Container(
              decoration: widget.style == SearchFieldType.NEUMORPHIC ? BoxDecoration(
                //Neumorphic outer container
                borderRadius: BorderRadius.circular(_fNode.hasFocus || _textController.value.text.isNotEmpty ? 14 : 12),

                //Neumorphic outer container
                gradient: _fNode.hasFocus || _textController.value.text.isNotEmpty ? LinearGradient(
                  colors: [
                    Colors.white, 
                    Colors.white.withOpacity(0.9), 
                    Colors.white.withOpacity(0.25), 
                    Color(0xFF3F5E7E).withOpacity(0.10)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
                ) : null,

                //No box show 
                boxShadow: _fNode.hasFocus || _textController.value.text.isNotEmpty ? [] : [
                  //Neumorphic shadows
                  BoxShadow(offset: Offset(-6, -6), blurRadius: 10, color: Colors.white.withOpacity(0.35)),
                  BoxShadow(offset: Offset(-1, -1), blurRadius: 18, color: Colors.white.withOpacity(0.3)),
                  BoxShadow(offset: Offset(-3, -3), blurRadius: 5, spreadRadius: -1, color: Colors.white.withOpacity(0.5)),
                  BoxShadow(offset: Offset(6, 6), blurRadius: 10, color: Color(0xFF92ACC4).withOpacity(0.14)),
                  BoxShadow(offset: Offset(1, 1), blurRadius: 18, color: Color(0xFF92ACC4).withOpacity(0.12)),
                  BoxShadow(offset: Offset(3, 3), blurRadius: 5, spreadRadius: -1, color: Color(0xFF92ACC4).withOpacity(0.2)),
                ]
              ) : BoxDecoration(
                //Material and large button style
                borderRadius: BorderRadius.circular(12),
                color: backgroundColor()
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),


                child: Container(
                  decoration: BoxDecoration(
                    color: (_fNode.hasFocus || _textController.value.text.isNotEmpty) && widget.style == SearchFieldType.NEUMORPHIC ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(13.5)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: Stack(
                      children: [

                        //Neumorphoic inner shadows
                        widget.style != SearchFieldType.NEUMORPHIC ? Container() :
                        Positioned.fill(
                          child: InnerShadow(
                            offset: Offset(-3, -3),
                            blur: 7,
                            color: _fNode.hasFocus || _textController.value.text.isNotEmpty ? Colors.white : Colors.transparent,
                            child: InnerShadow(
                              offset: Offset(3, 3),
                              blur: 7,
                              color: _fNode.hasFocus || _textController.value.text.isNotEmpty ? Color(0xFFB6C8D8).withOpacity(0.48) : Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: backgroundColor(),
                                ),
                              ),
                            ),
                          ),
                        ),

                        widget.style != SearchFieldType.LARGE ? Positioned(
                          left: 6,
                          top: 6,
                          bottom: 6,
                          child: Icon(Icons.search, size: 24, color: Colors.grey,)
                        ) : Container(),

                        Padding(
                          padding: EdgeInsets.only(left: widget.style != SearchFieldType.LARGE ? 35 : 0),
                          child: TextField(
                            focusNode: _fNode,
                            controller: _textController,
                            textAlignVertical: TextAlignVertical.center,
                            // style: textFieldStyle(textStyles, appColors.onBackground),
                            onChanged: (val){

                              //Set statae is called to update the internal state
                              //No state variables are changed, however the chnage is recorded within the text editting controller
                              setState(() {});

                              //Calls onChanged to update the parent widget
                              if(widget.onChanged != null){
                                widget.onChanged(val);
                              }
                            },
                            decoration: InputDecoration(

                              //Hard centering for text
                              contentPadding: EdgeInsets.only(
                                top: widget.style != SearchFieldType.LARGE ? 0 : 11,
                                bottom: (widget.style != SearchFieldType.LARGE ? 16.5: 11)
                              ),
                              border: InputBorder.none,
                              hintText: 'Search',
                              // hintStyle: textFieldStyle(textStyles, hintColor(appColors)),
                            ),
                          ),
                        ),

                        //Cancel button for neumorphic search bar
                        _textController.value.text.isEmpty ?
                         Container() : 
                         Positioned(
                           right: 8,
                           top: 8,
                           bottom: 8,
                           child: Center(
                            //  alignment: Alignment.centerRight,
                             child: GestureDetector(
                                onTap: (){
                                  //Resets textfield thorugh controller
                                  setState(() {
                                    _textController.clear();
                                  });

                                  //Calls onChanged to update the parent widget
                                  if(widget.onChanged != null){
                                    widget.onChanged('');
                                  }

                                  _fNode.requestFocus();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10.0),
                                  child: Icon(Icons.cancel, color: Colors.grey.withOpacity(0.8),),
                                ),
                              ),
                           ),
                         )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          //Cancel button, only visisble when the textfield is empty
          //Also displays the cancel button on neumorphic search bars when the text field has focus
          _textController.value.text.isNotEmpty
          || _fNode.hasFocus ? GestureDetector(
            onTap: (){
              //Resets textfield thorugh controller
              setState(() {
                _textController.clear();
              });

              //Calls onChanged to update the parent widget
              if(widget.onChanged != null){
                widget.onChanged('');
              }

              //Removes the focus from the text field, collaping the keyboard
              _fNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text('Cancel'),
            ),
          ) : Container()
        ],
      ),
    );
  }
}

///Rounded Search Field. 
///Updated Material search field
class RoundedSearchFeild extends StatefulWidget {

  ///The height of the rounded material textfield
  static const double TEXT_FIELD_HEIGHT = 36;

  ///Function that returns the updated value of the textfield
  final Function(String) onChanged;

  ///The function called when the focus value is cahed for the search field
  final Function(bool) onFocus;

  ///Allows for the controlling of the texfield
  final TextEditingController controller;

  ///Hint text for the search field
  final String hintText;

  const RoundedSearchFeild({Key key, this.onChanged, this.onFocus, this.controller, this.hintText}) : super(key: key);

  @override
  _RoundedSearchFeildState createState() => _RoundedSearchFeildState();
}

class _RoundedSearchFeildState extends State<RoundedSearchFeild> {
  
  ///Controller used to manipulate the textfield
  TextEditingController _textController;

  ///Controls the focus value for the text field
  FocusNode _fNode;

  @override
  void initState() {
    super.initState();

    _fNode = FocusNode()
      ..addListener(() {
        //If focus changes set state
        setState(() {});
        
        //Called the defined onfocus chanegd function
        if(widget.onFocus != null)
          {widget.onFocus(_fNode.hasFocus);}
      });

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Retreive controller from parent or define own
    if(widget.controller != null) {_textController = widget.controller;}
    else {_textController = TextEditingController();}
  }

  @override
  void dispose(){

    _fNode.dispose();

    if(widget.controller == null)
      {_textController.dispose();}

    super.dispose();
  }

  ///Returns the style for the text style based on the type
  TextStyle textFieldStyle(TextTheme textStyles, Color textColor) {
    return textStyles.button.copyWith(color: textColor);
  }

  ///Returns the opacity of the hint type based on the type
  Color hintColor(){
    return Colors.white.withOpacity(_fNode.hasFocus ? 0.25 : 1);
  }

  ///Returns the backgorudn color of textfield type based on the type
  Color backgroundColor(){
    return Colors.grey.withOpacity(0.15);
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      height: RoundedSearchFeild.TEXT_FIELD_HEIGHT,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          //Container for text feild 
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.grey.withOpacity(0.15)
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Row(
                  children: [

                    Padding(
                      padding: const EdgeInsets.only(left: 6, right: 10),
                      child: Icon(Icons.search, size: 24, color: Colors.white.withOpacity(_fNode.hasFocus ? 0.8 : 1),),
                    ),

                    Expanded(
                      child: TextField(
                        focusNode: _fNode,
                        controller: _textController,
                        textAlignVertical: TextAlignVertical.center,
                        // style: textFieldStyle(textStyles, appColors.onBackground),
                        onChanged: (val){

                          //Set statae is called to update the internal state
                          //No state variables are changed, however the chnage is recorded within the text editting controller
                          setState(() {});

                          //Calls onChanged to update the parent widget
                          if(widget.onChanged != null){
                            widget.onChanged(val);
                          }
                        },
                        decoration: InputDecoration(

                          //Hard centering for text
                          contentPadding: EdgeInsets.only(
                            bottom: 15.5
                          ),
                          border: InputBorder.none,
                          hintText: widget.hintText ?? 'Search',
                          // hintStyle: textFieldStyle(textStyles, hintColor(appColors)),
                        ),
                      ),
                    ),

                    //Cancel button for neumorphic search bar
                    _textController.value.text.isEmpty ?
                     Container() : 
                     GestureDetector(
                        onTap: (){
                          //Resets textfield thorugh controller
                          setState(() {
                            _textController.clear();
                          });

                          //Calls onChanged to update the parent widget
                          if(widget.onChanged != null){
                            widget.onChanged('');
                          }

                          _fNode.requestFocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0, right: 8),
                          child: Icon(Icons.cancel, color: Colors.grey.withOpacity(0.8),),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),

          //Cancel button, only visisble when the textfield is empty
          //Also displays the cancel button on neumorphic search bars when the text field has focus
          _textController.value.text.isNotEmpty
          || _fNode.hasFocus ? GestureDetector(
            onTap: (){
              //Resets textfield thorugh controller
              setState(() {
                _textController.clear();
              });

              //Calls onChanged to update the parent widget
              if(widget.onChanged != null){
                widget.onChanged('');
              }

              //Removes the focus from the text field, collaping the keyboard
              _fNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text('Cancel'),
            ),
          ) : Container()
        ],
      ),
    );
  }
}