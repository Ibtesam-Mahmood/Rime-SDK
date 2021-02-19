

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../state/chat/chatBloc.dart';
import '../state/chat/chatEvent.dart';
import '../state/store/pollarStoreBloc.dart';
import 'package:pubnub/core.dart';

///General functions used in the managing of chat sstate within pollar
class ChatFunctions {
  ///Reposible for handling receiving newMessages and altering the Chat model accordingly. 
  ///Acts as feedBack loop for personal messages to see if they were delivered. 
  ///adds the messages to the end of the list
  static Chat handleNewMessage(Chat currentChat, ChatMessage message) {

    bool validMessage = !(message is SettingMessage) && !(message is ReadMessage) && !(message is SettingMessage);

    if(currentChat?.messages?.length == 1 && message.clientID == PollarStoreBloc().loggedInUserID && validMessage){
      currentChat.messages.insert(0, DateMessage(clientID: 'DateMessage', timeToken: message.timeToken));
    }
    else if(message.clientID != PollarStoreBloc().loggedInUserID && validMessage){
      DateMessage dateMessage = findNewDateMessage(message, currentChat.messages, currentChat.messages.length - 1);
      if(dateMessage != null){
        currentChat.messages.add(dateMessage);
      }
    }
    else if(validMessage){
      DateMessage dateMessage = findNewDateMessage(message, currentChat.messages, currentChat.messages.length - 2);
      if(dateMessage != null){
        currentChat.messages.insert(currentChat.messages.length - 1, dateMessage);
      }
    }

    //If the message was sent by the login user
    bool isYourMessage = message.clientID == PollarStoreBloc().loggedInUserID;

    //Verify message was delivered
    message.delivered = true;

    ///Check if message is [Delete Message]
    if(message is DeleteMessage){
      if(isYourMessage){
        //Delete message sent by you, delete previous messages
        currentChat = currentChat.copyWith(Chat(messages: [], hidden: true));
        return currentChat;
      }
      else{
        //Delete message sent by other user, ignore
        return currentChat;
      }
    }

    ///Check if message is [Read Message]
    if(message is ReadMessage){
      if(isYourMessage){
        ///If not remove other read message and `add` the new read message
        currentChat = currentChat.copyWith(Chat(read: true));
        return currentChat;
      }
      else{
        //Remove old user read message and track new read message
        currentChat.messages.remove(currentChat.readMessageIndex[currentChat.id]);
        currentChat.messages.add(message);
        currentChat.readMessageIndex[currentChat.id] = message;
        return currentChat;
      }
    }
    
    ///Handle all other [Messages]
    
    if(isYourMessage){

       //Set read tag
      currentChat = currentChat.copyWith(Chat(read: true));

      //Is user's message, check delivered value and update read status
      int index = currentChat.messages.indexWhere((element) => element.id == message.id);
      
      if(index == -1){

        //Message not current added, add message
        currentChat.messages.add(message);

        //Updates the timeToken on the current chat
        ChatBloc().add(EditChatEvent(currentChat.id, Chat(timeToken: DateTime.now())));
      }
      else{
        currentChat.messages[index].delivered = true;
      }
    }
    else{
      //Not your message, set read to false and add to list
      currentChat.messages.add(message);
      currentChat = currentChat.copyWith(Chat(read: false));

      //Updates the timeToken on the current chat
      ChatBloc().add(EditChatEvent(currentChat.id, Chat(timeToken: DateTime.now())));
    }

    //Unhide chat
    currentChat = currentChat.copyWith(Chat(hidden: false, timeToken: DateTime.now()));

    //Return updated chat model
    return currentChat;

  }

  ///Handles receiving old messages in the chat. 
  ///appends mesages to the front of the list.
  static Chat handleOldMessage(Chat currentChat, ChatMessage oldMessage){
    
    ///Handle if message is [Read Message]
    if(oldMessage is ReadMessage){
      if(oldMessage.clientID == PollarStoreBloc().loggedInUserID){
        //Ignore own read message
        return currentChat;
      }
      else{
        if(currentChat.readMessageIndex?.isEmpty != false){
          currentChat.readMessageIndex[currentChat.id] = oldMessage;
        }
      }
    }
    
    if(!(oldMessage is DeleteMessage)){
      
      //Set delivered tag
      oldMessage.delivered = true;

      //Handle all other message types
      //Add to front of list
      currentChat.messages.insert(0, oldMessage);
    }

    return currentChat;

  }

  ///Parses a list of messages into the chat object, adding date messages appropriatly. 
  ///A list of messages is passed in which is loaded from the channel, and a start index for the current message offset in the list
  static Chat handleOldMessageList(Chat chat, List<BaseMessage> messages, int startIndex){

    assert(startIndex >= 0);
    assert(messages != null);
    assert(chat != null);

    //Add messages to list of messages
    for(int i = messages.length - 1; i >= startIndex; i--){
      ChatMessage m = ChatMessage.decodeMessage(messages[i]);

      if(i < messages.length - 1){
        if(!(m is ReadMessage) && !(m is DeleteMessage)){
          DateMessage dateMessage = addDateMessage(m, messages, i + 1);

           if(dateMessage != null){
            //Add date message
            chat.messages.insert(0, dateMessage);
          }
        }
      }

      if(m is DeleteMessage && m.clientID == PollarStoreBloc().loggedInUserID){
        chat.messages.insert(0, DateMessage(clientID: 'DateMessage', timeToken: chat.messages[0].timeToken));
        break;
      }

      //Set delivered tag
      m.delivered = true;

      chat = ChatFunctions.handleOldMessage(chat, m);

    }

    return chat;
  }

  static DateMessage addDateMessage(ChatMessage message, List<BaseMessage> allMessages, int beginIndex){

    //Don't compare delete or read messages
    if(!(message is ReadMessage) && !(message is DeleteMessage) && !(message is SettingMessage)){

      ChatMessage tempMessage = ChatMessage.decodeMessage(allMessages[beginIndex]);

      while((tempMessage is ReadMessage || tempMessage is DeleteMessage)){
        
        //Don't compare to older messages if delete message is found
        if(tempMessage is DeleteMessage){
          return null;
        }

        //Move message to next index
        tempMessage = ChatMessage.decodeMessage(allMessages[beginIndex]);

        if(beginIndex == allMessages.length - 1) break;

        //Increment
        ++beginIndex;

        if(beginIndex == allMessages.length - 1 && ((tempMessage is ReadMessage) || (tempMessage is DeleteMessage))) {return null;}
        else if(beginIndex == allMessages.length - 1) break;
      }

      //Return DateMessage
      if(tempMessage.timeToken.difference(message.timeToken) >= Duration(hours: 2)){
        return DateMessage(clientID: 'DateMessage', timeToken: tempMessage.timeToken);
      }

    }

    //If no DateMessage should be displayed return null
    return null;
  }

  ///Hashes the current time to md5 [128-bit hash]
  static String hash(){

    DateTime date = DateTime.now();

    //Convert to List<int>
    var encode = utf8.encode(date.toString());

    //Convert to md5
    var convert = md5.convert(encode);

    //Conver to string
    return convert.toString();
  }

   static DateMessage findNewDateMessage(ChatMessage message, List<ChatMessage> allMessages, int beginIndex){

    //Don't compare delete or read messages
    if(!(message is ReadMessage) && !(message is DeleteMessage) && !(message is SettingMessage)){

      ChatMessage tempMessage = allMessages[beginIndex];

      while((tempMessage is ReadMessage || tempMessage is DeleteMessage)){
        
        //Don't compare to older messages if delete message is found
        if(tempMessage is DeleteMessage){
          return null;
        }

        //Move message to next index
        tempMessage = allMessages[beginIndex];

        if(beginIndex == allMessages.length - 1) break;

        //Increment
        ++beginIndex;

        if(beginIndex == allMessages.length - 1 && ((tempMessage is ReadMessage) || (tempMessage is DeleteMessage))) {return null;}
        else if(beginIndex == allMessages.length - 1) break;
      }

      //Return DateMessage
      if(message.timeToken.difference(tempMessage.timeToken).abs() >= Duration(hours: 2)){
        return DateMessage(clientID: 'DateMessage', timeToken: message.timeToken);
      }

    }

    //If no DateMessage should be displayed return null
    return null;
  }

}