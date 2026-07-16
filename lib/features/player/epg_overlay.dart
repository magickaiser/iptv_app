import 'package:flutter/material.dart';

/// Overlay that shows current/upcoming EPG data on top of the video player.
class EpgOverlay extends StatelessWidget {
  final String currentTitle;
  final String? nextTitle;
  final VoidCallback? onTap;

  const EpgOverlay({
    super.key,
    required this.currentTitle,
    this.nextTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.01),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (nextTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                'A continuación: $nextTitle',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
