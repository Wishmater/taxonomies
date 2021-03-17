

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moor/moor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:taxonomies/main.dart';
import 'database_impl.dart';
import 'package:image/image.dart';

abstract class DatabaseController{

  static Map<String, dynamic> config = {};
  static List<AdModel> bannerAds = [];
  static List<AdModel> fullscreenAds = [];
  static List<GameModel> games = [];
  static List<String> homeCategories = [];
  static late LazyDatabase _db;

  static Future<void> init({String? propertiesPath, bool loadDb=true}) async{
//    String props = await rootBundle.loadString('assets/config.properties');
    var data; var list; var list2;
    if (propertiesPath==null){
      var data = await rootBundle.load('assets/config.properties');
      var buffer = data.buffer;
      list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      try {
        var data2 = await rootBundle.load('assets/manual_config.properties');
        var buffer2 = data2.buffer;
        list2 = buffer2.asUint8List(data2.offsetInBytes, data2.lengthInBytes);
      } catch (_){}
    } else{
      list = File(propertiesPath).readAsBytesSync();
    }
    try{
      list = utf8.decode(list);
    } catch (_){
      list = ascii.decode(list, allowInvalid: true);
    }
    if (list2!=null){
      try{
        list2 = utf8.decode(list2);
      } catch (_){
        list2 = ascii.decode(list2, allowInvalid: true);
      }
    }
    List<AdModel> ads = [];
    List<String> props = LineSplitter.split(list).toList();
    if (list2!=null) props.addAll(LineSplitter.split(list2));
    props.forEach((element) {
      if (element.startsWith("#")) return;
      try{
        var index = element.indexOf(' = ');
        String key = element.substring(0, index);
        String value = element.substring(index+3);
        value = value.replaceAll("\\\\", "\\");
        if (key.startsWith("home_category")){
          homeCategories.add(value);
        } else if (key.startsWith("publicity")){
          var underscoreIndex = key.indexOf('_');
          index = int.parse(key.substring(9, underscoreIndex))-1;
          while(ads.length<=index){
            ads.add(AdModel());
          }
          key = key.substring(underscoreIndex+1);
          switch(key){
            case 'display_type':
              ads[index].displayType = value;
              break;
            case 'type':
              ads[index].type = value;
              break;
            case 'data':
              ads[index].data = value;
              break;
            case 'name':
              ads[index].name = value;
              break;
            case 'link':
              ads[index].link = value;
              break;
          }
        } else if (key.startsWith("game")) {
          var underscoreIndex = key.indexOf('_');
          index = int.parse(key.substring(4, underscoreIndex))-1;
          while(games.length<=index){
            games.add(GameModel());
          }
          key = key.substring(underscoreIndex+1);
          if (key.startsWith('target_attribute') || key.startsWith('hint_attribute')){
            List<String> list = games[index].targetAttributes;
            if (key.startsWith('hint_attribute')) list = games[index].hintAttributes;
            list.add(value);
          } else{
            switch(key){
              case 'name':
                games[index].name = value;
                break;
              case 'description':
                games[index].description = value;
                break;
              case 'type':
                games[index].type = value;
                break;
              case 'target_category':
                games[index].targetCategory = value;
                break;
              case 'hint_category':
                games[index].hintCategory = value;
                break;
            }
          }
        } else{
          config[key] = value;
        }
      } catch(e){}
    });
    ads.forEach((element) {
      if (element.displayType=='Banner'){
        bannerAds.add(element);
      } else if (element.displayType=='Fullscreen'){
        fullscreenAds.add(element);
      }
    });
    log(config.toString());
    if (loadDb){
      data = await rootBundle.load('assets/main.db');
      Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (kIsWeb) {
        _db = LazyDatabase(()=>getPlatformDatabase(null, bytes));
      } else{
        Directory targetDirectory = await getApplicationSupportDirectory();
        String path = p.join(targetDirectory.path, "${config['title']}.db");
        // if ( FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound // TODO in production, dont recopy db
        //     || File(path).lengthSync()!=bytes.lengthInBytes){
          await (File(path)..createSync(recursive: true)).writeAsBytes(bytes);
          log("Database copied to $path.");
        // } else{
        //   log("Database already found in $path.");
        // }
        _db = LazyDatabase(()=>getPlatformDatabase(File(path), null));
      }
      await _db.ensureOpen(DatabaseUser());
    }
  }

  static Future<List<List<String>>> executeQuery(String sql) async{
//    log("Execute SQLite Query: $sql");
    return _db.runSelect(sql, []).then(
            (value) => value.map(
                (e) => e.values.map(
                    (e) {
                      if (e is Uint8List){
                        String res;
                        try{
                          res = utf8.decode(e);
                        } catch (_){
                          res = ascii.decode(e, allowInvalid: true);
                        }
                        return res;
                      } else{
                        return e.toString();
                      }
                    }
                ).toList(growable: false)
            ).toList(growable: false)
    );
  }

  static Future<void> executeSynch(String propertiesPath) async{

    // INITIALIZE PATHS FROM ARGUMENTS
    String scriptPath = Platform.script.path.substring(1, Platform.script.path.indexOf(Platform.script.pathSegments.last))
        .replaceAll('%20', ' ');
    String title = config["title"];
    String dbPath = config["db_path"];
    String assetsPath = config["storage_path"];
    String iconPath = config["icon_path"];
    String destinationFolderPath = config["destination_folder"];
    print("Properties Path: "+propertiesPath);
    print("Database Path: "+dbPath);
    print("Assets Path: "+assetsPath);
    print("Destination Folder Path: "+destinationFolderPath);

    String windowsFolderPath = p.join(destinationFolderPath, title+" Windows");
    String androidFolderPath = p.join(destinationFolderPath, title+" Android");

    // INITIALIZE FILES FROM PATHS
    File dbFile = new File(dbPath);
    File propertiesFile = new File(propertiesPath);
    Directory assetsFolder = new Directory(assetsPath);
    Directory windowsFolder = new Directory(windowsFolderPath);
    Directory androidFolder = new Directory(androidFolderPath);
//    Directory windowsOriginFolder = Directory("C:\\Workspaces\\Flutter\\taxonomies\\release\\syncTest_multi_windows");
    String windowsOriginFolderPath = p.join(File(Platform.script.toFilePath(windows: true)).parent.absolute.path, 'app');
    Directory windowsOriginFolder = Directory(windowsOriginFolderPath);

    // COPY WINDOWS FILES
    logFileWrite.writeln('Starting Windows synch...');
    if (windowsFolder.existsSync()) windowsFolder.deleteSync(recursive: true);
    windowsFolder.createSync(recursive: true);
    copyDirectory(windowsOriginFolder, windowsFolder, recursive: false);
    Directory windowsDataTargetFolder = Directory(p.join(windowsFolderPath, 'data'));
    windowsDataTargetFolder.createSync();
    copyDirectory(Directory(p.join(windowsOriginFolderPath, 'data')), windowsDataTargetFolder);
    String windowsAssetsPath = "$windowsFolderPath\\data\\flutter_assets\\assets";
    copyDirectory(assetsFolder, Directory(windowsAssetsPath));
    dbFile.copySync(p.join(windowsAssetsPath,'main.db'));
    String propertiesOutput = p.join(windowsAssetsPath,'config.properties');
    propertiesFile.copySync(propertiesOutput);
    logFileWrite.writeln('Starting Windows icon integration process...');
    Process icoIntegrationProcess = await Process.start('app\\android\\ResourceHacker\\ResourceHacker.exe',
      [
        '-open', p.join(windowsFolderPath,'multi.exe'),
        '-save', p.join(windowsFolderPath,title+'.exe'),
        '-action', 'addoverwrite',
        '-res', iconPath,
        '-mask', 'ICONGROUP,101,', //MAINICON
      ],
      workingDirectory: scriptPath.replaceAll('/', '\\'),
    );
    icoIntegrationProcess.stdout.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    icoIntegrationProcess.stderr.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    logFileWrite.writeln('Windows icon integration process exit code: ' + (await icoIntegrationProcess.exitCode).toString());
    File(p.join(windowsFolderPath,'multi.exe')).deleteSync();
    logFileWrite.writeln('Windows Synch Successful !!!! :)...');

    // extract images from .ico
    logFileWrite.writeln('Starting ico process...');
    Process icoProcess = await Process.start('app\\android\\ImageMagick-7.0.10-Q16-HDRI\\magick.exe'
      , ['convert',
        iconPath,
        p.join(destinationFolderPath, 'logo.png'),
      ],
      workingDirectory: scriptPath.replaceAll('/', '\\'),
    );
    icoProcess.stdout.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    icoProcess.stderr.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    logFileWrite.writeln('Ico process exit code: ' + (await icoProcess.exitCode).toString());
    int i = 9;
    late File iconImageFile;
    do {
      i--;
      iconImageFile = File(p.join(destinationFolderPath, 'logo-$i.png'),);
    } while (!iconImageFile.existsSync() && i>0);
    Image iconImage = decodeImage(iconImageFile.readAsBytesSync());

    // COPY ANDROID FILES
    logFileWrite.writeln('Starting Android synch...');
    if (androidFolder.existsSync()) androidFolder.deleteSync(recursive: true);
    androidFolder.createSync(recursive: true);
    String androidExtraFolderPath = p.join(androidFolderPath, 'extra');
    Directory androidExtraFolder = Directory(androidExtraFolderPath);
    String androidAssetsFolderPath = p.join(androidExtraFolderPath, 'assets', 'flutter_assets', 'assets');
    Directory androidAssetsFolder = Directory(androidAssetsFolderPath);
    androidAssetsFolder.createSync(recursive: true);
    copyDirectory(assetsFolder, androidAssetsFolder);
    dbFile.copySync(p.join(androidAssetsFolderPath,'main.db'));
    // copy icons
    List<String> resolutionNames = ['mipmap-mdpi-v4', 'mipmap-hdpi-v4', 'mipmap-xhdpi-v4', 'mipmap-xxhdpi-v4', 'mipmap-xxxhdpi-v4'];
    List<int> resolutionSizes = [48, 72, 96, 144, 192];
    for (var j = 0; j < resolutionNames.length; ++j) {
      File(p.join(androidExtraFolderPath,'res',resolutionNames[j],'ic_launcher.png'))..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(copyResize(iconImage, width: resolutionSizes[j], height: resolutionSizes[j], interpolation: Interpolation.average)));
    }
    // replace name in manifest
    File manifest = File('app/android/AndroidManifest.xml');
    var xml = manifest.readAsStringSync();
    xml = xml.replaceAll('android:label="taxonomies"', 'android:label="$title"');
    manifest.deleteSync();
    manifest.createSync();
    manifest.writeAsString(xml);
    // encode manifest
    logFileWrite.writeln('Starting manifest encode process...');
    Process encodeProcess = await Process.start('java',
      ['-jar', 'app\\android\\xml2axml-1.1.0-SNAPSHOT.jar',
        'e',
        'app/android/AndroidManifest.xml',
        p.join(androidExtraFolderPath,'AndroidManifest.xml'),
      ],
      workingDirectory: scriptPath.replaceAll('/', '\\'),
    );
    encodeProcess.stdout.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    encodeProcess.stderr.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    logFileWrite.writeln('Manifest encode exit code: ' + (await encodeProcess.exitCode).toString());
    // update AssetManifest.json
    String assets = File('app/android/AssetManifest.json').readAsStringSync();
    assets = assets.substring(0, assets.length-1);
    assets = addAllAssets(androidAssetsFolder, assets, 'assets/');
    assets += '}';
    File assetsManifest = File(p.join(androidExtraFolderPath,'assets','flutter_assets','AssetManifest.json'));
    assetsManifest.createSync();
    assetsManifest.writeAsString(assets);
    File('app/android/app.apk').copySync(p.join(androidFolderPath, '$title.apk'));
    // run 7zip to add androidExtraFolderPath to p.join(androidFolderPath, '$title.apk')
    logFileWrite.writeln('Starting zip process...');
    Process zipProcess = await Process.start('app\\android\\7-Zip\\7z'
      , ['a',
        p.join(androidFolderPath, '$title.apk'),
        p.join(androidExtraFolderPath, '*'),
        '-tzip',
      ],
      workingDirectory: scriptPath.replaceAll('/', '\\'),
    );
    zipProcess.stdout.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    zipProcess.stderr.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    logFileWrite.writeln('Zip process exit code: ' + (await zipProcess.exitCode).toString());
    // run uber_apk_signer on p.join(androidFolderPath, '$title.apk')
    logFileWrite.writeln('Starting signing process...');
    Process signingProcess = await Process.start('java',
      ['-jar', 'app\\android\\uber-apk-signer-1.2.1.jar',
        '--apks', p.join(androidFolderPath, '$title.apk'),
        '--ksAlias', 'taxonomies',
        '--ksPass', 'Informatica2020',
        '--ksKeyPass', 'Informatica2020',
        '--overwrite',
      ],
      workingDirectory: scriptPath.replaceAll('/', '\\'),
    );
    signingProcess.stdout.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    signingProcess.stderr.listen((event) {
      logFileWrite.writeln(String.fromCharCodes(event));
    });
    logFileWrite.writeln('Signing process exit code: ' + (await signingProcess.exitCode).toString());
    androidExtraFolder.deleteSync(recursive: true);
    logFileWrite.writeln('Android Synch Successful !!!! :)...');

    Directory(destinationFolderPath).listSync().forEach((element) {
      if (element.path.contains('logo')) try{ element.deleteSync(); } catch(_){}
    });

  }

  static void copyDirectory(Directory source, Directory destination, {bool recursive=true}) =>
      source.listSync(recursive: false)
          .forEach((var entity) {
        if (entity is Directory) {
          if (recursive){
            var newDirectory = Directory(p.join(destination.absolute.path, p.basename(entity.path)));
            newDirectory.createSync(recursive: true);
            copyDirectory(entity.absolute, newDirectory);
          }
        } else if (entity is File) {
          entity.copySync(p.join(destination.path, p.basename(entity.path)));
        }
      });

  static String addAllAssets(Directory currentDirectory, String base, [String prefix='']){
    String result = base;
    currentDirectory.listSync().forEach((element) {
      if (FileSystemEntity.isDirectorySync(element.absolute.path)){
        result = addAllAssets(Directory(element.absolute.path), result, prefix+p.basename(element.path)+'/');
      } else{
        String path = (prefix+p.basename(element.path));
        result += ',"$path":["$path"]';
      }
    });
    return result;
  }

}









class DatabaseUser extends QueryExecutorUser{

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 1;

}

class AdModel {
  String? displayType;
  String? type;
  String? data;
  String? name;
  String? link;
}

class GameModel {
  String? name;
  String? description;
  String? type;
  String? targetCategory;
  List<String> targetAttributes = [];
  String? hintCategory;
  List<String> hintAttributes = [];
}

class MyZipFileEncoder {
  String? zip_path;
  OutputFileStream? _output;
  ZipEncoder? _encoder;

  static const int STORE = 0;
  static const int GZIP = 1;

  void zipDirectory(Directory dir, {String? filename}) {
    final dirPath = dir.path;
    final zip_path = filename ?? '${dirPath}.zip';
    create(zip_path);
    addDirectory(dir, includeDirName: false);
    close();
  }

  void open(String zip_path) => create(zip_path);

  void create(String zip_path) {
    this.zip_path = zip_path;

    _output = OutputFileStream(zip_path);
    _encoder = ZipEncoder();
    _encoder!.startEncode(_output);
  }

  void addDirectory(Directory dir, {bool includeDirName = true}) {
    List files = dir.listSync(recursive: true);
    for (var file in files) {
      if (file is! File) {
        continue;
      }

      final f = file as File;
      final dir_name = p.basename(dir.path);
      final rel_path = p.relative(f.path, from: dir.path);
      addFile(f, includeDirName ? (dir_name + '/' + rel_path) : rel_path);
    }
  }

  void addFile(File file, [String? filename]) {
    var file_stream = InputFileStream.file(file);
    var f = ArchiveFile.stream(
        filename ?? p.basename(file.path),
        file.lengthSync(),
        file_stream);

    try{
      f.lastModTime = file.lastModifiedSync().millisecondsSinceEpoch;
    } catch(_){}
    f.mode = file.statSync().mode;

    _encoder!.addFile(f);
    file_stream.close();
  }

  void close() {
    try{ _encoder!.endEncode(); } catch(_){}
    try{ _output!.close(); } catch(_){}
  }
}