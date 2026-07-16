import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

/// Video player using VLC for universal codec support (AC3, E-AC3, AAC, etc).
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

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    if (_urlIndex >= widget.streamUrls.length) return;

    final url = widget.streamUrls[_urlIndex];

    _controller?.dispose();
    _controller = VlcPlayerController.network(
      url,
      autoPlay: true,
    );

    setState(() {});

    _controller!.addListener(() {
      if (_controller!.value.hasError && mounted) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _urlIndex++;
            _connect();
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
    if (_controller == null) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

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
