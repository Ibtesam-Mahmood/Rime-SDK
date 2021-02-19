          // createButton("send Auth Code Text", () async {
          //   try {
          //     api.UserPhoneNumber userPhoneNumber =
          //         await api.AuthApi.sendAuthCodeText(_phoneNumber);
          //     _print(userPhoneNumber.code);
          //     _phoneAuthCode = userPhoneNumber.code;
          //   } catch (e) {
          //     _print(e.toString());
          //   }
          // }), 
          /* createButton("verify Text Code", () async {
            try {
              String response = await api.AuthApi.verifyPhoneAuthCode(
                  _phoneNumber, _phoneAuthCode);
              _print(response);
            } catch (e) {
              _print(e.toString());
            }
          }), */
          /* createButton("send Auth Code Email", () async {
            try {
              api.UserEmail userEmail = await api.AuthApi.sendAuthCodeEmail(_email);
              _print(userEmail.code);
              _emailAuthCode = userEmail.code;
            } catch (e) {
              _print(e.toString());
            }
          }),
          createButton("verify Email  Code", () async {
            try {
              String response = await api.AuthApi.verifyEmailAuthCode(_email, _emailAuthCode);
              _print(response);
            } catch (e) {
//               _print(e.toString());
//             }
//           }), */

//           createButton("Signup", () async {
//             try {
//               String username = forms["signup"].controllers["username"].text;
//               String firstName = forms["signup"].controllers["firstName"].text;
//               String lastName = forms["signup"].controllers["lastName"].text;
//               String email = forms["signup"].controllers["email"].text;
//               String phoneNumber = forms["signup"].controllers["phoneNumber"].text;
//               String password = forms["signup"].controllers["password"].text;

//               UserMain signupUserMain = new UserMain(username: username, email: email, phone: phoneNumber, password: password);
//               UserInfo signupUserInfo = new UserInfo(firstName: firstName, lastName: lastName);

//               Tuple2<UserMain, UserInfo> response = await api.SignupApi.signup(signupUserMain, signupUserInfo);
//               _print(response.item2.toString());
//               setState(() {
//                 _loggedIn = true;
//               });
//             } catch (e) {
//               _print(e.toString());
//             }
//           }),

//           createButton("w0w", () => _print("w0w")),
//           createButton("awesome", () => _print("awesome")),
//           createButton("swe3t", () => _print("swe3t")),
//         ],
//       ),
//     );
//   }

//   List<Widget> _allForms() {
//     List<Widget> widgets = [];
//     forms.forEach((k, v){
//       widgets.add(Column(children: <Widget>[
//         Text(k),
//         v,
//       ],));
//     });
//     return widgets;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           // crossAxisAlignment: CrossAxisAlignment.start,

//           // mainAxisAlignment: MainAxisAlignment.start,
//           children: <Widget>[
//             Expanded(child: ListView(children: [userDisplay()])),
//             Expanded(child: ListView(children: [buttons()])),
//             Expanded(child: ListView(children: _allForms())),
//           ],
//         ),
//       ),
//     ));
//   } */
// =======
// /* import 'package:flutter/material.dart';
// import 'package:pollar/api/form.dart';
// import 'package:pollar/models/userInfo.dart';
// import 'package:pollar/models/userMain.dart';
// import 'package:tuple/tuple.dart';
// import "api.dart" as api;

// class ApiScreen extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() {
//     return ApiScreenState();
//   }
// }

// class ApiScreenState extends State<ApiScreen> {
//   //state
//   bool _loggedIn = false;
//   UserInfo userInfo = null;
//   UserMain userMain = null;
//   String _printInfo = "prints go here";
//   String _phoneAuthCode = "";
//   String _emailAuthCode = "";


//   Map<String, FormWidget> forms = {
//     // "signup": FormWidget(["firstName", "lastName"]),
//     "email": FormWidget(["email"]),
//     "phone": FormWidget(["phone"]),
//     "signup": FormWidget(["firstName", "lastName", "email", "phoneNumber", "username", "password"]),
//   };

//   // String get _phoneNumber => "12269197946";
//   String get _phoneNumber => forms["phone"].controllers["phone"].text;
//   // String get _email => "isaiahballah@gmail.com";
//   String get _email => forms["email"].controllers["email"].text;

//   void _print(String printInfo) {
//     setState(() {
//       _printInfo = printInfo;
//       print(printInfo);
//     });
//   }

//   //widget builder helper function
//   Widget createButton(text, function) {
//     return RaisedButton(
//       child: Container(height: 20, child: Text(text)),
//       onPressed: function,
//     );
//   }

//   Widget userInfoWidget() {
//     return userInfo == null
//         ? Text("no  user info")
//         : Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//                 Text("firstName: " + userInfo.firstName),
//                 Text("lastName: " + userInfo.lastName),
//                 Text("userInfoId: " + userInfo.id),
//               ]);
//   }

//   Widget printInfoWidget() {
//     return Text(_printInfo);
//   }

//   Widget userDisplay() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         Text("Logged in: " + _loggedIn.toString()),
//         SizedBox(
//           height: 10,
//         ),
//         userInfoWidget(),
//         SizedBox(
//           height: 10,
//         ),
//         printInfoWidget()
//       ],
//     );
//   }

//   Widget buttons() {
//     return Center(
//       child: Column(
//         // crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           createButton("login", () async {
//             String username = "getRandomString@gmail.com";
//             String password = "password123";

//             try {
//               Tuple2<UserMain, UserInfo> tuple =
//                   await api.UserMainApi.login(username, password);
//               _print("loggin response recieved");
//               setState(() {
//                 userMain = tuple.item1;
//                 userInfo = tuple.item2;
//                 _loggedIn = true;
//               });
//             } catch (e) {
//               _print(e.toString());
//             }
//           }),
//           createButton("get All UserMain", () async {
//             try {
//               List<UserMain> users = await api.UserMainApi.getAllUserMain();
//               _print("getAllUserMain response recieved");
//               _print(users.toString());
//             } catch (e) {
//               _print(e.toString());
//             }
//           })

//           /* createButton("send Auth Code Text", () async {
// =======
//          /*  createButton("send Auth Code Text", () async {
// >>>>>>> 7b02159b561e8f97ea2547c5943bc384dddc7597
//             try {
//               api.UserPhoneNumber userPhoneNumber =
//                   await api.AuthApi.sendAuthCodeText(_phoneNumber);
//               _print(userPhoneNumber.code);
//               _phoneAuthCode = userPhoneNumber.code;
//             } catch (e) {
//               _print(e.toString());
//             }
//           }), */
//           /* createButton("verify Text Code", () async {
//             try {
//               String response = await api.AuthApi.verifyPhoneAuthCode(
//                   _phoneNumber, _phoneAuthCode);
//               _print(response);
//             } catch (e) {
//               _print(e.toString());
//             }
//           }), */
//           /* createButton("send Auth Code Email", () async {
//             try {
//               api.UserEmail userEmail = await api.AuthApi.sendAuthCodeEmail(_email);
//               _print(userEmail.code);
//               _emailAuthCode = userEmail.code;
//             } catch (e) {
//               _print(e.toString());
//             }
//           }),
//           createButton("verify Email  Code", () async {
//             try {
//               String response = await api.AuthApi.verifyEmailAuthCode(_email, _emailAuthCode);
//               _print(response);
//             } catch (e) {
//               _print(e.toString());
//             }
//           }), */

//           createButton("Signup", () async {
//             try {
//               String username = forms["signup"].controllers["username"].text;
//               String firstName = forms["signup"].controllers["firstName"].text;
//               String lastName = forms["signup"].controllers["lastName"].text;
//               String email = forms["signup"].controllers["email"].text;
//               String phoneNumber = forms["signup"].controllers["phoneNumber"].text;
//               String password = forms["signup"].controllers["password"].text;

//               UserMain signupUserMain = new UserMain(username: username, email: email, phone: phoneNumber, password: password);
//               UserInfo signupUserInfo = new UserInfo(firstName: firstName, lastName: lastName);

//               Tuple2<UserMain, UserInfo> response = await api.SignupApi.signup(signupUserMain, signupUserInfo);
//               _print(response.item2.toString());
//               setState(() {
//                 _loggedIn = true;
//               });
//             } catch (e) {
//               _print(e.toString());
//             }
//           }),

//           createButton("w0w", () => _print("w0w")),
//           createButton("awesome", () => _print("awesome")),
//           createButton("swe3t", () => _print("swe3t")),
//         ],
//       ),
//     );
//   }

//   List<Widget> _allForms() {
//     List<Widget> widgets = [];
//     forms.forEach((k, v){
//       widgets.add(Column(children: <Widget>[
//         Text(k),
//         v,
//       ],));
//     });
//     return widgets;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           // crossAxisAlignment: CrossAxisAlignment.start,

//           // mainAxisAlignment: MainAxisAlignment.start,
//           children: <Widget>[
//             Expanded(child: ListView(children: [userDisplay()])),
//             Expanded(child: ListView(children: [buttons()])),
//             Expanded(child: ListView(children: _allForms())),
//           ],
//         ),
//       ),
//     ));
//   } */
