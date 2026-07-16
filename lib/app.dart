import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/login_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/live_tv/categories_screen.dart';
import 'features/live_tv/channels_screen.dart';
import 'features/live_tv/live_tv_provider.dart';
import 'core/theme/mobile_theme.dart';

/// Root widget that adapts to auth state: login vs main app.
class IptvApp extends ConsumerWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(loginProvider);

    return MaterialApp(
      title: 'IPTV Player',
      theme: MobileTheme.theme,
      debugShowCheckedModeBanner: false,
      home: authState == AuthState.authenticated
          ? const _MainScreen()
          : const LoginScreen(),
    );
  }
}

/// Main screen after authentication: categories + channels.
class _MainScreen extends ConsumerStatefulWidget {
  const _MainScreen();

  @override
  ConsumerState<_MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<_MainScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = ref.read(liveTvProvider.notifier);
      provider.loadCategories();
      provider.loadChannels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveTvProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV en vivo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(loginProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          const CategoriesScreen(),
          const Divider(height: 1),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const ChannelsScreen(),
        ],
      ),
    );
  }
}
