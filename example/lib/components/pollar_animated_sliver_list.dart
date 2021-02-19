import 'package:flutter/material.dart';
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../models/message.dart';


/// Signature for the builder callback used by [AnimatedList].
typedef AnimatedListItemBuilder = Widget Function(BuildContext context, int index, ChatMessage message, Animation<double> animation,);

// The default insert/remove animation duration.
const Duration _kDuration = Duration(milliseconds: 300);

// Incoming and outgoing AnimatedList items.
class SliverActiveItem implements Comparable<SliverActiveItem> {
  SliverActiveItem.incoming(this.controller,this.message,  this.itemIndex) ;
  SliverActiveItem.index(this.itemIndex, )
    : controller = null, message=null;

  final AnimationController controller;
  int itemIndex;
  final ChatMessage message;

  @override
  int compareTo(SliverActiveItem other) {
    return itemIndex - other.itemIndex;
    // int messageCompare =0;// "${m?.clientID}-${m?.timeToken.toString()}"=="${other?.m?.clientID}-${other?.m?.timeToken.toString()}"?0:m.timeToken.compareTo(other.m.timeToken);
    // if(itemTemp==-1||messageCompare==-1) return -1;
    // else if(itemTemp==1||messageCompare==1) return 1;
    // else return 0;
  }
}

/// A sliver that animates items when they are inserted or removed.
///
/// This widget's [PollarAnimatedListState] can be used to dynamically insert or
/// remove items. To refer to the [PollarAnimatedListState] either provide a
/// [GlobalKey] or use the static [SliverAnimatedList.of] method from an item's
/// input callback.
///
/// {@tool dartpad --template=freeform}
/// This sample application uses a [SliverAnimatedList] to create an animated
/// effect when items are removed or added to the list.
///
/// ```dart imports
/// import 'package:flutter/foundation.dart';
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart
/// void main() => runApp(SliverAnimatedListSample());
///
/// class SliverAnimatedListSample extends StatefulWidget {
///   @override
///   _SliverAnimatedListSampleState createState() => _SliverAnimatedListSampleState();
/// }
///
/// class _SliverAnimatedListSampleState extends State<SliverAnimatedListSample> {
///   final GlobalKey<PollarAnimatedListState> _listKey = GlobalKey<PollarAnimatedListState>();
///   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
///   ListModel<int> _list;
///   int _selectedItem;
///   int _nextItem; // The next item inserted when the user presses the '+' button.
///
///   @override
///   void initState() {
///     super.initState();
///     _list = ListModel<int>(
///       listKey: _listKey,
///       initialItems: <int>[0, 1, 2],
///       removedItemBuilder: _buildRemovedItem,
///     );
///     _nextItem = 3;
///   }
///
///   // Used to build list items that haven't been removed.
///   Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
///     return CardItem(
///       animation: animation,
///       item: _list[index],
///       selected: _selectedItem == _list[index],
///       onTap: () {
///         setState(() {
///           _selectedItem = _selectedItem == _list[index] ? null : _list[index];
///         });
///       },
///     );
///   }
///
///   // Used to build an item after it has been removed from the list. This
///   // method is needed because a removed item remains visible until its
///   // animation has completed (even though it's gone as far this ListModel is
///   // concerned). The widget will be used by the
///   // [PollarAnimatedListState.removeItem] method's
///   // [AnimatedListRemovedItemBuilder] parameter.
///   Widget _buildRemovedItem(int item, BuildContext context, Animation<double> animation) {
///     return CardItem(
///       animation: animation,
///       item: item,
///       selected: false,
///     );
///   }
///
///   // Insert the "next item" into the list model.
///   void _insert() {
///     final int index = _selectedItem == null ? _list.length : _list.indexOf(_selectedItem);
///     _list.insert(index, _nextItem++);
///   }
///
///   // Remove the selected item from the list model.
///   void _remove() {
///     if (_selectedItem != null) {
///       _list.removeAt(_list.indexOf(_selectedItem));
///       setState(() {
///         _selectedItem = null;
///       });
///     } else {
///       _scaffoldKey.currentState.showSnackBar(SnackBar(
///         content: Text(
///           'Select an item to remove from the list.',
///           style: TextStyle(fontSize: 20),
///         ),
///       ));
///     }
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         key: _scaffoldKey,
///         body: CustomScrollView(
///           slivers: <Widget>[
///             SliverAppBar(
///               title: Text(
///                 'SliverAnimatedList',
///                 style: TextStyle(fontSize: 30),
///               ),
///               expandedHeight: 60,
///               centerTitle: true,
///               backgroundColor: Colors.amber[900],
///               leading: IconButton(
///                 icon: const Icon(Icons.add_circle),
///                 onPressed: _insert,
///                 tooltip: 'Insert a new item.',
///                 iconSize: 32,
///               ),
///               actions: [
///                 IconButton(
///                   icon: const Icon(Icons.remove_circle),
///                   onPressed: _remove,
///                   tooltip: 'Remove the selected item.',
///                   iconSize: 32,
///                 ),
///               ],
///             ),
///             SliverAnimatedList(
///               key: _listKey,
///               initialItemCount: _list.length,
///               itemBuilder: _buildItem,
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
///
/// // Keeps a Dart [List] in sync with an [AnimatedList].
/// //
/// // The [insert] and [removeAt] methods apply to both the internal list and
/// // the animated list that belongs to [listKey].
/// //
/// // This class only exposes as much of the Dart List API as is needed by the
/// // sample app. More list methods are easily added, however methods that
/// // mutate the list must make the same changes to the animated list in terms
/// // of [PollarAnimatedListState.insertItem] and [AnimatedList.removeItem].
/// class ListModel<E> {
///   ListModel({
///     @required this.listKey,
///     @required this.removedItemBuilder,
///     Iterable<E> initialItems,
///   }) : assert(listKey != null),
///        assert(removedItemBuilder != null),
///        _items = List<E>.from(initialItems ?? <E>[]);
///
///   final GlobalKey<PollarAnimatedListState> listKey;
///   final dynamic removedItemBuilder;
///   final List<E> _items;
///
///   PollarAnimatedListState get _animatedList => listKey.currentState;
///
///   void insert(int index, E item) {
///     _items.insert(index, item);
///     _animatedList.insertItem(index);
///   }
///
///   E removeAt(int index) {
///     final E removedItem = _items.removeAt(index);
///     if (removedItem != null) {
///       _animatedList.removeItem(
///         index,
///         (BuildContext context, Animation<double> animation) => removedItemBuilder(removedItem, context, animation),
///       );
///     }
///     return removedItem;
///   }
///
///   int get length => _items.length;
///
///   E operator [](int index) => _items[index];
///
///   int indexOf(E item) => _items.indexOf(item);
/// }
///
/// // Displays its integer item as 'Item N' on a Card whose color is based on
/// // the item's value.
/// //
/// // The card turns gray when [selected] is true. This widget's height
/// // is based on the [animation] parameter. It varies as the animation value
/// // transitions from 0.0 to 1.0.
/// class CardItem extends StatelessWidget {
///   const CardItem({
///     Key key,
///     @required this.animation,
///     @required this.item,
///     this.onTap,
///     this.selected = false,
///   }) : assert(animation != null),
///        assert(item != null && item >= 0),
///        assert(selected != null),
///        super(key: key);
///
///   final Animation<double> animation;
///   final VoidCallback onTap;
///   final int item;
///   final bool selected;
///
///   @override
///   Widget build(BuildContext context) {
///     return Padding(
///       padding:
///       const EdgeInsets.only(
///         left: 2.0,
///         right: 2.0,
///         top: 2.0,
///         bottom: 0.0,
///       ),
///       child: SizeTransition(
///         axis: Axis.vertical,
///         sizeFactor: animation,
///         child: GestureDetector(
///           onTap: onTap,
///           child: SizedBox(
///             height: 80.0,
///             child: Card(
///               color: selected
///                 ? Colors.black12
///                 : Colors.primaries[item % Colors.primaries.length],
///               child: Center(
///                 child: Text(
///                   'Item $item',
///                   style: Theme.of(context).textTheme.headline4,
///                 ),
///               ),
///             ),
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SliverList], which does not animate items when they are inserted or
///    removed.
///  * [AnimatedList], a non-sliver scrolling container that animates items when
///    they are inserted or removed.
class PollarAnimatedList extends StatefulWidget {
  /// Creates a sliver that animates items when they are inserted or removed.
  const PollarAnimatedList({
    Key key,
    @required this.itemBuilder,
    // this.initialItemCount = 0,
  }) : assert(itemBuilder != null),
      //  assert(initialItemCount != null && initialItemCount >= 0),
       super(key: key);

  /// Called, as needed, to build list item widgets.
  ///
  /// List items are only built when they're scrolled into view.
  ///
  /// The [AnimatedListItemBuilder] index parameter indicates the item's
  /// position in the list. The value of the index parameter will be between 0
  /// and [initialItemCount] plus the total number of items that have been
  /// inserted with [PollarAnimatedListState.insertItem] and less the total
  /// number of items that have been removed with
  /// [PollarAnimatedListState.removeItem].
  ///
  /// Implementations of this callback should assume that
  /// [PollarAnimatedListState.removeItem] removes an item immediately.
  final AnimatedListItemBuilder itemBuilder;

  // /// {@macro flutter.widgets.animatedList.initialItemCount}
  // final int initialItemCount;

  @override
  PollarAnimatedListState createState() => PollarAnimatedListState();

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [SliverAnimatedList] item widgets that
  /// insert or remove items in response to user input.
  ///
  /// ```dart
  /// PollarAnimatedListState animatedList = SliverAnimatedList.of(context);
  /// ```
  static PollarAnimatedListState of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    assert(nullOk != null);
    final PollarAnimatedListState result = context.findAncestorStateOfType<PollarAnimatedListState>();
    if (nullOk || result != null)
      {return result;}
    throw FlutterError(
        'SliverAnimatedList.of() called with a context that does not contain a SliverAnimatedList.\n'
        'No PollarAnimatedListState ancestor could be found starting from the '
        'context that was passed to PollarAnimatedListState.of(). This can '
        'happen when the context provided is from the same StatefulWidget that '
        'built the AnimatedList. Please see the SliverAnimatedList documentation '
        'for examples of how to refer to an PollarAnimatedListState object: '
        'https://docs.flutter.io/flutter/widgets/PollarAnimatedListState-class.html \n'
        'The context used was:\n'
        '  $context');
  }
}

/// The state for a sliver that animates items when they are
/// inserted or removed.
///
/// When an item is inserted with [insertItem] an animation begins running. The
/// animation is passed to [SliverAnimatedList.itemBuilder] whenever the item's
/// widget is needed.
///
/// When an item is removed with [removeItem] its animation is reversed.
/// The removed item's animation is passed to the [removeItem] builder
/// parameter.
///
/// An app that needs to insert or remove items in response to an event
/// can refer to the [SliverAnimatedList]'s state with a global key:
///
/// ```dart
/// GlobalKey<PollarAnimatedListState> listKey = GlobalKey<PollarAnimatedListState>();
/// ...
/// SliverAnimatedList(key: listKey, ...);
/// ...
/// listKey.currentState.insert(123);
/// ```
///
/// [SliverAnimatedList] item input handlers can also refer to their
/// [PollarAnimatedListState] with the static [SliverAnimatedList.of] method.
class PollarAnimatedListState extends State<PollarAnimatedList> with TickerProviderStateMixin {

  final List<SliverActiveItem> _incomingItems = <SliverActiveItem>[];
  final List<SliverActiveItem> _items = <SliverActiveItem>[];

  int index = 0;
  
  List<SliverActiveItem> get items => _items.followedBy(_incomingItems).toList()..sort((a, b) => a.compareTo(b));

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (final SliverActiveItem item in _incomingItems) {
      item.controller.dispose();
    }
    super.dispose();
  }

  SliverActiveItem _removeActiveItemAt(List<SliverActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, SliverActiveItem.index(itemIndex, ));
    return i == -1 ? null : items.removeAt(i);
  }

  SliverActiveItem activeItemAt(List<SliverActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, SliverActiveItem.index(itemIndex, ));
    return i == -1 ? null : items[i];
  }

  // The insertItem() and removeItem() index parameters are defined as if the
  // removeItem() operation removed the corresponding list entry immediately.
  // The entry is only actually removed from the ListView when the remove animation
  // finishes. The entry is added to _outgoingItems when removeItem is called
  // and removed from _outgoingItems when the remove animation finishes.



  SliverChildDelegate _createDelegate() {
    // return SliverChildBuilderDelegate(_itemBuilder, childCount: index);
    return SliverChildListDelegate(
      List.generate(index, (index) => this.index - index - 1).map((i){
        return _itemBuilder(context, i);
      }).toList()
    );
  }

  /// Insert an item at [index] and start an animation that will be passed to
  /// [SliverAnimatedList.itemBuilder] when the item is visible.
  ///
  /// This method's semantics are the same as Dart's [List.insert] method:
  /// it increases the length of the list by one and shifts all items at or
  /// after [index] towards the end of the list.
  void insertItem(int index, ChatMessage message, { Duration duration = _kDuration }) {
    if(index == null)
      {index = this.index;}

    assert(index != null && index >= 0);
    assert(duration != null);

    final int itemIndex = index;
    assert(itemIndex >= 0 && itemIndex <= items.length);

    // Increment the incoming and outgoing item indices to account
    // for the insertion.
    for (final SliverActiveItem item in _incomingItems) {
      if (item.itemIndex >= itemIndex)
        {item.itemIndex += 1;}
    }

    for (final SliverActiveItem item in _items) {
      if (item.itemIndex >= itemIndex)
        {item.itemIndex += 1;}
    }

    final AnimationController controller = AnimationController(
      duration: duration,
      vsync: this,
    );
    final SliverActiveItem incomingItem = SliverActiveItem.incoming(
      controller,
      message,
      itemIndex,
    );
    setState(() {
      _incomingItems
        ..add(incomingItem)
        ..sort();
      this.index++;
    });

    controller.forward().then<void>((_) {
      SliverActiveItem temp = _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)..controller.dispose();
      setState(() {
        _items..add(temp)..sort();
      });
    });
  }


  Widget _itemBuilder(BuildContext context, int itemIndex, ) {
    final SliverActiveItem incomingItem = activeItemAt(_incomingItems, itemIndex);
    final Animation<double> animation = incomingItem?.controller?.view ?? kAlwaysCompleteAnimation;
    return widget.itemBuilder(
      context,
      itemIndex,
      activeItemAt(items, itemIndex).message,
      animation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: _createDelegate(),
    );
  }
}
