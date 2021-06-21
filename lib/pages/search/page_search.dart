import 'dart:io';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:taxonomies/pages/search/page_qr_scanner.dart';
import 'package:taxonomies/widgets/ad_overlay.dart';
import 'package:taxonomies/widgets/instance_card.dart';
import 'package:dartx/dartx.dart';

class PageSearch extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;//2;
  @override
  String get pageScaffoldId => "home";

  final Category? initialCategory;
  final List<Instance>? initialInstances;
  final String? initialQuery;

  PageSearch(this.initialCategory, this.initialInstances, this.initialQuery,);

  @override
  _PageSearchState createState() => _PageSearchState();

}

class _PageSearchState extends State<PageSearch> {

  late ScrollController mainScrollController;
  late Future<List<Category>> categories;
  late List<Instance> instances;
  Category? filterCategory;
  String? filterQuery;
  FocusNode searchFocusNode = FocusNode();
  GlobalKey gridKey = GlobalKey();

  @override
  void initState() {
    filterQuery = QrPage.lastResult ?? widget.initialQuery;
    QrPage.lastResult = null;
    filterCategory = widget.initialCategory;
    instances = widget.initialInstances ?? [];
    categories = Category.getCategories();
    if (widget.initialInstances==null){
      fetchInstances();
    }
    super.initState();
  }

  Future<void> fetchInstances() async{
    if (filterCategory==null){
      instances = await Instance.getSearchResults(filterQuery);
      setState(() {});
    } else{
      instances = await filterCategory!.getInstances();
      setState(() {
        instances = instances.where((element) => element.name.toLowerCase().contains(filterQuery?.toLowerCase()??"")).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    mainScrollController = ScrollController();
    AppbarAction searchAction = AppbarAction(
      title: "Buscar",
      icon: Hero(
        tag: "search_view_button",
        child: Icon(Icons.search,
          color: Theme.of(context).primaryColorBrightness==Brightness.light
              ? Colors.black : Colors.white,
        ),
      ),
//          breakpoints: {
//            0: ActionState.icon,
//            ScaffoldFromZero.screenSizeLarge: ActionState.button,
//            ScaffoldFromZero.screenSizeXLarge: ActionState.expanded,
//          },
      expandedBuilder: (context, title, icon) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          child: Container(
            width: 384,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              border: Border.all(color: Theme.of(context).primaryColorLight, width: 2),
            ),
            child: Material(
              elevation: 4,
              type: MaterialType.card,
              color: Theme.of(context).primaryColorDark,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: TextFormField(
                        autofocus: true,
                        focusNode: searchFocusNode,
                        enableSuggestions: true,
                        cursorColor: Theme.of(context).accentColor,
                        initialValue: filterQuery,
                        decoration: InputDecoration(
                          hintText: "Buscar...",
                          hintStyle: Theme.of(context).primaryTextTheme.caption!.copyWith(fontSize: 17),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 8),
                        ),
                        onChanged: (value) {
                          filterQuery = value;
                          fetchInstances();
                        },
                        style: Theme.of(context).primaryTextTheme.bodyText1!.copyWith(fontSize: 17),
                      ),
                    ),
                  ),
                  IconButton(
                    splashRadius: 24,
                    icon: Hero(
                      tag: "search_view_button",
                      child: Material(
                        type: MaterialType.transparency,
                        child: Icon(Icons.search,
                          color: Theme.of(context).primaryColorBrightness==Brightness.light
                              ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    tooltip: "Buscar",
                    onPressed: (){
                      searchFocusNode.requestFocus();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return BannerAdOverlay(
      child: ScaffoldFromZero(
        assumeTheScrollBarWillShowOnDesktop: true,
        title: FutureBuilderFromZero(
          future: categories,
          successBuilder: (context, List<Category> data) {
            return PopupMenuButton(
              tooltip: "Seleccionar Categoría",
              initialValue: filterCategory,
              child: Container(
                height: 56,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(filterCategory==null ? "Buscar..." : filterCategory!.name, maxLines: 1,),
//                      if (filterCategory!=null)
//                        Text("Categoría", style: Theme.of(context).textTheme.caption,),
                      ],
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              itemBuilder: (context) => List.generate(data.length+1,
                      (index) => PopupMenuItem(
                        value: index==0 ? "all" : data[index-1],
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(index==0 ? "Buscar..." : data[index-1].name),
//                          if (index>0)
//                            Text("Categoría", style: Theme.of(context).textTheme.caption,),
                          ],
                        ),
                      ),
              ),
              onSelected: (value) {
                setState(() {
                  value=="all" ? filterCategory=null : filterCategory=value as Category;
                });
                fetchInstances();
              },
            );
          },
          errorBuilder: (context, error) => Container(),
          loadingBuilder: (context) => Container(),
        ),
        body: _getPage(context),
        currentPage: widget,
        mainScrollController: mainScrollController,
        appbarType: PlatformExtended.isMobile
            ? ScaffoldFromZero.appbarTypeQuickReturn : ScaffoldFromZero.appbarTypeStatic,
        initialExpandedAction: filterCategory==null ? searchAction : null,
        actions: [
          searchAction,
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
        ],
      ),
    );
  }

  Widget _getPage(BuildContext context){
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = 320;
        double minWidth = 256;
        int crossAxisCount = (constraints.maxWidth/minWidth).floor();
        double padding = (constraints.maxWidth - maxWidth*crossAxisCount).coerceIn(0, double.infinity);
        return CustomScrollView(
          controller: mainScrollController,
          slivers: [
            SliverToBoxAdapter(child: AppbarFiller()),
            SliverToBoxAdapter(child: SizedBox(height: 12,)),
            ResponsiveHorizontalInsetsSliver(
              sliver: SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: padding/2),
                sliver: instances.isEmpty
                    ? SliverToBoxAdapter(
                  child: filterQuery==null || filterQuery!.length < 2
                      ? Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: ErrorSign(
//                key: ValueKey("empty"),
                      title: "Escriba una palabra para buscar...",
                    ),
                  ) : Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: ErrorSign(
//                key: ValueKey("notFound"),
                      title: "No se encontraron resultados.",
                      subtitle: "Intente otro criterio de búsqueda o escriba menos palabras.",
                    ),
                  ),
                ) : SliverGrid(
                  key: gridKey,
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
  }

}