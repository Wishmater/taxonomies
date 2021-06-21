import 'package:flutter/material.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/main.dart';
import 'package:taxonomies/models/attribute.dart';
import 'package:taxonomies/models/category.dart';

class Instance {

  int id;
  String name;
  Category category;
  List<Attribute>? attributes;
  String? extra;
  bool sortByDefault;

  Instance({required this.id, required this.name, required this.category, this.extra, this.sortByDefault=true});

  static final attributeSeparationIndex = 5;
  List<Attribute>? get firstAttributeColumn{
    if (attributes==null) return null;
    return attributes!.where((element) => element.typePriority<=attributeSeparationIndex).toList();
  }
  List<Attribute>? get secondAttributeColumn{
    if (attributes==null) return null;
    return attributes!.where((element) => element.typePriority>attributeSeparationIndex).toList();
  }
  Future<List<Attribute>> getAttributes({bool? sort}) async{
    if (sort==null) sort = sortByDefault;
    var a = Attribute.getAttributesFromArticle(id, sort: false);
    var value = await a;
    value.removeWhere((element) => element.attributeName=='Nombre');
    final embedded = await getSons(true);
    for (var i = 0; i < embedded.length; ++i) {
      embedded[i].sortByDefault = false;
      final attributes = await embedded[i].getAttributes(sort: false);
      final attribute = attributes.firstWhere((element) => element.typeName=='Imagen' || element.typeName=='Audio' || element.typeName=='Video');
      value.add(attribute.copyWith(
        link: embedded[i],
      ));
      // attribute.prioritize = true;
    }
    if (sort && value.where((element) => element.typeName=='Imagen').length==0){
      String? firstImage = await getFirstImage();
      if (firstImage!=null){
        value.insert(0, Attribute(
          typeId: -1,
          typeName: "Imagen",
          attributeName: "Ejemplo de $name",
          value: firstImage,
        ),);
      }
    }
    attributes = sort ? Attribute.sort(value) : value;
    return attributes!;
  }

  Future<List<Instance>> getParents() async{
    final result = await Instance.getArticlesFromSon(id);
    result.sort((a,b){
      var result = a.category.id.compareTo(b.category.id);
      if (result==0 && a.extra!=null && b.extra!=null){
        result = -1 * a.extra!.compareTo(b.extra!);
      }
      return result;
    });
    return result;
  }

  Future<List<Instance>> getSons([bool embedded = false]) async{
    final result = await Instance.getArticlesFromParent(id);
    for (var i = 0; i < result.length; ++i) {
      final relationName = await Category.getRelationName(this.category.id.toString(), result[i].category.id.toString(), false,);
      if (embedded!=(relationName=='Embedded')) {
        result.removeAt(i);
        i--;
      }
    }
    return result;
  }

  static Future<List<Instance>> getArticlesFromCategory(int category_id, bool load) async{
    List<List<String>> result = [];
    try {
      result = await DatabaseController.executeQuery("select Instance.instance_id, value, Category.category_id, category_name from Instance" +
          " join Instance_Attribute on Instance.instance_id=Instance_Attribute.instance_id" +
          " join Attribute on Instance_Attribute.attribute_id=Attribute.attribute_id" +
          " join Category on Instance.category_id=Category.category_id" +
          " where attribute_name='Nombre' and Instance.category_id='$category_id'");
    } catch (e, st) {
      print(e); print(st);
    }
    List<Instance> instances = getInstancesfromQueryResult(result);
//    if (load){
//      for (int i = 0; i < instances.length; i++) {
//        instances[i].loadAttributes();
//      }
//    }
    return instances;
  }

  static Future<List<Instance>> getArticlesFromParent(int parent_id, [bool load=false]) async{
    List<List<String>> result = [];
    try {
      result = await DatabaseController.executeQuery("select Instance.instance_id, value, Category.category_id, category_name from Instance" +
          " join Instance_Attribute on Instance.instance_id=Instance_Attribute.instance_id" +
          " join Attribute on Instance_Attribute.attribute_id=Attribute.attribute_id" +
          " join Instance_Instance on Instance.instance_id=Instance_Instance.instance_son_id" +
          " join Category on Instance.category_id=Category.category_id" +
          " where attribute_name='Nombre' and Instance_Instance.instance_father_id='$parent_id'");
    } catch (e, st) {
      print(e); print(st);
    }
    List<Instance> instances = getInstancesfromQueryResult(result);
//    if (load){
//      for (int i = 0; i < instances.length; i++) {
//        instances[i].loadAttributes();
//      }
//    }
    return instances;
  }

  static Future<List<Instance>> getArticlesFromSon(int son_id, [bool load=false]) async{
    List<List<String>> result = [];
    try {
      result = await DatabaseController.executeQuery("select Instance.instance_id, value, Category.category_id, category_name, extra from Instance" +
          " join Instance_Attribute on Instance.instance_id=Instance_Attribute.instance_id" +
          " join Attribute on Instance_Attribute.attribute_id=Attribute.attribute_id" +
          " join Instance_Instance on Instance.instance_id=Instance_Instance.instance_father_id" +
          " join Category on Instance.category_id=Category.category_id" +
          " where attribute_name='Nombre' and Instance_Instance.instance_son_id='$son_id'");
    } catch (e, st) {
      print(e); print(st);
    }
    List<Instance> instances = getInstancesfromQueryResult(result);
//    if (load){
//      for (int i = 0; i < instances.length; i++) {
//        instances[i].loadAttributes();
//      }
//    }
    for (var i = 0; i < instances.length; ++i) {
      instances[i].extra = result[i][4];
    }
    return instances;
  }

  static Future<List<Instance>> getAll() async{
    List<List<String>> result = [];
    try {
      result = await DatabaseController.executeQuery("select Instance.instance_id, value, Category.category_id, category_name from Instance_Attribute" +
          " join Attribute on Instance_Attribute.attribute_id=Attribute.attribute_id" +
          " join Instance on Instance.instance_id=Instance_Attribute.instance_id" +
          " join Category on Instance.category_id=Category.category_id" +
          " where attribute_name='Nombre'");
    } catch (e, st) {
      print(e); print(st);
    }
    return getInstancesfromQueryResult(result);
  }

  static Future<List<Instance>> getSearchResults(String? query) async{
    List<List<String>> result = [];
    if (query!=null && query.length>=2) {
      try {
        result = await DatabaseController.executeQuery("select Instance.instance_id, value, Category.category_id, category_name from Instance_Attribute" +
            " join Attribute on Instance_Attribute.attribute_id=Attribute.attribute_id" +
            " join Instance on Instance.instance_id=Instance_Attribute.instance_id" +
            " join Category on Instance.category_id=Category.category_id" +
            " where value like '%" + query + "%' and attribute_name='Nombre'");
      } catch (e, st) {
        print(e); print(st);
      }
    }
    return getInstancesfromQueryResult(result);
  }

  static List<Instance> getInstancesfromQueryResult(List<List<String>> result){
    List<Instance> instances = [];
    for (int i = 0; i < result.length; i++) {
      instances.add(
        new Instance(
          id: int.parse(result[i][0]),
          name: result[i][1],
          category: new Category(id: int.parse(result[i][2]), name: result[i][3]),
        ),
      );
    }
    instances.sort((a, b){
      int res =  a.category.id.compareTo(b.category.id);
      if (res==0) res = a.name.compareTo(b.name);
      return res;
    });
    return instances;
  }


  /*PROGRAMACION COMPETITIVA*/

  //Método publico que será llamado por el controlador
  //Entrada: id del nodo al que se buscará la primera imagen
  //Salida: ruta de la imagen, null si no tiene
  Future<String?>? futureFirstImage;
  String? firstImage;
  Future<String?> getFirstImage([int? instance_id]) async{
    if (futureFirstImage==null) {
      futureFirstImage = _getFirstImage(instance_id);
      futureFirstImage!.then((value) => firstImage = value);
    }
    return futureFirstImage;
  }
  Future<String?> _getFirstImage([int? instance_id]) async{
    if (instance_id==null) instance_id=id;

   //Tiempo del sistema al iniciar el algoritmo
    final time = DateTime.now().millisecond;

    //Inicializar las listas de nodos por expandir y ya revisados, para evitar ciclos
    String? result;
    List<int> nodes = [];
    List<int> passed = [];
    nodes.add(instance_id);

    //Iniciar ciclo mientras no se encuentre una imagen y queden nodos por expandir
    do{

      //Chequear que no se haya revisado ya este nodo
      if (!passed.contains(nodes[0])){
        passed.add(nodes[0]);

        //Obtiene una imagen asociada a este nodo (si no tiene)
        result = await getImage(nodes[0]);

        //Si no se encuentra una imagen
        if (result==null){

          try {

            //Obtener lista de hijos de este nodo
            List<List<String>> sons = await DatabaseController.executeQuery("select Instance_Instance.instance_son_id" +
                " from Instance_Instance" +
                " join Instance son on son.instance_id=Instance_Instance.instance_son_id" +
                " join Instance father on father.instance_id=Instance_Instance.instance_father_id" +
                " join Category_Category on Category_Category.category_son_id=son.category_id and Category_Category.category_father_id=father.category_id"
                " where Instance_Instance.instance_father_id='${nodes[0]}'" +
                " order by Category_Category.Category_Category_id, Instance_Instance.instance_son_id");

            //Añadirlos al final de la lista, asegurando la búsqueda primero a lo ancho
            for (int i = 0; i < sons.length; i++) {
              nodes.add(int.parse(sons[i][0]));
            }

          } catch (e) {
            print (e);
          }

        }

      }
      //Elminar el nodo de la lista por expandir
      nodes.removeAt(0);

      } while (result==null && nodes.length>0);

     //Imprimir tiempo que demoró en terminar el algoritmo
     // logFileWrite.writeln("First Image for id "+instance_id.toString()+" found in "
     //     +(DateTime.now().millisecond-time).toString()+" ms.");

      return Future.value(result);

    }
  //Obtiene una imagen de las asociadas a un nodo
  //Entrada: id del nodo
  //Salida: ruta de la imagen, null si no tiene
  Future<String?> getImage(int instance_id) async{
    String? result = null;
    try {
      result = (await DatabaseController.executeQuery("select value" +
          " from Instance_Attribute" +
          " join Attribute on Instance_Attribute.attribute_id=Attribute.attribute_id" +
          " join Type on Attribute.attribute_type_id=Type.type_id" +
          " where Instance_Attribute.instance_id='$instance_id' and Type.type_name='Imagen'" +
          " order by Attribute.attribute_id, value limit 1"))[0][0];
    } catch (e) {
      result = null;
    }
    return result;
  }


  Future<List<Instance>> getRelativesOfCategory({
    required String category,
  }) async {
    return [...(await getParentsOfCategory(category: category)), ...(await getSonsOfCategory(category: category))];
  }
  Future<List<Instance>> getParentsOfCategory({
    required String category,
  }) async {
    List<Instance> result = [];
    List<Instance> stack = [];
    stack.addAll(await getParents());
    for (var i = 0; i < stack.length; ++i) {
      if (stack[i].category.name==category) {
        result.add(stack[i]);
      }
      stack.addAll(await stack[i].getParents());
    }
    return result;
  }
  Future<List<Instance>> getSonsOfCategory({
    required String category,
  }) async {
    List<Instance> result = [];
    List<Instance> stack = [];
    stack.addAll(await getSons(true));
    for (var i = 0; i < stack.length; ++i) {
      if (stack[i].category.name==category) {
        result.add(stack[i]);
      }
      stack.addAll(await stack[i].getSons(true));
    }
    return result;
  }


}