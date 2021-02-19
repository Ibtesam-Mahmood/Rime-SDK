import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api/endpoints/pollApi.dart';
import '../../api/endpoints/postApi.dart';
import '../../api/endpoints/storyApi.dart';
import '../../api/endpoints/userInfoApi.dart';
import '../../models/poll.dart';
import '../../models/post.dart';
import '../../models/story.dart';
import '../../models/storyResponse.dart';
import '../../models/userInfo.dart';
import 'pollarStoreBloc.dart';
import 'storable.dart';


///The StoreBuilder provides a mechanism to pipeline calls to load a subject into the cache. 
///The refrence to the cahched subject is remained in the application to allow through PollarStore. 
///StoreBuilder will then continue to check if the subject was removed from the cache to reload it.
///
///
///The information for PollarStore is streamed so that any changes to the subject state will reflect in the children of this widget. 
///StoreBuilder also allows for any required information to be loaded onto the subject.
///
///The type of the StoreBuilder defines the type of the subject. Which must be a valid storable object.
///
///Parameters:
///
///[T] - The type of the StoreBuilder and the subject, must be a valid storable object for PollarStore
///
///[subjectID] - The id for the primary subject
///
///[dataLoad] - The call made to load any subsidirary data onto the subject. This is called after the subject is loaded
///
///[determinant] - A function that provides a view of the loaded subject to reflect if the desired properties are retreived or not
///
///[builder] - The child of this widget that is build based on the retrevied subject. The function also provides access toa  bool representing the current value of the determinant
///
///[reload] - Ensures that the subject is reloaded from the server when true
///
///[reloadConditions] - allows the definition of additon conditions where the widget should be rebuilt, each function allows the comparison of old and new states
class StoreBuilder<T extends Storable> extends StatefulWidget {
  
  final String subjectID; //The primary subject id for the store to retreive

  ///An asyncrounous call that populates the desired information for the call
  ///This call must be directly linked to the loading on the desired data through the Store() event
  final List<Future Function(String)> dataLoad;

  //This function defines if the dataLoad call should be made
  //Determines if the relevant information is present in the subject
  final List<bool Function(T)> determinant;

  //Defines additional cases where the store shuold be rebuilt
  final List<bool Function(T oldSubject, T newSubject)> reloadConditions;

  //The builder function that allows for the children to be built based on the state
  //The state of the application reflects the subject
  //The builder also returns a boolean to represent the determinant
  final Widget Function(BuildContext, T, List<bool>) builder;

  //The listner function that allows for the children to be built based on the state
  //The state of the application reflects the subject
  //The builder also returns a boolean to represent the determinant
  final void Function(BuildContext, T, List<bool>) listener;

  ///The child to be displayed
  ///Overrides the builder
  final Widget child;

  //Determines if the subject should be innitially reloaded from the server
  final bool reload;

  //Generates a unique key for the widget's subscriber key
  final Key subKey = UniqueKey();

  ///A store controll can be defined to manipulate the ststa eof the builder
  final StoreController<T> controller;

  StoreBuilder({Key key , @required this.subjectID, this.dataLoad = const [], this.determinant = const [], this.builder, this.reload = false, this.listener, this.child, this.reloadConditions = const [], this.controller}) : assert (dataLoad.length==determinant.length), super(key: key);

  @override
  _StoreBuilderState<T> createState() => _StoreBuilderState<T>();


  ///Generates a key for a typed storebuilder<T>
  static Key getKey<T extends Storable>(String id){
    String keyValue = 'storeBuilder - ';
    if(T == UserInfo){
      keyValue = keyValue + 'UserInfo - ';
    }
    else if(T == Post){
      keyValue = keyValue + 'Post - ';
    }
    else if(T == Poll){
      keyValue = keyValue + 'Poll - ';
    }
    else{
      throw('Type is not storable');
    }
    keyValue = keyValue + (id ?? 'null');
    return Key(keyValue);
  }
}

class _StoreBuilderState<T extends Storable> extends State<StoreBuilder<T>> with AutomaticKeepAliveClientMixin {

  //this state value determines if the dataLoad call is made a7a
  //If the call is made it prevents duplicate dataLoad calls to be made on state reload
  bool _dataLoadCalled = false;

  //this state value determines if the subject load call is made
  //If the call is made it prevents duplicate subject load calls to be made on state reload
  bool _subjectLoadCalled = false;

  //The primary subject for the builder
  T _subject;

  //The connection to the store
  final PollarStoreBloc _storeBloc = PollarStoreBloc();

  //Responsible for loading the subject data when the cache is empty
  Future Function(String) _subjectLoadCall;

  ///The id used to listen for refresh changes
  String _refreshId = '';

  //Defines the subject load call for the storebuilder based on the type
  Future Function(String) _defineSubjectLoadCall(){

    if(T == UserInfo){
      return UserInfoApi.getUserInfoFromId;
    }
    else if(T == Post){
      return PostApi.getPostById;
    }
    else if(T == Poll){
      return PollApi.getPollById;
    }
    else if(T == Story){
      return StoryApi.getStoryById;
    }
    else if(T == StoryResponse){
      return StoryApi.getStoryResponseById;
    }
    else{
      throw('T is not a stored type within the store');
    }
  }

  @override
  void initState() {
    super.initState();
    _subjectLoadCall = _defineSubjectLoadCall();
    refreshBloc(); //Reloads the state to activate the bloc listener

    //Conditionally retreives a fresh subject from the server
    // if(widget.reload || widget.subjectID != null)
    callLoadSubject();
  }

  @override
  void dispose() {
    _storeBloc.drain();
    //Unsubscribes to the subject from the store
    _storeBloc.add(UnSubscribeToSubject<T>(widget.subjectID, widget.subKey.toString()));

    super.dispose();
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();

    if (widget.controller != null)
      {widget.controller._bindEasyRefreshState(this);}
  }

  ///Refreshes the bloc to force load recent state onto the bloc builder
  void refreshBloc(){
    Refresh event = Refresh();
    setRefreshID(event.refreshID);
    PollarStoreBloc().add(event);
  } 


  //Loads the subject from the server
  void callLoadSubject([bool refresh = false]){

    if(refresh) _subject = null;

    //Subject info is not loaded, the primary load call loads the subject
    //Unblocks subject load calls upon completion
    _subjectLoadCall(widget.subjectID).then((loaded) {
      if(mounted) {setState((){
        _subjectLoadCalled = false;
        _subject = loaded;
        // if(loaded is T) _subject = loaded;
      });}
    });

    setState(() {
      //unblocks future dataLoad calls
      _dataLoadCalled = false;
      //blocks subject load calls
      _subjectLoadCalled = true;
    });
  }


  ///Calls the listner
  void callListener(BuildContext context){
    widget.listener(context, _subject, _subject == null ? List<bool>.filled(widget.determinant.length, false) : widget.determinant.map<bool>((d) => d(_subject)).toList());
  }

  ///Determines if the state is worth updating
  ///Prevents out of context reshreshes to occur on each element
  bool _refreshCondition(PollarStoreState o, PollarStoreState n){

    bool _refreshCalc(PollarStoreState oldState, PollarStoreState newState){
      Storable newSubject = newState.retreive<T>(widget.subjectID);

      //Doesnt update if no objects are retreived
      if(newSubject == null) return false;

      ///Refresh called explicitly on this widget
      if(_refreshId == newState.refreshId) return true;

      //Always updates if the subject is not loaded in
      if(_subject == null) return true;

      //Do not reload of new subject is not validated
      //Allows nullable subjects to be loaded in the first time
      if(!(newSubject.validate())) return false;

      //Checks all additional reload conditions
      for (bool Function(T, T) reloadCondition in widget.reloadConditions) {
        if(reloadCondition(_subject, newSubject)) return true;
      }

      //Always updates if the determinant has just loaded in
      for(bool Function(T) det in widget.determinant){
        if(det(_subject) != det(newSubject)) return true;
      }

      //If the newObject is not the oldObject it updates the state
      bool compare = _subject.compare(newSubject);

      // print('Reset $type (${subject.id}) -> ${!compare}');
      return !compare;
    }

    bool refreshCondition = _refreshCalc(o, n);

    return refreshCondition;
  }

  ///Gets the type of the object
  String get type{
    if(T == UserInfo){
      return 'UserInfo';
    }
    else if(T == Post){
      return 'Post';
    }
    else if(T == Poll){
      return 'Poll';
    }
    else{
      return 'T';
    }
  }


  @override
  Widget build(BuildContext context) {

    super.build(context);

    return BlocListener<PollarStoreBloc, PollarStoreState>(
      bloc: _storeBloc,
      condition: _refreshCondition,
      listener: (context, state){
        Storable retreivedValue = state.retreive<T>(widget.subjectID);

        if(retreivedValue != null){

          //Do not subscribe to or call data load on validated objects
          if(retreivedValue.validate()){
          
            //When the value is loaded the builder subscribes to it, if not already subscribed 
            if(!state.isSubscribed<T>(widget.subjectID, widget.subKey.toString())){
              _storeBloc.add(SubscribeToSubject<T>(widget.subjectID, widget.subKey.toString()));
            }
            
            //Runs if the determinant is false and if the request has not been made
            if(!_dataLoadCalled && widget.dataLoad != null){
              
              for (var i = 0; i < widget.determinant.length ; i++) {
                if(widget.determinant[i](retreivedValue) == false){
                  widget.dataLoad[i](widget.subjectID);
                }
              }
              //Info not comletely loaded, make call to load info
              setState(() {
                //blocks duplicate aysnc calls on bloc update for dataLoad
                _dataLoadCalled = true;
              });

            }
          }

          //Updates the subject information
          setState(() {
            _subject = retreivedValue;
          });

        }
        else if(!_subjectLoadCalled && widget.subjectID != null){
          callLoadSubject();
        }

        if(widget.listener != null)
          {widget.listener(context, _subject, _subject == null ? List<bool>.filled(widget.determinant.length, false) : widget.determinant.map<bool>((d) => d(_subject)).toList());}
      },

      //Builds the nested widget
      child: (widget.child ?? 
        (widget.builder != null ? 
          widget.builder(context, _subject, _subject == null ? List<bool>.filled(widget.determinant.length, false) : widget.determinant.map<bool>((d) => d(_subject)).toList()) 
          : null)
        ?? Container()),
    );
  }

  ///Updates the refresh id to listen for
  void setRefreshID(String id) =>  _refreshId = id;

  @override
  bool get wantKeepAlive => true;
}


class StoreController<T extends Storable> {

  _StoreBuilderState<T> _state;

  StoreController();

  ///Reloads the subject and sbsidary information
  void refresh(){
    if(_state != null){
      _state.callLoadSubject(true);
    }
  }

  ///Refreshes the store bloc
  void recheck(){
    if(_state != null){
      _state.refreshBloc();
    }
  }

  ///Recalls the listener for the store builder
  void build(BuildContext context){
    if(_state != null){
      _state.callListener(context);
    }
    else{
      print('store null');
    }
  }

  void update(){
    if(_state != null){
      _state.refreshBloc();
    }
    else{
      print('store null');
    }
  }


  ///Binds the state of the store to the controller
  void _bindEasyRefreshState(_StoreBuilderState<T> newState) => _state = newState;

  ///Called to properly dispose the controller
  void dispose() => _state = null;
}

/*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Example Code ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

StoreBuilder<UserInfo>(
  subjectID: '5e26641b3b59060017eba4bf',
  dataLoad: (id) async {
    FollowApi.getWhoAUserFollows(id);
    FollowApi.getWhoFollowsAUser(id);
  },
  determinant: (user) => user.following != null && user.followers != null,
  builder: (context, user, loaded){
    return Card(
      child: ListTile(
        title: Text('${user?.firstName} ${user?.lastName}'),
        subtitle: loaded ? Text('${user.following.length} Following | ${user.followers.length} Followers') : null,
      ),
    );
  },
)

*/