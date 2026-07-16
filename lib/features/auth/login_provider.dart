import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/xtream_client.dart';
import '../../core/api/models/xtream_account.dart';
import '../../core/storage/account_storage.dart';

/// Auth states.
enum AuthState { initial, loading, authenticated, error }

/// Manages authentication with multi-account support.
class LoginProvider extends StateNotifier<AuthState> {
  final AccountStorage _storage;

  XtreamClient? _client;
  XtreamAccount? _currentAccount;
  String? _errorMessage;
  List<XtreamAccount> _accounts = [];

  LoginProvider(this._storage) : super(AuthState.initial);

  XtreamClient? get client => _client;
  XtreamAccount? get currentAccount => _currentAccount;
  String? get errorMessage => _errorMessage;
  List<XtreamAccount> get accounts => _accounts;

  /// Load saved accounts. Called at app start.
  Future<void> loadAccounts() async {
    _accounts = await _storage.loadAll();
  }

  /// Add a new account and save credentials.
  Future<void> addAccount({
    required String name,
    required String server,
    required String username,
    required String password,
  }) async {
    state = AuthState.loading;
    _errorMessage = null;

    try {
      final client = XtreamClient(
        serverUrl: server,
        username: username,
        password: password,
      );
      await client.authenticate();

      final account = await _storage.saveAccount(
        name: name,
        server: server,
        username: username,
        password: password,
      );

      _accounts.add(account);
      _client = client;
      _currentAccount = account;
      state = AuthState.authenticated;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = AuthState.error;
    }
  }

  /// Connect with an existing saved account.
  Future<void> connectAccount(XtreamAccount account) async {
    state = AuthState.loading;
    _errorMessage = null;

    try {
      final password = await _storage.getPassword(account.id);
      if (password == null) {
        throw Exception('Contraseña no encontrada');
      }

      final client = XtreamClient(
        serverUrl: account.server,
        username: account.username,
        password: password,
        dio: Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 8),
        )),
      );

      await client.authenticate();
      _client = client;
      _currentAccount = account;
      state = AuthState.authenticated;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = AuthState.error;
    }
  }

  /// Delete an account.
  Future<void> deleteAccount(String id) async {
    await _storage.deleteAccount(id);
    _accounts.removeWhere((a) => a.id == id);
    if (_currentAccount?.id == id) {
      _currentAccount = null;
      _client = null;
    }
    // Notify UI to refresh
    state = AuthState.initial;
  }

  /// Logout: disconnect but keep accounts.
  void logout() {
    _client = null;
    _currentAccount = null;
    _errorMessage = null;
    state = AuthState.initial;
  }
}

/// Provider instance.
final loginProvider =
    StateNotifierProvider<LoginProvider, AuthState>((ref) {
  final storage = AccountStorage();
  return LoginProvider(storage);
});
