import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Checks GitHub for latest FrameTV release.
class UpdateService {
  static const _repoOwner = 'magickaiser';
  static const _repoName = 'iptv_app';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Returns the latest release version tag (e.g., "v1.0.6") or null.
  static Future<String?> checkLatestVersion() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.get(_apiUrl);
      final data = response.data as Map<String, dynamic>;
      return data['tag_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Returns the local app version.
  static Future<String> getLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '1.0.0';
    }
  }

  /// Returns true if a newer version is available.
  static Future<bool> isUpdateAvailable() async {
    final local = await getLocalVersion();
    final remote = await checkLatestVersion();
    if (remote == null) return false;
    return _compareVersions(remote, local) > 0;
  }

  /// Compare: returns >0 if v1 > v2.
  static int _compareVersions(String v1, String v2) {
    int parse(String v, int i) {
      final parts = v.replaceAll('v', '').split('.');
      return i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0;
    }
    for (int i = 0; i < 3; i++) {
      final a = parse(v1, i);
      final b = parse(v2, i);
      if (a > b) return 1;
      if (a < b) return -1;
    }
    return 0;
  }
}
