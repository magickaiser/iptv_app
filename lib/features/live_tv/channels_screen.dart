import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/models/channel.dart';
import 'live_tv_provider.dart';

/// Channel list filtered by selected category.
class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveTvProvider);

    if (state.loading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final channels = ref.read(liveTvProvider.notifier).filteredChannels;

    if (channels.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No se encontraron canales', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          return _ChannelTile(channel: channels[index]);
        },
      ),
    );
  }
}

class _ChannelTile extends ConsumerWidget {
  final Channel channel;

  const _ChannelTile({required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: channel.streamIcon != null && channel.streamIcon!.isNotEmpty
              ? Image.network(
                  channel.streamIcon!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.tv, size: 36),
                )
              : const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.tv, size: 36),
                ),
        ),
        title: Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.play_circle_outline),
        onTap: () {
          ref.read(liveTvProvider.notifier).loadEpgForChannel(channel.streamId);
          // Navigate to player
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _DummyPlayer(channel: channel),
            ),
          );
        },
      ),
    );
  }
}

/// Temporary placeholder until PlayerScreen is wired.
class _DummyPlayer extends StatelessWidget {
  final Channel channel;
  const _DummyPlayer({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(channel.name)),
      body: const Center(child: Text('Reproductor - próximamente')),
    );
  }
}
