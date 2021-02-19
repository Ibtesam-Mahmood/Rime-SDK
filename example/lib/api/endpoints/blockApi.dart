import 'package:pollar/api/request.dart';
import 'package:pollar/models/follow.dart';
import 'package:pollar/models/trust.dart';
import 'package:pollar/models/userInfo.dart';
import 'package:pollar/models/userSettings.dart';
import 'package:pollar/state/store/pollarStoreBloc.dart';

class BlockApi {

  //Determines if a user blocks the logged in user
  static Future<bool> doesBlock(String userInfoId) async {
    Map response = await request.get('/block/check/$userInfoId');
    
    //Checks if the response was successful
    if (response['statusCode'] == 200) {
      return response['blockStatus'];
    }
    return Future.error(response['message'].toString());
  }

  ///Blocks the user by ID
  ///Removes any mutal follows or trusts
  static Future<bool> blockUser(String userInfoId) async {

    //Updates the blocked user list to improve response time
    UserSettings settings = PollarStoreBloc().loginSettings;
    List<String> blockedList = [...settings.blocked, userInfoId];
    PollarStoreBloc().add(EditPollarStoreState(loginSettings: settings.copyWith(UserSettings(blocked: blockedList))));

    //Retreives the loggedInUser and receipientUser to update for faster response time
    String loginUserID = PollarStoreBloc().loggedInUserID;
    UserInfo loggedInUser = PollarStoreBloc().retreive<UserInfo>(loginUserID);
    UserInfo recipientUser = PollarStoreBloc().retreive<UserInfo>(userInfoId);

    //Removes follows and trusts between the users

    //fast reponse time function
    if(loggedInUser != null){
      List<Follow> userFollowing = (loggedInUser.following ?? []).where((f) => f.recipientId != userInfoId).toList();
      List<Follow> userFollowers = (loggedInUser.followers ?? []).where((f) => f.userInfoId != userInfoId).toList();
      List<Trust> userTrusting = (loggedInUser.whoITrust ?? []).where((t) => t.recipientId != userInfoId).toList();
      List<Trust> userTrusts = (loggedInUser.whoTrustsMe ?? []).where((t) => t.userInfoId != userInfoId).toList();
      PollarStoreBloc().store(loggedInUser.copyWith(UserInfo(following: userFollowing, followers: userFollowers, whoITrust: userTrusting, whoTrustsMe: userTrusts)));
    }
    //Stores and modifies the receipint if found
    if(recipientUser != null){
      List<Follow> userFollowing = (recipientUser.following ?? []).where((f) => f.recipientId != loginUserID).toList();
      List<Follow> userFollowers = (recipientUser.followers ?? []).where((f) => f.userInfoId != loginUserID).toList();
      List<Trust> userTrusting = (recipientUser.whoITrust ?? []).where((t) => t.recipientId != loginUserID).toList();
      List<Trust> userTrusts = (recipientUser.whoTrustsMe ?? []).where((t) => t.userInfoId != loginUserID).toList();
      PollarStoreBloc().store(recipientUser.copyWith(UserInfo(following: userFollowing, followers: userFollowers, whoITrust: userTrusting, whoTrustsMe: userTrusts)));
    }

    Map response = await request.put('/block/user/$userInfoId', contentType: 'application/json');
    
    //Checks if the response was successful
    if (response['statusCode'] == 200) {
      return true;
    }
    return Future.error(response['message'].toString());
  }
  
  ///Unblocks the listed user by ID
  static Future<bool> unBlockUser(String userInfoId) async {

    //Updates the blocked user list to improve response time
    UserSettings settings = PollarStoreBloc().loginSettings;
    List<String> blockedList = settings.blocked.where((id) => id != userInfoId).toList();
    PollarStoreBloc().add(EditPollarStoreState(loginSettings: settings.copyWith(UserSettings(blocked: blockedList))));

    Map response = await request.delete('/block/user/$userInfoId', contentType: 'application/json');
    
    //Checks if the response was successful
    if (response['statusCode'] == 200) {
      return true;
    }
    return Future.error(response['message'].toString());
  }

}