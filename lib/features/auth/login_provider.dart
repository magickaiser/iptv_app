import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/xtream_client.dart';
import '../../core/storage/local_storage.dart';

/// Auth states.
enum AuthState { initial, loading, authenticated, error }

/// Manages authentication state.
class LoginProvider extends StateNotifier<AuthState> {
  final LocalStorage _storage;

  XtreamClient? _client;
  String? _errorMessage;

  LoginProvider(this._storage) : super(AuthState.initial);

  XtreamClient? get client => _client;
  String? get errorMessage => _errorMessage;

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
    await _storage.clearCredentials();
    state = AuthState.initial;
  }
}

/// Provider instance.
final loginProvider =
    StateNotifierProvider<LoginProvider, AuthState>((ref) {
  final storage = LocalStorage();
  return LoginProvider(storage);
});
