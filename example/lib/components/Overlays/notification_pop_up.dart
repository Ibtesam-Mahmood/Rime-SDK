// import 'package:flutter/material.dart';

// import '../../util/colorProvider.dart';

// ///Builds a confirmation pop up overlay. 
// ///Displays a message with an ontap action
// ///Can be swiped to dismiss
// class NotificationPopUp extends StatelessWidget {
  
//   ///The title on the noptification
//   final String title;

//   ///The notification subtitle
//   final String subtitle;
  
//   ///The primary image url
//   final String primary;

//   ///The function that runs when the pop up is tapped
//   final VoidCallback onTap;

//   const NotificationPopUp({Key key, this.primary, this.onTap, this.title = '', this.subtitle = ''}) : super(key: key);
  
//   @override
//   Widget build(BuildContext context) {

//     //Color provider
//     final appColors = ColorProvider.of(context);

//     //Text style provider
//     final textStyles = Theme.of(context).textTheme;

//     return SafeArea(
//       bottom: true,
//       top: true,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         child: GestureDetector(
//           onVerticalDragUpdate: (details){
//             //Dismiss notification on vertical swipe
//             if(details.delta.dy.abs() > 1){
//               Notifeye().add(DismissNotification(context: context));
//             }
//           },
//           onTap: (){
//             if(onTap != null) {
//               onTap();
//             }
//           },
//           child: EECard(
//             color: appColors.surface.withOpacity(0.94),
//             borderRadius: BorderRadius.circular(16),
//             child: WrappedListTile(
//               leading: OverlappingProfilePicture(topImage: primary, height: 50, width: 50,),
//               title: title,
//               titleStyle: textStyles.bodyText2.copyWith(color: appColors.onBackground),
//               subtitle: Text(subtitle, style: textStyles.caption.copyWith(color: appColors.grey),),
//               contentPadding: EdgeInsets.all(16),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }