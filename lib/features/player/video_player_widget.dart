import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Video player using ExoPlayer + FFmpeg for AC3/E-AC3 codec support.
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
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initialized = false;
  bool _error = false;
  int _urlIndex = 0;

  @override
  void initState() {
    super.initState();
    _tryNextUrl();
  }

  Future<void> _tryNextUrl() async {
    if (_urlIndex >= widget.streamUrls.length) {
      if (mounted) setState(() => _error = true);
      return;
    }

    final url = widget.streamUrls[_urlIndex];

    await _videoController?.dispose();
    _chewieController?.dispose();

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
        'Referer': Uri.parse(url).scheme + '://' + Uri.parse(url).host + ':' + Uri.parse(url).port.toString(),
        'Origin': Uri.parse(url).scheme + '://' + Uri.parse(url).host,
      },
    );

    try {
      await _videoController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          bufferedColor: Colors.grey.shade700,
        ),
      );
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      _urlIndex++;
      await _tryNextUrl();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.orange, size: 48),
              const SizedBox(height: 12),
              const Text('No se pudo cargar',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() { _error = false; _urlIndex = 0; });
                  _tryNextUrl();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized || _chewieController == null) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}
