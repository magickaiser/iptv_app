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
  final void Function(List<XtreamAccount>) _onAccountsChanged;

  XtreamClient? _client;
  XtreamAccount? _currentAccount;
  String? _errorMessage;
  List<XtreamAccount> _accounts = [];

  LoginProvider(this._storage, this._onAccountsChanged) : super(AuthState.initial);

  XtreamClient? get client => _client;
  XtreamAccount? get currentAccount => _currentAccount;
  String? get errorMessage => _errorMessage;
  List<XtreamAccount> get accounts => _accounts;

  void _refreshAccounts() => _onAccountsChanged(List.unmodifiable(_accounts));

  /// Load saved accounts. Called at app start.
  Future<void> loadAccounts() async {
    _accounts = await _storage.loadAll();
    _refreshAccounts();
  }

  /// Add a new account and save credentials.
  /// Saves FIRST, then authenticates. Account persists even if auth fails.
  Future<void> addAccount({
    required String name,
    required String server,
    required String username,
    required String password,
  }) async {
    state = AuthState.loading;
    _errorMessage = null;

    try {
      // Always save credentials first (so they persist even if server is down)
      final account = await _storage.saveAccount(
        name: name,
        server: server,
        username: username,
        password: password,
      );
      _accounts.add(account);
      _refreshAccounts();

      // Now try to authenticate
      final client = XtreamClient(
        serverUrl: server,
        username: username,
        password: password,
      );
      await client.authenticate();

      _client = client;
      _currentAccount = account;
      state = AuthState.authenticated;
    } catch (e) {
      _errorMessage = 'Cuenta guardada. ${e.toString().replaceFirst("Exception: ", "")}';
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

  /// Update an existing account's data.
  Future<void> updateAccount(XtreamAccount updated, String? newPassword) async {
    await _storage.updateAccount(updated);
    if (newPassword != null && newPassword.isNotEmpty) {
      await _storage.updatePassword(updated.id, newPassword);
    }
    final index = _accounts.indexWhere((a) => a.id == updated.id);
    if (index != -1) _accounts[index] = updated;
    _refreshAccounts();
  }

  /// Delete an account.
  Future<void> deleteAccount(String id) async {
    await _storage.deleteAccount(id);
    _accounts.removeWhere((a) => a.id == id);
    if (_currentAccount?.id == id) {
      _currentAccount = null;
      _client = null;
    }
    _refreshAccounts();
  }

  /// Logout: disconnect but keep accounts.
  void logout() {
    _client = null;
    _currentAccount = null;
    _errorMessage = null;
    state = AuthState.initial;
  }

  /// Clear any stale error state. Call before showing login UI.
  void clearError() {
    _errorMessage = null;
    if (state == AuthState.error) {
      state = AuthState.initial;
    }
  }
}

/// Provider instance.
final loginProvider =
    StateNotifierProvider<LoginProvider, AuthState>((ref) {
  final storage = AccountStorage();
  return LoginProvider(storage, (accounts) {
    ref.read(accountsProvider.notifier).state = accounts;
  });
});

/// Reactive list of saved accounts.
final accountsProvider = StateProvider<List<XtreamAccount>>((ref) => []);
