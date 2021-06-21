import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/notifiers/theme_parameters.dart';
import 'package:taxonomies/router.dart';
import 'package:path/path.dart' as p;

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
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).brightness==Brightness.light ? Colors.white : Theme.of(context).cardColor,
      elevation: 6,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Theme.of(context).accentColor,
                height: 5,
              ),
              Padding(
                padding: EdgeInsets.only(left: 12, right: 12,),
                child: Text(widget.instance.name,
                  style: Theme.of(context).textTheme.headline6!.copyWith(fontSize: 21),
                ),
              ),
              SizedBox(height: 5,),
              Expanded(
                child: Container(
                  child: FutureBuilderFromZero(  //widget.instance.firstImage==null ?
                    future: imagePath,
                    successBuilder: (context, String? data) {
                      return _getImage(context, data);
                    },
                    loadingBuilder: (context) => Container(),
                    errorBuilder: (context, error) => Container(),
                  ), // : _getImage(context, widget.instance.firstImage)
                ),
              ),
            ],
          ),
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
    Widget result;
    if (DatabaseController.customAssetPathPrefix==null) {
      result = Image.asset("assets/"+path.replaceAll("\\", '/'),
        fit: BoxFit.contain,
        alignment: Alignment(0, -0.3),
      );
    } else {
      result = Image.file(File(p.join(DatabaseController.customAssetPathPrefix!, "assets/"+path.replaceAll("\\", '/'))),
        fit: BoxFit.contain,
        alignment: Alignment(0, -0.3),
      );
    }
    // result = Hero(
    //   tag: "image${widget.instance.id}-$path",
    //   child: result,
    // );
    return result;
  }

}