import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:taxonomies/models/attribute.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/pages/instance/attribute_widget.dart';
import 'package:taxonomies/router.dart';
import 'package:taxonomies/widgets/ad_overlay.dart';
import 'package:taxonomies/widgets/instance_list_tile.dart';
import 'package:taxonomies/widgets/instance_embedded.dart';

class PageInstance extends PageFromZero {

  @override
  int get pageScaffoldDepth => depth;
  @override
  String get pageScaffoldId => "home";

  final Instance instance;
  final int depth;

  PageInstance(this.instance, this.depth);

  @override
  _PageViewState createState() => _PageViewState();

}

class _PageViewState extends State<PageInstance> {

  late ScrollController mainScrollController;
  late Future<List<Instance>> parents;
  late Future<List<Instance>> sons;

  @override
  void initState() {
    if (widget.instance.attributes==null){
      widget.instance.getAttributes().then((value) {
        setState(() {});
      });
    }
    parents = widget.instance.getParents();
    sons = widget.instance.getSons();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mainScrollController = ScrollController();
    return BannerAdOverlay(
      child: ScaffoldFromZero(
        assumeTheScrollBarWillShowOnDesktop: true,
        title: widget.instance.name.isEmpty ?
            Text(widget.instance.category.name)
            : Stack(
          children: [
            Positioned(
              top: 6,
              left: 0, right: 0,
              child: Text("${widget.instance.name}", maxLines: 1,),
            ),
            Positioned(
              bottom: 6,
              left: 0, right: 0,
              child: Opacity(
                opacity: 0.75,
                child: Text(widget.instance.category.name,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.subtitle1!.fontSize,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
        body: _getPage(context),
        currentPage: widget,
        mainScrollController: mainScrollController,
        appbarType: PlatformExtended.isMobile
            ? ScaffoldFromZero.appbarTypeQuickReturn : ScaffoldFromZero.appbarTypeStatic,
        actions: [
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
    return SingleChildScrollView(
      controller: mainScrollController,
      child: AppbarFiller(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ResponsiveHorizontalInsets(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
//                 FutureBuilderFromZero(
//                   future: parents,
//                   successBuilder: (context, List<Instance> data) {
//                     return data.length==0 ? SizedBox.shrink() : Container(
//                       width: double.infinity,
// //                    color: Color.fromRGBO(245, 245, 245, 1),
//                       padding: EdgeInsets.only(left: 12, right: 12, bottom: 6),
//                       alignment: Alignment.center,
//                       child: SizedBox(
//                         width: 512,
//                         child: Column(
//                           children: List.generate(data.length, (index) {
//                             return InstanceListTileCard(data[index],
//                               depth: widget.depth-1,
//                               son: widget.instance.category,
//                             );
//                           }),
//                         ),
//                       ),
//                     );
//                   },
//                   loadingBuilder: (context) => Container(),
//                   errorBuilder: (context, error) => Container(),
//                   applyDefaultTransition: false,
//                 ),

                Card(
                  elevation: 6,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Column(
                      children: [
                        SizedBox(height: 2,),
                        if(widget.instance.name.isNotEmpty)
                          Center(
                            child: Text(widget.instance.name, textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headline5!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if(widget.instance.name.isNotEmpty)
                          SizedBox(height: 8,),
                        getAttributeColumn(widget.instance.firstAttributeColumn),
                        FutureBuilderFromZero(
                          future: parents,
                          successBuilder: (context, List<Instance> data) {
                            return data.length==0 ? SizedBox.shrink() : Container(
                              width: double.infinity,
//                    color: Color.fromRGBO(245, 245, 245, 1),
                              padding: EdgeInsets.only(left: 12, right: 12, bottom: 6),
                              alignment: Alignment.center,
                              child: Column(
                                children: List.generate(data.length, (index) {
                                  return InstanceEmbeddedListTile(data[index],
                                    depth: widget.depth-1,
                                    son: widget.instance.category,
                                  );
                                }),
                              ),
                            );
                          },
                          loadingBuilder: (context) => Container(),
                          errorBuilder: (context, error) => Container(),
                          applyDefaultTransition: false,
                        ),
                        getAttributeColumn(widget.instance.secondAttributeColumn),
                      ],
                    ),
                  ),
                ),

                FutureBuilderFromZero(
                  future: sons,
                  successBuilder: (context, List<Instance> data) {
                    return data.length==0 ? SizedBox.shrink() : Container(
                      width: double.infinity,
//                    color: Color.fromRGBO(245, 245, 245, 1),
                      padding: EdgeInsets.only(left: 12, right: 12, top: 6),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 512,
                        child: Column(
                          children: List.generate(data.length, (index) {
                            return InstanceListTileCard(data[index],
                              depth: widget.depth+1,
                              father: widget.instance.category,
                            );
                          }),
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context) => Container(),
                  errorBuilder: (context, error) => Container(),
                  applyDefaultTransition: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getAttributeColumn(List<Attribute>? attributes){
    return attributes==null ? SizedBox.shrink()
        : Column(
      children: List.generate(attributes.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AttributeWidget.factory(
            instance: widget.instance,
            attribute: attributes[index],
          ),
        );
      }),
    );
  }

}