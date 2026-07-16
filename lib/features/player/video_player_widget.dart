import 'package:flutter/material.dart';

/// Video player widget using media_kit (to be implemented).
/// Placeholder that shows the stream URL for now.
class VideoPlayerWidget extends StatelessWidget {
  final String streamUrl;
  final bool autoPlay;

  const VideoPlayerWidget({
    super.key,
    required this.streamUrl,
    this.autoPlay = true,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Integrate media_kit for HLS playback
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle, size: 64, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              streamUrl,
              style: const TextStyle(color: Colors.white24, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
