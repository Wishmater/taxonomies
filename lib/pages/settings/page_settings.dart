import 'package:animations/animations.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/main.dart';
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
                if (PlatformExtended.isMobile && DatabaseController.availableModules.length > 1)
                  SizedBox(height: 4,),
                if (PlatformExtended.isMobile && DatabaseController.availableModules.length > 1)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Módulos disponibles:', style: Theme.of(context).textTheme.subtitle1,),
                          ),
                          ...DatabaseController.availableModules.map((e) {
                            final selected = e==(DatabaseController.config['title'] ?? 'tax_default');
                            return ListTile(
                              selected: selected,
                              leading: selected
                                  ? Icon(Icons.check_circle_outline, color: Theme.of(context).primaryColor,)
                                  : Icon(Icons.style),
                              title: Text(e),
                              selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              onTap: selected ? null : () async {
                                bool? confirm = await showModal(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('¿Seguro que quiere cargar el módulo $e?'),
                                      actions: [
                                        TextButton(
                                          child: Text('CANCELAR', style: TextStyle(color: Theme.of(context).textTheme.bodyText1!.color),),
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                        ),
                                        SizedBox(width: 8,),
                                        TextButton(
                                          child: Text('ACEPTAR'),
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                        ),
                                        SizedBox(width: 8,),
                                      ],
                                    )
                                  },
                                );
                                if (confirm ?? false) {
                                  await initProject(e);
                                  final themeParameters = Provider.of<ThemeParameters>(context, listen: false);
                                  themeParameters.init();
                                  themeParameters.notifyListeners();
                                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                                }
                              },
                            );
                          }),
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