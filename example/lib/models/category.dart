
import 'topics.dart';

class Category {
  String name;
  String id;
  List<Topic> topics;
  Category({this.name, this.topics, this.id});

  factory Category.fromJson(Map<String, dynamic> json) {
    List<Topic> topics = [];
    for (var topic in json['topics']) {
      topics.add(Topic(name: topic, category: json['name']));
    }

    return Category(
      name: json['name'],
      topics: topics,
      id: json['id'],
    );
  }

  @override
  String toString() {
    String objectString = '**';
    objectString += name;
    objectString += '**';
    for (Topic topic in topics) {
      objectString += ', ';
      objectString += topic.name;
    }
    return objectString;
  }
}
//todo populate with api calls
List<Category> categories;
bool isCategoriesLoaded = false;
