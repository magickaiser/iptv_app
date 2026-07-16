import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_provider.dart';

/// Login screen for Xtream Codes credentials.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _prefillSavedCredentials();
  }

  void _prefillSavedCredentials() {
    // Pre-fill from saved credentials so user can just re-login
    final info = ref.read(loginProvider.notifier).savedInfo;
    if (info != null) {
      _serverController.text = info.serverUrl;
      _usernameController.text = info.username;
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final server = _serverController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (server.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    await ref.read(loginProvider.notifier).login(
          serverUrl: server,
          username: username,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final savedInfo = ref.read(loginProvider.notifier).savedInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('FrameTV')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.live_tv, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Inicia sesión',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Introduce tus credenciales Xtream Codes',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Quick login button (if credentials are saved)
                if (savedInfo != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person, size: 20),
                      label: Text('Reanudar sesión como ${savedInfo.username}'),
                      onPressed: state == AuthState.loading ? null : _login,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o introduce nuevos datos',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Server URL
                TextField(
                  controller: _serverController,
                  decoration: const InputDecoration(
                    labelText: 'URL del servidor',
                    hintText: 'http://example.com:8080',
                    prefixIcon: Icon(Icons.dns),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                // Username
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed:
                        state == AuthState.loading ? null : _login,
                    child: state == AuthState.loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Conectar', style: TextStyle(fontSize: 16)),
                  ),
                ),

                // Error message
                if (state == AuthState.error) ...[
                  const SizedBox(height: 16),
                  Container(
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
                            ref.read(loginProvider.notifier).errorMessage ??
                                'Error desconocido',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
