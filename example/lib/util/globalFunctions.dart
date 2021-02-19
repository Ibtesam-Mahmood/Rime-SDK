import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:progress_dialog/progress_dialog.dart';

import '../components/Dialogs/confirmAlert.dart';
import '../models/notifications.dart';
import '../models/poll.dart';
import '../models/pollResponse.dart';

///Holds a list of constants used within the application
class PollarConstants {
  
  ///The limit of text within a poll
  static int get POLL_TEXT_LIMIT => 160;

  ///The limit of the recent searches Circular Queue. 
  ///For both [Topics] and [Users]. 
  ///
  ///Currently set to `10`
  static int get RECENT_SEARCH_LIMIT => 10;

  ///The duration for an inapp notification in pollar
  static Duration get POLLAR_NOTIFICATION_TIMEOUT => Duration(seconds: 3);

  static Duration get NORMAL_DURATION => Duration(milliseconds: 300);

}

///Collection of commonly used functions around the application
class PollarFunctions {
  ///Sends out many haptic events to simulate a complex haptic vibration, done when erros are present
  static void hapticErrorVibrate() async {
    HapticFeedback.selectionClick();
    HapticFeedback.selectionClick();
    await Future.delayed(Duration(milliseconds: 150));
    HapticFeedback.lightImpact();
    HapticFeedback.lightImpact();
    await Future.delayed(Duration(milliseconds: 150));
    HapticFeedback.mediumImpact();
    HapticFeedback.mediumImpact();
    await Future.delayed(Duration(milliseconds: 150));
    HapticFeedback.mediumImpact();
  }

  static void hapticCancelVibrate() async {
    HapticFeedback.lightImpact();
  }

  //Clamps a value between to optional upper and lower bounds
  //Clamps an int
  static int clamp(int x, {int max, int min}) {
    if (min != null) {
      if (x < min) return min;
    }
    if (max != null) {
      if (x > max) return max;
    }
    return x;
  }

  //Formats the time since the post was posted
  //Formats(x) xm - xh - xd
  static String formatTime(DateTime time) {
    DateTime now = DateTime.now();
    int timeDifernce = now.difference(time).inMinutes;
    if (timeDifernce / 60 > 1) {
      timeDifernce = (timeDifernce / 60).floor();
      if (timeDifernce / 24 > 1) {
        timeDifernce = (timeDifernce / 24).floor();

        if (timeDifernce >= 7) {
          return DateFormat('MMM dd, yyyy').format(now);
        }

        return '${timeDifernce}d'; //Return time in days
      } else {
        return '${timeDifernce}h';
      } //Return time in hours
    } else {
      return '${timeDifernce == 0 ? 1 : timeDifernce}m';
    } //Return time in minutes
  }

  //Formats a number to display in 3 digits
  //Adds appropriate trailing for value
  static String formatCount(int x) {
    //x is divisible by 1000 breakpoint
    if (x >= 1000) {
      //x is divisible by 1000000 breakpoint
      if (x >= 1000000) {
        return (x / 1000000).toStringAsFixed(1) + 'M';
      }

      return (x / 1000).toStringAsFixed(1) + 'K';
    }

    //x is 3 digits
    return x.toString();
  }

  ///Checks for a permission within the system
  ///If permission is granted runs a callback function an returns true
  ///If permission is not granted prompts the user the permission request and returns true
  ///If permission is never granted return false
  // static Future<bool> promptPermission(PermissionGroup permission) async {
  //   if ((await PermissionHandler().checkPermissionStatus(permission)) ==
  //       PermissionStatus.granted) {
  //     //Permission granded
  //     return true;
  //   } else {
  //     //Permission not granted
  //     //Requests for acces to the system permission
  //     Map<PermissionGroup, PermissionStatus> permissions =
  //         await PermissionHandler().requestPermissions([permission]);

  //     //If permission is authorized return the callback function
  //     if (permissions[permission] == PermissionStatus.granted) {
  //       return true;
  //     } else {
  //       return false;
  //     }
  //   }
  // }

  ///Allows for dynamic searching of a list
  ///If it is a list of strings the search is performed trivally
  ///If the list is a complex object the accessor function must be defined to define how the search index is accessed
  static List<T> search<T>(List<T> list, String filter,
      {String Function(T item) accessor}) {
    //Satitizes the index to perfomr the search
    //Ignores case sensitivity
    String sanitizeIndex(String index) => index.toLowerCase();

    //Throws an error to avoid logical errors within the search code
    if (!(T is String) && accessor == null)
      throw ('accessor cannot be null when type is not String');

    //If the filer is empty the search result is trivial
    if (filter.isEmpty) return list;

    List<T> filteredList = [];

    //Sanitizes the search redex
    filter = sanitizeIndex(filter);

    list.forEach((item) {
      //access search index trivially if the type is a String
      //If not use the accessor function to find the element
      String index = T is String ? item : accessor(item);

      //Satitizes the index
      index = sanitizeIndex(index);

      if (index.contains(filter)) {
        //If the filter is present in the search i dex add the item to the filteredList
        filteredList.add(item);
      }
    });

    //Sorts the list by relevency
    filteredList.sort((a, b) {
      String aIndex = sanitizeIndex(T is String ? a : accessor(a));
      String bIndex = sanitizeIndex(T is String ? b : accessor(b));
      return aIndex.indexOf(filter) > bIndex.indexOf(filter) ? 1 : -1;
    });

    return filteredList;
  }

  ///Returns any integer in 2 digits.
  ///Deos not modify `n >= 10`.
  ///
  ///`Ex: twoDigits(1) = '01'`
  ///
  ///`Ex: twoDigits(100) = '100'`
  static String twoDigits(int n) => n.toString().padLeft(2, '0');

  static int calculateMaxLines(double aspectRatio) {
    if (aspectRatio <= 0.8) {
      return 1;
    } else if (aspectRatio <= 0.857 && aspectRatio > 0.8) {
      return 2;
    } else if (aspectRatio <= 0.923 && aspectRatio > 0.857) {
      return 3;
    } else if (aspectRatio <= 1 && aspectRatio > 0.923) {
      return 4;
    } else if (aspectRatio <= 1.09 && aspectRatio > 1) {
      return 5;
    } else if (aspectRatio <= 1.2 && aspectRatio > 1.09) {
      return 6;
    } else if (aspectRatio <= 1.33 && aspectRatio > 1.2) {
      return 7;
    }
    return 8;
  }

  ///Determines the vote percentage on the poll.
  ///If agree is toggled then the agree percentage is calculated, else diagree is calcualted
  static int calculateVote(bool agree, Poll poll) {
    //Break point case, votes not loaded
    if (poll?.agrees == null || poll?.disagrees == null) {
      return null;
    }

    //Calculated the percentage
    double total = poll.agrees.toDouble() + poll.disagrees.toDouble();
    total = total == 0 ? 1 : total;

    return ((agree ? poll.agrees.toDouble() : poll.disagrees.toDouble()) /
            total *
            100)
        .floor();
  }

  ///Returns true if the vote is locked in
  static bool timeOutPoll(PollResponse res) {
    if (res == null) return false;
    return DateTime.now().difference(res.createdAt).inHours >= 24;
  }

  ///Returns the topic name text symbol
  static String getTopicSymbol(String topic) {
    List<String> split = topic.split(' ');
    String titleText = '';
    if (split[0] != '') {
      for (int j = 0; j < split.length; j++) {
        titleText = titleText + split[j].substring(0, 1);
      }
    }
    return titleText;
  }

  ///Returns the area code from a phone number.
  ///The original text must include a starting code.
  ///
  ///`phone.text > 10`
  static String getAreaCode(String phone) =>
      '+${phone.substring(0, phone.length - 10)}';

  static String getNotifTitle(PollarNotification n) {
    String topicName;
    if (n.type['child'] == 'trusts' ||
        n.type['child'] == 'trusting' ||
        n.type['child'] == 'newTrusts') {
      int startIndex = n.subject.indexOf('in ');
      topicName = n.subject.substring(startIndex + 3);
    }
    switch (n.type['child']) {
      case 'newFollowers':
        return 'Followed you';
      case 'likes':
        return 'Liked your post';
      case 'trusts':
        return 'Voted with you in ${topicName}';
      case 'votes':
        return 'Voted on your poll';
      case 'replies':
        return 'Replied to your poll';
      case 'newTrusts':
        return 'Trusted you in ${topicName}';
      case 'trusting':
        return 'Voted for you in ${topicName}';
      default:
        return '';
    }
  }
}

///Global display related functions for displaying different types generic of widgets
class PollarDisplay {
  static Future<bool> showConfirmDialog(BuildContext context,
      {Widget title,
      String description,
      String confirmButton,
      String cancelButton,
      Color confirmButtonColor,
      Color cancelButtonColor,
      Color confirmButtonTextColor,
      Color cancelButtonTextColor,
      double width}) async {
    bool confirm = false;

    await showDialog(
        context: context,
        builder: (c) => ConfirmAlert(
              title: title,
              description: description,
              confirmButton: confirmButton,
              cancelButton: cancelButton,
              confirmButtonColor: confirmButtonColor,
              cancelButtonColor: cancelButtonColor,
              confirmButtomTextColor: confirmButtonColor,
              cancelButtonTextColor: cancelButtonColor,
              width: width,
              onConfirm: () {
                confirm = true;
              },
              onCancel: () {
                confirm = false;
              },
            ));

    return confirm;
  }

  ///Runs an async function, while the function is executing a loader is displayed
  static Future<T> wrapWithLoader<T>(BuildContext context,
      {Future<T> loader, String message = ''}) async {
    //Show loading
    ProgressDialog loading = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: false);

    //ProgressDialog style
    loading.style(message: message);

    loading.show();

    ///Awaits for the complition of the request the request
    T value = await (loader ?? Future.delayed(Duration(milliseconds: 100)));

    ///Hides the laoder
    loading.hide();

    return value;
  }
}
