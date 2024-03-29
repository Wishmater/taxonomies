import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:dartx/dartx.dart';
import 'package:taxonomies/controllers/database_controller.dart';

class ThemeParameters extends AppParametersFromZero {

  late Color primary;
  late Color accent;

  ThemeParameters() {
    init();
  }

  void init() {
    primary = DatabaseController.config['color_r']==null
        ? Colors.blue
        : Color.fromRGBO(
      (255*double.parse(DatabaseController.config['color_r'])).round(),
      (255*double.parse(DatabaseController.config['color_g'])).round(),
      (255*double.parse(DatabaseController.config['color_b'])).round(),
      1,
    );
    accent = DatabaseController.config['colora_r']==null
        ? primary
        : Color.fromRGBO(
      (255*double.parse(DatabaseController.config['colora_r'])).round(),
      (255*double.parse(DatabaseController.config['colora_g'])).round(),
      (255*double.parse(DatabaseController.config['colora_b'])).round(),
      1,
    );
  }

  @override
  ThemeData get defaultLightTheme => ThemeData(
    canvasColor: Colors.grey.shade300,
    primaryColor: primary,
    primaryColorLight: getLighterColor(primary),
    primaryColorDark: getDarkerColor(primary),
    accentColor: accent,
    visualDensity: VisualDensity.compact,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey.shade700.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(999999)),
      ),
      padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
      textStyle: TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      isAlwaysShown: PlatformExtended.isDesktop,
      showTrackOnHover: true,
      crossAxisMargin: 0,
      mainAxisMargin: 0,
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.dragged)) {
          return Colors.black54;
        }
        if (states.contains(MaterialState.hovered)) {
          return Colors.black45;
        }
        return Colors.black38;
      }),
    ),
    cardColor: Color.fromRGBO(250, 250, 250, 1),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      color: Color.fromRGBO(250, 250, 250, 1),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        primary: accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(999999))),
      )
    ),
    appBarTheme: AppBarTheme(
      brightness: ThemeData.estimateBrightnessForColor(getDarkerColor(primary))==Brightness.dark
          ? Brightness.dark : Brightness.light,
    ),
  );

  @override
  ThemeData get defaultDarkTheme => ThemeData(
    brightness: Brightness.dark,
    accentColor: primary,
    toggleableActiveColor: primary,
    visualDensity: VisualDensity.compact,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(999999)),
      ),
      padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
      textStyle: TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      isAlwaysShown: PlatformExtended.isDesktop,
      showTrackOnHover: true,
      crossAxisMargin: 0,
      mainAxisMargin: 0,
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          primary: accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(999999))),
        )
    ),
  );

  Color getDarkerColor(Color base){
    return (Color.fromARGB(base.alpha, getDarker(base.red), getDarker(base.green), getDarker(base.blue)));
  }
  int getDarker(int base){
    return (base-30).coerceIn(base~/2, 255);
  }

  Color getLighterColor(Color base){
    return (Color.fromARGB(base.alpha, getLighter(base.red), getLighter(base.green), getLighter(base.blue)));
  }
  int getLighter(int base){
    return (base-30).coerceIn(255-((255-base)~/2), 255);
  }

}