import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/api/models/xtream_account.dart';
import '../../core/services/update_service.dart';
import 'edit_account_screen.dart';
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
  String? _latestApkUrl;
  String _localVersion = '...';
  DateTime? _lastCheckTime;

  @override
  void initState() {
    super.initState();
    _loadLocalVersion();
    _checkUpdate(silent: true);
  }

  Future<void> _loadLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _localVersion = info.version);
    } catch (_) {
      if (mounted) setState(() => _localVersion = '1.0.0');
    }
  }

  Future<void> _checkUpdate({bool silent = false}) async {
    // Cooldown: skip API call within 5 minutes of last check (only for silent auto-checks)
    if (silent &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < const Duration(minutes: 5)) {
      return;
    }

    try {
      final result = await UpdateService.check();
      _lastCheckTime = DateTime.now();
      if (!mounted) return;
      final local = result.local;
      final remote = result.remote;
      setState(() => _localVersion = local);

      if (remote != null && UpdateService.isNewer(remote, local)) {
        setState(() {
          _updateAvailable = true;
          _latestVersion = remote;
          _latestApkUrl = result.apkUrl;
        });
        _showUpdateDialog(remote, result.apkUrl);
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ya tienes la última versión ($local)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && !silent) {
        final message = switch (e) {
          DioException() => _dioErrorMessage(e),
          _ => 'Error: ${e.toString().replaceFirst("Exception: ", "")}',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  void _showUpdateDialog(String version, String? apkUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Actualización disponible'),
        content: Text('Versión $version está disponible.\nTu versión: $_localVersion\n¿Quieres descargarla?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ahora no')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndInstall(version, apkUrl);
            },
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(String version, String? apkUrl) async {
    final progressNotifier = ValueNotifier<double>(0);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Schedule download after dialog is fully built to avoid Navigator lock
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startDownload(version, apkUrl, (pct) => progressNotifier.value = pct, ctx);
        });
        return ValueListenableBuilder(
          valueListenable: progressNotifier,
          builder: (_, progress, _) {
            return AlertDialog(
              title: const Text('Descargando...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 12),
                  Text('${(progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startDownload(String version, String? apkUrl, void Function(double) onProgress, BuildContext ctx) async {
    if (apkUrl == null) {
      if (!mounted) return;
      Navigator.pop(ctx);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el enlace de descarga')),
      );
      return;
    }

    try {
      final path = await UpdateService.downloadApk(apkUrl, version, (r, t) {
        if (t > 0) onProgress(r / t);
      });
      if (!mounted) return;
      Navigator.pop(ctx);
      if (kReleaseMode) {
        await OpenFilex.open(path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('APK descargado en:\n$path')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(ctx);
      final message = switch (e) {
        DioException() => _dioErrorMessage(e),
        _ => 'Error descargando: $e',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _dioErrorMessage(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
        'Tiempo de espera agotado. Revisa tu conexión.',
      DioExceptionType.badResponse =>
        switch (e.response?.statusCode) {
          403 => 'Límite de peticiones a GitHub. Intenta más tarde.',
          404 => 'El archivo de actualización no está disponible.',
          _ => 'Error del servidor (${e.response?.statusCode ?? "?"}).',
        },
      DioExceptionType.connectionError =>
        'No se pudo conectar con GitHub. Revisa tu red o VPN.',
      _ => 'Error de red: ${e.message ?? "desconocido"}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final accounts = ref.watch(accountsProvider);

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
                          const Image(
                            image: AssetImage('assets/icon.png'),
                            width: 80,
                            height: 80,
                          ),
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
                    itemCount: accounts.length + 1,
                    itemBuilder: (context, index) {
                      if (index < accounts.length) {
                        return _AccountCard(
                          account: accounts[index],
                          onTap: () => _connect(accounts[index]),
                          onDelete: () => _delete(accounts[index]),
                        );
                      }
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

          // Version text
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'v$_localVersion',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),

          if (state == AuthState.loading) const LinearProgressIndicator(),
        ],
      ),
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
          onPressed: () => _downloadAndInstall(_latestVersion!, _latestApkUrl),
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
    final error = ref.read(loginProvider.notifier).errorMessage;
    if (error != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error de conexión'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditAccountScreen(account: account)),
                );
              },
              child: const Text('Editar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  void _addAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  const _AccountCard({required this.account, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(account.server, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditAccountScreen(account: account)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
