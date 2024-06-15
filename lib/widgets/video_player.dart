import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late CustomVideoPlayerController customVideoPlayerController;

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer(widget.videoUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomVideoPlayer(
              customVideoPlayerController: customVideoPlayerController),
        ],
      ),
    );
  }

  void initializeVideoPlayer(String videoUrl) {
    CachedVideoPlayerController videoPlayerController;

    videoPlayerController = CachedVideoPlayerController.network(videoUrl)
      ..initialize().then((value) {
        setState(() {});
      });

    customVideoPlayerController = CustomVideoPlayerController(
        context: context, videoPlayerController: videoPlayerController);
  }
}
