import 'package:flutter/material.dart';
import 'package:dartx/dartx.dart';
import 'package:taxonomies/controllers/database_controller.dart';

class AdsNotifier extends ChangeNotifier{

  AdsNotifier(){
    if (DatabaseController.bannerAds.isNotEmpty)
      changeBannerAd();
  }

  int currentFullscreenAdIndex = 0;
  int ticksForFullscreenAd = 0;
  final int maxTicksForFullscreenAd = 10;
  void increaseCurrentFullscreenAdIndex(){
    currentFullscreenAdIndex++;
    if (currentFullscreenAdIndex>=DatabaseController.fullscreenAds.length){
      currentFullscreenAdIndex = 0;
    }
  }

  int _currentBannerAdIndex = 0;
  int get currentBannerAdIndex => _currentBannerAdIndex;
  set currentBannerAdIndex(int value) {
    _currentBannerAdIndex = value;
    notifyListeners();
  }

  void changeBannerAd() async{
    await Future.delayed(10.seconds);
    int next = currentBannerAdIndex + 1;
    if (next==DatabaseController.bannerAds.length) next = 0;
    currentBannerAdIndex = next;
    changeBannerAd();
  }

}