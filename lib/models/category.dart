import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/instance.dart';

class Category {

  int id;
  String name;
  // List<int> possibleAttributes;

  Category({required this.id, required this.name,});


  Future<List<Instance>> getInstances({bool load=false}) async{
    return Instance.getArticlesFromCategory(id, load);
  }


  static Future<List<Category>> getCategories() async{
    List<List<String>> result = [];
    try {
      result = await DatabaseController.executeQuery("select category_id, category_name from Category");
    } catch (e, st) {
      print(e); print(st);
    }
    List<Category> categories = [];
    for (int i = 0; i < result.length; i++) {
      categories.add(new Category(
        id: int.parse(result[i][0]),
        name: result[i][1]),
      );
    }
    categories.sort((a, b){
      return a.id.compareTo(b.id);
    });
    return categories;
  }

  static Future<String> getRelationName(String fatherId, String sonId, [bool isSon=false]) async{
    List<List<String>> result = [];
    try {
      result = await DatabaseController.executeQuery("select father_son, son_father from Relation join Category_Category on Category_Category.relation_id=Relation.relation_id where category_father_id=$fatherId and category_son_id=$sonId");
    } catch (e, st) {
      print(e); print(st);
    }
    try{
      return result[0][isSon ? 0 : 1];
    } catch(_){
      return '';
    }
  }

}