import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Video player using WebView for native AC3 codec support.
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
  WebViewController? _controller;
  int _urlIndex = 0;
  bool _waiting = true;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  String _buildHtml(String url) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  * { margin: 0; padding: 0; }
  body { background: #000; display: flex; align-items: center; justify-content: center; height: 100vh; overflow: hidden; }
  video { width: 100%; height: 100%; object-fit: contain; }
</style>
</head>
<body>
  <video autoplay playsinline controls src="$url" type="application/vnd.apple.mpegurl"></video>
</body>
</html>
''';
  }

  Future<void> _loadPlayer() async {
    if (_urlIndex >= widget.streamUrls.length) return;

    final url = widget.streamUrls[_urlIndex];
    final html = _buildHtml(url);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _waiting = false);
          },
          onWebResourceError: (_) {
            _urlIndex++;
            _loadPlayer();
          },
        ),
      )
      ..loadHtmlString(html);
  }

  @override
  void dispose() {
    _controller?.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_waiting) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_controller == null) {
      return const Center(
        child: Text('Error cargando reproductor',
            style: TextStyle(color: Colors.white)),
      );
    }

    return WebViewWidget(controller: _controller!);
  }
}
