// import 'package:flutter/material.dart';
// import 'package:overlay_support/overlay_support.dart';
// import 'package:pollar/components/widgets/frosted_effect.dart';
// import 'package:pollar/state/notifeye/Notifeye.dart';
// import 'package:pollar/util/pollar_icons.dart';

// ///Builds a confirmation pop up overlay. 
// ///Displays a message with an ontap action
// ///Can be swiped to dismiss
// class ConfirmationPopUp extends StatelessWidget {
  
//   ///The primary text within the overlay
//   ///Always colored white
//   final String text;
  
//   ///The primary background color
//   final Color primary;

//   ///The position of the notification
//   final NotificationPosition position;

//   ///The function that runs when the pop up is tapped
//   final VoidCallback onTap;

//   const ConfirmationPopUp({Key key, this.text, this.primary = Colors.blue, this.position = NotificationPosition.bottom, this.onTap}) : super(key: key);
  
//   @override
//   Widget build(BuildContext context) {

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
//           child: Stack(
//             children: [

//               //Background, frosted
//               FrostedEffect(
//                 frost: true,
//                 shape: ClipShape.rRect(16),
//                 child: Container(
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: primary.withOpacity(0.94),
//                     borderRadius: BorderRadius.circular(16)
//                   ),
//                 ),
//               ),

//               //Forground, hold context
//               IntrinsicHeight(
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [

//                     //Text display
//                     Expanded(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Text(text, style: textStyles.button.copyWith(color: Colors.white),),
//                       ),
//                     ),

//                     VerticalDivider(color: Colors.white, width: 0.5 ),

//                     //Icon that holds onpress
//                     GestureDetector(
//                       behavior: HitTestBehavior.opaque,
//                       onTap: (){
//                         if(onTap != null) {
//                           onTap();
//                         }
//                       },
//                       child: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Icon(PollarIcons.forward, color: Colors.white,),
//                       ),
//                     )
//                   ],
//                 ),
//               ),

//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }