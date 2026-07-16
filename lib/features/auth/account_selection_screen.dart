import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/models/xtream_account.dart';
import '../../core/services/update_service.dart';
import 'login_provider.dart';
import 'login_screen.dart';

/// Shows saved accounts + add new + update check.
class AccountSelectionScreen extends ConsumerStatefulWidget {
  const AccountSelectionScreen({super.key});

  @override
  ConsumerState<AccountSelectionScreen> createState() => _AccountSelectionScreenState();
}

class _AccountSelectionScreenState extends ConsumerState<AccountSelectionScreen> {
  bool _updateAvailable = false;
  String? _latestVersion;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final available = await UpdateService.isUpdateAvailable();
      final latest = await UpdateService.checkLatestVersion();
      if (mounted && available) {
        setState(() {
          _updateAvailable = true;
          _latestVersion = latest;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final accounts = ref.read(loginProvider.notifier).accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FrameTV'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Update banner
          if (_updateAvailable) _buildUpdateBanner(),

          Expanded(
            child: accounts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.live_tv, size: 64, color: Colors.blueGrey),
                          const SizedBox(height: 16),
                          const Text('No hay cuentas guardadas',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _addAccount,
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir cuenta'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: accounts.length + 1, // +1 for "Add" card
                    itemBuilder: (context, index) {
                      if (index < accounts.length) {
                        return _AccountCard(
                          account: accounts[index],
                          onTap: () => _connect(accounts[index]),
                          onDelete: () => _delete(accounts[index]),
                        );
                      }
                      // "Add new" card
                      return Card(
                        margin: const EdgeInsets.only(top: 12),
                        child: ListTile(
                          leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                          title: const Text('Añadir nueva cuenta'),
                          onTap: _addAccount,
                        ),
                      );
                    },
                  ),
          ),

          // Loading overlay
          if (state == AuthState.loading)
            const LinearProgressIndicator(),

          // Error
          if (state == AuthState.error) _buildError(),
        ],
      ),
      // Manual update check button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _checkUpdate,
        icon: const Icon(Icons.system_update),
        label: const Text('Buscar actualización'),
      ),
    );
  }

  Widget _buildUpdateBanner() {
    return MaterialBanner(
      leading: const Icon(Icons.system_update, color: Colors.white),
      backgroundColor: Colors.green.shade700,
      content: Text('$_latestVersion disponible'),
      actions: [
        TextButton(
          onPressed: () => launchUrl(Uri.parse(
              'https://github.com/magickaiser/iptv_app/releases')),
          child: const Text('Descargar', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => setState(() => _updateAvailable = false),
          child: const Text('Ignorar', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ref.read(loginProvider.notifier).errorMessage ?? 'Error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connect(XtreamAccount account) async {
    await ref.read(loginProvider.notifier).connectAccount(account);
  }

  void _addAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(isNewAccount: true),
      ),
    );
  }

  Future<void> _delete(XtreamAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text('¿Eliminar "${account.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(loginProvider.notifier).deleteAccount(account.id);
    }
  }
}

class _AccountCard extends StatelessWidget {
  final XtreamAccount account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(account.server, style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
