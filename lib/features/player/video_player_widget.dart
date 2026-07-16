import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Video player using media_kit + libmpv nativo con todos los codecs.
class VideoPlayerWidget extends StatefulWidget {
  final List<String> streamUrls;
  const VideoPlayerWidget({super.key, required this.streamUrls});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final Player _player;
  late final VideoController _videoController;
  bool _ok = false;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _player = Player();
    // Create VideoController FIRST (before opening media)
    _videoController = VideoController(_player);
    _play();
  }

  Future<void> _play() async {
    if (_i >= widget.streamUrls.length) return;

    try {
      await _player.open(
        Media(
          widget.streamUrls[_i],
          httpHeaders: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36',
            'Referer': Uri.parse(widget.streamUrls[_i]).origin,
          },
        ),
        play: true,
      );
      if (mounted) setState(() => _ok = true);
    } catch (_) {
      _i++;
      _play();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ok) {
      return const Center(
        child: SizedBox(width: 40, height: 40,
            child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Video(
      controller: _videoController,
      fit: BoxFit.contain,
      controls: AdaptiveVideoControls,
    );
  }
}
