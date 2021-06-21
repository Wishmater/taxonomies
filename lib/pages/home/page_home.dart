import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/controllers/game_model.dart';
import 'package:taxonomies/main.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/pages/home/instance_carousel.dart';
import 'package:taxonomies/router.dart';
import 'package:taxonomies/widgets/ad_overlay.dart';
import 'package:taxonomies/widgets/instance_card.dart';
import 'package:uni_links/uni_links.dart';
import 'package:dartx/dartx.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class PageHome extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "home";

  PageHome();

  @override
  _PageHomeState createState() => _PageHomeState();

}

class _PageHomeState extends State<PageHome> with TickerProviderStateMixin {

  ValueNotifier<int> currentTab = ValueNotifier(0);
  List<ScrollController> scrollControllers = [
    ScrollController(),
    ScrollController(),
  ];
  late TabController tabController;
  late Future<List<Category>> categories;
  int mainCategoryId = 0;
  Category? mainCategory;
  late Future<List<Instance>> mainCategoryInstances;

  @override
  void initState() {
    super.initState();
    mainCategory = MyFluroRouter.cache;
    if (mainCategory != null) {
      mainCategoryInstances = mainCategory!.getInstances();
    } else {
      categories = Category.getCategories().then((value) {
        if (DatabaseController.homeCategories.isEmpty) return value;
        List<Category> result = [];
        for (int i=0; i<DatabaseController.homeCategories.length; i++){
          try{
            result.add(value.firstWhere(
                    (element) => element.name==DatabaseController.homeCategories[i]));
          } catch(e){}
        }
        return result;
      });
    }
    tabController = TabController(
      length: 2,
      vsync: this,
    );
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        currentTab.value = tabController.index;
      }
    });
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      handleInitialDeepLink();
      linkStream.listen((String? link) {
        handleDeepLink(link);
      }, onError: (err) { });
    });
  }

  Future<void> handleInitialDeepLink() async {
    String? initialDeepLink;
    try {
      initialDeepLink = await getInitialLink();
    } catch(_) { }
    handleDeepLink(initialDeepLink);
  }
  void handleDeepLink(String? initialDeepLink) async {
    Animation? introAnimation = ModalRoute.of(context)?.animation;
    while (introAnimation==null || !introAnimation.isCompleted) {
      introAnimation = ModalRoute.of(context)?.animation;
      print(introAnimation?.isCompleted);
      print(introAnimation?.value);
      await Future.delayed(Duration(milliseconds: 100));
    }
    print('Handling Deep Link - $initialDeepLink');
    // int cutLength = 'https://${(DatabaseController.config['deepLinkDomain']??'tax.cujae.edu.cu')}'.length;
    // if (initialDeepLink.length > cutLength) {
    //   String innerLink = initialDeepLink.substring(cutLength);
    // }
    if (initialDeepLink!=null) {
      int startIndex = initialDeepLink.indexOf('?');
      String innerLink = '/map_search' + (startIndex!=-1 ? initialDeepLink.substring(startIndex) : '');
      print('    Inner Link - $innerLink');
      while (navigatorKey.currentState==null) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      navigatorKey.currentState!.pushNamed(innerLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final body = _getPage(context);
    final actions = [
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
      if (!foundation.kIsWeb && Platform.isAndroid)
        AppbarAction(
          title: "Escanear QR",
          icon: Icon(Icons.settings_overscan),
          onTap: (context) => Navigator.of(context).pushNamed('/scan'),
        ),
      if (DatabaseController.searchableMapAttributeNames.isNotEmpty)
        AppbarAction(
          title: "Buscar en un Mapa",
          icon: Icon(Icons.map),
          onTap: (context) => Navigator.of(context).pushNamed('/map_search'),
          breakpoints: {
            0: ActionState.overflow,
            ScaffoldFromZero.screenSizeLarge: ActionState.icon,
          },
        ),
      if (!foundation.kIsWeb && Platform.isAndroid)
        AppbarAction(
          title: "Buscar en mi Área",
          icon: Icon(Icons.location_on),
          onTap: (context) => Navigator.of(context).pushNamed('/map_search?current=true'),
          breakpoints: {
            0: ActionState.overflow,
            ScaffoldFromZero.screenSizeLarge: ActionState.icon,
          },
        ),
      AppbarAction(
        title: "Opciones",
        icon: Icon(Icons.settings),
        onTap: (context) => Navigator.of(context).pushNamed('/settings'),
        breakpoints: {
          0: ActionState.overflow,
          ScaffoldFromZero.screenSizeLarge: ActionState.icon,
        },
      ),
    ];
    return BannerAdOverlay(
      child: ValueListenableBuilder<int>(
        valueListenable: currentTab,
        // child: body,
        builder: (context, int value, child) {
          print(value);
          scrollControllers[value] = ScrollController();
          return ScaffoldFromZero(
            title: Text(DatabaseController.config['title'], style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            )),
            body: _getPage(context),
            currentPage: widget,
            mainScrollController: scrollControllers[value],
            appbarType: PlatformExtended.isMobile
                ? ScaffoldFromZero.appbarTypeQuickReturn : ScaffoldFromZero.appbarTypeStatic,
            actions: actions,
          );
        },
      ),
    );
  }

  Key encyclopediaKey = GlobalKey();
  Key tabViewKey = GlobalKey();
  Widget _getPage(BuildContext context){
    Widget encyclopedia = mainCategory==null ? Enciclopedia(
      key: encyclopediaKey,
      categories: categories,
      scrollController: scrollControllers[0],
    ) : FutureBuilderFromZero<List<Instance>>(
      key: encyclopediaKey,
      future: mainCategoryInstances,
      successBuilder: (context, instances) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = 320;
            double minWidth = 256;
            int crossAxisCount = (constraints.maxWidth/minWidth).floor();
            double padding = (constraints.maxWidth - maxWidth*crossAxisCount).coerceIn(0, double.infinity);
            return CustomScrollView(
              controller: scrollControllers[0],
              slivers: [
                SliverToBoxAdapter(child: AppbarFiller()),
                SliverToBoxAdapter(child: SizedBox(height: 12 + (DatabaseController.games.isNotEmpty?44:0),)),
                ResponsiveHorizontalInsetsSliver(
                  sliver: SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: padding/2),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          return AnimatedEntryWidget(
                            key: ValueKey(instances[index].id),
                            duration: 300.milliseconds,
                            child: InstanceCard(instances[index]),
                            curve: Curves.easeOut,
                            transitionBuilder: (child, animation) {
//                          return ZoomedFadeInTransition(
//                            child: child, animation: animation,
//                          );
                              return FadeTransition(
                                child: child, opacity: animation,
                              );
                            },
                          );
                        },
                        childCount: instances.length,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 12,)),
              ],
            );
          },
        );
      },
    );
    if (DatabaseController.games.isEmpty) return encyclopedia;
    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              return notification.metrics.axis!=Axis.vertical;
            },
            child: ExtendedTabBarView(
              key: tabViewKey,
              controller: tabController,
              cacheExtent: 2,
              children: [
                encyclopedia,
                Games(
                  scrollController: scrollControllers[1],
                ),
              ],
            ),
          ),
        ),
        Consumer<AppbarChangeNotifier>(
          builder: (context, appbarChangeNotifier, child) {
            final scaffold = context.findAncestorWidgetOfExactType<ScaffoldFromZero>()!;
            final double currentHeight = scaffold.bodyFloatsBelowAppbar ? appbarChangeNotifier.currentAppbarHeight : 0.0;
            final double topLatchSize = (MediaQuery.of(context).padding.top - currentHeight).clamp(0, double.infinity).toDouble();
            return Align(
              alignment: Alignment.topCenter,
              child: AnimatedPadding(
                duration: scaffold.drawerAnimationDuration,
                curve: scaffold.drawerAnimationCurve,
                padding: EdgeInsets.only(top: currentHeight,),
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
                  child: AnimatedContainer(
                    duration: scaffold.drawerAnimationDuration,
                    curve: scaffold.drawerAnimationCurve,
                    width: 368,
                    height: 48 + topLatchSize,
                    padding: EdgeInsets.only(top: topLatchSize,),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TabBar(
                        controller: tabController,
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
                                  Expanded(
                                    child: AutoSizeText("ENCICLOPEDIA", style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),),
                                  ),
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
            );
          },
        ),
      ],
    );
  }

}



class Enciclopedia extends StatefulWidget {

  final Future<List<Category>> categories;
  final ScrollController scrollController;

  Enciclopedia({
    Key? key,
    required this.categories,
    required this.scrollController,
  }) : super(key: key,);

  @override
  _EnciclopediaState createState() => _EnciclopediaState();

}

class _EnciclopediaState extends State<Enciclopedia> {

  @override
  Widget build(BuildContext context) {
    return FutureBuilderFromZero(
      future: widget.categories,
      successBuilder: (context, List<Category> data) {
        return ListView.builder(
          controller: widget.scrollController,
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
  }

}



class Games extends StatefulWidget {

  final ScrollController scrollController;

  Games({
    required this.scrollController,
  });

  @override
  _GamesState createState() => _GamesState();

}

class _GamesState extends State<Games> {

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: List.generate(DatabaseController.games.length+1, (index) {
          if (index==0) {
            return Column(
              children: [
                AppbarFiller(),
                if (DatabaseController.games.isNotEmpty)
                  SizedBox(height: 44,),
              ],
            );
          }
          index--;
          GameModel game = DatabaseController.games[index];
          final timesPlayed = game.timesPlayed;
          final lastPlayed = game.lastPlayed;
          final percent = game.winPercentLastHundred;
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: ResponsiveHorizontalInsets(
                child: SizedBox(
                  width: 512+128,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 6,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed('/game?id=$index',);
                      },
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0, bottom: 0, width: 5,
                            child: Container(color: Theme.of(context).accentColor,),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(13, 8, 8, 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 64, height: 64,
                                  alignment: Alignment.center,
                                  child: game.icon==null ? Container()
                                      : DatabaseController.customAssetPathPrefix==null 
                                          ? Image.asset('assets/'+game.icon!) 
                                          : Image.file(File(p.join(DatabaseController.customAssetPathPrefix!, 'assets', game.icon!))),
                                ),
                                SizedBox(width: 12,),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(game.name,
                                        style: Theme.of(context).textTheme.headline5,
                                      ),
                                      SizedBox(height: 4,),
                                      Text(game.description),
                                      SizedBox(height: 4,),
                                      // RichText(
                                      //   text: TextSpan(
                                      //     children: [
                                      //       TextSpan(
                                      //         text: 'Total de veces jugado:   ',
                                      //         style: Theme.of(context).textTheme.caption,
                                      //       ),
                                      //       WidgetSpan(
                                      //         child: Text(timesPlayed.toString(),
                                      //           style: Theme.of(context).textTheme.bodyText1!.copyWith(fontWeight: FontWeight.w700, height: 0.65),
                                      //         ),
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                      // SizedBox(height: 2,),
                                      // if (lastPlayed!=null)
                                      //   RichText(
                                      //     text: TextSpan(
                                      //       children: [
                                      //         TextSpan(
                                      //           text: 'Jugado por última vez:  ',
                                      //           style: Theme.of(context).textTheme.caption,
                                      //         ),
                                      //         WidgetSpan(
                                      //           child: Text(DateFormat('dd/MM/yyyy').format(lastPlayed),
                                      //             style: Theme.of(context).textTheme.bodyText1!.copyWith(fontWeight: FontWeight.w700, height: 0.65),
                                      //           ),
                                      //         ),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // if (lastPlayed!=null)
                                      //   SizedBox(height: 2,),
                                      if (timesPlayed>0)
                                        FutureBuilderFromZero<Map<String, int>?>(
                                          future: game.cleared,
                                          applyDefaultTransition: false,
                                          loadingBuilder: (context) => SizedBox.shrink(),
                                          errorBuilder: (context, error) => SizedBox.shrink(),
                                          successBuilder: (context, data) {
                                            if (data==null) return SizedBox.shrink();
                                            return Padding(
                                              padding: EdgeInsets.only(bottom: 2),
                                              child: RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Ganados una vez:          ',
                                                      style: Theme.of(context).textTheme.caption,
                                                    ),
                                                    WidgetSpan(
                                                      child: Text('${data['win']}/${data['total']}',
                                                        style: Theme.of(context).textTheme.bodyText1!.copyWith(fontWeight: FontWeight.w700, height: 0.65,
                                                          color: data['win']==data['total'] ? Colors.green.shade600 : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      if (percent!=null)
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Promedio de victoria:    ',
                                                style: Theme.of(context).textTheme.caption,
                                              ),
                                              WidgetSpan(
                                                child: Text(NumberFormat('##.#%').format(percent['perc']),
                                                  style: Theme.of(context).textTheme.bodyText1!.copyWith(fontWeight: FontWeight.w700, height: 0.65,
                                                    color: percent['win']==percent['total'] ? Colors.green.shade600 : null,
                                                  ),
                                                ),
                                              ),
                                              TextSpan(
                                                text: ' (${percent['win']}/${percent['total']}${timesPlayed>100 ? ' en los úlitmos 100 juegos)' : ')'}',
                                                style: Theme.of(context).textTheme.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (percent!=null)
                                        SizedBox(height: 2,),
                                      SizedBox(height: 2,),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

}
