//~~~~~~~~~~~~~~~ Type defs ~~~~~~~~~~~~~~~~~~~
typedef ChatAcceptedDeterminant = bool Function(String loginUser, List<String> otherUser);

/// Functions that are used within the rime sdk
/// Defined to be overriden by the developer
class RimeDeveloperFunctions {
  /// Determines if the chat is accepted when subscribed
  final ChatAcceptedDeterminant chatAccepted;

  //Defaults any values not provided
  RimeDeveloperFunctions({ChatAcceptedDeterminant chatAcceptedFunction})
      : chatAccepted = chatAcceptedFunction ?? ((_, __) => true);
}
