import 'package:example/components/widgets/fadeUserImage.dart';
import 'package:example/components/widgets/wrapped_list_tile.dart';
import 'package:example/models/userInfo.dart';
import 'package:example/state/store/pollarStoreBloc.dart';
import 'package:example/state/store/pollarStoreBlocBuilder.dart';
import 'package:example/util/colorProvider.dart';
import 'package:flutter/material.dart';

enum ProfileCardMode {
  TILE, FOLLOW, FOLLOWTILE
}

///Profile card that displays user information. 
///Can be pressed to navigate to the users profile
class ProfileCard extends StatelessWidget {

  ///The user witin the card
  final UserInfo user;

  ///the ontap function run on the user card when tapped
  final Function(String userId) onTap;

  ///The type of the card
  final ProfileCardMode mode;

  ///The widget that appears at the end of the tile
  final Widget trailing;

  ///On options press for `card mode`
  final Function(UserInfo) onOptionsPress;

  //Internal content padding
  final EdgeInsets padding;

  const ProfileCard({Key key, @required this.user, this.onTap, this.mode = ProfileCardMode.TILE, this.trailing, this.onOptionsPress, this.padding }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    if(user?.validate() != true){
      //User not valid
      return Container();
    }

    if(mode == ProfileCardMode.FOLLOW) return Container();

    return WrappedListTile(
      onTap: (){
        if(user?.id != null && user.id.isNotEmpty){
          if(onTap != null) onTap(user.id);
        }
      },
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: ClipOval(
          child: Container(
            height: 50,
            width: 50,
            child: FadeInUserImage(profileImg: user?.profilePicture, fit: BoxFit.cover,),
          ),
        ),
      ),
      title: '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
      subtitle: Text('${user.username}', style: textStyles.caption.copyWith(color: appColors.grey),),

      //Builds trailing or follow button
      trailing: trailing != null ? trailing : mode == ProfileCardMode.TILE ? trailing : Container(),
      contentPadding: padding,
    );
  }

}

///Streams a profile card through pollar store state
class ProfileCardBuilder extends StatelessWidget {

  ///The the profile user id
  final String userId;

  ///The type of the card
  final ProfileCardMode mode;

  ///The widget that appears at the end of the tile
  final Widget trailing;

  ///The function that runs on tap
  final Function(String id) onTap;

  ///On options press for `card mode`
  final Function(UserInfo) onOptionsPress;

  //Padding around the tile
  final EdgeInsets padding;

  const ProfileCardBuilder({Key key, @required this.userId, this.mode = ProfileCardMode.TILE, this.trailing, this.onOptionsPress, this.onTap, this.padding}) : assert(userId != null) , super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Key('user-card-builder-hero-key-$userId'),
      child: StoreBuilder<UserInfo>(
        key: StoreBuilder.getKey<UserInfo>(userId),
        subjectID: userId,
        builder: (context, user, _) {

          
          return ProfileCard(user: user, mode: mode, trailing: trailing, onOptionsPress: onOptionsPress, onTap: onTap, padding: padding,);
        },
      ),
    );
  }
}