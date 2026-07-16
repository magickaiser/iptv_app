import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/login_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/live_tv/categories_screen.dart';
import 'features/live_tv/channels_screen.dart';
import 'features/live_tv/live_tv_provider.dart';
import 'core/theme/mobile_theme.dart';

/// Root widget that adapts to auth state: login vs main app.
class IptvApp extends ConsumerStatefulWidget {
  const IptvApp({super.key});

  @override
  ConsumerState<IptvApp> createState() => _IptvAppState();
}

class _IptvAppState extends ConsumerState<IptvApp> {
  @override
  void initState() {
    super.initState();
    // Auto-login with saved credentials
    Future.microtask(() => ref.read(loginProvider.notifier).tryAutoLogin());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(loginProvider);

    return MaterialApp(
      title: 'FrameTV',
      theme: MobileTheme.theme,
      debugShowCheckedModeBanner: false,
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    switch (authState) {
      case AuthState.initial:
        // Show login, but if we have saved credentials (still loading info), show splash
        final hasSaved = ref.read(loginProvider.notifier).savedInfo != null;
        if (hasSaved) {
          // Auto-login in progress but already checking
          return const _SplashScreen();
        }
        return const LoginScreen();

      case AuthState.loading:
        return const _SplashScreen();

      case AuthState.authenticated:
        return const _MainScreen();

      case AuthState.error:
        return const LoginScreen();
    }
  }
}

/// Loading splash shown while auto-login tries to connect.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            Text(
              'Conectando...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
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
