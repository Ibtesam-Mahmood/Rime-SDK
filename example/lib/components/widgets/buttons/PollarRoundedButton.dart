import 'package:flutter/material.dart';

///Var to control different sizes of this button
enum SizeVariation { LARGE, MEDIUM, SMALL }

///Genaric button used within the pollar application.
///The specfication for the button are the following:
///
///`18dp rounded border, 52dp height, unbounded width`
class PollarRoundedButton extends StatelessWidget {
  ///The internal widget to be placed within the button. If defined [overrides] the text parameter
  final Widget child;

  ///If no child is define, this parameter is used to display text within the button
  final String text;

  //The color of the text used if child is not defined
  final Color textColor;

  ///The callback function that is run when the button is tapped, if null the button is disabled
  final Function() onPressed;

  ///The color of the button when enabled
  final Color color;

  ///The color of the button when disabled
  final Color disabledColor;

  ///Allows for 3 variations for the PollarRoundedButton
  final SizeVariation sizeVariation;

  ///The circular border radius depth for the button
  final double borderRadius;

  ///The border side on the button
  final BorderSide borderSide;

  const PollarRoundedButton(
      {Key key,
      this.text,
      @required this.onPressed,
      this.color,
      this.disabledColor,
      this.child,
      this.sizeVariation = SizeVariation.LARGE,
      this.borderRadius,
      this.textColor, 
      this.borderSide})
      : super(key: key);

  ///Creats a pollar rounded button from a rounded button specification
  factory PollarRoundedButton.fromSpec({Key key, PollarRoundedButtonSpec spec}){
    return PollarRoundedButton(
      key: key, text: spec.text, onPressed: spec.onPressed, child: spec.child,
      color: spec.color, disabledColor: spec.disabledColor, sizeVariation: spec.sizeVariation,
      borderRadius: spec.borderRadius, textColor: spec.textColor, borderSide: spec.borderSide,
    );
  }

  @override
  Widget build(BuildContext context) {
    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return ButtonTheme(
      height: sizeVariation == SizeVariation.LARGE ? 52 : sizeVariation == SizeVariation.MEDIUM ? 36 : 32,
      minWidth: double.infinity,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      child: FlatButton(
        padding: EdgeInsets.zero,
          splashColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: borderSide ?? BorderSide.none,
              borderRadius: BorderRadius.circular(borderRadius ?? 16)),
          color: color ?? Colors.blue,
          disabledColor: disabledColor ?? color ?? Colors.blue,
          child: child ??
              (text != null
                  ? Text(text,
                      style: sizeVariation == SizeVariation.LARGE
                          ? textStyles.headline5.copyWith(color: textColor)
                          : sizeVariation == SizeVariation.MEDIUM
                              ? textStyles.button.copyWith(color: textColor)
                              : textStyles.headline6.copyWith(color: textColor),)
                  : null),
          onPressed: onPressed),
    );
  }
}

///Creates 2 small varaition 12px border radius polar rounded buttons in a row. 
///The buttons are seperated by `16px` padding. 
///`PollarRoundedButtonSpec` is used to define both buttons, if spec is missing the button is not drawn
class PollarRoundedButtonBar extends StatelessWidget {

  final PollarRoundedButtonSpec firstSpec;
  final PollarRoundedButtonSpec secondSpec;

  ///The padding around the row
  final EdgeInsets padding;

  ///Flex for relative button sizing
  final int specOneFlex;

  ///Flex for relative button sizing
  final int specTwoFlex;

  ///Spacing between buttons (Optional)
  final double spacing;

  const PollarRoundedButtonBar({Key key, @required this.firstSpec, @required this.secondSpec, this.padding, this.specOneFlex = 1, this.specTwoFlex = 1, this.spacing = 16}) : assert(firstSpec != null && secondSpec != null), super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            firstSpec == null ? Container() : Expanded(
              flex: specOneFlex,
              child: PollarRoundedButton.fromSpec(
                spec: firstSpec.copyWith(borderRadius: 12, sizeVariation: SizeVariation.MEDIUM),
              ),
            ),

            //Middle padding only present if both buttons present
            firstSpec == null || secondSpec == null ? Container() : Container(width: spacing),

            secondSpec == null ? Container() : Expanded(
              flex: specTwoFlex,
              child: PollarRoundedButton.fromSpec(
                spec: secondSpec.copyWith(borderRadius: 12, sizeVariation: SizeVariation.MEDIUM),
              ),
            )
          ],
        ),
      ),
    );
  }
}

///A specification for creating a pollar rounded button
class PollarRoundedButtonSpec {
  ///The internal widget to be placed within the button. If defined [overrides] the text parameter
  final Widget child;

  ///If no child is define, this parameter is used to display text within the button
  final String text;

  //The color of the text used if child is not defined
  final Color textColor;

  ///The callback function that is run when the button is tapped, if null the button is disabled
  final Function() onPressed;

  ///The color of the button when enabled
  final Color color;

  ///The color of the button when disabled
  final Color disabledColor;

  ///Allows for 3 variations for the PollarRoundedButton
  final SizeVariation sizeVariation;

  ///The circular border radius depth for the button
  final double borderRadius;

  ///The border side on the button
  final BorderSide borderSide;

  PollarRoundedButtonSpec({
    this.child, 
    this.text, 
    this.textColor, 
    @required this.onPressed, 
    this.color, 
    this.disabledColor, 
    this.sizeVariation, 
    this.borderRadius, 
    this.borderSide
  });

  ///Copies over any defied params intot he specification
  PollarRoundedButtonSpec copyWith({
    Widget child, 
    String text, 
    Color textColor, 
    Function() onPressed, 
    Color color, 
    Color disabledColor, 
    SizeVariation sizeVariation, 
    double borderRadius, 
    BorderSide borderSide
  }){
    return PollarRoundedButtonSpec(
      child: child ?? this.child, 
      text: text ?? this.text, 
      textColor: textColor ?? this.textColor, 
      onPressed: onPressed ?? this.onPressed, 
      color: color ?? this.color, 
      disabledColor: disabledColor ?? this.disabledColor, 
      sizeVariation: sizeVariation ?? this.sizeVariation, 
      borderRadius: borderRadius ?? this.borderRadius, 
      borderSide: borderSide ?? this.borderSide
    );
  }
}