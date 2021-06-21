import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:taxonomies/controllers/game_model.dart';
import 'package:taxonomies/pages/instance/attribute_widget.dart';
import 'package:taxonomies/router.dart';

class HintBasedGame extends StatefulWidget {

  final GameModel model;
  final ScrollController scrollController;

  HintBasedGame({
    required this.model,
    required this.scrollController,
    Key? key,
  }) : super(key: key);

  @override
  _HintBasedGameState createState() => _HintBasedGameState();

}

class _HintBasedGameState extends State<HintBasedGame> {

  List<GlobalKey> hintContainerKeys = [];
  FocusNode initialFocusNode = FocusNode();
  late Future<GameInstanceModel> _instance;
  int previousIndex = -1;
  int instanceIndex = -1;
  Future<GameInstanceModel> get instance => _instance;
  set instance(Future<GameInstanceModel> value) {
    _instance = value;
    previousIndex = instanceIndex;
    value.then((value) {
      instanceIndex = widget.model.instances.indexOf(value);
    });
  }
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    instance = widget.model.createGameInstace().init();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      initialFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool expand = false;
    return FutureBuilderFromZero<GameInstanceModel>(
      future: instance,
      loadingBuilder: (context) => Container(),
      successBuilder: (context, data) {
        if (data.errorMessage!=null) {
          return ErrorSign(
            icon: Icon(Icons.error_outline,
              color: Theme.of(context).errorColor,
              size: 64,
            ),
            title: 'Error',
            subtitle: data.errorMessage,
          );
        }
        return StatefulBuilder(
          builder: (context, setState) {
            final hints = <Widget>[];
            for (var i = 0; i < data.hints.length; ++i) {
              if (hintContainerKeys.length <= i) {
                hintContainerKeys.add(GlobalKey());
              }
              print(widget.model.audioDelay);
              data.hints[i].audioDelay = widget.model.audioDelay;
              hints.add(InitiallyAnimatedWidget(
                key: hintContainerKeys[i],
                duration: Duration(milliseconds: 750),
                builder: (animationController, child) {
                  return SizeTransition(
                    child: child,
                    sizeFactor: CurveTween(curve: Curves.easeOutCubic).animate(animationController),
                    axis: Axis.vertical,
                    axisAlignment: -1,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4,),
                  alignment: Alignment.center,
                  child: AttributeWidget.factory(
                    instance: data.hintInstances[i],
                    attribute: data.hints[i],
                    embedded: false,
                    compact: true,
                  ),
                ),
              ));
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final double width = min(640, constraints.maxWidth);
                Widget answers = SizedBox.shrink();
                double nextButtonContainerWidth = width;
                double answersWidth = width;
                if (data is SelectGameInstanceModel) {
                  final answersCol1 = <Widget>[];
                  final answersCol2 = <Widget>[];
                  for (var i = 0; i < data.targets.length; ++i) {
                    final answerContents = <Widget>[];
                    for (var j = 0; j < data.targets[i].length; ++j) {
                      Widget attributeWidget = AttributeWidget.factory(
                        instance: data.targetInstances[i][j],
                        attribute: data.targets[i][j],
                        embedded: false,
                        compact: true,
                      );
                      if (data.targets[i][j].typeName=='Imagen' || data.targets[i][j].typeName=='Video') {
                        expand = true;
                        attributeWidget = Expanded(child: Center(child: attributeWidget,),);
                      }
                      answerContents.add(attributeWidget);
                    }
                    Widget result = Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...answerContents,
                      ],
                    );
                    result = Center(child: result,);
                    if (!expand) {
                      result = Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 12, left: 8, right: 8,),
                        child: result,
                      );
                    }
                    result = Card(
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        // focusNode: i==0 ? initialFocusNode : null,
                        onTap: () {
                          if (data.win==null) {
                            setState(() {
                              data.selectedIndex = i;
                            });
                          } else {
                            // final instance = data.targets[i].first.link ?? data.targetInstances[i].first;
                            final instance = data.correctIndex==i ? data.targetInstance : data.targetInstances[i].first;
                            MyFluroRouter.cache = instance;
                            Navigator.of(context).pushNamed('/view?id=${instance?.id}',);
                          }
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 750),
                          curve: Curves.easeOutCubic,
                          color: data.win==null ? Colors.transparent
                              : data.selectedIndex==i
                              ? data.win! ? Colors.green.withOpacity(0.4)
                              : Colors.red.withOpacity(0.4)
                              : Colors.transparent,
                          child: Stack(
                            children: [
                              result,
                              Positioned(
                                left: 0, top: 0, bottom: 0, width: 8,
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 750),
                                  curve: Curves.easeOutCubic,
                                  color: data.win==null ? Colors.transparent
                                      : data.correctIndex==i ? Colors.green.withOpacity(0.8)
                                      : data.selectedIndex==i ? Colors.red.withOpacity(0.8)
                                      : Colors.transparent,
                                  // color: data.win==null ? Colors.transparent
                                  //     : data.selectedIndex!=i && data.correctIndex==i ? Colors.green.withOpacity(0.8)
                                  //     : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    if (i.isEven) {
                      answersCol1.add(result);
                    } else {
                      answersCol2.add(result);
                    }
                  }
                  Widget row1 = Row(
                    children: answersCol1.map((e) => Expanded(child: e)).toList(),
                  );
                  Widget row2 = Row(
                    children: answersCol2.map((e) => Expanded(child: e)).toList(),
                  );
                  if (expand) {
                    row1 = Expanded(child: row1,);
                    row2 = Expanded(child: row2,);
                  }
                  answers = ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: width),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        row1,
                        row2,
                      ],
                    ),
                  );
                } else if (data is WriteGameInstanceModel) {
                  nextButtonContainerWidth = min(nextButtonContainerWidth, 384);
                  answersWidth = nextButtonContainerWidth;
                  final confirm = () {
                    setState(() {
                      if (data.win==null) {
                        setState(() {
                          data.givenAnswer = data.temporalAnswer??'';
                        });
                      } else {
                        final instance = data.targetInstance;
                        MyFluroRouter.cache = instance;
                        Navigator.of(context).pushNamed('/view?id=${instance?.id}',);
                      }
                    });
                  };
                  answers = Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      width: 384,
                      child: Card(
                        clipBehavior: Clip.hardEdge,
                        elevation: 12,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 750),
                          color: data.win==null ? Colors.transparent
                              : data.win! ? Colors.green.withOpacity(0.4)
                              : Colors.red.withOpacity(0.4),
                          child: Stack(
                            children: [
                              TypeAheadField<String>(
                                key: ValueKey(data),
                                textFieldConfiguration: TextFieldConfiguration(
                                  controller: textController,
                                  focusNode: initialFocusNode,
                                  enabled: data.win==null,
                                  onChanged: (value) {
                                    data.temporalAnswer = value;
                                  },
                                  decoration: InputDecoration(
                                    labelText: data.targets.first.first.attributeName,
                                    contentPadding: EdgeInsets.only(left: 16, right: 48, bottom: 6, top: 4),
                                  ),
                                  onSubmitted: (value) {
                                    data.temporalAnswer = value;
                                    confirm();
                                  },
                                ),
                                onSuggestionSelected: (suggestion) {
                                  textController.text = suggestion;
                                  data.temporalAnswer = suggestion;
                                  confirm();
                                },
                                suggestionsCallback: (pattern) async {
                                  if (!(data.model as WriteGameModel).autofill) return [];
                                  if (pattern.length<2) return [];
                                  return (await data.targetInstance!.category.getInstances())
                                      .map((e) => e.name)
                                      .where((e) => e.toLowerCase().contains(pattern.toLowerCase()));
                                },
                                itemBuilder: (context, itemData) {
                                  return AbsorbPointer(
                                    child: ListTile(
                                      title: Text(itemData),
                                    ),
                                  );
                                },
                                suggestionsBoxDecoration: SuggestionsBoxDecoration(
                                  constraints: BoxConstraints(maxHeight: 192),
                                  color: Theme.of(context).cardColor,
                                  hasScrollbar: false,
                                ),
                                hideOnEmpty: true,
                                hideOnLoading: true,
                                hideSuggestionsOnKeyboardHide: true,
                                direction: AxisDirection.up,
                              ),
                              Positioned(
                                right: 6, top: 3,
                                child: IconButton(
                                  icon: Icon(Icons.check),
                                  onPressed: confirm,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (data is LettersGameInstanceModel) {
                  answersWidth = double.infinity;
                  answers = StatefulBuilder(
                    builder: (context, lettersSetState) {
                      return RawKeyboardListener(
                        focusNode: initialFocusNode,
                        onKey: (value) {
                          print (value.character);
                          int i = -1;
                          for (var j = 0; i==-1 && j<data.possibleAnswers.length; ++j) {
                            if (data.possibleAnswers[j]==value.character?.toUpperCase() && !data.givenIndices.contains(j)) {
                              i = j;
                            }
                          }
                          print(i);
                          if (i != -1) {
                            int insertIndex = -1;
                            for (var j = 0; insertIndex==-1 && j<data.givenIndices.length; ++j) {
                              if (data.givenIndices[j]<0) insertIndex = j;
                            }
                            if (insertIndex!=-1) {
                              data.givenIndices[insertIndex] = i;
                            }
                            if (insertIndex==data.givenIndices.length-1) {
                              data.confirmed = true;
                              setState((){});
                            } else {
                              lettersSetState((){});
                            }
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(height: 12,),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: List.generate(data.correctAnswer.length, (i) {
                                return Padding(
                                  padding: EdgeInsets.only(right: data.spaceIndices.contains(i) ? 24 : 0),
                                  child: Stack(
                                    children: [
                                      Card(
                                        clipBehavior: Clip.hardEdge,
                                        child: Container(
                                          width: 32, height: 48,
                                          color: Color.alphaBlend(Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.33), Theme.of(context).canvasColor),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: AnimatedSwitcher(
                                          duration: Duration(milliseconds: 450),
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeInCubic,
                                          transitionBuilder: (child, animation) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: SlideTransition(
                                                position: Tween<Offset>(begin: Offset(0, 0.66), end: Offset.zero,).animate(animation),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: data.givenIndices[i]<0 ? SizedBox.shrink() : Card(
                                            clipBehavior: Clip.hardEdge,
                                            child: InkWell(
                                              onTap: data.confirmed ? null : () {
                                                lettersSetState((){
                                                  data.givenIndices[i] = -1;
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: Duration(milliseconds: 750),
                                                width: 32, height: 48,
                                                alignment: Alignment.center,
                                                color: data.win==null ? Colors.transparent
                                                    : data.win! ? Colors.green.withOpacity(0.4)
                                                    : Colors.red.withOpacity(0.4),
                                                child: Text(data.possibleAnswers[data.givenIndices[i]], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: 32,),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: List.generate(data.possibleAnswers.length, (i) {
                                Widget result;
                                return Stack(
                                  children: [
                                    Card(
                                      clipBehavior: Clip.hardEdge,
                                      child: Container(
                                        width: 32, height: 48,
                                        color: Color.alphaBlend(Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.15), Theme.of(context).canvasColor),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: AnimatedSwitcher(
                                        duration: Duration(milliseconds: 450),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: Tween<Offset>(begin: Offset(0, -0.66), end: Offset.zero,).animate(animation),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: data.givenIndices.contains(i) ? SizedBox.shrink() : Card(
                                          clipBehavior: Clip.hardEdge,
                                          child: InkWell(
                                            onTap: data.confirmed ? null : () {
                                              int insertIndex = -1;
                                              for (var j = 0; insertIndex==-1 && j<data.givenIndices.length; ++j) {
                                                if (data.givenIndices[j]<0) insertIndex = j;
                                              }
                                              if (insertIndex!=-1) {
                                                data.givenIndices[insertIndex] = i;
                                              }
                                              if (insertIndex==data.givenIndices.length-1) {
                                                data.confirmed = true;
                                                setState((){});
                                              } else {
                                                lettersSetState((){});
                                              }
                                            },
                                            child: Container(
                                              width: 32, height: 48,
                                              alignment: Alignment.center,
                                              child: Text(data.possibleAnswers[i], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                            SizedBox(height: 12,),
                          ],
                        ),
                      );
                    },
                  );
                }
                Widget hintsWidget = Column(children: hints,);
                if (data.win!=null) {
                  hintsWidget = InkWell(
                    onTap: () {
                      MyFluroRouter.cache = data.targetInstance;
                      Navigator.of(context).pushNamed('/view?id=${data.targetInstance?.id}',);
                    },
                    child: hintsWidget,
                  );
                }
                Widget result = CustomScrollView(
                  key: ValueKey(instanceIndex),
                  controller: widget.scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: AppbarFiller(child: SizedBox(height: 18,))),
                    SliverToBoxAdapter(
                      child: Center(
                        child: SizedBox(
                          width: width,
                          child: hintsWidget,
                        ),
                      ),
                    ),
                    // SliverToBoxAdapter(child: SizedBox(height: 12,)),
                    SliverToBoxAdapter(
                      child: Center(
                        child: SizedBox(
                          width: nextButtonContainerWidth,
                          child: PageTransitionSwitcher(
                            key: ValueKey(instanceIndex),
                            duration: Duration(milliseconds: 700),
                            reverse: true,
                            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                              return SharedAxisTransition(
                                animation: primaryAnimation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType: SharedAxisTransitionType.horizontal,
                                child: child,
                              );
                            },
                            child: data.win==null ? SizedBox(height: 48,)
                                :  Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                              alignment: Alignment.centerRight,
                              child: Tooltip(
                                message: 'Jugar de Nuevo',
                                child: ElevatedButton(
                                  onPressed: () {
                                    textController.text = '';
                                    hintContainerKeys = [];
                                    this.setState((){
                                      initialFocusNode = FocusNode();
                                      instance = widget.model.createGameInstace().init();
                                    });
                                    Future.delayed(Duration(milliseconds: 1000)).then((value) {
                                      initialFocusNode.requestFocus();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.double_arrow_rounded, size: 40,),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      fillOverscroll: false,
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: answersWidth,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 18),
                            child: answers,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
                result = PageTransitionSwitcher(
                  duration: Duration(milliseconds: 750),
                  reverse: previousIndex > instanceIndex,
                  transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                    return SharedAxisTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                  child: result,
                );
                result = FocusableActionDetector(
                  child: result,
                );
                return result;
              },
            );
          },
        );
      },
    );
  }

}
