import 'package:pollar/api/request.dart';
import 'package:pollar/models/category.dart';

class CategoryApi {

  static Future<List<Category>> getCategories() async {
    List<Category> categories = [];
    List<dynamic> categoriesMap = (await request.get('/topics/categories'))['categories'];
    for (Map<String, dynamic> category in categoriesMap) {
      categories.add(Category.fromJson(category));
    }
    return categories;
  }
  
}
