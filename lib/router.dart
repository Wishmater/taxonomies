import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/notifiers/ads_notifier.dart';
import 'package:taxonomies/pages/home/page_home.dart';
import 'package:taxonomies/pages/instance/page_instance.dart';
import 'package:taxonomies/pages/page_fullscreen_ad.dart';
import 'package:taxonomies/pages/search/page_search.dart';
import 'package:taxonomies/pages/settings/page_settings.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:fluro/fluro.dart';

class MyFluroRouter{

  static FluroRouter router = FluroRouter();
  static var cache;


  static void maybeShowFullscreenAd(BuildContext context){
    if (DatabaseController.fullscreenAds.isEmpty) return;
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
          return SplashPage(() async {
            try{
              int id = int.parse(DatabaseController.config['main_category']);
              if (id>0){
                Category category = (await Category.getCategories()).firstWhere((element) => element.id==id);
                List<Instance> instances =  await category.getInstances();
                MyFluroRouter.cache = [category, instances];
                return '/category?id=$id';
              }
            } catch(_){}
            return '/home';
          });
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
          Instance? instance = null;
          if (cache is Instance) instance = cache;
          try{
            int id = int.parse(params['id']![0]);
            if (instance==null || instance.id!=id){
              //TODO ? load instance (?async)
            }
          } catch (_){
            //TODO 3 show not found page
          }
          int? depth = null;
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
          return PageSearch(null, null);
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
              //TODO ? load category (?async)
            }
          } catch (_){
            //TODO 3 show not found page
          }
          return PageSearch(category, instances);
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

  }

}