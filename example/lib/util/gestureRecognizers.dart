import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

///Contains any custom gesture regonziers used by the application. 
///These are fed into a `RawGestureDectecor` for finer tune control over gesture pointers and events.

enum _DragState {
  ready,
  possible,
  accepted,
}

///A Gesture Arena member that always wins within any drag gesture recognizers
class PanEagerGestureRecognizer extends OneSequenceGestureRecognizer {

  _DragState _dragState;

  GestureDragUpdateCallback onUpdate;
  GestureDragEndCallback onEnd;
  
  PanEagerGestureRecognizer({this.onEnd, this.onUpdate}) : _dragState = _DragState.possible;

  @override
  void addPointer(PointerEvent event) {

    //Starts tracking the pointer
    startTrackingPointer(event.pointer, event.transform);

    _dragState = _DragState.ready;
  }

  @override
  void handleEvent(PointerEvent event) {

    try{
      assert(_dragState != _DragState.possible);
    }catch(e){
      return;
    }
    

    //rejects and removes the pointer
    if(event is PointerCancelEvent || event is PointerUpEvent || event is PointerExitEvent){

      ///Calls the [onEnd] function
      if(onEnd != null){
        final DragEndDetails details = DragEndDetails(
          primaryVelocity: 0.0,
          velocity: Velocity.zero
        );
        onEnd(details);
      }

      _dragState = _DragState.accepted;
      
      resolvePointer(event.pointer, GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
    }

    //If the pointer is being dragged
    if (event is PointerMoveEvent) {

      if((event.delta.dy != 0 || event.delta.dx != 0)){
        //Accepts the pointer if it has moved
        resolvePointer(event.pointer, GestureDisposition.accepted);
        _dragState = _DragState.accepted;

      }

      ///Calls the [onUpdate] function if the pointer is accepted
      if(onUpdate != null && _dragState == _DragState.accepted){
        final DragUpdateDetails details = DragUpdateDetails(
          sourceTimeStamp: event.timeStamp,
          delta: event.localDelta,
          primaryDelta: null,
          globalPosition: event.position,
          localPosition: event.localPosition,
        );
        onUpdate(details);
      }
      
    }
    else if(!(event is PointerDownEvent)){
      resolvePointer(event.pointer, GestureDisposition.rejected);
    }
  }

  @override
  String get debugDescription => 'singlePointerDrag';

  @override
  void didStopTrackingLastPointer(int pointer) {}

}