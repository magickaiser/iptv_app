import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/models/channel.dart';
import 'live_tv_provider.dart';

/// Channel list with search and category filter.
class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveTvProvider);

    return Expanded(
      child: Column(
        children: [
          // --- Search bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar canal...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(liveTvProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                ref.read(liveTvProvider.notifier).setSearchQuery(value);
                setState(() {}); // refresh suffix icon
              },
            ),
          ),

          // --- Channel list ---
          if (state.loading)
            const Center(child: CircularProgressIndicator())
          else if (ref.read(liveTvProvider.notifier).filteredChannels.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Text(
                'No se encontraron canales',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: ref.read(liveTvProvider.notifier).filteredChannels.length,
                itemBuilder: (context, index) {
                  final channel =
                      ref.read(liveTvProvider.notifier).filteredChannels[index];
                  return _ChannelTile(channel: channel);
                },
              ),
            ),
        ],
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
