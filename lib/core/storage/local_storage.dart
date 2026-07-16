import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Manages local persistence: credentials (secure) and cache (Hive).
class LocalStorage {
  static const _serverKey = 'xtream_server';
  static const _usernameKey = 'xtream_username';
  static const _passwordKey = 'xtream_password';

  final FlutterSecureStorage _secureStorage;

  LocalStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // --- Secure Credentials ---

  Future<void> saveCredentials({
    required String server,
    required String username,
    required String password,
  }) async {
    await _secureStorage.write(key: _serverKey, value: server);
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  Future<Map<String, String>?> loadCredentials() async {
    final server = await _secureStorage.read(key: _serverKey);
    final username = await _secureStorage.read(key: _usernameKey);
    final password = await _secureStorage.read(key: _passwordKey);

    if (server == null || username == null || password == null) return null;
    return {'server': server, 'username': username, 'password': password};
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _serverKey);
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  // --- Hive Cache ---

  static Future<void> init() async {
    await Hive.initFlutter();
    // Boxes will be opened lazily by providers
  }

  /// Opens (or returns already open) a Hive box.
  static Future<Box<T>> openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return Hive.openBox<T>(name);
  }
}
