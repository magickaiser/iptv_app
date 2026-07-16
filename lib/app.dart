import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/login_provider.dart';
import 'features/auth/account_selection_screen.dart';
import 'features/live_tv/categories_screen.dart';
import 'features/live_tv/channels_screen.dart';
import 'features/live_tv/live_tv_provider.dart';
import 'core/theme/mobile_theme.dart';

/// Root widget.
class IptvApp extends ConsumerStatefulWidget {
  const IptvApp({super.key});

  @override
  ConsumerState<IptvApp> createState() => _IptvAppState();
}

class _IptvAppState extends ConsumerState<IptvApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(loginProvider.notifier).loadAccounts());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(loginProvider);

    return MaterialApp(
      title: 'FrameTV',
      theme: MobileTheme.theme,
      debugShowCheckedModeBanner: false,
      home: authState == AuthState.authenticated
          ? const _MainScreen()
          : const AccountSelectionScreen(),
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
    final account = ref.read(loginProvider.notifier).currentAccount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV en vivo'),
        actions: [
          if (account != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(account.name, style: const TextStyle(fontSize: 13)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar cuenta',
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
              child: Text(state.error!, style: const TextStyle(color: Colors.red)),
            ),
          const ChannelsScreen(),
        ],
      ),
    );
  }
}
