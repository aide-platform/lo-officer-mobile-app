import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays a downloaded training video from the app's private storage.
class TrainingVideoPlayerScreen extends StatefulWidget {
  const TrainingVideoPlayerScreen({
    super.key,
    required this.title,
    required this.file,
  });

  final String title;
  final File file;

  @override
  State<TrainingVideoPlayerScreen> createState() =>
      _TrainingVideoPlayerScreenState();
}

class _TrainingVideoPlayerScreenState extends State<TrainingVideoPlayerScreen> {
  late final VideoPlayerController _video = VideoPlayerController.file(
    widget.file,
  );
  ChewieController? _chewie;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _video.initialize();
      if (!mounted) return;
      setState(() {
        _chewie = ChewieController(
          videoPlayerController: _video,
          autoPlay: true,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
          aspectRatio: _video.value.aspectRatio,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'This video cannot be played on this phone. '
            'Remove the download and try again.',
      );
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewie;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Center(
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : chewie == null
              ? const CircularProgressIndicator(color: Colors.white)
              : Chewie(controller: chewie),
        ),
      ),
    );
  }
}
