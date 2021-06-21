import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';

class PageNotFound extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "not_found";

  PageNotFound();

  @override
  _PageNotFoundState createState() => _PageNotFoundState();

}

class _PageNotFoundState extends State<PageNotFound> with TickerProviderStateMixin {

  ScrollController mainScrollController = ScrollController();
  GlobalKey gameKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      title: Text('No Encontrado'),
      body: ErrorSign(
        title: 'No Encontrado',
        subtitle: 'La página que usted busca no existe',
        icon: Icon(Icons.error_outline, size: 64, color: Theme.of(context).errorColor,),
      ),
      currentPage: widget,
      mainScrollController: mainScrollController,
      appbarType: PlatformExtended.isMobile
          ? ScaffoldFromZero.appbarTypeQuickReturn : ScaffoldFromZero.appbarTypeStatic,
      actions: [
        AppbarAction(
          title: "Opciones",
          icon: Icon(Icons.settings),
          onTap: (context) => Navigator.of(context).pushNamed('/settings'),
        ),
      ],
    );
  }

}