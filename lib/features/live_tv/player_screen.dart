import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/models/channel.dart';
import '../../core/api/models/epg_program.dart';
import '../player/video_player_widget.dart';
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
  String? _workingUrl;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Future.microtask(() {
      ref.read(liveTvProvider.notifier).loadEpgForChannel(widget.channel.streamId);
      _findWorkingUrl();
    });
  }

  Future<void> _findWorkingUrl() async {
    final provider = ref.read(liveTvProvider.notifier);
    final client = provider.client;

    // Build URL list: direct source first if available, then our constructed ones
    final urls = <String>[];
    final directSource = widget.channel.directSource;
    if (directSource != null && directSource.isNotEmpty) {
      urls.add(directSource);
    }
    urls.addAll(client.buildStreamUrlList(widget.channel.streamId));

    for (final url in urls) {
      final result = await client.checkStreamUrl(url);
      final status = result['status']!;
      if (status != 'ERR' && int.tryParse(status) != null) {
        final code = int.parse(status);
        if (code >= 200 && code < 300) {
          setState(() {
            _workingUrl = url;
            _loading = false;
          });
          return;
        }
      }
    }

    setState(() {
      _loading = false;
      _errorMessage = 'No se pudo conectar con el stream.\n'
          'Probadas: .m3u8, .ts, sin extensión';
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveTvProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background: loading / video / error
            if (_loading)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    SizedBox(height: 12),
                    Text('Probando conexión...',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              )
            else if (_workingUrl != null)
              VideoPlayerWidget(streamUrl: _workingUrl!)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.orange, size: 48),
                      const SizedBox(height: 12),
                      Text(_errorMessage ?? 'Error desconocido',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() => _loading = true);
                          _findWorkingUrl();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),

            // Tap-to-toggle overlay (behind controls so they stay tappable)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _showControls = !_showControls),
              ),
            ),

            // EPG overlay
            if (_showEpg) _buildEpgOverlay(state.epgPrograms),

            // Top controls (on top of gesture detector)
            if (_showControls) _buildTopControls(),
          ],
        ),
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
