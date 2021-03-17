import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/router.dart';

class InstanceEmbeddedListTile extends StatefulWidget {

  final Instance instance;
  final int depth;
  final Category? father;
  final Category? son;

  InstanceEmbeddedListTile(this.instance, {Key? key, this.depth=1000, this.father, this.son}) : super(key: key);

  @override
  _InstanceEmbeddedListTileState createState() => _InstanceEmbeddedListTileState();
}

class _InstanceEmbeddedListTileState extends State<InstanceEmbeddedListTile> {

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
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.subtitle1!,
      child: InkWell(
        onTap: () async{
          setState(() {
            heroActivated = true;
          });
          WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async{
            if (widget.instance.attributes==null) await widget.instance.getAttributes();
            MyFluroRouter.cache = widget.instance;
            Navigator.of(context).pushNamed('/view?id=${widget.instance.id}&depth=${widget.depth}',);
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                flex: 1000000,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FutureBuilderFromZero(
                    future: relationName,
                    successBuilder: (context, String data) {
                      return Text(widget.instance.category.name + ' ' + (widget.instance.extra??''),
                        textAlign: TextAlign.right,
                      );
                      return Text(data+" "+widget.instance.category.name,);
                    },
                    loadingBuilder: (context) => Container(),
                    errorBuilder: (context, error) => Container(),
                  ),
                ),
              ),
              Container(
                height: 24,
                child: VerticalDivider(width: 16,),
              ),
              Expanded(
                flex: 1618034,
                child: Row(
                  children: [
                    SizedBox(
                      height: 48, width: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: FutureBuilderFromZero(
                          future: imagePath,
                          successBuilder: (context, String? data) {
                            if (data==null) return Container();
                            Widget image = Image.asset("assets/"+data.replaceAll("\\", '/'), //TODO 2 better images
                              fit: BoxFit.contain,
                            );
                            if (heroActivated){
                              image = Hero(
                                tag: "image${widget.instance.id}-$data",
                                child: image,
                              );
                            }
                            return image;
                          },
                          loadingBuilder: (context) => Container(),
                          errorBuilder: (context, error) => Container(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8,),
                    Expanded(child: Text(widget.instance.name)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}