import 'dart:io';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart' as assets_audio_player;
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_desktop/flutter_audio_desktop.dart' as flutter_audio_desktop;
import 'package:flutter_svg/svg.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:open_file/open_file.dart';
import 'package:taxonomies/controllers/database_controller.dart';
import 'package:taxonomies/models/attribute.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:video_player/video_player.dart';
import 'package:dartx/dartx.dart';
import 'package:taxonomies/router.dart';
import 'package:path/path.dart' as p;

abstract class AttributeWidget extends StatelessWidget {

  final Instance instance;
  final Attribute attribute;
  AttributeWidget(this.instance, this.attribute);

  factory AttributeWidget.factory({
    required Instance instance,
    required Attribute attribute,
    bool compact = false,
    bool? embedded,
  }) {
    AttributeWidget result;
    if ((embedded??true) && attribute.link!=null){
      return AttributeEmbeddedInstance(
        instance: instance,
        attribute: attribute,
        compact: compact,
        embedded: embedded,
      );
    }
    switch(attribute.typeName){
      case "Imagen":
        result = AttributePicture(
          instance: instance,
          attribute: attribute,
          compact: compact,
          embedded: embedded,
        );
        break;
      case "Audio":
        result = AttributeAudio(
          instance: instance,
          attribute: attribute,
          compact: compact,
          embedded: embedded,
        );
        break;
      case "Video":
        if (kIsWeb || Platform.isAndroid || Platform.isIOS){
          result =  AttributeVideo(
            instance: instance,
            attribute: attribute,
            compact: compact,
            embedded: embedded,
          );
        } else{
          result =  AttributeVideoDesktop(instance, attribute);
        }
        break;
      case "Texto Largo":
        result =  AttributeLongText(
          instance: instance,
          attribute: attribute,
          compact: compact,
          embedded: embedded,
        );
        break;
      case "Mapa":
        result =  AttributeMap(
          instance: instance,
          attribute: attribute,
          compact: compact,
          embedded: embedded,
        );
        break;
      default:
        result =  AttributeShortText(
          instance: instance,
          attribute: attribute,
          compact: compact,
          embedded: embedded,
        );
    }
    return result;
  }

}

class AttributeEmbeddedInstance extends AttributeWidget{
  final bool compact;
  final bool? embedded;
  AttributeEmbeddedInstance({
    required Instance instance,
    required Attribute attribute,
    this.compact = false,
    this.embedded,
  }) : super(instance, attribute);
  @override
  Widget build(BuildContext context) {
    return _ReactiveEmbeddedInstance(
      instance: instance,
      attribute: attribute,
      compact: compact,
    );
  }
}
class _ReactiveEmbeddedInstance extends StatefulWidget {
  final Instance instance;
  final Attribute attribute;
  final bool compact;
  _ReactiveEmbeddedInstance({
    required this.instance,
    required this.attribute,
    this.compact = false,
  });
  @override
  __ReactiveEmbeddedInstanceState createState() => __ReactiveEmbeddedInstanceState();
}
class __ReactiveEmbeddedInstanceState extends State<_ReactiveEmbeddedInstance> {

  bool heroActivated = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:  (){
        setState(() {
          heroActivated = true;
        });
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async{
          MyFluroRouter.cache = widget.attribute.link!;
          Navigator.of(context).pushNamed('/view?id=${widget.attribute.link!.id}',);
        });
      },
      child: AttributeWidget.factory(
        instance: heroActivated ? widget.attribute.link! : widget.instance,
        attribute: widget.attribute.copyWith()..link=null,
        embedded: true,
        compact: widget.compact,
      ),
    );
  }

}




class AttributeMap extends AttributeWidget {

  final bool compact;
  final bool? embedded;
  final String? mapImage;
  final bool fullscreen;
  final double mapTopLeftX;
  final double mapTopLeftY;
  final double mapWidth;
  final double mapHeight;
  List<Point<double>> points = [];
  List<List<Point<double>>> polygons = [];

  AttributeMap({
    required Instance instance,
    required Attribute attribute,
    this.compact = false,
    this.embedded,
    this.fullscreen = false,
  }) :  mapImage = DatabaseController.config['map_${attribute.attributeName}_image'],
        mapTopLeftY = double.parse(DatabaseController.config['map_${attribute.attributeName}_top_left_lat'] ?? 0),
        mapTopLeftX = double.parse(DatabaseController.config['map_${attribute.attributeName}_top_left_long'] ?? 0),
        mapHeight = double.parse(DatabaseController.config['map_${attribute.attributeName}_height_lat'] ?? 0),
        mapWidth = double.parse(DatabaseController.config['map_${attribute.attributeName}_width_long'] ?? 0),
        super(instance, attribute) {
    try {
      // PARSE POINTS
      int endIndex = 0;
      while (true) {
        int index = attribute.value.indexOf('POINT', endIndex);
        if (index < 0) break;
        int startIndex = attribute.value.indexOf('(', index) + 1;
        endIndex = attribute.value.indexOf(')', startIndex);
        int middleIndex = attribute.value.indexOf(' ', startIndex+1);
        points.add(Point(
          double.parse(attribute.value.substring(startIndex, middleIndex).trim()),
          double.parse(attribute.value.substring(middleIndex, endIndex).trim()),
        ),);
      }
      // PARSE POLYGONS
      polygons = parsePolygons(attribute);
      // print ('POINTS');
      // print (points);
      // print ('POLYGONS');
      // print (polygons);
    } catch(e, st){
      print ('ERROR PARSING MAP POINTS INFO');
      // print (attribute.value);
      print(e);
      print(st);
    }
  }

  static List<List<Point<double>>> parsePolygons(Attribute attribute) {
    List<List<Point<double>>> polygons = [];
    int multipolygonEndIndex = 0;
    while (true) {
      int multipolygonIndex = attribute.value.indexOf('MULTIPOLYGON', multipolygonEndIndex);
      if (multipolygonIndex < 0) break;
      int multipolygonStartIndex = attribute.value.indexOf('(((', multipolygonIndex) + 1;
      multipolygonEndIndex = attribute.value.indexOf(')))', multipolygonStartIndex) + 2;
      int polygonEndIndex = multipolygonStartIndex;
      // print ('MULTIPOLYGON');
      while (true) {
        int polygonStartIndex = attribute.value.indexOf('((', polygonEndIndex);
        if (polygonStartIndex>=0) polygonStartIndex = polygonStartIndex + 2;
        if (polygonStartIndex < 0 || polygonStartIndex > multipolygonEndIndex) break;
        polygonEndIndex = attribute.value.indexOf('))', polygonStartIndex);
        polygons.add([]);
        int startIndex = polygonStartIndex;
        int endIndex = startIndex;
        // print ('POLYGON');
        while (true) {
          if (startIndex < 0 || startIndex > polygonEndIndex) break;
          endIndex = attribute.value.indexOf(',', startIndex);
          if (endIndex < 0 || endIndex > polygonEndIndex) endIndex = polygonEndIndex;
          int middleIndex = attribute.value.indexOf(' ', startIndex+1);
          // print ('POINT');
          // print (startIndex);
          // print (middleIndex);
          // print (endIndex);
          polygons.last.add(Point(
            double.parse(attribute.value.substring(startIndex, middleIndex).trim()),
            double.parse(attribute.value.substring(middleIndex, endIndex).trim()),
          ),);
          startIndex = attribute.value.indexOf(',', endIndex);
          if (startIndex>=0) startIndex = startIndex + 1;
        }
      }
    }
    return polygons;
  }

  @override
  Widget build(BuildContext context) {
    if (mapImage==null) {
      return SizedBox.shrink();
    }
    Widget result;
    if (mapImage!.endsWith('.svg')) {
      result = LayoutBuilder(
        builder: (context, constraints) {
          return DatabaseController.customAssetPathPrefix==null 
              ? SvgPicture.asset('assets/$mapImage',
                  width: fullscreen ? constraints.maxWidth : min(constraints.maxWidth, 768),
                ) 
              : SvgPicture.file(File(p.join(DatabaseController.customAssetPathPrefix!, 'assets', mapImage)),
                  width: fullscreen ? constraints.maxWidth : min(constraints.maxWidth, 768),
                ) ;
        },
      );
    } else {
      result = DatabaseController.customAssetPathPrefix==null 
          ? Image.asset('assets/$mapImage') 
          : Image.file(File(p.join(DatabaseController.customAssetPathPrefix!, 'assets', mapImage)));
    }
    result = Stack(
      children: [
        result,
        ...polygons.map((e) {
          return Positioned.fill(
            child: ClipPath(
              clipper: PolygonClipper(
                points: e,
                mapTopLeftX: mapTopLeftX,
                mapTopLeftY: mapTopLeftY,
                mapWidth: mapWidth,
                mapHeight: mapHeight,
              ),
              child: Container(
                color: Theme.of(context).accentColor.withOpacity(0.9),
                child: Container(),
              ),
            ),
          );
        }),
        ...points.map((e) {
          return Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double multiplier = constraints.minWidth>512 ? 1 : 0.66;
                return Align(
                  alignment: Alignment.topLeft,
                  child: Transform.translate(
                    offset: Offset(
                      constraints.minWidth * ((e.x - (mapTopLeftX)).abs() / (mapWidth)) - 8*multiplier,
                      constraints.minHeight * ((e.y - (mapTopLeftY)).abs() / (mapHeight)) - 8*multiplier,
                    ),
                    child: PhysicalModel(
                      color: Theme.of(context).accentColor.withOpacity(0.98),
                      shape: BoxShape.circle,
                      elevation: 6*multiplier,
                      child: Container(width: 16*multiplier, height: 16*multiplier,),
                    ),
                  ),
                );
              },
            ),
          );
        }),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxSize = max(constraints.maxHeight, constraints.maxWidth);
              if (maxSize<128) {
                return SizedBox.shrink();
              }
              Widget result;
              if (fullscreen) {
                result = Column(
                  children: [
                    IconButtonBackground(
                      child: IconButton(
                        icon: Icon(Icons.close),
                        tooltip: FromZeroLocalizations.of(context).translate('close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                );
              } else {
                result = Column(
                  children: [
                    IconButtonBackground(
                      child: IconButton(
                        icon: Icon(Icons.fullscreen),
                        tooltip: FromZeroLocalizations.of(context).translate('fullscreen'),
                        onPressed: () {
                          pushFullscreenImage(context);
                        },
                      ),
                    ),
                  ],
                );
              }
              return Material(
                type: MaterialType.transparency,
                child: Container(
                  alignment: Alignment.topRight,
                  padding: EdgeInsets.all(maxSize<256 ? 0 : 8),
                  child: result,
                ),
              );
            },
          ),
        ),
      ],
    );
    if (!fullscreen) {
      result = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 384),
        child: result,
      );
    }
    if (attribute.attributeName!='Mapa') {
      result = Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: result,
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(attribute.attributeName,
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return result;
  }

  void pushFullscreenImage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        fullscreenDialog: true,
        // opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ZoomedFadeInTransition(
            animation: animation,
            child: Material(
              child: InteractiveViewer(
                maxScale: 100,
                child: Center(
                  child: SafeArea(
                    child: AttributeMap(
                      compact: compact,
                      attribute: attribute,
                      instance: instance,
                      embedded: embedded,
                      fullscreen: true,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

class PolygonClipper extends CustomClipper<Path> {

  final double mapTopLeftX;
  final double mapTopLeftY;
  final double mapWidth;
  final double mapHeight;
  final List<Point<double>> points;


  PolygonClipper({
    required this.mapTopLeftX,
    required this.mapTopLeftY,
    required this.mapWidth,
    required this.mapHeight,
    required this.points,
  });

  @override
  getClip(Size size) {
    var path = Path();
    for (var i = 0; i < points.length; ++i) {
      // THIS WILL BREAK WHEN MAP REFERENCE AND TARGET POINT ARE DIFFERENT SIGNS, BUT WHATEVER
      double x = size.width * ((points[i].x - (mapTopLeftX)).abs() / (mapWidth));
      double y = size.height * ((points[i].y - (mapTopLeftY)).abs() / (mapHeight));
      // print('Map Top Left: $mapTopLeftX, $mapTopLeftY');
      // print('Map size: $mapWidth, $mapHeight');
      // print('Original: ${points[i].x}, ${points[i].y}');
      // print('Local: $x, $y');
      if (i==0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return false;
  }

}




class AttributeShortText extends AttributeWidget {

  final bool compact;
  final bool? embedded;

  AttributeShortText({
    required Instance instance,
    required Attribute attribute,
    this.compact = false,
    this.embedded,
  }) : super(instance, attribute);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            attribute.attributeName,
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.center,
          ),
          Text(
            attribute.value,
            style: Theme.of(context).textTheme.headline6!.copyWith(height: 1.2,),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1000000,
            child: Text(attribute.attributeName,
              style: Theme.of(context).textTheme.subtitle1,
              textAlign: TextAlign.right,
            ),
          ),
          Container(
            height: 24,
            child: VerticalDivider(width: 16,),
          ),
          Expanded(
            flex: 1618034,
            child: Text(attribute.value,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
        ],
      ),
    );
  }

}

class AttributeLongText extends AttributeWidget {

  final bool compact;
  final bool? embedded;

  AttributeLongText({
    required Instance instance,
    required Attribute attribute,
    this.compact = false,
    this.embedded,
  }) : super(instance, attribute);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(attribute.attributeName,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          Divider(height: 6,),
          Text(attribute.value,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

}

class AttributePicture extends AttributeWidget {

  final bool compact;
  final bool? embedded;

  AttributePicture({
    required Instance instance,
    required Attribute attribute,
    this.compact = false,
    this.embedded,
  }) : super(instance, attribute);

  @override
  Widget build(BuildContext context) {
    bool insideInkWell = context.findAncestorWidgetOfExactType<InkWell>() != null;
    Widget result = ImageFromZero (
      url: DatabaseController.customAssetPathPrefix!=null
          ? p.join(DatabaseController.customAssetPathPrefix!, "assets", attribute.value.replaceAll("\\", '/'))
          : "assets/"+attribute.value.replaceAll("\\", '/'),
      fullscreenType: insideInkWell ? FullscreenType.asAction : FullscreenType.onClickAndAsAction,
      // fullscreenType: (embedded??false) ? FullscreenType.none : FullscreenType.onClick,
    );
    result = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: attribute.attributeName=='Icon' ? 48 : 384),
      child: result,
    );
    // result = Hero(
    //   tag: "image${instance.id}-${attribute.value}",
    //   child: result,
    // );
    if (attribute.attributeName!='Icon' && attribute.attributeName!='Foto') {
      result = Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: result,
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(attribute.attributeName,
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return result;
  }

}

class AttributeAudio extends AttributeWidget {
  final bool compact;
  final bool? embedded;
  AttributeAudio({
    required Instance instance,
    required Attribute attribute,
    this.compact = false,
    this.embedded,
  }) : super(instance, attribute);
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isWindows || Platform.isLinux || Platform.isMacOS){
      return AttributeAudioDesktop(
        instance: instance,
        attribute: attribute,
        compact: compact,
        embedded: embedded,
      );
    } else{
      return AttributeAudioDefault(
        instance: instance,
        attribute: attribute,
        compact: compact,
        embedded: embedded,
      );
    }

  }
}
class AttributeAudioDefault extends StatefulWidget {

  final Instance instance;
  final Attribute attribute;
  final bool compact;
  final bool? embedded;

  AttributeAudioDefault({
    required this.instance,
    required this.attribute,
    this.compact = false,
    this.embedded,
  });

  @override
  _AttributeAudioDefaultState createState() => _AttributeAudioDefaultState();

}
class _AttributeAudioDefaultState extends State<AttributeAudioDefault> with TickerProviderStateMixin, RouteAware {

  late assets_audio_player.AssetsAudioPlayer audioPlayer;
  late AnimationController iconController;

  @override
  void initState() {
    super.initState();
    iconController = AnimationController(
      duration: 300.milliseconds,
      vsync: this,
    );
    initAudioPlayer();
  }

  @override
  void didUpdateWidget(AttributeAudioDefault old) {
    super.didUpdateWidget(old);
    try { audioPlayer.dispose(); } catch(_) {}
    initAudioPlayer();
  }

  bool initialized = false;
  Future<void> initAudioPlayer() async {
    initialized = true;
    audioPlayer = assets_audio_player.AssetsAudioPlayer();
    open();
    audioPlayer.playlistFinished.listen(_onPlaylistFinished);
  }
  void _onPlaylistFinished(event) {
    if (event){
      open();
    }
  }

  void open() {
    audioPlayer.open(
      DatabaseController.customAssetPathPrefix==null
          ? assets_audio_player.Audio("assets/"+widget.attribute.value.replaceAll("\\", '/'))
          : assets_audio_player.Audio.file(p.join(DatabaseController.customAssetPathPrefix!, "assets", widget.attribute.value.replaceAll("\\", '/'))),
      autoStart: false,
      loopMode: assets_audio_player.LoopMode.single,
    );
  }


  @override
  void dispose() {
    super.dispose();
    print ('Disposing audio because of dispose...');
    audioPlayer.dispose();
    initialized = false;
  }

  @override
  void didPushNext() {
    print ('Disposing audio because of push...');
    audioPlayer.dispose();
    initialized = false;
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    double width = 312;
    Widget result = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              assets_audio_player.PlayerBuilder.isPlaying(
                player: audioPlayer,
                builder: (context, isPlaying) {
                  iconController.animateTo(isPlaying ? 1 : 0);
                  return IconButton(
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: iconController,
                    ),
                    iconSize: 32,
                    onPressed: () async {
                      if (!initialized) {
                        await initAudioPlayer();
                      }
                      if (widget.attribute.audioDelay!=null){
                        Duration position = audioPlayer.currentPosition.hasValue ? audioPlayer.currentPosition.value : Duration.zero;
                        if (position < widget.attribute.audioDelay!) {
                          audioPlayer.seek(widget.attribute.audioDelay);
                        }
                      }
                      audioPlayer.playOrPause();
                    },
                  );
                },
              ),
              Expanded(
                child: assets_audio_player.PlayerBuilder.current(
                  player: audioPlayer,
                  builder: (context, playing) {
                    return assets_audio_player.PlayerBuilder.currentPosition(
                      player: audioPlayer,
                      builder: (context, position) {
                        Duration current = position;
                        Duration total = playing==null ? Duration.zero : playing.audio.duration;
                        return Slider(
                          value: current.inSeconds.toDouble(),
                          max: total.inSeconds.toDouble(),
                          onChanged: (value) {
                            if (widget.attribute.audioDelay==null || widget.attribute.audioDelay! < value.floor().seconds) {
                              audioPlayer.seek(value.floor().seconds);
                            }
                          },
                          activeColor: Theme.of(context).accentColor,
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
          Transform.translate(
            offset: Offset(0, -12),
            child: Padding(
              padding: const EdgeInsets.only(left: 14, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.attribute.attributeName),
                  assets_audio_player.PlayerBuilder.current(
                    player: audioPlayer,
                    builder: (context, playing) {
                      return assets_audio_player.PlayerBuilder.currentPosition(
                        player: audioPlayer,
                        builder: (context, position) {
                          Duration current = position;
                          Duration total = playing==null ? Duration.zero : playing.audio.duration;
                          return Text(_printDuration(current) + ' / ' + _printDuration(total));
                        },
                      );
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
    if (widget.compact) {
      return Center(
        child: result,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        double pad = (constraints.maxWidth*(1.618034/(1+1.618034))-(width-44)).coerceIn(0);
        return Container(
          padding: EdgeInsets.only(right: pad),
          alignment: Alignment.centerRight,
          child: result,
        );
      },
    );
  }

}
class AttributeAudioDesktop extends StatefulWidget {

  final Instance instance;
  final Attribute attribute;
  final bool compact;
  final bool? embedded;

  AttributeAudioDesktop({
    required this.instance,
    required this.attribute,
    this.compact = false,
    this.embedded,
  });

  @override
  _AttributeAudioDesktopState createState() => _AttributeAudioDesktopState();

}
flutter_audio_desktop.AudioPlayer? lastWindowsAudioPlayer;
class _AttributeAudioDesktopState extends State<AttributeAudioDesktop> with TickerProviderStateMixin, RouteAware {

  late flutter_audio_desktop.AudioPlayer audioPlayer;
  late AnimationController iconController;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    iconController = AnimationController(
      duration: 300.milliseconds,
      vsync: this,
    );
    initAudioPlayer();
  }

  @override
  void didUpdateWidget(AttributeAudioDesktop old) {
    super.didUpdateWidget(old);
    initAudioPlayer();
  }

  Future<void> initAudioPlayer() async {
    try{ lastWindowsAudioPlayer?.pause(); }catch(_){}
    try{ lastWindowsAudioPlayer?.stop(); }catch(_){}
    audioPlayer = flutter_audio_desktop.AudioPlayer();
    lastWindowsAudioPlayer = audioPlayer;
    await audioPlayer.load(DatabaseController.customAssetPathPrefix==null 
            ? p.join(File(Platform.script.toFilePath(windows: true)).parent.absolute.path,
                'data','flutter_assets','assets',widget.attribute.value.replaceAll("\\", '/'))
            : p.join(DatabaseController.customAssetPathPrefix!,'assets',widget.attribute.value.replaceAll("\\", '/'))
    );
    setState(() {});
  }

  @override
  void dispose() {
    // try{ audioPlayer.pause(); }catch(_){}
    try{ audioPlayer.stop(); }catch(_){}
    super.dispose();
  }

  @override
  void didPushNext() {
    // try{ audioPlayer.pause(); }catch(_){}
    try{ audioPlayer.stop(); }catch(_){}
    if (isPlaying) {
      setState(() {
        isPlaying = false;
      });
    }
  }

  // @override
  // void didPop() {
  //   try{ audioPlayer.pause(); }catch(_){}
  //   try{ audioPlayer.stop(); }catch(_){}
  //   if (isPlaying) {
  //     setState(() {
  //       isPlaying = false;
  //     });
  //   }
  // }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  _update(){
    if (mounted) {
      setState(() {});
      if (audioPlayer.isPlaying){
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          _update();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    iconController.animateTo(isPlaying ? 1 : 0);
    double width = 312;
    Widget result = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: iconController,
                ),
                iconSize: 32,
                onPressed: () async {
                  if (isPlaying) {
                    isPlaying = false;
                    audioPlayer.pause();
                  } else {
                    if (!audioPlayer.isLoaded) {
                      await initAudioPlayer();
                    }
                    print (widget.attribute.audioDelay);
                    if (widget.attribute.audioDelay!=null){
                      var position = await audioPlayer.getPosition();
                      if (position==null || position.runtimeType!=Duration) position = Duration.zero;
                      if (position < widget.attribute.audioDelay) {
                        audioPlayer.setPosition(widget.attribute.audioDelay);
                      }
                    }
                    isPlaying = true;
                    audioPlayer.play();
                    // audioPlayer.onStop().then((value) {
                    //   isPlaying = false;
                    //   _update();
                    // });
                  }
                  _update();
                },
              ),
              Expanded(
                child: FutureBuilderFromZero(
                  future: Future.wait([audioPlayer.getPosition(), audioPlayer.getDuration()]),
                  keepPreviousDataWhileLoading: true,
                  successBuilder: (context, List data) {
                    Duration current = data[0] is Duration ? data[0] : Duration.zero;
                    Duration total = data[1] is Duration ? data[1] : Duration.zero;
                    if (data[0] is Duration && current.inMilliseconds+100>=total.inMilliseconds){
                      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
                        audioPlayer.stop();
                      });
                    }
                    return Slider(
                      value: current.inMilliseconds.toDouble(),
                      max: total.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        if (widget.attribute.audioDelay==null || widget.attribute.audioDelay!.inMilliseconds < value.floor()){
                          setState(() {
                            audioPlayer.setPosition(value.floor().milliseconds);
                          });
                        }
                      },
                      activeColor: Theme.of(context).accentColor,
                    );
                  },
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: Offset(0, -12),
            child: Padding(
              padding: const EdgeInsets.only(left: 14, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.attribute.attributeName),
                  FutureBuilderFromZero(
                    future: Future.wait([audioPlayer.getPosition(), audioPlayer.getDuration()]),
                    keepPreviousDataWhileLoading: true,
                    successBuilder: (context, List data) {
                      Duration current = data[0] is Duration ? data[0] : Duration.zero;
                      Duration total = data[1] is Duration ? data[1] : Duration.zero;
                      return Text(_printDuration(current) + ' / ' + _printDuration(total));
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
    if (widget.compact) {
      return Center(
        child: result,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        double pad = (constraints.maxWidth*(1.618034/(1+1.618034))-(width-44)).coerceIn(0);
        return Container(
          padding: EdgeInsets.only(right: pad),
          alignment: Alignment.centerRight,
          child: result,
        );
      },
    );
  }

}




class AttributeVideo extends AttributeWidget {

  final bool compact;
  final bool? embedded;

  AttributeVideo({
    required Instance instance,
    required Attribute attribute,
    this.compact = false,
    this.embedded,
  }) : super(instance, attribute);

  @override
  Widget build(BuildContext context) {
    return AttributeVideoImpl(
      instance: instance,
      attribute: attribute,
      compact: compact,
      embedded: embedded,
    );
  }

}

class AttributeVideoImpl extends StatefulWidget {

  final Instance instance;
  final Attribute attribute;
  final bool compact;
  final bool? embedded;

  AttributeVideoImpl({
    required this.instance,
    required this.attribute,
    Key? key,
    this.compact = false,
    this.embedded,
  }) : super(key: key);

  @override
  _AttributeVideoImplState createState() => _AttributeVideoImplState();

}

// Map<String, VideoPlayerController> videoControllers = {};
// Map<String, ChewieController> chewieControllers = {};
class _AttributeVideoImplState extends State<AttributeVideoImpl> with RouteAware {

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  @override
  void initState() {
    super.initState();
    initPlayer();
  }

  bool initialized = false;
  void initPlayer() {
    print ('VIDEO FULLSCREEN');
    print (chewieController?.isFullScreen);
    if (chewieController?.isFullScreen??false) {
      skipInit = true;
      return;
    }
    try { videoPlayerController?.dispose(); } catch(_) {}
    try { chewieController?.dispose(); } catch(_) {}
    // final controller = videoControllers[widget.attribute.value];
    // try {
    //   controller?.pause();
    //   controller?.dispose();
    // } catch(_) {}
    videoPlayerController = DatabaseController.customAssetPathPrefix==null
        ? VideoPlayerController.asset("assets/"+widget.attribute.value.replaceAll("\\", '/'))
        : VideoPlayerController.file(File(p.join(DatabaseController.customAssetPathPrefix!, "assets", widget.attribute.value.replaceAll("\\", '/'))));
    // videoControllers[widget.attribute.value] = videoPlayerController;
    // final ccontroller = chewieControllers[widget.attribute.value];
    // try {
    //   ccontroller?.pause();
    //   ccontroller?.dispose();
    // } catch(_) {}
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoInitialize: true,
      aspectRatio: 16 / 9,
//      autoPlay: true,
//      looping: true,
    );
    // chewieControllers[widget.attribute.value] = chewieController;
    initialized = true;
  }

  @override
  void dispose() {
    super.dispose();
    print ('Disposing video because of dispose...');
    try {
      videoPlayerController?.pause();
      videoPlayerController?.dispose();
      chewieController?.pause();
      chewieController?.dispose();
      initialized = false;
    } catch (e, st) {
      print(e); print(st);
    }
  }

  // @override
  // void didPushNext() {
  //   super.didPushNext();
  //   print ('Disposing video because of push...');
  //   try {
  //     videoPlayerController?.pause();
  //     videoPlayerController?.dispose();
  //     chewieController?.pause();
  //     chewieController?.dispose();
  //     initialized = false;
  //   } catch (e, st) {
  //     print(e); print(st);
  //   }
  // }

  bool skipInit = false;
  @override
  Widget build(BuildContext context) {
    if (skipInit) {
      skipInit = false;
    } else {
      initPlayer();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            bool wider = constraints.maxWidth/constraints.maxHeight > 16/9;
            double width = wider ? constraints.maxHeight*(16/9) : constraints.maxWidth;
            double height = !wider ? constraints.maxWidth/(16/9) : constraints.maxHeight;
            print('width: $width');
            print('height: $height');
            return Container(
              height: height,
              alignment: Alignment.center,
              child: SizedBox(
                width: width,
                child: Chewie(
                  controller: chewieController,
                ),
              ),
            );
          },
        ),
        Text(widget.attribute.attributeName,
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

}



class AttributeVideoDesktop extends AttributeWidget {

  AttributeVideoDesktop(Instance instance, Attribute attribute) : super(instance, attribute);

  @override
  Widget build(BuildContext context) {
    Widget result = DatabaseController.customAssetPathPrefix==null
        ? Image.asset("assets/"+attribute.value.replaceAll("\\", '/')+'.jpg')
        : Image.file(File(p.join(DatabaseController.customAssetPathPrefix!, "assets", attribute.value.replaceAll("\\", '/')+'.jpg')));
    result = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 384, minHeight: 128),
      child: result,
    );
    result = Stack(
      children: [
        result,
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () async {
                String scriptPath = Platform.script.path.substring(1, Platform.script.path.indexOf(Platform.script.pathSegments.last))
                    .replaceAll('%20', ' ');
                String path = DatabaseController.customAssetPathPrefix==null
                    ? "${scriptPath}data/flutter_assets/assets/"+attribute.value.replaceAll("\\", '/')
                    : p.join(DatabaseController.customAssetPathPrefix!, "assets", attribute.value.replaceAll("\\", '/'));
                print ('Opening video   $path');
                await OpenFile.open(path);
                print ('Video Open Successful!');
              },
              child: Center(
                child: Icon(Icons.play_circle_outline,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (attribute.attributeName!='Video') {
      result = Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: result,
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(attribute.attributeName,
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return result;
  }

}