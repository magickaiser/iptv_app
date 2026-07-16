import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Video player widget using video_player + chewie for HLS streaming.
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
  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _initialized = false;
  bool _error = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.streamUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    _init();
  }

  Future<void> _init() async {
    try {
      await _videoController.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout: el stream no respondió'),
      );
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        showControls: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Error de reproducción',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          bufferedColor: Colors.grey.shade700,
        ),
      );
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _error = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _retry() async {
    setState(() {
      _initialized = false;
      _error = false;
      _errorMessage = '';
    });
    await _init();
  }

  @override
  void dispose() {
    _videoController.dispose();
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
              const Text(
                'No se pudo cargar el canal',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                '$_errorMessage\n\n${widget.streamUrl}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _retry,
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
