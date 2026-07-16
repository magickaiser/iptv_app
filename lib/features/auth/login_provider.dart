import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/xtream_client.dart';
import '../../core/storage/local_storage.dart';

/// Auth states.
enum AuthState { initial, loading, authenticated, error }

/// Holds info about saved credentials for quick re-login.
class SavedCredentialsInfo {
  final String serverUrl;
  final String username;

  const SavedCredentialsInfo({
    required this.serverUrl,
    required this.username,
  });
}

/// Manages authentication state.
class LoginProvider extends StateNotifier<AuthState> {
  final LocalStorage _storage;

  XtreamClient? _client;
  String? _errorMessage;
  SavedCredentialsInfo? _savedInfo;

  LoginProvider(this._storage) : super(AuthState.initial);

  XtreamClient? get client => _client;
  String? get errorMessage => _errorMessage;
  SavedCredentialsInfo? get savedInfo => _savedInfo;

  /// Auto-login with stored credentials (called at app start).
  Future<void> tryAutoLogin() async {
    _savedInfo = await _loadSavedInfo();
    if (_savedInfo == null) return; // No saved credentials

    state = AuthState.loading;
    _errorMessage = null;

    try {
      final creds = await _storage.loadCredentials();
      if (creds == null) {
        state = AuthState.initial;
        return;
      }

      final client = XtreamClient(
        serverUrl: creds['server']!,
        username: creds['username']!,
        password: creds['password']!,
        dio: Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 5),
        )),
      );

      await client.authenticate();
      _client = client;
      state = AuthState.authenticated;
    } catch (_) {
      // Silent fail: user will see login screen normally
      state = AuthState.initial;
    }
  }

  /// Attempt to login with Xtream Codes credentials.
  Future<void> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    state = AuthState.loading;
    _errorMessage = null;

    try {
      final client = XtreamClient(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );

      await client.authenticate();

      _client = client;
      _errorMessage = null;

      // Save credentials securely.
      await _storage.saveCredentials(
        server: serverUrl,
        username: username,
        password: password,
      );

      _savedInfo = SavedCredentialsInfo(serverUrl: serverUrl, username: username);
      state = AuthState.authenticated;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = AuthState.error;
    }
  }

  /// Logout: clear client and credentials.
  Future<void> logout() async {
    _client = null;
    _errorMessage = null;
    _savedInfo = null;
    await _storage.clearCredentials();
    state = AuthState.initial;
  }

  Future<SavedCredentialsInfo?> _loadSavedInfo() async {
    try {
      final creds = await _storage.loadCredentials();
      if (creds == null) return null;
      return SavedCredentialsInfo(
        serverUrl: creds['server']!,
        username: creds['username']!,
      );
    } catch (_) {
      // Plugin not available (e.g., in test environment)
      return null;
    }
  }
}

/// Provider instance.
final loginProvider =
    StateNotifierProvider<LoginProvider, AuthState>((ref) {
  final storage = LocalStorage();
  return LoginProvider(storage);
});
