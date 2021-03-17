import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_desktop/flutter_audio_desktop.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
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

  factory AttributeWidget.factory(Instance instance, Attribute attribute){
    AttributeWidget result;
    if (attribute.link!=null){
      return AttributeEmbeddedInstance(instance, attribute);
    }
    switch(attribute.typeName){
      case "Imagen":
        result = AttributePicture(instance, attribute);
        break;
      case "Audio":
        result =  AttributeAudio(instance, attribute);
        break;
      case "Video":
        if (kIsWeb || Platform.isAndroid || Platform.isIOS){
          result =  AttributeVideo(instance, attribute);
        } else{
          result =  AttributeVideoDesktop(instance, attribute);
        }
        break;
      case "Texto Largo":
        result =  AttributeLongText(instance, attribute);
        break;
      default:
        result =  AttributeShortText(instance, attribute);
    }
    return result;
  }

}

class AttributeEmbeddedInstance extends AttributeWidget{
  AttributeEmbeddedInstance(Instance instance, Attribute attribute) : super(instance, attribute);
  @override
  Widget build(BuildContext context) {
    return _ReactiveEmbeddedInstance(instance, attribute);
  }
}
class _ReactiveEmbeddedInstance extends StatefulWidget {
  final Instance instance;
  final Attribute attribute;
  _ReactiveEmbeddedInstance(this.instance, this.attribute);
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
        heroActivated ? widget.attribute.link! : widget.instance,
        widget.attribute.copyWith(link: null,),
      ),
    );
  }

}



class AttributeShortText extends AttributeWidget {

  AttributeShortText(instance, attribute) : super(instance, attribute);

  @override
  Widget build(BuildContext context) {
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

  AttributeLongText(instance, attribute) : super(instance, attribute);

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

  AttributePicture(instance, attribute) : super(instance, attribute);

  @override
  Widget build(BuildContext context) {

//    return SizedBox(
//      height: 512,
//      child: FlutterMap(
//        options: MapOptions(
//          debug: true,
//          center: LatLng(51.5, -0.09),
//          zoom: 13.0,
//        ),
//        layers: [
//          TileLayerOptions(
//              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//              subdomains: ['a', 'b', 'c'],
//          ),
//          MarkerLayerOptions(
//            markers: [
//              Marker(
//                width: 80.0,
//                height: 80.0,
//                point: LatLng(51.5, -0.09),
//                builder: (ctx) =>
//                Container(
//                  child: FlutterLogo(),
//                ),
//              ),
//            ],
//          ),
//        ],
//      ),
//    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Hero(
          tag: "image${instance.id}-${attribute.value}", //
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: attribute.attributeName=='Icon' ? 48 : 384),
            child: Image.asset("assets/"+attribute.value.replaceAll("\\", '/'), //TODO 2 better images
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (attribute.attributeName!='Icon')
          Text(attribute.attributeName,
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

}

class AttributeAudio extends AttributeWidget { //TODO 1 implement audio
  AttributeAudio(instance, attribute) : super(instance, attribute);
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isWindows || Platform.isLinux || Platform.isMacOS){
      return AttributeAudioDesktop(instance, attribute);
    } else{
      return AttributeAudioDefault(instance, attribute);
    }

  }
}
class AttributeAudioDefault extends StatefulWidget {

  final Instance instance;
  final Attribute attribute;
  AttributeAudioDefault(this.instance, this.attribute);

  @override
  _AttributeAudioDefaultState createState() => _AttributeAudioDefaultState();

}
class _AttributeAudioDefaultState extends State<AttributeAudioDefault> with TickerProviderStateMixin {

  final audioPlayer = AssetsAudioPlayer();
  late AnimationController iconController;

  @override
  void initState() {
    super.initState();
    print("assets/"+widget.attribute.value.replaceAll("\\", '/'));
    audioPlayer.open(
      Audio("assets/"+widget.attribute.value.replaceAll("\\", '/')),
      autoStart: false,
      loopMode: LoopMode.single,
    );
    audioPlayer.playlistFinished.listen((event) {
      if (event){
        audioPlayer.open(
          Audio("assets/"+widget.attribute.value.replaceAll("\\", '/')),
          autoStart: false,
          loopMode: LoopMode.single,
        );
      }
    });
    iconController = AnimationController(
      duration: 300.milliseconds,
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.dispose();
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
              PlayerBuilder.isPlaying(
                player: audioPlayer,
                builder: (context, isPlaying) {
                  iconController.animateTo(isPlaying ? 1 : 0);
                  return IconButton(
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: iconController,
                    ),
                    iconSize: 32,
                    onPressed: (){
                      audioPlayer.playOrPause();
                    },
                  );
                },
              ),
              Expanded(
                child: PlayerBuilder.current(
                  player: audioPlayer,
                  builder: (context, playing) {
                    return PlayerBuilder.currentPosition(
                      player: audioPlayer,
                      builder: (context, position) {
                        Duration current = position;
                        Duration total = playing.audio.duration;
                        return Slider(
                          value: current.inSeconds.toDouble(),
                          max: total.inSeconds.toDouble(),
                          onChanged: (value) {
                            audioPlayer.seek(value.floor().seconds);
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
                  PlayerBuilder.current(
                    player: audioPlayer,
                    builder: (context, playing) {
                      return PlayerBuilder.currentPosition(
                        player: audioPlayer,
                        builder: (context, position) {
                          Duration current = position;
                          Duration total = playing.audio.duration;
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
  AttributeAudioDesktop(this.instance, this.attribute);

  @override
  _AttributeAudioDesktopState createState() => _AttributeAudioDesktopState();

}
class _AttributeAudioDesktopState extends State<AttributeAudioDesktop> with TickerProviderStateMixin {

  final audioPlayer = AudioPlayer();
  late AnimationController iconController;

  @override
  void initState() {
    super.initState();

    audioPlayer.load(p.join(File(Platform.script.toFilePath(windows: true)).parent.absolute.path,
        'data','flutter_assets','assets',widget.attribute.value.replaceAll("\\", '/')))
            .then((value) {
              setState(() {});
            });
    iconController = AnimationController(
      duration: 300.milliseconds,
      vsync: this,
    );
  }

  @override
  void dispose() {
    try{ audioPlayer.pause(); }catch(_){}
    try{ audioPlayer.stop(); }catch(_){}
    super.dispose();
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  _update(){
    setState(() {});
    if (audioPlayer.isPlaying){
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        _update();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    iconController.animateTo(audioPlayer.isPlaying ? 1 : 0);
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
                  await (audioPlayer.isPlaying ? audioPlayer.pause() : audioPlayer.play());
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
                        setState(() {
                          audioPlayer.setPosition(value.floor().milliseconds);
                        });
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




class AttributeVideo extends AttributeWidget { //TODO 1 TEST video in supported platforms

  late VideoPlayerController videoPlayerController;
  late ChewieController chewieController;

  AttributeVideo(instance, Attribute attribute) : super(instance, attribute){
    videoPlayerController = VideoPlayerController.asset("assets/"+attribute.value.replaceAll("\\", '/'));
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
//      aspectRatio: 3 / 2,
//      autoPlay: true,
//      looping: true,
    );
  }

  // videoPlayerController.dispose();
  // chewieController.dispose();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 384),
          child: Chewie(
            controller: chewieController,
          ),
        ),
        Text(attribute.attributeName,
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
    return SizedBox.shrink(); //TODO 3 implement an alternative to support video on Desktop
  }

}