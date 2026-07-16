import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Checks GitHub for latest FrameTV release.
class UpdateService {
  static const _repoOwner = 'magickaiser';
  static const _repoName = 'iptv_app';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Returns (localVersion, latestVersion). Throws on HTTP error.
  static Future<({String local, String? remote})> check() async {
    final local = await _localVersion();
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'User-Agent': 'FrameTV/1.0'},
    ));
    final response = await dio.get(_apiUrl);
    final data = response.data as Map<String, dynamic>;
    final remote = data['tag_name'] as String?;
    return (local: local, remote: remote);
  }

  /// Returns true if remote version is newer than local.
  static bool isNewer(String remote, String local) {
    return _compareVersions(remote, local) > 0;
  }

  /// Get the download URL for the APK in a specific release.
  static Future<String?> getApkUrl(String version) async {
    final dio = Dio(BaseOptions(
      headers: {'User-Agent': 'FrameTV/1.0'},
    ));
    final url = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases/tags/$version';
    final resp = await dio.get(url);
    final assets = resp.data['assets'] as List? ?? [];
    for (final a in assets) {
      final name = a['name'] as String? ?? '';
      if (name.endsWith('.apk')) {
        return a['browser_download_url'] as String?;
      }
    }
    return null;
  }

  /// Download the APK from GitHub with progress callback.
  static Future<String> downloadApk(
    String version,
    void Function(int received, int total) onProgress,
  ) async {
    final apkUrl = await getApkUrl(version);
    if (apkUrl == null) throw Exception('No se encontró el APK');

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
