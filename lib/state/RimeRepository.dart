
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/model/channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../rime.dart';


/// Base extendable repository for Rime. 
///
/// Hold information about userIDs and channels.
/// Both of these are held in seperate hive cointainers
class RimeRepository {

  /// Meta data box name
  static const String META_DATA_BOX = 'rime-meta';

  /// Box name that stores all channels
  static const String CHANNEL_BOX = 'rime-channel';

  /// The root pubnub client
  PubNub _client;

  /// Getter for the pubnub client. 
  /// Ensures that client is initialized
  PubNub get client{
    assert(_client != null);
    return _client;
  } 

  /// Getter for the 
  
  /// Used to initialize the repository. 
  /// 
  /// Must be called to initialize the pubnub service. 
  /// 
  Future<bool> initializeRime(String userID) async {
    assert(Rime.INITIALIZED);

    //Opens the meta data box to compare previous initialization
    Box<String> metaBox = await Hive.openBox<String>(META_DATA_BOX);

    //Opens the channel box
    Box<RimeChannel> channelBox = await Hive.openBox<RimeChannel>(CHANNEL_BOX);

    //Retreive previous userID
    String previousId = metaBox.get('userID');

    // Determined by relogging in the same user
    bool isCached = previousId == userID;

    if(!isCached){

      // Clear the hive stores and resets user meta data
      metaBox.put('userID', userID);
      channelBox.clear();

    }

    //Build keyset from dot env
    final pubnubKeySet = Keyset(
      subscribeKey: env['RIME-SUB-KEY'],
      publishKey: env['RIME-PUB-KEY'],
      uuid: UUID(userID)
    );

    // Initialize the pubnub client
    _client = PubNub(defaultKeyset: pubnubKeySet);
    
    return isCached;
  }
  


}