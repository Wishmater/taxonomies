import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/notifiers/ads_notifier.dart';
import 'package:taxonomies/pages/page_fullscreen_ad.dart';
import 'package:url_launcher/url_launcher.dart';

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
    AdModel? adModel = DatabaseController.bannerAds.isEmpty ? null
        : DatabaseController.bannerAds[Provider.of<AdsNotifier>(context).currentBannerAdIndex];
    if (adModel==null) return widget.child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: widget.child),
        Material(child: Divider(height: 1, thickness: 1,
          color: Theme.of(context).textTheme.caption!.color,
        )),
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
    if (adModel.type=='Picture'){
      result = Image.asset("assets/"+adModel.data!.replaceAll("\\", '/'),
        fit: fullscreen ? BoxFit.contain : BoxFit.fitHeight,
      );
    } else if (adModel.type=='Video'){
      result = Container(); //TODO implement video ad
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
      result = InkWell(
        onTap: () => launch(adModel.link),
        child: result,
      );
    }
    return result;
  }

}
