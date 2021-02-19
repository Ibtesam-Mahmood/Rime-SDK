import 'package:pollar/api/api.dart' as api;
import 'package:pollar/models/category.dart';
import 'package:pollar/models/topics.dart';
import 'package:pollar/models/userMain.dart';

//todo consider changing this to a static function and export through api
//private global variables
//String _alphabet = 'abcdefghijklmnopqrstuvwxyz';
//String _digits = '123456789';
//Random _random = Random(DateTime.now().millisecond);

//private global helper functions
/* String _getRandomString(int length, {String characters}) {
  characters = characters != null ? characters : _alphabet;
  String randomString = '';
  for (int i = 0; i < length; i++) {
    randomString += _alphabet[_random.nextInt(characters.length - 1)];
  }
  return randomString;
} */

/* String _getRandomEmail(int length) {
  return _getRandomString(length) + '@gmail.com';
} */

// void createUserMainTest() async {
//   // required info for a user main from the serverer
//   UserMain newUserMain = UserMain(
//     email: '_getRandomEmail(20)',
//     username: 'getRandomString@gmail.com',
//     phone: _getRandomString(10, characters: _digits),
//     password: 'password123',
//   );
//   UserInfo userInfo = new UserInfo(firstName: 'noob', lastName: 'let');
//   Tuple2<UserMain, UserInfo> tuple =
//       await api.SignupApi.signup(newUserMain, userInfo);
//   print('created user main ' +
//       tuple.item1.toString() +
//       ' || ' +
//       tuple.item2.toString());
// }

void getTopicsTest() {
  api.TopicApi.getTopics().then((topics) {
    for (Topic topic in topics) {
      print(topic.toString());
    }
  });
}

void deleteUserMains() {
  api.UserMainApi.getAllUserMain().then((userMains) {
    for (UserMain userMain in userMains) {
      api.UserMainApi.deleteUserMain(userMain);
    }
  });
}

void login() {
  //String username = 'getRandomString@gmail.com';
  //String password = 'password123';
  // // Tuple<UserMain, UserInfo> loggedIn = awai
  // api.UserMainApi.login(username, password).then((Tuple2 tuple2) {
  //   UserMain userMain = tuple2.item1;
  //   UserInfo userInfo = tuple2.item2;
  //   print(userMain.toString());
  //   print(userInfo.toString());
  //   // print('@@@@');
  //   // print(request.defaultHeaders.toString());
  // });
}

void testing() {

  //api.FollowApi.followUser('5d9a75b91d87761e90984c7b', '5dcc64002200baca14bac8c0').then((var a){print(a);});

  /* UserMain userMain=UserMain(
    username : 'testing1',
    email : 'liamjc22@hotmail.com',
    phone: '12899240967',
    password : 'persheeve',
  );
  UserInfo userInfo=UserInfo(
    firstName : 'Befy',
    lastName : 'B',
    gender: 'Male',
  );
  api.UserMainApi.signup(userMain, userInfo).then((Tuple2<UserMain, UserInfo> u){
    print('usermainid   ' + u.item1.id);
    print('userinfoid   ' + u.item2.id);
    print('phone:  '+u.item1.phone);
    print('name:  '+u.item2.firstName);    
  }); */
  //api.AuthApi.verifyPhoneAuthCode('12899240967', '52896').then((var a){print(a);});
  //api.AuthApi.verifyEmailAuthCode('liamjc22@hotmail.com', '06335').then((var a){print(a);});

  //userid: 5d8e85802bd36eed2101bdf2
  //poll id: 5d9aa7c61d87761e90984c7e
  /* PollResponse b=PollResponse(pollId: '5d9aa7c61d87761e90984c7e', userInfoId: '5da376a6de08ae2f79c8c197', vote: false);
  api.PollApi.addPollResponse(b).then((PollResponse a ){
      print('poll:   '+ a.vote.toString());
      print(a.id.toString());
  });  */
  /*  api.PollResponseApi.getPollResponses().then((List<PollResponse> a){
    print('count: '+a.length.toString());
    for(PollResponse k in a){
      print('prAPI  '+k.id.toString());
    }
  }); */
  /* api.PollResponseApi.getPollResponseById('5dc34468a9c5be001741393c').then((PollResponse a){
    print(a.vote.toString());
    a.vote=true;
    api.PollResponseApi.editPollResponse(a).then((PollResponse c){
      print(c.vote.toString());
  });
  }); */
  /* api.PostApi.getPostById('5dc33d04a9c5be0017413938').then((Post a) {
      print(a.message.toString() + '   postapi');
      a.message='floop';
      api.PostApi.editPost(a).then((Post b){
        print(b.message.toString());
      });
  }); */
  /* Post b = Post(
      parentId: '5dd1a1217402fb00170cb6e8',
      userInfoId: '5d8e85802bd36eed2101bdf2',
      message: 'Hello there persheeve'); */
  //api.PollApi.addPost(b);
  //api.PostApi.getPostByUser('5d8e85802bd36eed2101bdf2').then((List<Post> b){for(Post a in b)print(a.message);});

  //api.PostApi.deletePost('');
  /* api.PollApi.getPollById('5d9aa7c61d87761e90984c7e').then((Poll a){
    print('forst:  '+a.content.toString());
    a.content='Universities profit from events while charging students to attend';
    api.PollApi.editPoll(a).then((Poll b){
      print('second: '+b.content.toString());
    });
  }); */
  /* api.UserInfoApi.getUserInfoFromId('5dc09b454f8ee5001780dc6b').then((UserInfo a) {
      print(a.lastName.toString());
      a.lastName='slayer';
      api.UserInfoApi.editUserInfo(a).then((UserInfo b){
        print(b.lastName);
      });
  }); */
}
//random usermain id: 5d8f0d80737a823fbbfad5a3
// UserInfo loginTest() async {
//     return await api.UserMainApi.login('frhksrhcxiyrhtksfikq', 'password123');

// }

/*
created user main {
  'id':'5da39703de08ae2f79c8c1a0',
  'username':'frhksrhcxiyrhtksfikq',
  'email':'vcjbwemmfpeigxyqjysa@gmail.com',
  'phone':'bgdadghefa',
  'password':'$2b$10$FmB5mMWacw8GesKq9FzkTumdIudU2nH25Qj9uRkCcEHj/nQRCfBAe',
  'isAuth':false
}


*/

void getDaddy() {
  api.CategoryApi.getCategories().then((categories) {
    for (Category cat in categories) {
      print(cat.toString());
    }
  });
}
