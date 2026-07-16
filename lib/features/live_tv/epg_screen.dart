import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/models/epg_program.dart';
import 'live_tv_provider.dart';

/// Timeline EPG (electronic program guide) screen.
class EpgScreen extends ConsumerStatefulWidget {
  final int channelId;
  final String channelName;

  const EpgScreen({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  ConsumerState<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends ConsumerState<EpgScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(liveTvProvider.notifier).loadEpgForChannel(widget.channelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveTvProvider);
    final programs = state.epgPrograms;

    return Scaffold(
      appBar: AppBar(title: Text('Guía - ${widget.channelName}')),
      body: state.epgLoading
          ? const Center(child: CircularProgressIndicator())
          : programs.isEmpty
              ? const Center(child: Text('Sin información de programación'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    return _EpgTile(program: programs[index]);
                  },
                ),
    );
  }
}

class _EpgTile extends StatelessWidget {
  final EpgProgram program;

  const _EpgTile({required this.program});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final isCurrentlyLive = program.isLive;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentlyLive
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isCurrentlyLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('EN VIVO',
                        style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                const Spacer(),
                Text(
                  '${timeFormat.format(program.start)} - ${timeFormat.format(program.end)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              program.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (program.description != null && program.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                program.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[300]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
