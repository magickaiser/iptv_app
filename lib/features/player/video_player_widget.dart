import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

/// Video player widget using VLC for universal IPTV stream support.
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

    await _controller?.stop();
    await _controller?.dispose();

    _controller = VlcPlayerController.network(
      url,
      autoPlay: true,
    );

    try {
      await _controller!.initialize();
      // Give VLC a moment to connect
      await Future.delayed(const Duration(seconds: 3));

      if (_controller!.value.isInitialized) {
        if (mounted) setState(() => _initialized = true);
      } else {
        _urlIndex++;
        if (mounted) {
          setState(() => _errorMessage = 'Stream no inició: $url');
        }
        await _tryNextUrl();
      }
    } catch (e) {
      _urlIndex++;
      if (mounted) {
        setState(() {
          _errorMessage = '$url\n${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
      await _tryNextUrl();
    }
  }

  @override
  void dispose() {
    _controller?.stop();
    _controller?.dispose();
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

    if (!_initialized || _controller == null) {
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
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
