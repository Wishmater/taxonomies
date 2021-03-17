import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/notifiers/ads_notifier.dart';
import 'package:taxonomies/widgets/ad_overlay.dart';

class PageFullscreenAd extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "ad";

  PageFullscreenAd();

  @override
  _PageFullscreenAdState createState() => _PageFullscreenAdState();

}

class _PageFullscreenAdState extends State<PageFullscreenAd> {

  @override
  Widget build(BuildContext context) {
    var adsNotifier = Provider.of<AdsNotifier>(context, listen: false);
    var adModel = DatabaseController.fullscreenAds[adsNotifier.currentFullscreenAdIndex];
    adsNotifier.increaseCurrentFullscreenAdIndex();
    return ScaffoldFromZero(
      currentPage: widget,
      appbarType: ScaffoldFromZero.appbarTypeNone,
      body: Stack(
        children: [
          AdContent(adModel),
          Positioned(
            right: 32, top: 32,
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: CircleBorder(),
              child: SizedBox(
                width: 42, height: 42,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

}