import 'dart:io';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/router.dart';
import 'package:path/path.dart' as p;


class InstanceListTileCard extends StatelessWidget {

  final Instance instance;
  final int depth;
  final Category? father;
  final Category? son;

  InstanceListTileCard(this.instance, {Key? key, this.depth=1000, this.father, this.son}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).brightness==Brightness.light ? Colors.white : Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 6,
                color: Theme.of(context).accentColor,
              ),
            ),
          ),
          InstanceListTile(instance, depth: depth, father: father, son: son,),
        ],
      ),
      elevation: 6,
    );
//    return Container(
//      decoration: BoxDecoration(
//        borderRadius: BorderRadius.only(topRight: Radius.circular(4), topLeft: Radius.circular(4)),
//        color: Theme.of(context).brightness==Brightness.light
//            ? Colors.grey : Theme.of(context).canvasColor,
//      ),
//      clipBehavior: Clip.antiAlias,
//      child: InstanceListTile(instance),
//    );
  }

}


class InstanceListTile extends StatefulWidget {

  final Instance instance;
  final int depth;
  final Category? father;
  final Category? son;

  InstanceListTile(this.instance, {Key? key, this.depth=1000, this.father, this.son}) : super(key: key);

  @override
  _InstanceListTileState createState() => _InstanceListTileState();

}

class _InstanceListTileState extends State<InstanceListTile> {

  late Future<String?> imagePath;
  late Future<String> relationName;
  bool heroActivated = false;

  @override
  void initState() {
    imagePath = widget.instance.getFirstImage();
    if (widget.father==null && widget.son==null){
      relationName = Future.value("");
    } else {
      bool isSon = widget.son==null;
      relationName = Category.getRelationName(
        isSon ? widget.father!.id.toString() : widget.instance.category.id.toString(),
        isSon ? widget.instance.category.id.toString() : widget.son!.id.toString(),
        isSon,
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async{
        setState(() {
          heroActivated = true;
        });
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async{
          if (widget.instance.attributes==null) await widget.instance.getAttributes();
          MyFluroRouter.cache = widget.instance;
          Navigator.of(context).pushNamed('/view?id=${widget.instance.id}&depth=${widget.depth}',);
        });
        // Future.delayed(Duration(milliseconds: 500)).then((value) {
        //   setState(() {
        //     heroActivated = false;
        //   });
        // });
      },
      title: Text(widget.instance.name),
//      subtitle: Text(widget.instance.category.name),
      subtitle: Align(
        alignment: Alignment.centerLeft,
        child: FutureBuilderFromZero(
          future: relationName,
          successBuilder: (context, String data) {
            return Text(widget.instance.category.name + ' ' + (widget.instance.extra??''),);
            return Text(data+" "+widget.instance.category.name,);
          },
          loadingBuilder: (context) => Container(),
          errorBuilder: (context, error) => Container(),
        ),
      ),
      leading: AspectRatio(
        aspectRatio: 1,
        child: FutureBuilderFromZero(
          future: imagePath,
          successBuilder: (context, String? data) {
            if (data==null) return Container();
            Widget image;
            if (DatabaseController.customAssetPathPrefix==null) {
              image = Image.asset("assets/"+data.replaceAll("\\", '/'),
                fit: BoxFit.contain,
              );
            } else {
              image = Image.file(File(p.join(DatabaseController.customAssetPathPrefix!, "assets/"+data.replaceAll("\\", '/'))),
                fit: BoxFit.contain,
              );
            }
            if (heroActivated){
              // image = Hero(
              //   tag: "image${widget.instance.id}-$data",
              //   child: image,
              // );
            }
            return image;
          },
          loadingBuilder: (context) => Container(),
          errorBuilder: (context, error) => Container(),
        ),
      ),
    );
  }

}
