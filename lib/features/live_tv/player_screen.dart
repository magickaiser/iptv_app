import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/models/channel.dart';
import '../../core/api/models/epg_program.dart';
import 'live_tv_provider.dart';

/// Full-screen video player with EPG overlay.
class PlayerScreen extends ConsumerStatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _showControls = true;
  bool _showEpg = false;
  int? _selectedEpgIndex;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(liveTvProvider.notifier).loadEpgForChannel(widget.channel.streamId);
    });
  }

  String get _streamUrl {
    final provider = ref.read(liveTvProvider.notifier);
    return provider.client.buildStreamUrl(widget.channel.streamId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveTvProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player placeholder
          Center(
            child: _VideoPlaceholder(
              streamUrl: _streamUrl,
              channel: widget.channel,
            ),
          ),

          // EPG overlay
          if (_showEpg) _buildEpgOverlay(state.epgPrograms),

          // Top controls
          if (_showControls) _buildTopControls(),

          // Gesture detector for tap-to-toggle controls
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _showControls = !_showControls),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.channel.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showEpg ? Icons.view_agenda_outlined : Icons.view_agenda,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _showEpg = !_showEpg),
                tooltip: 'EPG',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpgOverlay(List<EpgProgram> programs) {
    if (programs.isEmpty) {
      return const Center(
        child: Text('Sin EPG', style: TextStyle(color: Colors.white70)),
      );
    }

    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          itemCount: programs.length,
          itemBuilder: (context, index) {
            final program = programs[index];
            final isSelected = _selectedEpgIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedEpgIndex = index),
              child: Container(
                width: 160,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (program.description != null)
                      Text(
                        program.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Temporary video placeholder (will be replaced by media_kit integration).
class _VideoPlaceholder extends StatelessWidget {
  final String streamUrl;
  final Channel channel;

  const _VideoPlaceholder({
    required this.streamUrl,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.play_circle_outline, size: 80, color: Colors.white38),
        const SizedBox(height: 16),
        Text(
          channel.name,
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'Reproductor de video',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          streamUrl,
          style: TextStyle(color: Colors.grey[700], fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
