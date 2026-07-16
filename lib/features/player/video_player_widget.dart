import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

/// Video player widget using VLC for universal IPTV stream support.
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
  VlcPlayerController? _controller;
  bool _error = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    _controller?.dispose();
    _controller = VlcPlayerController.network(
      widget.streamUrl,
      autoPlay: true,
    );

    _controller!.addListener(() {
      if (_controller!.value.hasError && mounted) {
        setState(() {
          _error = true;
          _errorMessage = 'Error de reproducción';
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
    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.orange, size: 48),
              const SizedBox(height: 12),
              const Text('No se pudo cargar el canal',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              Text(_errorMessage,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _error = false);
                  _initPlayer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
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
