
import 'subscription.dart';

class Topic {
  String id;
  String name;
  String category;
  String categoryId;
  String image;

  Topic({this.image, this.name, this.category, this.categoryId, this.id});

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      name: json['name'],
      category: json['category'],
      categoryId: json['categoryId'],
      id: json['_id'],
      image: json['image']
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> topicMap = {};
    if (name != null) topicMap['name'] = name;
    if (id != null) topicMap['_id'] = id;
    if (categoryId != null) topicMap['categoryId'] = categoryId;
    if (category != null) topicMap['category'] = category;
    topicMap['image'] = image;
    return topicMap;
  }

  //Organizes a list of topics by category
  static Map<String, List<Topic>> organizeByCategory(List<Topic> topicList,
      [bool addSubSection = false, List<Subscription> subs = const [], bool addSearchSection = false]) {
    Map<String, List<Topic>> map = Map();
    if (addSubSection) {
      if (!map.containsKey('Subscribed'))
        {map['Subscribed'] = [];} //Creates an empty list for topics
      subs.forEach((sub) {
        //Adds the key for any category that has not been added
        Topic top = Topic(id: sub.topicId, name: sub.topic);
        map['Subscribed']
            .add(top); //Adds the topic under its category in the map
      });
    }
    if (addSearchSection) {
      if (!map.containsKey('Search'))
        {map['Search'] = [];} //Creates an empty list for topics
      
    }
    //Itterates through list of topics
    topicList.forEach((topic) {
      //Adds the key for any category that has not been added
      if (!map.containsKey(topic.category))
        {map[topic.category] = [];} //Creates an empty list for topics
      map[topic.category]
          .add(topic); //Adds the topic under its category in the map
    });

    //returns the map of topics mapped to categories
    return map;
  }

  //Organizes a list of topics by id
  static Map<String, Topic> organizeByID(List<Topic> topicList) {
    Map<String, Topic> map = Map();

    //Itterates through list of topics
    topicList.forEach((topic) {
      map[topic.id] = topic; //Adds the topic under its id in the map
    });

    //returns the map of topics mapped to categories
    return map;
  }

  @override
  String toString() {
    return 'Topic: ' + name + ' | Category: ' + category + ' | id: ' + id;
  }
}
