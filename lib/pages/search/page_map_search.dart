import 'dart:io';
import 'dart:math';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:location/location.dart';
import 'package:poly/poly.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/attribute.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:dartx/dartx.dart';
import 'package:taxonomies/pages/instance/attribute_widget.dart';
import 'package:taxonomies/widgets/instance_card.dart';
import 'package:path/path.dart' as p;

class PageMapSearch extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "home";

  final bool userLocation;
  final Point<double>? initialQuery;

  PageMapSearch({
    this.userLocation = false,
    this.initialQuery,
  });

  @override
  _PageMapSearchState createState() => _PageMapSearchState();

}

class _PageMapSearchState extends State<PageMapSearch> with TickerProviderStateMixin {

  late ScrollController mainScrollController;
  late Future<List<Instance>> instances;
  Point<double>? filterQuery;
  GlobalKey gridKey = GlobalKey();
  late String selectedAttributeName;

  @override
  void initState() {
    filterQuery = widget.initialQuery;
    selectedAttributeName = DatabaseController.searchableMapAttributeNames.first;
    if (widget.userLocation) {
      instances = fetchInstancesFromUserLocation();
    } else {
      instances = fetchInstances();
    }
    super.initState();
  }

  Future<List<Instance>> fetchInstancesFromUserLocation() async {
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return fetchInstances();
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return fetchInstances();
      }
    }
    LocationData _locationData = await location.getLocation();
    setState(() {
      filterQuery = Point(_locationData.longitude!, _locationData.latitude!);
    });
    print (filterQuery);
    return fetchInstances();
  }

  Future<List<Instance>> fetchInstances() async {
    if (filterQuery==null) return [];
    final List<Instance> result = [];
    await Future.delayed(Duration(milliseconds: 300));
    final allInstances = await Instance.getAll();
    for (var i = 0; i < allInstances.length; ++i) {
      if (i%20==0) await Future.delayed(Duration(milliseconds: 50));
      final List<Attribute> attributes = await allInstances[i].getAttributes();
      final List<Attribute> maps = attributes.where((e) => e.attributeName==selectedAttributeName).toList();
      bool add = false;
      for (var j = 0; j < maps.length && !add; ++j) {
        final polygonPoints = AttributeMap.parsePolygons(maps[j]);
        final List<Polygon> polygons = polygonPoints.map((e) => Polygon(e)).toList();
        for (var k = 0; k < polygons.length && !add; ++k) {
          add = polygons[k].isPointInside(filterQuery);
        }
      }
      if (add) {
        result.add(allInstances[i]);
      }
    }
    return result;
  }

  GlobalKey mapKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    mainScrollController = ScrollController();
    final map = buildMap(context);
    return ScaffoldFromZero(
      title: Text('Buscar ' + selectedAttributeName),
      currentPage: widget,
      mainScrollController: mainScrollController,
      appbarType: PlatformExtended.isMobile
          ? ScaffoldFromZero.appbarTypeQuickReturn : ScaffoldFromZero.appbarTypeStatic,
      actions: [
        if (PlatformExtended.isMobile)
          AppbarAction(
            title: "Compartir esta Ubicación",
            icon: Icon(Icons.share),
            onTap: (context) {
              String? link = getLink();
              if (link==null) {
                SnackBarFromZero(
                  context: context,
                  type: SnackBarFromZero.error,
                  title: Text('Seleccione un punto en el mapa.'),
                ).show(context);
              } else {
                Share.share(link);
              }
            },
            breakpoints: {
              0: ActionState.overflow,
              ScaffoldFromZero.screenSizeLarge: ActionState.icon,
            },
          ),
        AppbarAction(
          title: "Copiar Enlace a esta Ubicación",
          icon: Icon(Icons.copy),
          onTap: (context) {
            String? link = getLink();
            if (link==null) {
              SnackBarFromZero(
                context: context,
                type: SnackBarFromZero.error,
                title: Text('Seleccione un punto en el mapa.'),
              ).show(context);
            } else {
              FlutterClipboard.copy(link).then(( value ) {
                SnackBarFromZero(
                  context: context,
                  type: SnackBarFromZero.info,
                  title: Text('Enlace copiado con éxito.'),
                ).show(context);
              });
            }
          },
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
      body: FutureBuilderFromZero<List<Instance>>(
        key: mapKey,
        future: instances,
        successBuilder: (context, data) => _buildPage(context, data, map,),
        loadingBuilder: (context) => _buildPage(context, null, map,),
        duration: Duration(milliseconds: 200,),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildPage (BuildContext context, List<Instance>? instances, Widget map,) {
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
            SliverToBoxAdapter(child: SizedBox(height: 18,)),
            SliverToBoxAdapter(child: Center(child: map),),
            SliverToBoxAdapter(child: SizedBox(height: 18,)),
            instances==null
                ? SliverFillRemaining(
                  child: LoadingSign(),
                ) : ResponsiveHorizontalInsetsSliver(
              sliver: SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: padding/2),
                sliver: instances.isEmpty ? SliverToBoxAdapter(
                  child: filterQuery==null ? Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: ErrorSign(
                      title: "Seleccione un punto en el mapa para buscar...",
                    ),
                  ) : Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: ErrorSign(
                      title: "No se encontraron resultados.",
                      subtitle: "Intente buscar en otro punto...",
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

  Widget buildMap (BuildContext context, {bool fullscreen = false}) {
    String mapImage = DatabaseController.config['map_${selectedAttributeName}_image']!;
    double mapTopLeftY = double.parse(DatabaseController.config['map_${selectedAttributeName}_top_left_lat'] ?? 0);
    double mapTopLeftX = double.parse(DatabaseController.config['map_${selectedAttributeName}_top_left_long'] ?? 0);
    double mapHeight = double.parse(DatabaseController.config['map_${selectedAttributeName}_height_lat'] ?? 0);
    double mapWidth = double.parse(DatabaseController.config['map_${selectedAttributeName}_width_long'] ?? 0);
    Widget image;
    if (mapImage.endsWith('.svg')) {
      image = LayoutBuilder(
        builder: (context, constraints) {
          return DatabaseController.customAssetPathPrefix==null
              ? SvgPicture.asset('assets/$mapImage',
                width: fullscreen ? constraints.maxWidth : min(constraints.maxWidth, 768),
              )
              : SvgPicture.file(File(p.join(DatabaseController.customAssetPathPrefix!, 'assets', mapImage)),
                width: fullscreen ? constraints.maxWidth : min(constraints.maxWidth, 768),
              ) ;
        },
      );
    } else {
      image = DatabaseController.customAssetPathPrefix==null
          ? Image.asset('assets/$mapImage')
          : Image.file(File(p.join(DatabaseController.customAssetPathPrefix!, 'assets', mapImage)));
    }
    final map = StatefulBuilder(
      builder: (context, mapSetState) {
        return Stack(
          children: [
            image,
            if (filterQuery!=null)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double multiplier = constraints.minWidth>512 ? 1 : 0.66;
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Transform.translate(
                        offset: Offset(
                          constraints.minWidth * ((filterQuery!.x - (mapTopLeftX)).abs() / (mapWidth)) - 8*multiplier,
                          constraints.minHeight * ((filterQuery!.y - (mapTopLeftY)).abs() / (mapHeight)) - 8*multiplier,
                        ),
                        child: PhysicalModel(
                          color: Theme.of(context).accentColor.withOpacity(0.98),
                          shape: BoxShape.circle,
                          elevation: 6*multiplier,
                          child: Container(width: 16*multiplier, height: 16*multiplier,),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final updateSelected = (details) async {
                    Offset localPosition = Offset(
                      details.localPosition.dx.clamp(0.0, constraints.minWidth),
                      details.localPosition.dy.clamp(0.0, constraints.minHeight),
                    );
                    mapSetState(() {
                      filterQuery = Point(
                        (localPosition.dx / constraints.minWidth) * mapWidth + mapTopLeftX,
                        -((localPosition.dy / constraints.minHeight) * mapHeight) + mapTopLeftY,
                      );
                    });
                  };
                  final submit = (details) async {
                    instances = fetchInstances();
                    setState(() {});
                  };
                  return GestureDetector(
                    onTapDown: updateSelected,
                    onPanUpdate: fullscreen ? null : updateSelected,
                    onPanEnd: fullscreen ? null : submit,
                    onTapUp: (details) async {
                      updateSelected(details);
                      submit(details);
                    },
                  );
                },
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxSize = max(constraints.maxHeight, constraints.maxWidth);
                  if (maxSize<128) {
                    return SizedBox.shrink();
                  }
                  Widget result;
                  if (fullscreen) {
                    result = SafeArea(
                      child: Column(
                        children: [
                          IconButtonBackground(
                            child: IconButton(
                              icon: Icon(Icons.close),
                              tooltip: FromZeroLocalizations.of(context).translate('close'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    result = Column(
                      children: [
                        IconButtonBackground(
                          child: IconButton(
                          icon: Icon(Icons.fullscreen),
                            tooltip: FromZeroLocalizations.of(context).translate('fullscreen'),
                            onPressed: () {
                              pushFullscreenImage(context);
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  return Material(
                    type: MaterialType.transparency,
                    child: Container(
                      alignment: Alignment.topRight,
                      padding: EdgeInsets.all(maxSize<256 ? 0 : 8),
                      child: result,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
    return map;
  }

  void pushFullscreenImage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        fullscreenDialog: true,
        // opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ZoomedFadeInTransition(
            animation: animation,
            child: Material(
              child: InteractiveViewer(
                child: Center(
                  child: SafeArea(
                    child: buildMap(context,
                      fullscreen: true,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? getLink() {
    if (filterQuery==null) return null;
    return 'https://osmand.net/go?lat=${filterQuery!.y}&lon=${filterQuery!.x}';
  }

}