import 'package:flutter/cupertino.dart';

/// cache gif fetched image
class GifCache{

  static final GifCache _store = GifCache._internal(); //NavStack singlton

  GifCache._internal();

  factory GifCache() {
    return _store;
  }

  @protected
  final Map<String,List<ImageInfo>> caches= Map();

  void clear() {
    caches.clear();
  }

  bool evict(Object key) {
    final List<ImageInfo> pendingImage = caches.remove(key);
    if(pendingImage!=null){
      return true;
    }
    return false;
  }

  Map<String,List<ImageInfo>> cache(){
    return caches;
  }

  void addCache(String key, List<ImageInfo> infos){ 
    caches.putIfAbsent(key, () => infos);
  }
  
}