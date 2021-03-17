import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/notifiers/theme_parameters.dart';
import 'package:taxonomies/router.dart';

class InstanceCard extends StatefulWidget {

  final Instance instance;

  InstanceCard(this.instance, {Key? key}) : super(key: key);

  @override
  _InstanceCardState createState() => _InstanceCardState();

}

class _InstanceCardState extends State<InstanceCard> {

  late Future<String?> imagePath;

  @override
  void initState() {
    imagePath = widget.instance.getFirstImage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      color: Theme.of(context).brightness==Brightness.light ? Colors.white : Theme.of(context).cardColor,
      elevation: 6,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
//              Padding(
//                padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 4,),
//                child: Text(widget.instance.name,
//                  style: Theme.of(context).textTheme.headline6,
//                ),
//              ),
              Container(
                child: Text(widget.instance.name, style: Theme.of(context).textTheme.headline6!.copyWith(
                  color: Theme.of(context).accentColorBrightness==Brightness.light ? Colors.black : Colors.white,
                  height: 1.1,
                ),),
                color: Theme.of(context).accentColor,
                padding: EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
                alignment: Alignment.topLeft,
//                height: 32,
              ),
              Expanded(
                child: Container(
//                  color: Theme.of(context).canvasColor,
//                  color: Theme.of(context).accentColor,
                  child: widget.instance.firstImage==null ? FutureBuilderFromZero(
                    future: imagePath,
                    successBuilder: (context, String? data) {
                      return _getImage(context, data);
                    },
                    loadingBuilder: (context) => Container(),
                    errorBuilder: (context, error) => Container(),
                  ) : _getImage(context, widget.instance.firstImage),
                ),
              ),
            ],
          ),
//          Container(
//            alignment: Alignment.topLeft,
//            padding: EdgeInsets.all(6),
//            child: TitleTextBackground(
//              horizontalPadding: 16,
//              verticalPadding: 6,
//              backgroundColor: (Theme.of(context).tooltipTheme.decoration as BoxDecoration).color,
//              child: Text(widget.instance.name,
//                style: Theme.of(context).textTheme.headline6.copyWith(
//                  color: Theme.of(context).brightness==Brightness.light ? Colors.white : Colors.black,
//                ),
//              ),
//            ),
//          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () async{
                if (widget.instance.attributes==null) await widget.instance.getAttributes();
                MyFluroRouter.cache = widget.instance;
                Navigator.of(context).pushNamed('/view?id=${widget.instance.id}',);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getImage(BuildContext context, String? path){
    if (path==null) return SizedBox.shrink();
    return Hero(
      tag: "image${widget.instance.id}-$path",
      child: Image.asset("assets/"+path.replaceAll("\\", '/'), //TODO 2 better images
        fit: BoxFit.contain,
      ),
    );
  }

}