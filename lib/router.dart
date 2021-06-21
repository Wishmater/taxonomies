import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/notifiers/ads_notifier.dart';
import 'package:taxonomies/pages/game/page_game.dart';
import 'package:taxonomies/pages/home/page_home.dart';
import 'package:taxonomies/pages/instance/page_instance.dart';
import 'package:taxonomies/pages/page_fullscreen_ad.dart';
import 'package:taxonomies/pages/search/page_map_search.dart';
import 'package:taxonomies/pages/search/page_qr_scanner.dart';
import 'package:taxonomies/pages/search/page_search.dart';
import 'package:taxonomies/pages/settings/page_settings.dart';
import 'package:taxonomies/pages/page_not_found.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:fluro/fluro.dart';
import 'package:path/path.dart' as p;
import 'package:taxonomies/util/assets_file_utilities.dart';
import 'package:intl/intl.dart';

class MyFluroRouter{

  static FluroRouter router = FluroRouter();
  static var cache;


  static void maybeShowFullscreenAd(BuildContext? context){
    if (DatabaseController.fullscreenAds.isEmpty || context==null) return;
    var adsNotifier = Provider.of<AdsNotifier>(context, listen: false);
    adsNotifier.ticksForFullscreenAd++;
    if (adsNotifier.ticksForFullscreenAd >= adsNotifier.maxTicksForFullscreenAd){
      adsNotifier.ticksForFullscreenAd = 0;
      Future.delayed(Duration(milliseconds: 400)).then((value) {
        return Navigator.of(context).pushNamed("/ad");
      });
    }
  }

  static void setupRouter(){

    router.define('/',
      handler: Handler(
        handlerFunc: (context, params){
          ValueNotifier<double?> installProgress = ValueNotifier(null);
          return SplashPage(
            (context) async {
              if (PlatformExtended.isMobile) {
                final sharedPreferences = await SharedPreferences.getInstance();
                List<String> availableModules = sharedPreferences.getStringList('modules') ?? [];
                if (!availableModules.contains(DatabaseController.currentlyInstalledTitle)) {
                  Directory appDocumentsDirectory = await getApplicationSupportDirectory();
                  File baseDirectory = File(p.join(appDocumentsDirectory.absolute.path, DatabaseController.currentlyInstalledTitle));
                  await copyAssetsDirectory('/assets', baseDirectory.absolute.path,
                    progressNotifier: installProgress,
                  );
                  availableModules.add(DatabaseController.currentlyInstalledTitle!);
                  DatabaseController.availableModules = availableModules;
                  sharedPreferences.setString('selectedModule', DatabaseController.customAssetPathPrefix ?? DatabaseController.currentlyInstalledTitle!);
                  sharedPreferences.setStringList('modules', availableModules);
                }
              }
              try{
                int id = int.parse(DatabaseController.config['main_category']);
                if (id>0){
                  Category category = (await Category.getCategories()).firstWhere((element) => element.id==id);
                  MyFluroRouter.cache = category;
                } else {
                  MyFluroRouter.cache = null;
                }
              } catch(_){
                MyFluroRouter.cache = null;
              }
              print('Push /home');
              return '/home';
            },
            child: Container(
              color: Theme.of(context!).primaryColor,
              alignment: Alignment.center,
              child: StatefulBuilder(
                builder: (context, setState) {
                  if (!(cache is double?)) return SizedBox.shrink();
                  double? value = cache;
                  if (value==null) {
                    installProgress.addListener(() {
                      setState((){
                        cache = installProgress.value;
                      });
                    });
                  }
                  if (value==null) {
                    return SizedBox.shrink();
                  }
                  return SizedBox(
                    width: 512,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 8,),
                              Text(
                                "Terminando Instalación...",
                                style: Theme.of(context).textTheme.headline6,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16,),
                              ClipRRect(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                child: LinearProgressIndicator(
                                  value: value,
                                  valueColor: ColorTween(begin: Theme.of(context).accentColor, end: Theme.of(context).accentColor).animate(kAlwaysDismissedAnimation) as Animation<Color>,
                                  // backgroundColor: Theme.of(context).primaryColor,
                                  minHeight: 12,
                                ),
                              ),
                              SizedBox(height: 8,),
                              Text(
                                NumberFormat('##.#%').format(value),
                                style: Theme.of(context).textTheme.caption,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16,),
                              Text(
                                "Por favor, no cierre la aplicación.",
                                style: Theme.of(context).textTheme.caption,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8,),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    router.define('/home',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          maybeShowFullscreenAd(context);
          return PageHome();
        },
      ),
    );

    router.define('/view',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          maybeShowFullscreenAd(context);
          Instance? instance;
          if (cache is Instance) instance = cache;
          try{
            int id = int.parse(params['id']![0]);
            if (instance==null || instance.id!=id){
              // ? load instance (?async)
            }
          } catch (_){
            // show not found page
          }
          int? depth;
          try{depth = int.parse(params['depth']![0]);} catch (_){}
          return PageInstance(instance!, depth??1000);
        },
      ),
    );

    router.define('/search',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          maybeShowFullscreenAd(context);
          return PageSearch(null, null, params['query']?[0]);
        },
      ),
    );

    router.define('/category',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          maybeShowFullscreenAd(context);
          Category? category;
          List<Instance>? instances;
          try{
            if (cache is List<dynamic> && cache[0] is Category && cache[1] is List<Instance>){
              category = cache[0];
              instances = cache[1];
            }
          } catch(_){}
          try{
            int id = int.parse(params['id']![0]);
            if (category==null || category.id!=id){
              // ? load category (?async)
            }
          } catch (_){
            // show not found page
          }
          return PageSearch(category, instances, null);
        },
      ),
    );

    router.define('/settings',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageSettings();
        },
      ),
    );

    router.define('/ad',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageFullscreenAd();
        },
      ),
    );

    router.define('/scan',
      handler: Handler(
        handlerFunc: (context, params){
          return QrPage();
        },
      ),
    );

    router.define('/game',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          maybeShowFullscreenAd(context);
          int id;
          try{
            id = int.parse(params['id']![0]);
          } catch (_){
            id = Random().nextInt(DatabaseController.games.length);
          }
          return PageGame(model: DatabaseController.games[id]);
        },
      ),
    );

    router.define('/map_search',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          maybeShowFullscreenAd(context);
          if (params['current']?[0]=='true'){
            return PageMapSearch(userLocation: true,);
          }
          try {
            double lat = double.parse(params['lat']![0]);
            double lon = double.parse(params['lon']![0]);
            return PageMapSearch(
              initialQuery: Point(lon, lat),
            );
          } catch(_){}
          try {
            String q = params['q']![0];
            int middleIndex = q.indexOf(',');
            double lat = double.parse(q.substring(0, middleIndex));
            double lon = double.parse(q.substring(middleIndex + 1));
            return PageMapSearch(
              initialQuery: Point(lon, lat),
            );
          } catch(_){}
          return PageMapSearch();
        },
      ),
    );

    router.notFoundHandler = Handler(
      handlerFunc: (context, params){
        return PageNotFound();
      },
    );

  }

}