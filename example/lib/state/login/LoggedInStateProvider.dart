

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide BuildContext;
import 'loginBloc.dart';
import 'loginState.dart';


///Provides the logged in state for its child
///Provides a null object to the child when
///Should be only used when state is logged in
class LoggedInStateProvider extends StatelessWidget {

  final Widget Function(BuildContext, LoggedInState) builder;

  const LoggedInStateProvider({Key key, this.builder}) : super(key: key);

  ///Returns the current logged in state when logged in
  ///else returns null
  static LoggedInState loggedInState(BuildContext context){
    LoginState currentState = BlocProvider.of<LoginBloc>(context).state;

    return currentState is LoggedInState ? currentState : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      cubit: BlocProvider.of<LoginBloc>(context),
      builder: (context, state){
        if(state is LoggedInState){
          return builder(context, state);
        }
        else {return Container();}
      },
    );
  }
}