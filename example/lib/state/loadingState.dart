import 'package:bloc/bloc.dart';

/*
  Used to create multple states from the same pattern
  Content type is defined by abstract variable: T

  WARNING: Bloc must take a function that returns Future<T>
*/

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

///Parent class for bloc state generalization
///State in which the content is being loaded
class LoadState<T>{
  LoadState();
}

///Intermidiate state that the bloc is when when the even is loading
class Loading<T> extends LoadState<T>{}

///State in which the content is loaded
///Holds the loaded content
class Loaded<T> extends LoadState<T> {
  T content; //Loaded content
  Loaded(this.content);
}

///State in which Loading for the content was failed
class LoadFailed<T> extends LoadState<T>{
  final String error;
  LoadFailed(this.error);

  @override
  String toString() => error;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Events ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

///Absstract parent class for bloc event generalization
abstract class LoadStateEvent<T>{}

///Event to load the state
class Load<T> extends LoadStateEvent<T>{}

///Event is called to reload the state and provide it a new function to load from
class LoadThis<T> extends LoadStateEvent<T>{
  final Future<T> Function() newLoadCall;
  LoadThis(this.newLoadCall);
}

///Failed load event
class FailedLoadEvent<T> extends LoadStateEvent<T>{
  final String error;
  FailedLoadEvent([this.error = 'Load Failed']);
}

///Sucessful load event
///Holds a loadedVlaue to deliver to the Loaded state
class SuccessfulLoadEvent<T> extends LoadStateEvent<T>{
  final T loadedValue; //Loaded value from call
  SuccessfulLoadEvent(this.loadedValue); 
}

///Used to reset the load state back into the innital value
class Reset<T> extends LoadStateEvent<T>{}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Bloc ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

///Bloc for generalized Load state
class LoadBloc<T> extends Bloc<LoadStateEvent<T>, LoadState<T>>{

  //Future function to be called to load the state
  Future<T> Function() _loadCall;

  //Subsidirary functions that can be defined to provide more interaction
  final Function() onComplete;
  final Function(T) onSuccess;
  final Function() onFail;

  LoadBloc(this._loadCall, {bool innitialLoad = true, this.onComplete, this.onSuccess, this.onFail}){
    //Runs the load call if the innitialLoad value is set to true
    if(innitialLoad){
      add(Load<T>());
    }
    
  }

  @override
  LoadState<T> get initialState => LoadState();

  @override
  Stream<LoadState<T>> mapEventToState(LoadStateEvent<T> event) async* {
    if(event is Load<T>){
      //Loading event
      yield* _mapLoadToState();
    }
    else if(event is LoadThis<T>){
      //Load this function specifically
      yield* _mapLoadThisToState(event.newLoadCall);
    }
    else if(event is SuccessfulLoadEvent<T>){
      //Successful load event
      yield* _mapLoadedToState(event.loadedValue);
    }
    else if(event is FailedLoadEvent){
      //Failed load event
      yield* _mapFailedLoadToState(event.toString());
    }
    else if(event is Reset){
      //Resets to the innitial state
      yield initialState;
    }
  }

  //Manages the Load when a load function is specifically provided event
  Stream<LoadState<T>> _mapLoadThisToState(Future<T> Function() newLoadCall) async* {

     //Checks to see if the new load call is defined before running it
    if(newLoadCall == null){
      yield LoadFailed<T>('New load call not defined');
    }

    newLoadCall().then((val){
      if(onSuccess != null) onSuccess(val); //Calls the on sucess function with the loaded value
      //Push load successful event
      add(SuccessfulLoadEvent<T>(val));
    })
    .catchError((onError){
      if(onFail != null) onFail(); //Calls the on error function when an error is reached
      //Push failed load event
      add(FailedLoadEvent<T>(onError.toString()));
    }).whenComplete((){
      if(onComplete != null) onComplete(); //Calls the on complete function when the call is complete
    });

    //Enters the loading state
    yield Loading();
  }

  //Manages the Load event
  Stream<LoadState<T>> _mapLoadToState() async* {

    //Checks to see if load call is defined before running it
    if(_loadCall == null){
      yield LoadFailed<T>('Load call not defined');
    }

    _loadCall().then((val){
      if(onSuccess != null) onSuccess(val); //Calls the on sucess function with the loaded value
      //Push load successful event
      add(SuccessfulLoadEvent<T>(val));
    })
    .catchError((onError){
      print(onError);
      if(onFail != null) onFail(); //Calls the on error function when an error is reached
      //Push failed load event
      add(FailedLoadEvent<T>(onError.toString()));
    }).whenComplete((){
      if(onComplete != null) onComplete(); //Calls the on complete function when the call is complete
    });

    //Enters the loading state
    yield Loading();
  }

  //Manages the Successful event
  Stream<LoadState<T>> _mapLoadedToState(T val) async* {
    yield Loaded<T>(val);
  }

  //Manages Failed event
  Stream<LoadState<T>> _mapFailedLoadToState(String error) async* {
    yield LoadFailed<T>(error);
  }

  ///Resets the load call for the state
  void setLoadCall(Future<T> Function() newCall) => _loadCall = newCall;

}