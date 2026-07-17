import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../api/models/xtream_account.dart';

/// Manages saved Xtream Accounts with Hive + SecureStorage.
class AccountStorage {
  static const _boxName = 'accounts';
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;

  AccountStorage({
    FlutterSecureStorage? secureStorage,
    Uuid? uuid,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _uuid = uuid ?? const Uuid();

  Box<Map>? _box;

  Future<Box<Map>> get box async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  /// Save a new account (password stored in secure storage).
  Future<XtreamAccount> saveAccount({
    required String name,
    required String server,
    required String username,
    required String password,
  }) async {
    final id = _uuid.v4();
    final account = XtreamAccount(id: id, name: name, server: server, username: username);

    final b = await box;
    await b.put(id, account.toJson());
    await _secureStorage.write(key: 'pass_$id', value: password);

    return account;
  }

  /// Update an existing account's name/server/username.
  Future<void> updateAccount(XtreamAccount account) async {
    final b = await box;
    await b.put(account.id, account.toJson());
  }

  /// Update password for an account.
  Future<void> updatePassword(String accountId, String password) async {
    await _secureStorage.write(key: 'pass_$accountId', value: password);
  }

  /// Get password for an account. Returns null if not found or corrupted.
  Future<String?> getPassword(String accountId) async {
    try {
      return await _secureStorage.read(key: 'pass_$accountId');
    } catch (e) {
      // BadPaddingError, KeyStoreException, etc. — key may have been
      // invalidated by OS update, app reinstall, or keystore reset.
      await _secureStorage.delete(key: 'pass_$accountId');
      return null;
    }
  }

  /// Load all saved accounts.
  Future<List<XtreamAccount>> loadAll() async {
    final b = await box;
    return b.values.map((e) => XtreamAccount.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Delete an account (including password).
  Future<void> deleteAccount(String accountId) async {
    final b = await box;
    await b.delete(accountId);
    await _secureStorage.delete(key: 'pass_$accountId');
  }

  /// Clear old localStorage (migration from single-account).
  static Future<void> migrateIfNeeded(AccountStorage storage) async {
    final secureStorage = const FlutterSecureStorage();
    final oldServer = await secureStorage.read(key: 'xtream_server');
    if (oldServer != null && oldServer.isNotEmpty) {
      final oldUsername = await secureStorage.read(key: 'xtream_username') ?? '';
      final oldPassword = await secureStorage.read(key: 'xtream_password') ?? '';
      // Save as named account
      await storage.saveAccount(
        name: oldUsername,
        server: oldServer,
        username: oldUsername,
        password: oldPassword,
      );
      // Clear old keys
      await secureStorage.delete(key: 'xtream_server');
      await secureStorage.delete(key: 'xtream_username');
      await secureStorage.delete(key: 'xtream_password');
    }
  }
}
