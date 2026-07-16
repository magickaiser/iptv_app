import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Video player widget using video_player + chewie.
/// Tries multiple stream URLs in sequence.
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
  String _errorMessage = '';
  int _urlIndex = 0;

  @override
  void initState() {
    super.initState();
    _tryNextUrl();
  }

  Future<void> _tryNextUrl() async {
    if (_urlIndex >= widget.streamUrls.length) {
      setState(() {
        _error = true;
        _errorMessage = 'Ninguna URL de stream funcionó';
      });
      return;
    }

    final url = widget.streamUrls[_urlIndex];

    try {
      await _videoController?.dispose();
      _chewieController?.dispose();
    } catch (_) {}

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
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
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                  const SizedBox(height: 12),
                  const Text('Error de reproducción',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(errorMessage,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center),
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
      // Try next URL
      _urlIndex++;
      if (mounted) {
        setState(() {
          _errorMessage = '${widget.streamUrls[_urlIndex - 1]}\n${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: Colors.orange, size: 48),
                const SizedBox(height: 12),
                const Text('No se pudo cargar el canal',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Probadas: .m3u8, .ts, sin extensión\n$_errorMessage',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = false;
                      _urlIndex = 0;
                    });
                    _tryNextUrl();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
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
