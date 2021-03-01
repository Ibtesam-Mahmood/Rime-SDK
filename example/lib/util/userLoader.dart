import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide BuildContext;
import '../api/endpoints/userInfoApi.dart';
import '../models/userInfo.dart';
import '../state/loadingState.dart';

///Statically retreives a user and builds a widget based on the loaded user
class UserInfoLoader extends StatelessWidget {

  //User Id fro the user being loaded
  final String userId;

  //Builds the widget based on the UserInfo load state
  final Widget Function(BuildContext, UserInfo) builder;

  const UserInfoLoader({Key key, this.userId, @required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadBloc<UserInfo>, LoadState<UserInfo>>(
      cubit: LoadBloc(() async => userId != null || userId.isNotEmpty ? await UserInfoApi.getUserInfoFromId(userId) : null),
      builder: (context, state) {
        
        UserInfo loadedUser;

        if(state is Loaded){
          loadedUser = (state as Loaded<UserInfo>).content;
        }

        return builder(context, loadedUser);

      }
    );
  }
}