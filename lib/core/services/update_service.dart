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

  /// Returns true if a newer version is available.
  static Future<bool> isUpdateAvailable() async {
    final local = await _localVersion();
    final remote = await checkLatestVersion();
    if (remote == null) return false;
    return _compareVersions(remote, local) > 0;
  }

  static Future<String> _localVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '1.0.0';
    }
  }

  /// Compare: returns >0 if v1 > v2.
  static int _compareVersions(String v1, String v2) {
    final parse = (String v) {
      final parts = v.replaceAll('v', '').split('.');
      return parts.map((e) => int.tryParse(e) ?? 0).toList();
    };
    final p1 = parse(v1);
    final p2 = parse(v2);
    for (int i = 0; i < 3; i++) {
      if (p1[i] > p2[i]) return 1;
      if (p1[i] < p2[i]) return -1;
    }
    return 0;
  }
}
