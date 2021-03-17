import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/instance.dart';

class Attribute{

  int typeId;
  String typeName;
  String attributeName;
  String value;
  Instance? link;
  bool prioritize;

  Attribute({required this.typeId, required this.typeName, required this.attributeName, required this.value, this.link, this.prioritize=false});

  Attribute copyWith({
    int? typeId,
    String? typeName,
    String? attributeName,
    String? value,
    Instance? link,
  }) {
    return Attribute(
      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,
      attributeName: attributeName ?? this.attributeName,
      value: value ?? this.value,
      link: link,
    );
  }

  double? _overridenPriority;
  double get typePriority{
    if (_overridenPriority!=null) return _overridenPriority!;
    double result = -1;
    if (typeName == "Texto Corto"){
      result = 1;
    } else if (typeName == "Numero"){
      result = 2;
    } else if (typeName == "Fecha"){
      result = 4;
    } else if (typeName == "Texto Largo"){
      result = 6;
    } else if (typeName == "Audio"){
      result = 5;
    } else if (typeName == "Imagen"){
      result = 8;
    } else if (typeName == "Video"){
      result = 7;
    }
    return result;
  }

  static Future<List<Attribute>> getAttributesFromArticle(int instance_id, {sort=true}) async{

    List<List<String>> result = [];
    try {
      result = await DatabaseController.executeQuery("select Type.type_id, type_name, attribute_name, value from Instance" +
          " join Instance_Attribute on Instance.instance_id=Instance_Attribute.instance_id" +
          " join Attribute on Instance_Attribute.attribute_id=Attribute.attribute_id" +
          " join Type on Attribute.attribute_type_id=Type.type_id" +
          " where Instance.instance_id='$instance_id'" +
          " order by Attribute.attribute_id, Type.type_id, type_name, attribute_name, value");
    } catch (e, st) {
      print(e); print(st);
    }
    return getAttributesfromQueryResult(result, sort: sort);

  }

  static List<Attribute> getAttributesfromQueryResult(List<List<String>> result, {sort=true}){
  List<Attribute> attributes = [];
    for (int i = 0; i < result.length; i++) {
      attributes.add(
        new Attribute(
          typeId: int.parse(result[i][0]),
          typeName: result[i][1],
          attributeName: result[i][2],
          value: result[i][3],
        ),
      );
    }
    if (sort && attributes.isNotEmpty){
      attributes = Attribute.sort(attributes);
    }
    return attributes;
  }

  static List<Attribute> sort(List<Attribute> attributes){
    attributes.sort((a, b){
      int res = a.typePriority.compareTo(b.typePriority);
      // if (a.prioritize) res = 1;
      // else if (b.prioritize) res = -1;
      // if (res==0) res = a.attributeName.compareTo(b.attributeName);
      return res;
    });
    if (attributes[0].typeName!="Imagen"){
      int i = attributes.lastIndexWhere((element) => element.typeName=="Imagen");
      if (i!=-1){
        final temp = attributes[i];
        attributes.removeAt(i);
        attributes.insert(0, temp);
        temp._overridenPriority = 0;
      }
    }
    return attributes;
  }

}