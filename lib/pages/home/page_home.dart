import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/pages/home/instance_carousel.dart';
import 'package:taxonomies/widgets/ad_overlay.dart';

class PageHome extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "home";

  PageHome();

  @override
  _PageHomeState createState() => _PageHomeState();

}

class _PageHomeState extends State<PageHome> {

  ScrollController tab1ScrollController = ScrollController();
  ScrollController tab2ScrollController = ScrollController();
  late Future<List<Category>> categories;

  @override
  void initState() {
    categories = Category.getCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BannerAdOverlay(
      child: ScaffoldFromZero(
        title: Text(DatabaseController.config['title'], style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
        )),
        body: _getPage(context),
        currentPage: widget,
        mainScrollController: tab1ScrollController,
        appbarType: foundation.kIsWeb||Platform.isIOS||Platform.isAndroid
            ? ScaffoldFromZero.appbarTypeQuickReturn : ScaffoldFromZero.appbarTypeStatic,
        actions: [
          AppbarAction(
            title: "Buscar",
            icon: Hero(
              tag: "search_view_button",
              child: Icon(Icons.search,
                color: Theme.of(context).primaryColorBrightness==Brightness.light
                    ? Colors.black : Colors.white,
              ),
            ),
            onTap: (context) => Navigator.of(context).pushNamed('/search'),
          ),
          AppbarAction(
            title: "Opciones",
            icon: Icon(Icons.settings),
            onTap: (context) => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _getPage(BuildContext context){
    Widget encyclopedia = FutureBuilderFromZero(
      future: categories.then((value) {
        if (DatabaseController.homeCategories.isEmpty) return value;
        List<Category> result = [];
        for (int i=0; i<DatabaseController.homeCategories.length; i++){
          try{
            result.add(value.firstWhere(
                    (element) => element.name==DatabaseController.homeCategories[i]));
          } catch(e, st){
            print(e); print(st);
          }
        }
        return result;
      }),
      successBuilder: (context, List<Category> data) {
        return ListView.builder(
          controller: tab1ScrollController,
          padding: EdgeInsets.symmetric(vertical: 12),
          itemCount: data.length+1,
          itemBuilder: (context, index) {
            if (index==0) return Column(
              children: [
                AppbarFiller(),
                if (DatabaseController.games.isNotEmpty)
                  SizedBox(height: 44,),
              ],
            );
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: ResponsiveHorizontalInsets(
                child: CategoryInstancesCarousel(data[index-1]),
              ),
            );
          },
        );
      },
      loadingBuilder: (context) => Container(),
      errorBuilder: (context, error) => Container(),
    );
    if (DatabaseController.games.isEmpty) return encyclopedia;
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          Positioned.fill(
            child: TabBarView(
              children: [
                encyclopedia,
                ListView.builder(
                  controller: tab1ScrollController,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  itemCount: DatabaseController.games.length+1,
                  itemBuilder: (context, index) {
                    if (index==0) return Column(
                      children: [
                        AppbarFiller(),
                        if (DatabaseController.games.isNotEmpty)
                          SizedBox(height: 44,),
                      ],
                    );
                    GameModel game = DatabaseController.games[index-1];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: ResponsiveHorizontalInsets(
                        child: Card(
                          child: InkWell(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Text(game.name!,
                                    style: Theme.of(context).textTheme.headline5,
                                  ),
                                  Text(game.description!),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: AppbarFiller(
              child: Card(
                clipBehavior: Clip.antiAlias,
                color: Theme.of(context).primaryColor.withOpacity(0.95),
                elevation: 3,
                margin: EdgeInsets.all(0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: SizedBox(
                  width: 368,
                  height: 48,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: TabBar(
                      indicatorWeight: 4,
                      tabs: [
                        Tab(
                          child: Container(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(MaterialCommunityIcons.book_open_page_variant, size: 28,),
                                SizedBox(width: 8,),
                                AutoSizeText("ENCICLOPEDIA", style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),),
                              ],
                            ),
                          ),
                        ),
                        Tab(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(MaterialCommunityIcons.gamepad_variant, size: 34,),
                                SizedBox(width: 8,),
                                AutoSizeText("JUEGOS", style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),),
                                SizedBox(width: 16,),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
