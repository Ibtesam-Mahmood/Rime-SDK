import 'package:bloc/bloc.dart';

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ BLOC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

///The bloc used for simple verification proccesses
class VerificationBloc extends Bloc<VerificationEvent, VerificationState>{

  VerificationBloc() : super(initialState);

  static VerificationState get initialState => VerificationState();

  @override
  Stream<VerificationState> mapEventToState(VerificationEvent event) async* {
    if(event is VerifyEvent){ //Start verification event
      yield* _mapVerifyToState(event.verify, event.onVerify, event.onFail);
    }
    else if(event is ResetVerfication){ //Reset verification
      yield VerificationState();
    }
    else if(event is FailedToVerify){ //Failed to verify
      yield VerificationEnded(verified: false, reason: event.error);
    }
    else{ //Verified
      (event as Verified).onVerify();
      yield VerificationEnded(verified: true);
    }
  }

  Stream<VerificationState> _mapVerifyToState(Future<bool> Function() verification, Function onVerify, Function(dynamic) onFail) async* {
    
    //Runs the verification function nested within the event
    verification().then((bool val){
      
      //Passes the onVerify function to the sucessful verification event if defined
      if(val) {add(Verified(onVerify: onVerify??(){}));} //If verfication is successful pushes the verfied event
      else {add(FailedToVerify());} //If verification failed pushes the verification failed event
    })
    .catchError((err){
      if(onFail != null) onFail(err); //Runs the onfail function for the verification
      add(FailedToVerify(error: err)); //If there is in error in verification then pushes the verification failed event
    });
    yield Verifying(); //Meanwhile yeilds the verifying state
  }

}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ STATES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

///Base class for the state
///Acts as the innital state
class VerificationState{}

///The state the page is in when verifying to the server
class Verifying extends VerificationState{}

///The state the page is in when the verification ends
///Hodls a boolean for verifed or not
class VerificationEnded extends VerificationState{
  final bool verified;
  final String reason; //Holds a reason for why the verification suceeded or failed
  VerificationEnded({this.verified, this.reason});
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ EVENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

///Parent class for all verification events
abstract class VerificationEvent{}

///Event is thrown to begin the verification process
///Holds a verify function that is run to verffy the users input
class VerifyEvent extends VerificationEvent{
  final Future<bool> Function() verify;
  final Function onVerify; //Runs when the application is verfied
  final Function(dynamic) onFail; //Runs when the application fails to verify the input
  VerifyEvent(this.verify, {this.onVerify, this.onFail});
}

///Event is thrown if verification fails
class FailedToVerify extends VerificationEvent{
  final dynamic error;
  FailedToVerify({this.error});
}

///Event is thrown if the verification is successful
class Verified extends VerificationEvent{
  final Function onVerify;
  Verified({this.onVerify});
}

//Event run to reset the verfication state
class ResetVerfication extends VerificationEvent{}