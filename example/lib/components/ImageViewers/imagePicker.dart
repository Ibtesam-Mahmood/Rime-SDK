import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../util/colorProvider.dart';
import '../../util/pollar_icons.dart';
import '../Pickers/picker.dart';

class ImagePicker extends StatefulWidget {
  final ImagePickerController controller;

  final double initialExtent;

  final double expandedExtent;

  ImagePicker(
      {Key key,
      this.controller,
      this.initialExtent = 0.4,
      this.expandedExtent = 1.0})
      : super(key: key);

  @override
  _ImagePickerState createState() => _ImagePickerState();
}

class _ImagePickerState extends State<ImagePicker> {
  //Holds all albums it can access on your phone
  List<AssetPathEntity> albums = List<AssetPathEntity>();

  //Holds all photos in a specific album
  List<AssetEntity> photos = List<AssetEntity>();

  //If the all albums view is activated
  bool allAlbums = false;

  //Map from album ID to preview or tumbnail picture
  Map<String, AssetEntity> previewAlbum = Map<String, AssetEntity>();

  //What category the user is currently on
  String category = '';

  //image sheet comes up 40% of the screen initially
  double currentExtent;

  //Used to expand and collapse the draggable sheet
  BuildContext draggableSheetContext;

  //Selected images
  List<AssetEntity> selected = List<AssetEntity>();

  //if it is open or closed
  Option type = Option.Open;

  @override
  void initState() {
    super.initState();

    currentExtent = widget.initialExtent ?? widget.expandedExtent;

    category = 'All Photos';

    PhotoManager.requestPermission();

    getAlbums();
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

  ///Get all the categories in your phone ex: recents, favourites
  void getAlbums() async {
    albums = await PhotoManager.getAssetPathList(
        type: widget.controller.onlyPhotos
            ? RequestType.image
            : RequestType.common,
        filterOption: FilterOptionGroup()
          ..setOption(
              AssetType.video,
              FilterOption(
                  durationConstraint: widget.controller.duration,
                  needTitle: true)));

    getPreviewPhotos(albums);

    await getRecentPhotos(albums, 0);

    if (widget.controller.innitialSelect == true) {
      //If initial select is deifned, try to select first image
      try {
        addToSelected(photos[0]);
      } catch (e) {
        print('imagePicker - no images to select');
      }
    }

    //Add initially selected assets to the list
    if ((widget.controller.selectedAssets?.length ?? 0) > 0) {
      for (var asset in photos) {
        if (widget.controller.selectedAssets.contains(asset.id)) {
          addToSelected(asset);
        }
      }
    }
  }

  ///Get all photos in a specifi category
  ///Default: recent photos
  Future<void> getRecentPhotos(List<AssetPathEntity> al, int index) async {
    List<AssetEntity> holdPhotos;
    holdPhotos = await al[index].getAssetListPaged(0, al[index].assetCount);
    setState(() {
      photos = holdPhotos;
    });
  }

  ///Get preview photos for every album
  ///Returns a thumbnail it the first image is a video in the album
  void getPreviewPhotos(List<AssetPathEntity> al) async {
    Map<String, AssetEntity> preview = Map<String, AssetEntity>();

    for (AssetPathEntity temp in al) {
      temp
          .getAssetListPaged(0, 1)
          .then((value) => {preview[temp.id] = value[0]});
    }
    setState(() {
      previewAlbum = preview;
    });
  }

  void addToSelected(AssetEntity photo) {
    if (selected.isEmpty) {
      setState(() {
        selected.add(photo);
      });
    } else {
      if ((selected[0].videoDuration.inMilliseconds > 0) !=
          (photo.videoDuration.inMilliseconds > 0)) {
        setState(() {
          selected.clear();
          selected.add(photo);
        });
      } else if (selected.contains(photo)) {
        setState(() {
          selected.remove(photo);
        });
      } else if (selected[0].videoDuration.inMilliseconds > 0) {
        if (selected.length < widget.controller.videoLength) {
          setState(() {
            selected.add(photo);
          });
        } else {
          setState(() {
            selected.removeLast();
            selected.add(photo);
          });
        }
      } else {
        if (selected.length < widget.controller.imageLength) {
          setState(() {
            selected.add(photo);
          });
        } else {
          setState(() {
            selected.removeLast();
            selected.add(photo);
          });
        }
      }
    }

    widget.controller._update();
  }

  @override
  Widget build(BuildContext context) {
    //Width of the screen
    var width = MediaQuery.of(context).size.width;

    //height of the screen
    var height = MediaQuery.of(context).size.height;

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    //Color provider
    final appColors = ColorProvider.of(context);

    return NotificationListener<DraggableScrollableNotification>(
        onNotification: (DraggableScrollableNotification DSNotification) {
          if (widget.initialExtent == null) return true;

          print(DSNotification.extent);
          if (DSNotification.extent >= widget.initialExtent + 0.1 &&
              DSNotification.extent <= widget.initialExtent + 0.3) {
            setState(() {
              currentExtent = widget.expandedExtent;
            });
            DraggableScrollableActuator.reset(draggableSheetContext);
            return true;
          } else if (DSNotification.extent <= widget.expandedExtent - 0.1 &&
              DSNotification.extent > widget.expandedExtent - 0.3) {
            setState(() {
              currentExtent = widget.initialExtent;
              allAlbums = false;
            });
            DraggableScrollableActuator.reset(draggableSheetContext);
            return false;
          } else if (DSNotification.extent <= widget.initialExtent) {
            setState(() {
              type = Option.Close;
            });
            widget.controller._update();
            return false;
          }
          return false;
        },
        child: DraggableScrollableActuator(
          child: DraggableScrollableSheet(
              key: Key(currentExtent.toString()),
              initialChildSize: currentExtent,
              minChildSize: widget.initialExtent ?? widget.expandedExtent,
              maxChildSize: widget.expandedExtent,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                draggableSheetContext = context;
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                      color: appColors.surface,
                      height: height,
                      width: width,
                      child: !allAlbums
                          ? Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: currentExtent == widget.initialExtent
                                          ? 47
                                          : 37),
                                  child: Container(
                                    height:
                                        currentExtent == widget.initialExtent
                                            ? height * widget.initialExtent - 47
                                            : double.infinity,
                                    child: GridView.builder(
                                        scrollDirection: currentExtent ==
                                                widget.initialExtent
                                            ? Axis.horizontal
                                            : Axis.vertical,
                                        itemCount: photos.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: currentExtent ==
                                                        widget.initialExtent
                                                    ? 2
                                                    : 3,
                                                crossAxisSpacing: 1,
                                                mainAxisSpacing: 1,
                                                childAspectRatio: 1),
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return GestureDetector(
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: Image(
                                                    image:
                                                        AssetEntityThumbImage(
                                                      entity: photos[index]
                                                        ..typeInt = 1,
                                                      width:
                                                          (width / 3).floor(),
                                                      height:
                                                          (width / 3).floor(),
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                photos[index]
                                                            .videoDuration
                                                            .inMilliseconds >
                                                        0
                                                    ? Opacity(
                                                        opacity: 0.4,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .bottomRight,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    bottom: 8,
                                                                    right: 8),
                                                            child: Container(
                                                              height: 16,
                                                              width: 32,
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                              child: Center(
                                                                  child: Text(
                                                                photos[index]
                                                                    .videoDuration
                                                                    .toString()
                                                                    .split(
                                                                        '.')[0]
                                                                    .substring(
                                                                        3),
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.8),
                                                                    fontSize:
                                                                        12),
                                                              )),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : Container(),
                                                if (selected.contains(
                                                    photos[index])) ...[
                                                  Positioned.fill(
                                                    child: Opacity(
                                                      opacity: 0.4,
                                                      child: Container(
                                                        height: width / 3,
                                                        width: width / 3,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Container(
                                                        height: 30,
                                                        width: 30,
                                                        decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30)),
                                                        child: Center(
                                                            child: Text(
                                                          (selected.indexOf(photos[
                                                                      index]) +
                                                                  1)
                                                              .toString(),
                                                          style: textStyles
                                                              .headline5
                                                              .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black),
                                                        )),
                                                      ))
                                                ]
                                              ],
                                            ),
                                            onTap: () {
                                              addToSelected(photos[index]);
                                            },
                                          );
                                        }),
                                  ),
                                ),
                                currentExtent == widget.initialExtent
                                    ? Positioned(
                                        top: 0,
                                        child: Container(
                                          height: 47,
                                          width: width,
                                          color: appColors.surface,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16, right: 16),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Recent',
                                                  style: textStyles.bodyText1
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                ),
                                                Spacer(),
                                                GestureDetector(
                                                  child: Text('All Photos',
                                                      style: textStyles
                                                          .bodyText1
                                                          .copyWith(
                                                              color: appColors
                                                                  .blue)),
                                                  onTap: () {
                                                    setState(() {
                                                      currentExtent =
                                                          widget.expandedExtent;
                                                    });
                                                    DraggableScrollableActuator
                                                        .reset(
                                                            draggableSheetContext);
                                                  },
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    : Positioned(
                                        top: 0,
                                        child: Container(
                                          height: 56,
                                          width: width,
                                          color: appColors.surface,
                                          child: GestureDetector(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    !allAlbums
                                                        ? category
                                                        : 'All Photos',
                                                    style: textStyles.headline5
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 3),
                                                    child: Icon(
                                                      PollarIcons
                                                          .small_down_arrow,
                                                      size: 24,
                                                    ),
                                                  )
                                                ],
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  allAlbums = !allAlbums;
                                                });
                                              }),
                                        ),
                                      ),
                              ],
                            )
                          : Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 56, left: 16, right: 16, bottom: 10),
                                  child: GridView.extent(
                                    childAspectRatio: 0.5,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 16,
                                    maxCrossAxisExtent: width / 3,
                                    children: [
                                      for (int i = 0; i < albums.length; i++)
                                        GestureDetector(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FutureBuilder(
                                                future:
                                                    previewAlbum[albums[i].id]
                                                        .thumbDataWithSize(
                                                            200, 200,
                                                            format: ThumbFormat
                                                                .png),
                                                builder: (BuildContext context,
                                                    snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.done) {
                                                    return ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              17),
                                                      child: Container(
                                                          width: 105,
                                                          height: 139,
                                                          child: snapshot
                                                                      .data !=
                                                                  null
                                                              ? Image.memory(
                                                                  snapshot.data,
                                                                  fit: BoxFit
                                                                      .fitWidth,
                                                                )
                                                              : Container(
                                                                  color:
                                                                      appColors
                                                                          .grey,
                                                                )),
                                                    );
                                                  } else {
                                                    return Container(
                                                      width: 105,
                                                      height: 179,
                                                    );
                                                  }
                                                },
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 5),
                                                child: Text(albums[i].name,
                                                    style: textStyles.bodyText1
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                              ),
                                              Text(
                                                  albums[i]
                                                      .assetCount
                                                      .toString(),
                                                  style: textStyles.caption
                                                      .copyWith(
                                                          color:
                                                              appColors.grey))
                                            ],
                                          ),
                                          onTap: () {
                                            getRecentPhotos(albums, i);
                                            setState(() {
                                              category = albums[i].name;
                                              allAlbums = false;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  child: Container(
                                    height: 56,
                                    width: width,
                                    color: appColors.surface,
                                    child: GestureDetector(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              !allAlbums
                                                  ? category
                                                  : 'All Photos',
                                              style: textStyles.headline5
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 3),
                                              child: !allAlbums
                                                  ? Icon(
                                                      PollarIcons
                                                          .small_down_arrow,
                                                      size: 24)
                                                  : Icon(
                                                      PollarIcons
                                                          .small_up_arrow,
                                                      size: 24),
                                            )
                                          ],
                                        ),
                                        onTap: () {
                                          setState(() {
                                            allAlbums = true;
                                          });
                                        }),
                                  ),
                                ),
                              ],
                            )),
                );
              }),
        ));
  }
}

class ImagePickerController extends ChangeNotifier {
  _ImagePickerState _state;

  final int videoLength;

  final int imageLength;

  final DurationConstraint duration;

  final bool onlyPhotos;

  ///Selects the first index if defined as true
  final bool innitialSelect;

  ///The previously selected assets id
  final List<String> selectedAssets;

  ImagePickerController(
      {this.selectedAssets,
      this.innitialSelect = false,
      this.videoLength = 1,
      this.imageLength = 5,
      this.duration = const DurationConstraint(max: Duration(minutes: 1)),
      this.onlyPhotos = false});

  ///Selects an indexed photo in the current gallaery display
  ///Does not work whe in gallery view, or if index overflow
  void select(int index) => _state.addToSelected(_state.photos[index]);

  ///Binds the feed state
  void _bind(_ImagePickerState bind) => _state = bind;

  void _update() => _state != null ? notifyListeners() : null;

  List<AssetEntity> get list => _state != null ? _state.selected : null;

  Option get type => _state != null ? _state.type : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}
