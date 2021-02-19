import 'package:flutter/material.dart';

import '../../util/colorProvider.dart';

///Text widget that is styled using error styling
class ErrorText extends StatelessWidget {

  final String text;

  final bool show;

  const ErrorText(this.text, {Key key, this.show = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return Text(
      show != false ? (text ?? '') : '',
      style: textStyles.caption.copyWith(color: appColors.red, fontWeight: FontWeight.w600),
    );
  }
}