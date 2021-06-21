import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/controllers/migration_helper.dart';
import 'package:taxonomies/notifiers/ads_notifier.dart';
import 'package:taxonomies/notifiers/theme_parameters.dart';
import 'package:taxonomies/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:utf/utf.dart';
import 'package:window_size/window_size.dart';
import 'package:path/path.dart' as p;


String? mode;
String? propertiesPath;



late final IOSink logFileWrite;

void main() async {

  // await Migration('C:/Workspaces/Flutter/taxonomies/assets_new/AvesEndemicasCuba/AvesEndemicasCuba.db',
  //     'C:/Users/Dayan/Desktop/EDDY NOW/dbs/guatini_new.db').migrate();
  // await Migration('C:/Workspaces/Flutter/taxonomies/assets_new/Murcielago/MurcielagosCubanos.db',
  //     'C:/Workspaces/Flutter/taxonomies/assets_Murcielago/main.db').migrate();
  // return;

  if (!kIsWeb && Platform.isWindows){
    File argsFile = File('args.txt');
    if (argsFile.existsSync()){
      var bytes = await argsFile.readAsBytes();
      var decoder = Utf16leBytesToCodeUnitsDecoder(bytes); // use le variant if no BOM
      var raw = String.fromCharCodes(decoder.decodeRest())
          .replaceAll("\"", '')
          .replaceAll('\\\\', '\\')
          .trim();
      argsFile.delete();
      try{
        int space = raw.indexOf(" ");
        mode = raw.substring(0, space);
        propertiesPath = raw.substring(space+1);
      } catch(_){}
//      var log = File('log.txt');
//      log.createSync();
//      log.writeAsString(propertiesPath);
    }
  }
  if (!kIsWeb && Platform.isWindows && mode=='synch'){
    await initHive('taxonomies');
    setWindowTitle("Sincronizando...");
    final maxSize = (await getCurrentScreen())!.frame;
    setWindowFrame(Rect.fromCenter(
        center: Offset(maxSize.width/2, maxSize.height/2),
        width: 512, height: 112
    ));
    String scriptPath = Platform.script.path.substring(1, Platform.script.path.indexOf(Platform.script.pathSegments.last))
        .replaceAll('%20', ' ');
    String path = p.join(scriptPath, 'flutter_log.txt');
    File logFile = File(path)..createSync(recursive: true);
    logFileWrite = logFile.openWrite();
    FlutterError.onError = (FlutterErrorDetails details) {
      logFileWrite.writeln(details.exception.toString());
      logFileWrite.writeln(details.stack.toString());
    };
    runZonedGuarded(
          () async {
            runApp(LoadingApp());
          },
          (dynamic error, StackTrace stackTrace) {
            logFileWrite.writeln(error.toString());
            logFileWrite.writeln(stackTrace.toString());
          },
    );
  } else{
    MyFluroRouter.setupRouter();
    WidgetsFlutterBinding.ensureInitialized();
    await initProject();
    if (kReleaseMode && DatabaseController.logEnabled){
      try {
        String? path;
        if (Platform.isWindows){
          String scriptPath = Platform.script.path.substring(1, Platform.script.path.indexOf(Platform.script.pathSegments.last))
              .replaceAll('%20', ' ');
          path = p.join(scriptPath, 'log.txt');
        } else if (Platform.isAndroid){
          if (await Permission.storage.request().isGranted){
            path = p.join((await DownloadsPathProvider.downloadsDirectory).absolute.path, 'multimedia_log.txt');
          }
        }
        print (path);
        if (path!=null){
          File logFile = File(path)..createSync(recursive: true);
          logFileWrite = logFile.openWrite();
          logFileWrite.writeln(mode);
          FlutterError.onError = (FlutterErrorDetails details) {
            logFileWrite.writeln(details.exception.toString());
            logFileWrite.writeln(details.stack.toString());
          };
          runZonedGuarded(
                () async { runApp(MyApp()); },
                (dynamic error, StackTrace stackTrace) {
                  logFileWrite.writeln(error.toString());
                  logFileWrite.writeln(stackTrace.toString());
                },
          );
        } else{
          runApp(MyApp());
        }
      } catch (e, st){
        print (e);
        print(st);
        runApp(MyApp());
      }
    } else{
      runApp(MyApp());
    }
    if (!kIsWeb && Platform.isWindows){
      setWindowTitle(DatabaseController.config['title'] ?? "Título");
    }
  }
}

Future<void> initProject([String? module]) async {
  if (PlatformExtended.isMobile) {
    final sharedPreferences = await SharedPreferences.getInstance();
    if (DatabaseController.currentlyInstalledTitle==null) {
      await DatabaseController.init(loadDatabase: false);
      String title = DatabaseController.config['title'] ?? 'tax_default';
      DatabaseController.currentlyInstalledTitle = title;
    }
    List<String> availableModules = sharedPreferences.getStringList('modules') ?? [];
    if (module==null) {
      if (!availableModules.contains(DatabaseController.currentlyInstalledTitle)) {
        module = DatabaseController.currentlyInstalledTitle;
      } else {
        module = sharedPreferences.getString('selectedModule') ?? DatabaseController.currentlyInstalledTitle;
      }
    } else {
      sharedPreferences.setString('selectedModule', module);
    }
    await initHive('taxonomies');
    await DatabaseController.init(
        customAssetPathPrefix: PlatformExtended.isMobile && module!=DatabaseController.currentlyInstalledTitle
            ? p.join((await getApplicationSupportDirectory()).absolute.path, module)
            : null
    );
    DatabaseController.availableModules = availableModules;
    print('Available Modules: ' + availableModules.toString());
    print("Module '$module' loaded successfully.");
  } else {
    await initHive('taxonomies');
    await DatabaseController.init();
    DatabaseController.currentlyInstalledTitle = DatabaseController.config['title'] ?? 'tax_default';
  }
}

final RouteObserver<Route> routeObserver = RouteObserver<Route>();

class MyApp extends StatefulWidget {

  @override
  _MyAppState createState() => _MyAppState();

}

GlobalKey<NavigatorState> navigatorKey = GlobalKey();

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeParameters(),
      child: Consumer<ThemeParameters>(
        builder: (context, themeParameters, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            title: DatabaseController.config['title'] ?? "Título",
            builder: (context, child) {
              return FromZeroAppContentWrapper(
                child: MultiProvider(
                  providers: [
                    ChangeNotifierProvider(create: (context) => AdsNotifier(),),
                  ],
                  child: child,
                ),
              );
            },
            supportedLocales: [
//              Locale('en'),
              Locale('es'),
            ],
            localizationsDelegates: [
//              AppLocalizations.delegate,
              FromZeroLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            themeMode: themeParameters.themeMode,
            theme: themeParameters.lightTheme,
            darkTheme: themeParameters.darkTheme,
            initialRoute: '/',
            onGenerateRoute: MyFluroRouter.router.generator,
          );
        },
      ),
    );
  }

}

class LoadingApp extends StatefulWidget {
  @override
  _LoadingAppState createState() => _LoadingAppState();
}

class _LoadingAppState extends State<LoadingApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      await DatabaseController.init(
        useCustomDBPath: true,
        propertiesPath: propertiesPath,
      );
      DatabaseController.executeSynch(propertiesPath!).then((value) => exit(0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeParameters(),
      child: Consumer<ThemeParameters>(
        builder: (context, themeParameters, child) {
          return MaterialApp(
            title: "Sincronizando...",
            builder: (context, child) {
              return Container(
                color: Colors.white,
                alignment: Alignment.center,
//                child: Row(
//                  mainAxisAlignment: MainAxisAlignment.center,
//                  children: [
//                    CircularProgressIndicator(
//                      valueColor: ColorTween(begin: Theme.of(context).primaryColor, end: Theme.of(context).primaryColor).animate(kAlwaysDismissedAnimation),
//                    ),
//                    SizedBox(width: 16,),
//                    Text(
//                      "Procesando...",
//                      style: Theme.of(context).textTheme.headline6,
//                    ),
//                  ],
//                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      valueColor: ColorTween(begin: Theme.of(context).primaryColor, end: Theme.of(context).primaryColor).animate(kAlwaysDismissedAnimation) as Animation<Color>,
                    ),
                    Expanded(
                      child: Text(
                        "Procesando...",
                        style: Theme.of(context).textTheme.headline6,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
            themeMode: themeParameters.themeMode,
            theme: themeParameters.lightTheme,
            darkTheme: themeParameters.darkTheme,
            supportedLocales: [
              Locale('es'),
            ],
            localizationsDelegates: [
              FromZeroLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );

  }
}
