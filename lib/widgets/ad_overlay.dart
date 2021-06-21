import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/notifiers/ads_notifier.dart';
import 'package:taxonomies/pages/page_fullscreen_ad.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;

class BannerAdOverlay extends StatefulWidget {

  final Widget child;

  BannerAdOverlay({required this.child, Key? key}) : super(key: key);

  @override
  _BannerAdOverlayState createState() => _BannerAdOverlayState();
}

class _BannerAdOverlayState extends State<BannerAdOverlay> {

  int currentAdIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool show = MediaQuery.of(context).viewInsets.bottom==0;
    AdModel? adModel = DatabaseController.bannerAds.isEmpty ? null
        : DatabaseController.bannerAds[Provider.of<AdsNotifier>(context).currentBannerAdIndex];
    if (adModel==null) return widget.child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: widget.child),
        if (show)
          Material(child: Divider(height: 1, thickness: 1,
            color: Theme.of(context).textTheme.caption!.color,
          )),
        if (show)
          Material(
  //          color: Theme.of(context).brightness==Brightness.light ? Colors.white : Colors.black,
            child: Container(
              height: 64,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 1000),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child,),
                child: Container(
                  key: ValueKey(Provider.of<AdsNotifier>(context).currentBannerAdIndex),
                  width: double.infinity,
                  child: AdContent(adModel),
                ),
              ),
            ),
          ),
      ],
    );
  }

}


class AdContent extends StatelessWidget {

  final AdModel adModel;

  AdContent(this.adModel);

  @override
  Widget build(BuildContext context) {
    late Widget result;
    bool fullscreen = context.findAncestorWidgetOfExactType<PageFullscreenAd>()!=null;
    if (adModel.type=='Imagen'){
      if (DatabaseController.customAssetPathPrefix==null) {
        result = Image.asset("assets/"+adModel.data!.replaceAll("\\", '/'),
          fit: fullscreen ? BoxFit.contain : BoxFit.fitHeight,
        );
      } else {
        result = Image.file(File(p.join(DatabaseController.customAssetPathPrefix!, "assets/"+adModel.data!.replaceAll("\\", '/'))),
          fit: fullscreen ? BoxFit.contain : BoxFit.fitHeight,
        );
      }
    } else if (adModel.type=='Video'){
      result = Container();
    } else{
      result = SizedBox.shrink();
    }
    if (adModel.name!=null){
      result = Tooltip(
        message: adModel.name!,
        child: result,
      );
    }
    if (adModel.link!=null){
      String link = adModel.link!;
      if (!link.startsWith('http')) {
        link = 'http://$link';
      }
      result = InkWell(
        onTap: () => launch(link),
        child: result,
      );
    }
    return result;
  }

}
