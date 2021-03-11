/// A group of helper functions
/// 
/// These functions mainly help with quick repetitive string formatting
class RimeFunctions {
  /// Turns a userId and channel group index into a valid channelGroupId (according to how Rime uses channel groups)
  /// 
  /// * [String] [userId]: The user whose channel group Ids that are being generated
  /// * [int] [groupNo]: The index of the channel group you'd like
  /// 
  /// Rime uses this function to ensure every user has consistent channel group naming.
  /// Considering the 20,000 channel limit that PubNub imposes per keyset, Rime only uses 0-9
  /// 
  /// * returns [String]: A string formatted to be a Rime channel group Id
  static String channelGroupId(String userId, int groupNo) {
    return 'rime_cg_${userId}_$groupNo';
  }
}
