import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/controllers/game_model.dart';
import 'package:taxonomies/pages/game/game_select.dart';


class PageGame extends PageFromZero {
  
  @override
  int get pageScaffoldDepth => 2;
  @override
  String get pageScaffoldId => "home";

  final GameModel model;

  PageGame({
    required this.model,
  });

  @override
  _PageGameState createState() => _PageGameState();

}

class _PageGameState extends State<PageGame> with TickerProviderStateMixin {

  ScrollController mainScrollController = ScrollController();
  GlobalKey gameKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch(widget.model.type){
      case 'Select':
      case 'Write':
      case 'WriteAutofill':
      case 'Letters':
        body = HintBasedGame(
          key: gameKey,
          model: widget.model,
          scrollController: mainScrollController,
        );
        break;

    // case Hanged

      default:
        body = Container();
    }
    return ScaffoldFromZero(
      title: Text(widget.model.name),
      body: body,
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