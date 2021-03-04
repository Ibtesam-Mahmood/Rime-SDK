import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:giphy_client/giphy_client.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../util/colorProvider.dart';
import 'picker.dart';

class GiphyPickerView extends StatefulWidget {

  final GiphyPickerController controller;

  final double initialExtent;

  final double expandedExtent;

  GiphyPickerView({Key key, this.controller, this.initialExtent, this.expandedExtent}) : super(key: key);
  @override
  _GiphyPickerViewState createState() => _GiphyPickerViewState();
}

class _GiphyPickerViewState extends State<GiphyPickerView> {

  //Stores a reference to giphy API
  final client = GiphyClient(apiKey: '22C9mvy8P8ELxSMYqUr3g3DQbTXUIg9P');

  //Holds the URLs of all gifs
  Map<String, double> urls = Map<String, double>();

  //Stores the values of URLs
  List<String> urlList = List<String>();

  //Gets the value of the textField
  TextEditingController textController;

  //Gif that is selected
  String gif;

  //image sheet comes up 40% of the screen initially
  double initialExtent;

  //Used to expand and collapse the draggable sheet
  BuildContext draggableSheetContext;

  //Default set to open
  Option type = Option.Open;

  FocusNode _focusNode;

  //If searching for a gif
  bool searching = false;


  //Adds a listener to the scroll position of the staggered grid view
  @override
  void initState() {

    initialExtent = widget.initialExtent;

    super.initState();

    getTredingGifs();

    textController = TextEditingController();

    _focusNode = FocusNode();

  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null) {
      //Binds the controller to this state
      widget.controller._bind(this);
    }
  }

  ///Gets all the gifs that are currently trending to a mx of 50
  void getTredingGifs() async {

    await client.trending(offset: 0, limit: 40, rating: GiphyRating.r).then((value) {
      
      urlList.clear();

      Map<String, double> tempURLs = Map<String, double>();

      for(int i = 0; i < value.data.length; i++){
        setState(() {
          tempURLs[value.data[i].images.fixedWidth.url] = double.parse(value.data[i].images.fixedWidth.width)/double.parse(value.data[i].images.fixedWidth.height);
          urlList.add(value.data[i].images.fixedWidth.url);
        });
      }
      setState(() {
        urls = tempURLs;
      });
    });
  }

  ///Takes a string and searches most popular gifs depending on the string up to 50 maz
  void searchGifs(String string) async {
    if(string.isNotEmpty){

        await client.search(string, limit: 30, offset: 0, lang: GiphyLanguage.english, rating: GiphyRating.r).then((value) {

          urlList.clear();

          Map<String, double> tempURLs = Map<String, double>();

          for(int i = 0; i < value.data.length; i++){
            setState(() {
              tempURLs[value.data[i].images.fixedWidth.url] = double.parse(value.data[i].images.fixedWidth.width)/double.parse(value.data[i].images.fixedWidth.height);
              urlList.add(value.data[i].images.fixedWidth.url);
            });
          }
          setState(() {
            urls = tempURLs;
          });
      //If the getter length is null for searching gifs get trending gifs
      }).catchError((e){
          print(e);
        }
      );
    }
    else{
      //If search query is empty get trending gifs
      getTredingGifs();
    }
  }

  //Build all containers that hold the gifs
  Widget buildSlivers(String url, AppColor appColors){
    return FlatButton(
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 300,
            minHeight: 125, 
          ),
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: appColors.grey,
            image: DecorationImage(
              image: CachedNetworkImageProvider(url),
                fit: initialExtent == widget.initialExtent ? BoxFit.cover : BoxFit.fitWidth
              ),
            ),
          ),
        ),
      onPressed: (){
        setState(() {
          gif = url;
          type = Option.Close;
        });
        widget.controller._update();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    //Used for aspect ratios of gifs
    var width = MediaQuery.of(context).size.width;

    //Used for aspect ratios of gifs
    var height = MediaQuery.of(context).size.height;

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    //Color provider
    final appColors = ColorProvider.of(context);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (DraggableScrollableNotification DSNotification){
        if(DSNotification.extent >= widget.initialExtent + 0.1 && DSNotification.extent <= widget.initialExtent + 0.3){
          setState(() { 
            initialExtent = widget.expandedExtent;
          });
          DraggableScrollableActuator.reset(draggableSheetContext);
          return true;
        }
        else if(DSNotification.extent <= widget.expandedExtent - 0.1 && DSNotification.extent > widget.expandedExtent - 0.3){
          setState(() {
            initialExtent = widget.initialExtent;
          });
          DraggableScrollableActuator.reset(draggableSheetContext);
          return false;
        }
        else if(DSNotification.extent <= widget.initialExtent){
          setState(() {
            type = Option.Close;
          });
          widget.controller._update();
        }
        return false;
      },
      child: DraggableScrollableActuator(
        child: DraggableScrollableSheet(
          key: Key(initialExtent.toString()),
          initialChildSize: initialExtent,
          minChildSize: widget.initialExtent,
          maxChildSize: widget.expandedExtent,
          builder: (BuildContext context, ScrollController scrollController){
            draggableSheetContext = context;
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                color: appColors.surface,
                child: Column(
                  children:<Widget>[
                    PreferredSize(
                    preferredSize: Size(double.infinity, 36),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(top: initialExtent == widget.initialExtent ? 10 : 30, left: 16, right: !searching ? 16 : 0),
                              child: Container(
                                width: !searching ? width - 32 : width*0.84 - 26,
                                height: 36,
                                child: TextFormField(
                                  controller: textController,
                                  focusNode: _focusNode,
                                  decoration: InputDecoration(
                                    prefixStyle: TextStyle(color: appColors.grey.withOpacity(0.5)),
                                    prefixIcon: Icon(Icons.search, size: 24, color: appColors.grey.withOpacity(0.5),),
                                    prefixIconConstraints: BoxConstraints(
                                      maxHeight: 36,
                                      minHeight: 36,
                                      maxWidth: 30,
                                      minWidth: 30
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: appColors.grey.withOpacity(0.07),
                                    hintText: 'Search GIPHY',
                                    hintStyle: textStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, color: appColors.grey.withOpacity(0.5)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none
                                    ),
                                  ),
                                  onChanged: (value){
                                    setState(() {
                                      searchGifs(value);
                                    });
                                  },
                                  onTap: (){
                                    setState(() {
                                      initialExtent = widget.expandedExtent;
                                      searching = true;
                                    });
                                    DraggableScrollableActuator.reset(draggableSheetContext);
                                  },
                                  onEditingComplete: (){
                                    setState(() {
                                      searching = false;
                                      _focusNode.unfocus();
                                    });
                                  },
                                ),
                              ),
                            ),
                              searching ? GestureDetector(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10, right: 16, top: 27),
                                  child: Text('Cancel', style: textStyles.button.copyWith(fontWeight: FontWeight.normal)),
                                ),
                                onTap: (){
                                  setState(() {
                                    searching = false;
                                    _focusNode.unfocus();
                                  });
                                },
                              ) : Container()
                            ],
                          ),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, contraints){
                        List<double> urlRatio = urls.values.toList();
                        return Container(
                          width: width,
                          height: initialExtent == widget.initialExtent ? height*(widget.initialExtent - 0.1) : height,
                            child: StaggeredGridView.countBuilder(
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              padding: EdgeInsets.only(left: 5, right: 5),
                              itemCount: urlRatio.length,
                              scrollDirection: initialExtent == widget.initialExtent ? Axis.horizontal : Axis.vertical,
                              crossAxisCount: 2,
                              itemBuilder: (context, i){
                                return buildSlivers(urlList[i], appColors);
                              },
                              staggeredTileBuilder: (int index) => StaggeredTile.extent(1, initialExtent == widget.initialExtent ? (height*0.165)*urlRatio[index] - 15 : (width*0.5)/urlRatio[index] - 15),
                            ),
                        );
                      },
                    ),
                  ]
                  ),
              ),
            );
          },
        )
      ),
    );
  }
}

  class GiphyPickerController extends ChangeNotifier{

    _GiphyPickerViewState _state;

    ///Binds the feed state
    void _bind(_GiphyPickerViewState bind) => _state = bind;

    void _update() => notifyListeners();

    String get gif => _state != null ? _state.gif : null;

    Option get type => _state != null ? _state.type : null;

    //Disposes of the controller
    @override
    void dispose() {
      _state = null;
      super.dispose();
    }
  }