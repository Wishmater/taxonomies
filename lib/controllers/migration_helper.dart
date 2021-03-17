
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:moor/moor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/controllers/database_impl.dart';
import 'package:intl/intl.dart' as intl;

class Migration{

  int instanceIdCount = 1;
  int instanceAttributeIdCount = 1;
  int instanceInstanceIdCount = 1;
  late LazyDatabase from;
  late LazyDatabase to;
  String fromPath;
  String toPath;
  Map<String, Map<int, int>> oldToNewIdMappings = {};

  Migration(this.fromPath, this.toPath);

  Future<void> migrate() async{

    from = LazyDatabase(()=>getPlatformDatabase(File(fromPath), null));
    to = LazyDatabase(()=>getPlatformDatabase(File(toPath), null));
    await from.ensureOpen(DatabaseUser());
    await to.ensureOpen(DatabaseUser());

    to.runDelete('delete from Instance', []);
    to.runDelete('delete from Instance_Attribute', []);
    to.runDelete('delete from Instance_Instance', []);

    await insertInstance(12, 'abundancia',
      attributeIds: [1, 4],
      attributeOldNames: ['abundancia', 'icono'],
    );

    await insertInstance(9, 'actividad',
      attributeIds: [1, 4],
      attributeOldNames: ['actividad', 'icono'],
    );

    await insertInstance(10, 'conservacion',
      attributeIds: [1, 4],
      attributeOldNames: ['conservacion', 'icono'],
    );

    await insertInstance(11, 'dieta',
      attributeIds: [1, 4],
      attributeOldNames: ['nombre_dieta', 'icono'],
    );

    await insertInstance(14, 'habitat',
      attributeIds: [1, 4],
      attributeOldNames: ['habitat', 'icono'],
    );

    await insertInstance(13, 'endemismo',
      attributeIds: [1,],
      attributeOldNames: ['zona',],
    );

    await insertInstance(17, 'autor',
      attributeIds: [1, 2],
      attributeOldNames: ['nombre_autor', 'desc_autor'],
    );

    await insertInstance(18, 'licencia',
      attributeIds: [1, 2],
      attributeOldNames: ['nombre_licencia', 'desc_licencia'],
    );

    await insertInstance(15, 'media',
      attributeIds: [1, 7, 5, 8],
      attributeOldNames: ['SIN_NOMBRE', 'ubicacion', 'fecha', 'localizacion'],
      categoryIdGetter: (e) => e['tipo']=='audio' ? 16 : 15,
      attributeIdsGetter: (e) => e['tipo']=='audio' ? [1, 7, 5, 8] : [1, 6, 5, 8],
      relationOldNames: ['autor', 'licencia'],
    );

    await insertInstance(1, 'dominio',
      attributeIds: [1, 2],
      attributeOldNames: ['nombre_dominio', 'desc_dominio'],
    );

    await insertInstance(2, 'reino',
      attributeIds: [1, 2],
      attributeOldNames: ['nombre_reino', 'desc_reino'],
      relationOldNames: ['dominio'],
    );

    await insertInstance(3, 'filo',
      attributeIds: [1, 2],
      attributeOldNames: ['nombre_filo', 'desc_filo'],
      relationOldNames: ['reino'],
    );

    await insertInstance(4, 'clase',
      attributeIds: [1, 2],
      attributeOldNames: ['nombre_clase', 'desc_clase'],
      relationOldNames: ['filo'],
    );

    await insertInstance(5, 'orden',
      attributeIds: [1, 2],
      attributeOldNames: ['nombre_orden', 'desc_orden'],
      relationOldNames: ['clase'],
    );

    await insertInstance(6, 'familia',
      attributeIds: [1, 2],
      attributeOldNames: ['nombre_familia', 'desc_familia'],
      relationOldNames: ['orden'],
    );

    await insertInstance(7, 'genero',
      attributeIds: [1, 2],
      attributeOldNames: ['nombre_genero', 'desc_genero'],
      relationOldNames: ['familia'],
    );

    await insertInstance(8, 'especie',
      attributeIds: [1, 2, 3, 9, 10],
      attributeOldNames: ['nombre_especie', 'desc_especie', 'cient_especie', 'nidificacion', 'dimorfismo'],
      relationOldNames: ['genero', 'endemismo', 'abundancia'],
    );

    await insertRelation('especie_actividad', 'especie', 'actividad');
    await insertRelation('especie_conservacion', 'especie', 'conservacion');
    await insertRelation('especie_habitat', 'especie', 'habitat');
    await insertRelation('especie_media', 'media', 'especie',);
    await insertRelation('especie_dieta', 'especie', 'dieta',
      extraGetter: (e) => e['prioridad']==1 ? 'Principal' : 'Alternativa',
    );

    print(oldToNewIdMappings);

  }

  Future<void> insertInstance(int categoryId, String oldTableName, {
      List<int> attributeIds=const[], List<String> attributeOldNames=const[],
      List<String> relationOldNames=const[],
      int Function(Map<String, dynamic>)? categoryIdGetter,
      List<int> Function(Map<String, dynamic>)? attributeIdsGetter,}) async{

    String oldIdName = 'id_$oldTableName';
    Map<int, int> idMappings = {};
    final resultSet = await from.runSelect('select * from $oldTableName', []);
    // print (resultSet);
    for (var i = 0; i < resultSet.length; ++i) {
      final e = resultSet[i];
      if (categoryIdGetter!=null) categoryId = categoryIdGetter(e);
      if (attributeIdsGetter!=null) attributeIds = attributeIdsGetter(e);
      to.runInsert('insert into Instance values ($instanceIdCount, $categoryId)', []);
      if (e.containsKey(oldIdName)){
        idMappings[e[oldIdName]] = instanceIdCount;
      }
      for (var i = 0; i < attributeIds.length; ++i) {
        dynamic value = e[attributeOldNames[i]] ?? '';
        if (attributeIds[i]==5) value = intl.DateFormat('dd/MM/yyy').format(DateTime.fromMillisecondsSinceEpoch(value));
        if (attributeOldNames[i]=='dimorfismo') value = value==1 ? 'Sí - Hay Diferencias apreciables entre macho y hembra' : 'No - No hay Diferencias apreciables entre macho y hembra';
        if (attributeOldNames[i]=='SIN_NOMBRE') {
          final especie = await from.runSelect('select * from especie join especie_media on especie.id_especie=especie_media.id_especie where id_media=${e['id_media']}', []);
          value = (e['tipo']=='audio' ? 'Sonido de ' : 'Foto de ') + especie[0]['nombre_especie'];
        }
        to.runInsert("insert into Instance_Attribute values ($instanceAttributeIdCount, '$value', $instanceIdCount, ${attributeIds[i]})", []);
        instanceAttributeIdCount++;
      }
      if (oldTableName=='endemismo' || oldTableName=='autor' || oldTableName=='licencia'){
        dynamic value = oldTableName=='autor' ? 'icon/new/autor.png'
            : oldTableName=='endemismo' ? e['zona']=='Cuba' ? 'icon/new/cuba.png' : 'icon/new/america.png'
            : e['nombre_licencia']=='Propietaria' ? 'icon/new/licencia_copyright.png'
            : e['nombre_licencia']=='Creative Commons' ? 'icon/new/licencia_commons.png'
            : e['nombre_licencia']=='Libre' ? 'icon/new/licencia_free.png'
            : 'icon/new/licencia_desconocida.png';
        to.runInsert("insert into Instance_Attribute values ($instanceAttributeIdCount, '$value', $instanceIdCount, 4)", []);
        instanceAttributeIdCount++;
      }
      for (var i = 0; i < relationOldNames.length; ++i) {
        int value = oldToNewIdMappings[relationOldNames[i]]![e['${relationOldNames[i]}_id']]!;
        to.runInsert("insert into Instance_Instance values ($instanceInstanceIdCount, '$value', $instanceIdCount, '')", []);
        instanceInstanceIdCount++;
      }
      instanceIdCount++;
    }
    oldToNewIdMappings[oldTableName] = idMappings;

  }

  Future<void> insertRelation(String oldTableName, String sonName, String fatherName, {
      int Function(Map<String, dynamic>)? sonIdGetter, String where='',
      String Function(Map<String, dynamic>)? extraGetter }) async{

    final resultSet = await from.runSelect('select * from $oldTableName$where', []);
    resultSet.forEach((Map<String, dynamic> e) {
      String extra = extraGetter?.call(e) ?? '';
      final son = oldToNewIdMappings[sonName]![e['id_$sonName']];
      final father = oldToNewIdMappings[fatherName]![e['id_$fatherName']];
      to.runInsert("insert into Instance_Instance values ($instanceInstanceIdCount, '$father', $son, '$extra')", []);
      instanceInstanceIdCount++;
    });

  }

}