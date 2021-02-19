import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../util/globalFunctions.dart';
import '../../util/pollar_icons.dart';
import '../widgets/frosted_effect.dart';

///The type of video player
enum VideoPlayerType{
  File, Network, Asset
}

///Video player takes a video url and and uses it to display and play a Video from file, network or asset. 
///The page supports playback, mute, pause and play features. 
///Video sizes based on dynamic aspect ratios
class PollarVideoPlayer extends StatefulWidget {

  ///The url for the video
  final String url;

  ///The file used in a 
  final File file;

  ///The type of video player
  final VideoPlayerType type;

  ///Custom bottom widget under the playback controls. 
  ///By default `padding: 24px` applied from the playback controls.
  final Widget bottom;

  const PollarVideoPlayer({Key key, @required this.url, @required this.type, @required this.file, this.bottom}) 
    : assert(url != null || type == VideoPlayerType.File), 
      assert(file != null || type == VideoPlayerType.Asset || type == VideoPlayerType.Network),
      super(key: key);


  ///Creates an [asset] based video player
  factory PollarVideoPlayer.asset(String url, {Key key, Widget bottom}) => PollarVideoPlayer(
    key: key,
    bottom: bottom,
    url: url,
    file: null,
    type: VideoPlayerType.Asset,
  );


  ///Creates an [network] based video player
  factory PollarVideoPlayer.network(String url, {Key key, Widget bottom}) => PollarVideoPlayer(
    key: key,
    bottom: bottom,
    url: url,
    file: null,
    type: VideoPlayerType.Network,
  );


  ///Creates an [file] based video player
  factory PollarVideoPlayer.file(File file, {Key key, Widget bottom}) => PollarVideoPlayer(
    key: key,
    bottom: bottom,
    url: null,
    file: file,
    type: VideoPlayerType.File,
  );


  @override
  _PollarVideoPlayerState createState(){
    switch (type) {
      case VideoPlayerType.Asset:
        return _PollarVideoPlayerState(VideoPlayerController.asset(url));
        break;
      case VideoPlayerType.Network:
        return _PollarVideoPlayerState(VideoPlayerController.network(url));
        break;
      case VideoPlayerType.File:
        return _PollarVideoPlayerState(VideoPlayerController.file(file));
        break;
      default:
        throw('No type defined for video player');
    }
  }
}

class _PollarVideoPlayerState extends State<PollarVideoPlayer> with SingleTickerProviderStateMixin {

  _PollarVideoPlayerState(this._controller);

  ///Controller that is used to control, find and play the video
  ///Defined by widget thhrough type variable
  final VideoPlayerController _controller;

  ///If the video overlay is shown
  bool showOverlay = true;

  ///Controller used to define animation for the seek bar using the position. 
  ///Animation is needed to deliver position to seek bar, due to video controller only updated 1/sec.
  AnimationController _seekAnimation;

  ///Used to control dismissing the overlay after 3 seconds
  Future _dismissOverlay;

  ///The display string for the start time, formatted [mm:ss]
  String get startTime {
    if(_controller.value.initialized){
      String minutes = _controller.value.position.inMinutes.toString();
      String seconds = PollarFunctions.twoDigits(_controller.value.position.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }

    return '0:00';
  }

  ///The display string for the remaining time, formatted [-mm:ss]
  String get endTime {
    if(_controller.value.initialized){

      //calcualtes the remainder time
      String minutes = remainder.inMinutes.toString();
      String seconds = PollarFunctions.twoDigits(remainder.inSeconds.remainder(60));
      return '-$minutes:$seconds';
    }

    return '-0:00';
  }

  ///Retreives a duarion value for the remaining time left
  Duration get remainder {
    if(_controller.value.initialized){
      return Duration(
        seconds: _controller.value.duration.inSeconds - _controller.value.position.inSeconds
      );
    }

    return Duration(
      seconds: 0
    );
  }

  @override
  void initState() {
    super.initState();

    //Init the video
    initializeVideo();

    //Initalizes the seek animation
    _seekAnimation = AnimationController(vsync: this, duration: Duration(seconds: 1))
      ..addListener(() {if(mounted) setState(() {});});

  }

  @override
  void dispose() {

    _controller.dispose();
    _seekAnimation.dispose();

    super.dispose();
  }

  ///Initializes the video play and starts playing the video
  void initializeVideo() async {

    //Updates the page when the controller updates
    //Page only needs to be updated when the overlay is shown and video is playing
    _controller.addListener(() {
      setState(() {
        _seekAnimation.stop();
        //Update the animation to adjust to the current play rate
        if(_controller.value.isPlaying){
          _seekAnimation.animateTo(1, duration: remainder);
        }
      });
    });

    await _controller.initialize();

    //Toggle overlay to dismiss in 3 seconds
    setOverlay(true);

    //Sets the inital volume
    _controller.setVolume(1);

    _controller.play();

    //Aniamtes to 1 over the duration of the video
    _seekAnimation.animateTo(1, duration: remainder);

  }

  ///Sets the overlay and defines a dismiss function if toggled, 
  ///used to hide the over after 3 seconds
  void setOverlay(bool toggle){
    if(!mounted) return;

    setState(() {
      showOverlay = toggle;
    });

    if(toggle){
      //Define the dismiss function
      _dismissOverlay = Future.delayed(Duration(seconds: 3)).then((_){

        //Do nothing if video is paused
        if(!_controller.value.isPlaying) return;

        //Dismiss overlay in 3 seconds
        setOverlay(false);
      });
    }
    else{
      //reset dismiss function if dismissed
      _dismissOverlay = null;
    }

  }

  ///Navigates to a position in the video by manipulating the controller. 
  ///By defualt video is paused on seek
  ///
  ///seek: [0.0, 1.0]
  void seek(double seek, [bool pause = true]) async {
    if(_controller.value.initialized){
      
      //Puases the video while seeking
      if(pause || seek == 1)
        {await _controller.pause();}
      else
       { await _controller.play();}

      //Moves the cursor
      _seekAnimation.animateTo(seek, duration: Duration(seconds: 0));
      
      //Seek to new positon defined by a ratio of total time
      Duration newPosition = Duration(
        seconds: (_controller.value.duration.inSeconds * seek).floor()
      );
      
      _controller.seekTo(newPosition);

      setState(() {});

    }
  }

  ///Returns the current seek value for the video. 
  ///Seconds value can be offset
  ///
  ///[0.0 - 1.0]
  double getSeek([int offset = 0]){
    if(!_controller.value.initialized) return 0;

    //If controller is initialized, return seek with offset. 
    //clamped between [0.0, 1.0]
    double seek = (_controller.value.position.inSeconds + offset) / _controller.value.duration.inSeconds;
    return seek > 1 ? 1 : seek < 0 ? 0 : seek;
  }

  @override
  Widget build(BuildContext context) {

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(

      backgroundColor: Colors.black,

      body: Stack(
        children: [

          //Video player
          GestureDetector(
            onTap: (){
              //Toggle the overlay
              setOverlay(!showOverlay);
            },
            child: !_controller.value.initialized ? Container() : Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          ),


          //Pause, play overlay
          _buildPlayBackOverlay(),

          //App bar
          _buildAppBar(),
          
          //Bottom nav bar
          _buildBottomBar(textStyles)

        ],
      ),
      
    );
  }

  ///Builds the playback controls overlay
  ///Only displayed when `showOverlay = true`
  Widget _buildPlayBackOverlay(){
    return Center(
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        opacity: showOverlay ? 1 : 0,
        curve: Curves.decelerate,
        child: Container(
          height: 70,
          width: 200,
          color: Colors.transparent,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                //Seek back button
                GestureDetector(
                  onTap: _controller.value.initialized ? (){
                    //Seek backwards in the video 5s
                    seek(getSeek(-5), false);
                  } : null,
                  child: Icon(PollarIcons.skip_backward, color: _controller.value.initialized ? Colors.white : Colors.white.withOpacity(0.5),)
                ),

                //Pause, play button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 38),
                  child: GestureDetector(
                    onTap: _controller.value.initialized ? (){
                      //Pause of play the video
                      if(_controller.value.isPlaying){
                        _controller.pause();
                      }
                      else{
                        _controller.play();

                        //on video play, toggle overlay
                        setOverlay(false);
                      }
                    } : null,
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5)
                      ),
                      child: Icon(
                        _controller.value.isPlaying ? PollarIcons.pause : PollarIcons.play, 
                        color: Colors.white,
                      )
                    ),
                  ),
                ),

                //Seek forward button
                GestureDetector(
                  onTap: _controller.value.initialized ? (){
                    //Seek backwards in the video 5s
                    seek(getSeek(5), false);
                  } : null,
                  child: Icon(PollarIcons.skip_forward, color: _controller.value.initialized ? Colors.white : Colors.white.withOpacity(0.5),)
                ),

              ],
            ),
          ),
        ),
      )
    );
  }

  ///Builds the seek controls and custom bottom widget in a frosted bottom app bar. 
  ///Only displayed when `showOverlay = true`
  Widget _buildBottomBar(TextTheme textStyles){
    
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        bottom: true,
        child: FrostedEffect(
          frost: showOverlay,
          animateOpacity: true,
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                //Video Play back bar
                Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 24, left: 16, right: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(startTime, style: textStyles.headline6.copyWith(color: Colors.white),),

                      Expanded(
                        child: Slider(
                          value: _seekAnimation.value,
                          min: 0,
                          max: 1,
                          onChanged: (val) => seek(val),
                          onChangeEnd: (_) async {

                            //Replays the video
                            await _controller.play();

                            //Aniamtes to 1 over the remaining duration of the video
                            _seekAnimation.animateTo(1, duration: remainder);
                          },
                          activeColor: Colors.white.withOpacity(1),
                          inactiveColor: Colors.white.withOpacity(0.25),
                        ),
                      ),

                      Text(endTime, style: textStyles.headline6.copyWith(color: Colors.white),)
                    ],
                  ),
                ),

                //Additional custom bottom widget
                widget.bottom ?? SizedBox.shrink()
              ],
            ),
          ),
        )
      ),
    );

  }

  ///Builds the appearing top appbar, holding the close and mute options. 
  //////Only displayed when `showOverlay = true`
  Widget _buildAppBar(){

    return SafeArea(
      top: true,
      child: SizedBox.fromSize(
        size: Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,

            // //Close button
            leading: FrostedEffect(
              frost: showOverlay,
              animateOpacity: true,
              shape: ClipShape.circle,
              child: GestureDetector(
                onTap: Navigator.of(context).pop,
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle
                  ),
                  child: Icon(PollarIcons.cancel, color: Colors.white,),
                ),
              ),
            ),
            centerTitle: true,
            actions: [

              //Mute button
              FrostedEffect(
                animateOpacity: true,
                frost: showOverlay,
                shape: ClipShape.circle,
                child: GestureDetector(
                  onTap: (){
                    //Toggle muted value
                    if(_controller.value.initialized){
                      _controller.setVolume(_controller.value.volume == 0 ? 1 : 0);
                    }
                  },
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle
                    ),
                    child: Icon(_controller.value.volume == 0 ? PollarIcons.no_audio : PollarIcons.audio, color: Colors.white,),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );

  }

}