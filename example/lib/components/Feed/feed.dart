import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_easyrefresh/material_footer.dart';
import 'package:flutter_easyrefresh/material_header.dart';

import '../../models/poll.dart';
import '../../models/post.dart';
import '../../state/store/storable.dart';

///Feed uses the load call to display a list of storables.
///The size of the request is dynamically increased as the user scrolls.
///
///Has built in swipe down to refresh and notification on newItems loaded.
///
///Headers can be set before the list of storables.
///
///[loader] - Called when the widget wants to retreive a list of storables. Gives the state values size and date as parameters for the request.
///returns a list of storables returned from the request
///
///[headerSliver] - The function passed into the parent nested scroll view to build a header
///
///[lengthFactor] - Defines the length increase factor for loading items innitally and loading more items
///
///[initialLength] - Defines the length of the innital load
///
///[onRefresh] - called when refresh is called on the page, allows for chained refresh calls
///
///[childBuilder] - a builder function that takes the defined datatype and builds a custom child, if defined overrides the current builder
///
///[hide] - a state value passed from the parent, if toggled hides the feed
///
///`Supports: Posts, Polls, All Objects if childBuilder is present`

///TODO: Loader
class Feed<T> extends StatefulWidget {
  final Future<List<T>> Function(DateTime, int) loader;

  final List<Widget> headerSliver;

  final int lengthFactor;

  final int innitalLength;

  final bool hide;

  final Future Function() onRefresh;

  ///called once refresh is finished
  final Future Function(List<T>) onRefreshEnd;

  final Widget Function(T value, bool isLast) childBuilder;

  final FeedController<T> controller;

  const Feed(
      {Key key,
      @required this.loader,
      this.headerSliver,
      this.lengthFactor,
      this.innitalLength,
      this.onRefresh,
      this.controller,
      this.hide = false, this.childBuilder, this.onRefreshEnd})
      : super(key: key);

  @override
  State<Feed<T>> createState() => _FeedState<T>();

  static Key getFeedKey<T extends Storable>(String key) {
    if (T == Post) {
      return Key('FeedKey - Post - $key');
    } else if (T == Poll) {
      return Key('FeedKey - Poll - $key');
    } else if(T == Null){
      return Key('FeedKey - Custom - $key');
    } else {
      throw ('T is not supported by Feed');
    }
  }
}

///feed state used for displaying storable lists dynamically
class _FeedState<T> extends State<Feed<T>> {
  static const int LENGTH_INCREASE_FACTOR = 20;

  ///The list iof loaded items to be displayed on the feed
  List<T> items = [];

  ///The refresh controller
  EasyRefreshController _refeshController;

  ///State values used for loading more items
  int size = LENGTH_INCREASE_FACTOR;
  DateTime date;

  @override
  void initState() {
    super.initState();

    _refeshController = EasyRefreshController();
    //Loads the innitial set of items
    _refresh(false);
  }

  @override
  void dispose() {
    _refeshController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.controller != null) {
      //Binds the controller to this state
      widget.controller._bind(this);
    }

    _refresh(false);
  }

  ///Builds the type of item card based on the feed type. 
  ///If a custom child builder is present, uses the child builder instead
  Widget _loadCard(T item, int index) {
    if(widget.childBuilder != null){
      //Builds custom child if childBuilder is defined
      return widget.childBuilder(item, index == items.length - 1);
    }
    else {
      throw ('T is not supported by Feed');
    }
  }

  ///The function that is run to refresh the page
  ///[full] - defines if the parent widget should be refreshed aswell
  Future<void> _refresh([bool full = true]) async {
    date = DateTime.now(); //Resets date on refresh

    //Calls the refresh function from the parent widget
    Future<void> refresh = widget.onRefresh != null && full ? widget.onRefresh() : null;

    List<T> loaded = await widget.loader(date, widget.innitalLength ?? widget.lengthFactor ?? LENGTH_INCREASE_FACTOR);

    //Awaits the parent refresh function
    if (refresh != null) await refresh;

    if (mounted) {
      setState(() {
        items = loaded;
      });

      if (widget.controller != null) {
        //Notifies all the controller lisneteners
        widget.controller._update();
      }
    }
    if(widget.onRefreshEnd!=null){
      await widget.onRefreshEnd(items);
    }
  }

  ///The function run to load more items onto the page
  Future<void> _loadMore() async {
    List<T> loaded = await widget.loader(
        date, items.length + (widget.lengthFactor ?? LENGTH_INCREASE_FACTOR));
    // if(loaded.length < items.length + (widget.lengthFactor ?? LENGTH_INCREASE_FACTOR)){
    //   //Displays no more items to load
    // }
    List<T> add = loaded.sublist(items.length);
    if (mounted && add.isNotEmpty) {
      setState(() {
        items.addAll(add);
      });
      //Updates the size variable
      size = items.length;

      if (widget.controller != null) {
        //Notifies all the controller lisneteners
        widget.controller._update();
      }
    }
  }

  ///Builds the slivers used in the custom scroll view
  List<Widget> get _buildSlivers => [
    ...(widget.headerSliver ?? []),
    widget.hide ? SliverToBoxAdapter(child: Container(),) :
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i){
          return _loadCard(items[i], i);
        },
        childCount: items.length
      ),
    )
  ];



  @override
  Widget build(BuildContext context) {
    return EasyRefresh.custom(
      controller: _refeshController,
      header: MaterialHeader(),
      footer: MaterialFooter(),
      onLoad: _loadMore,
      onRefresh: () async => await _refresh(),
      slivers: _buildSlivers,
    );
  }
}

///Controller for the feed
class FeedController<T> extends ChangeNotifier {
  _FeedState<T> _state;

  ///Binds the feed state
  void _bind(_FeedState<T> bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  ///Retreives the list of items from the feed
  List<T> get list => _state != null ? _state.items : null;

  ///Reloads the feed state based on the original size parameter
  void reload() => _state._refresh();

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}
