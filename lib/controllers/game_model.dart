
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/attribute.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:dartx/dartx.dart';
import 'package:collection/collection.dart';

class GameModel {

  late String name;
  late String description;
  late String type;
  String? icon;
  int id;
  List<String> targetCategories = [];
  List<String> targetAttributes = [];
  List<String> hintCategories = [];
  List<String> hintAttributes = [];
  List<GameInstanceModel> instances = [];
  Duration? audioDelay;

  GameModel(this.id);

  factory GameModel.fromGameModel(GameModel model) {
    final result = GameModel.factory(
      id: model.id,
      name: model.name,
      description: model.description,
      type: model.type,
      icon: model.icon,
      targetCategories: model.targetCategories,
      targetAttributes: model.targetAttributes,
      hintCategories: model.hintCategories,
      hintAttributes: model.hintAttributes,
    );
    result.audioDelay = model.audioDelay;
    return result;
  }

  factory GameModel.factory({
    required int id,
    required String name,
    required String description,
    required String type,
    String? icon,
    List<String> targetCategories = const [],
    List<String> targetAttributes = const [],
    List<String> hintCategories = const [],
    List<String> hintAttributes = const [],
  }) {
    switch(type) {
      case 'Select':
        return SelectGameModel(
          id: id,
          name: name,
          description: description,
          type: type,
          icon: icon,
          targetCategories: targetCategories,
          targetAttributes: targetAttributes,
          hintCategories: hintCategories,
          hintAttributes: hintAttributes,
        );

      case 'Write':
      case 'WriteAutofill':
        return WriteGameModel(
          id: id,
          name: name,
          description: description,
          type: type,
          icon: icon,
          targetCategories: targetCategories,
          targetAttributes: targetAttributes,
          hintCategories: hintCategories,
          hintAttributes: hintAttributes,
        );

      case 'Letters':
        return LettersGameModel(
          id: id,
          name: name,
          description: description,
          type: type,
          icon: icon,
          targetCategories: targetCategories,
          targetAttributes: targetAttributes,
          hintCategories: hintCategories,
          hintAttributes: hintAttributes,
        );


      // case Hanged

      default:
        return GameModel(id)
          ..name = name
          ..description = description
          ..type = type
          ..icon = icon
          ..targetCategories = targetCategories
          ..targetAttributes = targetAttributes
          ..hintCategories = hintCategories
          ..hintAttributes = hintAttributes;
    }
  }

  GameInstanceModel createGameInstace() {
    instances.add(GameInstanceModel(
      model: this,
    ));
    return instances.last;
  }

  int get timesPlayed {
    return Hive.box('${DatabaseController.config['title'].hashCode}_Game$id').values.length;
  }

  DateTime? get lastPlayed {
    final list = getSortedRecords();
    return list.isEmpty ? null : DateTime.fromMillisecondsSinceEpoch(list.first[0]);
  }

  Map<String, num>? get winPercentLastHundred {
    var list = getSortedRecords();
    int total = min(list.length, 100);
    if (total==0) return null;
    list = list.sublist(0, total);
    final win = list.where((e) => e[2]==true).length;
    final percent = win / total;
    return {
      'win': win,
      'total': total,
      'perc': percent,
    };
  }

  Future<Map<String, int>?> get cleared async {
    try {
      final category = (await Category.getCategories()).where((e) => e.name==hintCategories.first).first;
      final instances = (await category.getInstances()).toList();
      final total = instances.length;
      instances.removeWhere((e) {
        return !didWinInstance(e);
      });
      final win = instances.length;
      return {
        'total': total,
        'win': win,
      };
    } catch(_) {}
    return null;
  }

  getSortedRecords() {
    var list = Hive.box('${DatabaseController.config['title'].hashCode}_Game$id').values.toList();
    list.sort((a, b) {
      return b[0].compareTo(a[0]);
    });
    return list;
  }

  get records => Hive.box('${DatabaseController.config['title'].hashCode}_Game$id').values.toList();
  bool didWinInstance(Instance e) {
    bool w = false;
    for (var i = 0; i < records.length && !w; ++i) {
      if (records[i][1]==e.id && records[i][2]==true) {
        w = true;
      }
    }
    return w;
  }

}

class GameInstanceModel {

  GameModel model;
  Instance? targetInstance;
  late List<Attribute> hiddenHints;
  late List<Attribute> _hints;
  List<Attribute> get hints => win==null ? _hints : [..._hints, ...hiddenHints,];
  set hints(List<Attribute> value) {
    _hints = value;
  }
  late List<Instance> hiddenHintInstances;
  late List<Instance> _hintInstances;
  List<Instance> get hintInstances => win==null ? _hintInstances : [..._hintInstances, ...hiddenHintInstances,];
  set hintInstances(List<Instance> value) {
    _hintInstances = value;
  }
  late List<List<Attribute>> targets;
  late List<List<Instance>> targetInstances;
  String? errorMessage;
  bool? get win => null;
  int get targetCount => -1;
  int? _insertIndex;

  GameInstanceModel({
    required this.model,
  });

  @mustCallSuper
  Future<GameInstanceModel> init() async {
    errorMessage = null;
    hints = [];
    hintInstances = [];
    // print (model.hintCategories);
    // print (model.hintAttributes);
    await _addHints(model.hintCategories, model.hintAttributes);
    if (targetInstance==null) {
      errorMessage = 'No se encontraron Instancias que tengan los Atributos especificados para jugar (hint).';
      return this;
    }
    targets = [];
    targetInstances = [];
    // print (model.targetCategories);
    // print (model.targetAttributes);
    for (var i = 0; i < model.targetCategories.length; ++i) {
      List<Instance> instances;
      // ADD DUMMY ANSWERS
      final category = (await Category.getCategories()).where((e) => e.name==model.hintCategories[i]).first;
      instances = (await category.getInstances())..removeWhere((e) => e.id==targetInstance!.id);
      bool addCategoryName = false;
      for (var j = 0; instances.isNotEmpty && j<targetCount-1; ++j) {
        bool done = false;
        while (instances.isNotEmpty && !done) {
          final instance = instances.removeAt(Random().nextInt(instances.length));
          Iterable<Attribute> filtered;
          if (model.targetAttributes[i]=='Nombre') {
            filtered = [Attribute(typeId: -1, typeName: 'Nombre', attributeName: 'Nombre', value: instance.name)];
          } else {
            final attributes = await instance.getAttributes();
            filtered = attributes.where((e) => e.attributeName==model.targetAttributes[i]);
          }
          if (filtered.isNotEmpty) {
            done = true;
            while (targets.length<=j) targets.add([]);
            targets[j].add(filtered.first);
            while (targetInstances.length<=j) targetInstances.add([]);
            targetInstances[j].add(instance);
          }
        }
      }
      // ADD REAL ANSWER
      if (targetInstance!.category.name==model.targetCategories[i]) {
        instances = [targetInstance!];
      } else {
        instances = await targetInstance!.getRelativesOfCategory(category: model.targetCategories[i]);
        addCategoryName = true;
      }
      final instance = instances.first;
      Iterable<Attribute> filtered;
      if (model.targetAttributes[i]=='Nombre') {
        filtered = [Attribute(
          typeId: -1,
          typeName: 'Nombre',
          attributeName: addCategoryName ? instance.category.name : 'Nombre',
          value: instance.name,
        )];
      } else {
        final attributes = await instance.getAttributes();
        filtered = attributes.where((e) => e.attributeName==model.targetAttributes[i]);
      }
      if (filtered.isNotEmpty) {
        _insertIndex = targets.length==0 ? 0 : Random().nextInt(targets.length);
        targets.insert(_insertIndex!, []);
        targetInstances.insert(_insertIndex!, []);
        if (targetCount<0) {
          filtered.forEach((element) {
            targets[_insertIndex!].add(element);
            targetInstances[_insertIndex!].add(instance);
          });
        } else {
          targets[_insertIndex!].add(filtered.first);
          targetInstances[_insertIndex!].add(instance);
        }
      } else {
        errorMessage = 'Esta instancia los Atributos especificados para jugar (target).';
        return this;
      }
    }
    targets.removeWhere((element) => element.isEmpty);
    targetInstances.removeWhere((element) => element.isEmpty);
    if (targets.isEmpty) {
      errorMessage = 'No se encontraron Instancias que tengan los Atributos especificados para jugar (target).';
      return this;
    }
    // ADD HIDDEN
    hiddenHints = [];
    hiddenHintInstances = [];
    bool addName = true;
    bool addPic = true;
    for (var i = 0; i < _hints.length && addPic; ++i) {
      if (_hints[i].typeName=='Imagen' || _hints[i].typeName=='Video') {
        addPic = false;
      }
    }
    if (model.type=='Select') {
      List<Attribute> allTargets = targets.flatten();
      for (var i = 0; i < allTargets.length && addPic; ++i) {
        if (allTargets[i].typeName=='Imagen' || allTargets[i].typeName=='Video') {
          addPic = false;
        }
      }
    }
    for (var i = 0; i < model.hintCategories.length && addName; ++i) {
      if (model.hintCategories[i]==targetInstance!.category.name && model.hintAttributes[i]=='Nombre') {
        addName = false;
      }
    }
    if (model.type=='Select') {
      for (var i = 0; i < model.targetCategories.length && addName; ++i) {
        if (model.targetCategories[i]==targetInstance!.category.name && model.targetAttributes[i]=='Nombre') {
          addName = false;
        }
      }
    }
    if (addName) {
      await _addHints([targetInstance!.category.name], ['Nombre'], hidden: true);
    }
    if (addPic) {
      String? pic = await targetInstance!.getFirstImage();
      if (pic!=null) {
        hiddenHintInstances.add(targetInstance!);
        hiddenHints.add(Attribute(
          typeId: -1,
          typeName: 'Imagen',
          attributeName: '',
          value: pic,
        ));
      }
    }
    return this;
  }

  Future<void> _addHints(List<String> hintCategories, List<String> hintAttributes, {bool hidden=false}) async {
    if (hidden && targetInstance==null) return;
    for (var i = 0; i < hintCategories.length; ++i) {
      List<Instance> instances;
      bool addCategoryName = false;
      if (targetInstance==null) {
        final category = (await Category.getCategories()).where((e) => e.name==hintCategories[i]).first;
        instances = await category.getInstances();
        instances.shuffle();
        if (Random().nextDouble()<0.66) { // PRIORITIZE NOT WON INSTANCES
          Map<Instance, bool> didWinInstance = {};
          instances.forEach((e) {
            didWinInstance[e] = model.didWinInstance(e);
          });
          instances.sort((a, b) {
            if (!didWinInstance[a]! && didWinInstance[b]!) return -1;
            if (didWinInstance[a]! && !didWinInstance[b]!) return 1;
            return 0;
          });
        }
      } else {
        if (targetInstance!.category.name==hintCategories[i]) {
          instances = [targetInstance!];
        } else {
          instances = await targetInstance!.getRelativesOfCategory(category: hintCategories[i]);
          addCategoryName = true;
        }
        instances.shuffle();
      }
      bool done = false;
      while (instances.isNotEmpty && !done) {
        final instance = instances.removeAt(0);
        Iterable<Attribute> filtered;
        if (hintAttributes[i]=='Nombre') {
          filtered = [Attribute(
            typeId: -1,
            typeName: 'Nombre',
            attributeName: addCategoryName ? instance.category.name : 'Nombre',
            value: instance.name,
          )];
        } else {
          final attributes = await instance.getAttributes();
          filtered = attributes.where((e) => e.attributeName==hintAttributes[i]);
        }
        if (filtered.isNotEmpty) {
          done = true;
          if (targetInstance==null) {
            targetInstance = instance;
          }
          if (hidden) {
            hiddenHints.add(filtered.first);
            hiddenHintInstances.add(instance);
          } else {
            _hints.add(filtered.first);
            _hintInstances.add(instance);
          }
        }
      }
    }
  }

}





class SelectGameModel extends GameModel {

  SelectGameModel({
    required String name,
    required String description,
    required String type,
    required int id,
    String? icon,
    List<String> targetCategories = const [], // length>=1
    List<String> targetAttributes = const [],
    List<String> hintCategories = const [], // length>=1
    List<String> hintAttributes = const [],
  }) :  super(id) {
    this.name = name;
    this.description = description;
    this.type = type;
    this.id = id;
    this.icon = icon;
    this.targetCategories = targetCategories;
    this.targetAttributes = targetAttributes;
    this.hintCategories = hintCategories;
    this.hintAttributes = hintAttributes;
  }

  SelectGameInstanceModel createGameInstace() {
    instances.add(SelectGameInstanceModel(
      model: this,
    ));
    return instances.last as SelectGameInstanceModel;
  }

}

class SelectGameInstanceModel extends GameInstanceModel {

  late int correctIndex;
  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;
  set selectedIndex(int? value) {
    _selectedIndex = value;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    Hive.box('${DatabaseController.config['title'].hashCode}_Game${model.id}').add([timestamp, targetInstance?.id??-1, win]);
  }

  SelectGameInstanceModel({
    required SelectGameModel model,
  }) : super(model: model,);

  @override
  bool? get win => selectedIndex==null ? null : correctIndex==selectedIndex;

  @override
  int get targetCount => 4;

  @override
  Future<GameInstanceModel> init() async {
    await super.init();
    correctIndex = _insertIndex ?? -1;
    return this;
  }

}





class WriteGameModel extends GameModel {

  bool autofill;

  WriteGameModel({
    required String name,
    required String description,
    required String type,
    required int id,
    String? icon,
    List<String> targetCategories = const [], // length==1 and needs to be Text
    List<String> targetAttributes = const [],
    List<String> hintCategories = const [], // length>=1
    List<String> hintAttributes = const [],
  }) :  autofill = type=='WriteAutofill',
        super(id) {
          this.name = name;
          this.description = description;
          this.type = type;
          this.id = id;
          this.icon = icon;
          this.targetCategories = targetCategories;
          this.targetAttributes = targetAttributes;
          this.hintCategories = hintCategories;
          this.hintAttributes = hintAttributes;
        }

  WriteGameInstanceModel createGameInstace() {
    instances.add(WriteGameInstanceModel(
      model: this,
    ));
    return instances.last as WriteGameInstanceModel;
  }

}

class WriteGameInstanceModel extends GameInstanceModel {

  late String correctAnswer;
  String? _givenAnswer;
  String? get givenAnswer => _givenAnswer;
  set givenAnswer(String? value) {
    _givenAnswer = value;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    Hive.box('${DatabaseController.config['title'].hashCode}_Game${model.id}').add([timestamp, targetInstance?.id??-1, win]);
  }

  String? temporalAnswer;

  WriteGameInstanceModel({
    required WriteGameModel model,
  }) : super(model: model,);

  @override
  bool? get win => givenAnswer==null ? null : givenAnswer!.toLowerCase()==correctAnswer.toLowerCase();

  @override
  int get targetCount => 1;

  @override
  Future<GameInstanceModel> init() async {
    await super.init();
    if (_insertIndex!=null) {
      correctAnswer = targets[_insertIndex!].isNotEmpty ? targets[_insertIndex!].first.value : 'ERROR';
    } else {
      correctAnswer = 'ERROR';
    }
    return this;
  }

}





class LettersGameModel extends GameModel {

  LettersGameModel({
    required String name,
    required String description,
    required String type,
    required int id,
    String? icon,
    List<String> targetCategories = const [], // length==1 and needs to be Text
    List<String> targetAttributes = const [],
    List<String> hintCategories = const [], // length>=1
    List<String> hintAttributes = const [],
  }) :  super(id) {
          this.name = name;
          this.description = description;
          this.type = type;
          this.id = id;
          this.icon = icon;
          this.targetCategories = targetCategories;
          this.targetAttributes = targetAttributes;
          this.hintCategories = hintCategories;
          this.hintAttributes = hintAttributes;
        }

  LettersGameInstanceModel createGameInstace() {
    instances.add(LettersGameInstanceModel(
      model: this,
    ));
    return instances.last as LettersGameInstanceModel;
  }

}

class LettersGameInstanceModel extends GameInstanceModel {

  late String correctAnswer;
  late List<String> possibleAnswers;
  late List<int> givenIndices;
  late List<int> spaceIndices;
  String get givenAnswer {
    String result = '';
    givenIndices.forEach((element) {
      result += element<0 ? ' ' : possibleAnswers[element];
    });
    return result;
  }

  bool _confirmed;
  bool get confirmed => _confirmed;
  set confirmed(bool value) {
    _confirmed = value;
    if (_confirmed) {
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      Hive.box('${DatabaseController.config['title'].hashCode}_Game${model.id}').add([timestamp, targetInstance?.id??-1, win]);
    }
  }

  LettersGameInstanceModel({
    required LettersGameModel model,
    bool confirmed = false,
  }) :  _confirmed = confirmed,
        super(model: model,);

  @override
  bool? get win => !confirmed ? null : givenAnswer==correctAnswer;

  @override
  int get targetCount => 1;

  @override
  Future<GameInstanceModel> init() async {
    await super.init();
    if (_insertIndex!=null) {
      correctAnswer = targets[_insertIndex!].isNotEmpty ? targets[_insertIndex!].first.value : 'ERROR';
    } else {
      correctAnswer = 'ERROR';
    }
    final tempAnswer = correctAnswer.toUpperCase().replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U');
    correctAnswer = '';
    spaceIndices = [];
    for (var i = 0; i < tempAnswer.length; ++i) {
      if (tempAnswer[i]==' ') {
        spaceIndices.add(correctAnswer.length-1);
      } else {
        correctAnswer += tempAnswer[i];
      }
    }
    print (correctAnswer);
    int possibleAnswersLength = max(15, correctAnswer.length+5);
    possibleAnswers = [];
    givenIndices = List.generate(correctAnswer.length, (index) => -1);
    List<String> availableCharacters = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'Ñ'];
    final rng = Random();
    for (var i = 0; i < possibleAnswersLength-correctAnswer.length; ++i) {
      possibleAnswers.add(availableCharacters[rng.nextInt(availableCharacters.length)]);
    }
    for (var i = 0; i < correctAnswer.length; ++i) {
      possibleAnswers.insert(rng.nextInt(possibleAnswers.length), correctAnswer[i]);
    }
    return this;
  }

}
