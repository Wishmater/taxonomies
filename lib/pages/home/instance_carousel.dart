import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/models/category.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/router.dart';
import 'package:taxonomies/widgets/instance_card.dart';

class CategoryInstancesCarousel extends StatefulWidget {

  final Category category;

  CategoryInstancesCarousel(this.category, {Key? key}) : super(key: key);

  @override
  _CategoryInstancesCarouselState createState() => _CategoryInstancesCarouselState();

}

class _CategoryInstancesCarouselState extends State<CategoryInstancesCarousel> {

  ScrollController scrollController = ScrollController();
  late Future<List<Instance>> instances;

  @override
  void initState() {
    instances = widget.category.getInstances();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).brightness==Brightness.light ? Color.fromRGBO(245, 245, 245, 1) : Color.fromRGBO(54, 54, 54, 1),
//      color: Theme.of(context).primaryColor,
      clipBehavior: Clip.hardEdge,
      elevation: 3,
      child: Column(
        children: [
          FlatButton(
            onPressed: () async{
              List<Instance> instances =  await this.instances;
              MyFluroRouter.cache = [widget.category, instances];
              Navigator.of(context).pushNamed('/category?id=${widget.category.id}',);
            },
            padding: EdgeInsets.all(0),
            child: Selector<ScreenFromZero, bool>(
                selector: (context, screen) => screen.displayMobileLayout,
                builder: (context, value, child) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: 8,
                      right: 8,
                      top: value ? 8 : 16,
                      left: value ? 16 : 32,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.category.name,
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        value ? Icon(Icons.chevron_right) : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Ver Más",
                              style: Theme.of(context).textTheme.caption,
                            ),
                            Icon(Icons.chevron_right),
                            SizedBox(width: 16,),
                          ],
                        ),
                      ],
                    ),
                  );
                }
            ),
          ),
          SizedBox(
            height: 256+24.0,
            child: FutureBuilderFromZero(
              future: instances,
              successBuilder: (context, List data) => NotificationListener(
                onNotification: (notification) => true,
                child: Scrollbar(
                  child: OpacityGradient(
                    direction: OpacityGradient.horizontal,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.length,
                      padding: EdgeInsets.only(bottom: 12, left: 8, right: 8, top: 4),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: InstanceCard(data[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              loadingBuilder: (context) => Container(),
              errorBuilder: (context, error) => Container(),
            ),
          ),
        ],
      ),
    );
  }

}