import 'package:taxonomies/notifiers/theme_parameters.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import 'package:taxonomies/widgets/ad_overlay.dart';

class PageSettings extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "settings";

  PageSettings();

  @override
  _PageSettingsState createState() => _PageSettingsState();

}

class _PageSettingsState extends State<PageSettings> {
  ScrollController mainScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return BannerAdOverlay(
      child: ScaffoldFromZero(
        title: Text("Settings"),
        body: _getPage(context),
        currentPage: widget,
      ),
    );
  }

  Widget _getPage(BuildContext context){
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 512,
        child: ScrollbarFromZero(
          controller: mainScrollController,
          child: SingleChildScrollView(
            controller: mainScrollController,
            child: Column(
              children: <Widget>[
                SizedBox(height: 12,),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Consumer<ThemeParameters>(
                          builder: (context, themeParameters, child) => ThemeSwitcher(themeParameters),
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12,),
              ],
            ),
          ),
        ),
      ),
    );
  }

}