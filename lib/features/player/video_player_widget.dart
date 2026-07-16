import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

/// Video player widget using VLC for universal IPTV stream support.
/// Tries multiple URLs in sequence until one works.
class VideoPlayerWidget extends StatefulWidget {
  final List<String> streamUrls;

  const VideoPlayerWidget({
    super.key,
    required this.streamUrls,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VlcPlayerController? _controller;
  int _urlIndex = 0;
  bool _waiting = true;

  @override
  void initState() {
    super.initState();
    _tryNextUrl();
  }

  void _tryNextUrl() {
    if (_urlIndex >= widget.streamUrls.length) {
      setState(() {
        _waiting = false; // stays on last player state (VLC shows its own error)
      });
      return;
    }

    final url = widget.streamUrls[_urlIndex];

    _controller?.dispose();
    _controller = VlcPlayerController.network(
      url,
      autoPlay: true,
    );

    setState(() {
      _waiting = false; // Show VLC immediately, it handles loading internally
    });

    _controller!.addListener(() {
      if (_controller!.value.hasError && mounted) {
        // Try next URL after a short delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _urlIndex++;
            _tryNextUrl();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_waiting || _controller == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: Colors.white),
            ),
            SizedBox(height: 12),
            Text('Conectando...',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }

    // VLC shows its own loading/error/playback states
    return VlcPlayer(
      controller: _controller!,
      aspectRatio: 16 / 9,
      placeholder: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: Colors.white),
            ),
            SizedBox(height: 12),
            Text('Conectando...',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
