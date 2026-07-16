import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Video player widget using media_kit for HLS streaming.
class VideoPlayerWidget extends StatefulWidget {
  final String streamUrl;

  const VideoPlayerWidget({
    super.key,
    required this.streamUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final Player _player;
  late final VideoController _videoController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.open(Media(widget.streamUrl));
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) {
        setState(() => _initialized = true); // show error state
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Video(
      controller: _videoController,
      fit: BoxFit.contain,
      controls: AdaptiveVideoControls,
    );
  }
}
