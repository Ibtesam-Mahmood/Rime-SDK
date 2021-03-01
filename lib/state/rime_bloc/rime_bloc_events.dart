


abstract class RimeEvent {}

/// Iniitalizes the Rime channel service by retreiving and subscring to channels. 
/// 
/// UserID provided is a unique identifier used to access user channels
class RimeInitEvent extends RimeEvent{

  final String userID;

  RimeInitEvent(this.userID);

}
