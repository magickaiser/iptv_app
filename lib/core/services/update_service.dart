import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Checks GitHub for latest FrameTV release.
class UpdateService {
  static const _repoOwner = 'magickaiser';
  static const _repoName = 'iptv_app';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Returns (localVersion, latestVersion, apkDownloadUrl). Throws on HTTP error.
  static Future<({String local, String? remote, String? apkUrl})> check() async {
    final local = await _localVersion();
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'User-Agent': 'FrameTV/1.0'},
    ));
    final response = await dio.get(_apiUrl);
    final data = response.data as Map<String, dynamic>;
    final remote = data['tag_name'] as String?;

    // Extract the APK download URL from the release assets
    String? apkUrl;
    final assets = data['assets'] as List? ?? [];
    for (final a in assets) {
      final name = a['name'] as String? ?? '';
      if (name.endsWith('.apk')) {
        apkUrl = a['browser_download_url'] as String?;
        break;
      }
    }

    return (local: local, remote: remote, apkUrl: apkUrl);
  }

  /// Returns true if remote version is newer than local.
  static bool isNewer(String remote, String local) {
    return _compareVersions(remote, local) > 0;
  }

  /// Download the APK from a direct URL with progress callback.
  static Future<String> downloadApk(
    String apkUrl,
    String version,
    void Function(int received, int total) onProgress,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/frametv-$version.apk';

    final dio = Dio(BaseOptions(
      headers: {'User-Agent': 'FrameTV/1.0'},
    ));
    await dio.download(apkUrl, path, onReceiveProgress: onProgress);
    return path;
  }

  static Future<String> _localVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '1.0.0';
    }
  }

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
