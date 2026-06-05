// Update checker: polls the GitHub Releases API for a newer version.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/providers/settings_provider.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.hasUpdate,
    this.releaseNotes,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final bool hasUpdate;

  /// Release notes in markdown.
  final String? releaseNotes;
}

/// Checks for updates via the GitHub Releases API.
class UpdateService {
  /// [currentVersionOverride] replaces `PackageInfo.fromPlatform()` in tests.
  UpdateService({
    required SharedPreferences prefs,
    required Dio dio,
    String? currentVersionOverride,
  })  : _prefs = prefs,
        _dio = dio,
        _currentVersionOverride = currentVersionOverride;

  // ignore: unused_field
  static final Logger _log = Logger('UpdateService');

  final SharedPreferences _prefs;
  final Dio _dio;
  final String? _currentVersionOverride;

  static const String _repoOwner = 'hacan359';
  static const String _repoName = 'tonkatsu_box';
  static const String _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static const String _lastCheckKey = 'update_last_check';
  static const String _latestVersionKey = 'update_latest_version';
  static const String _releaseUrlKey = 'update_release_url';

  static const int _throttleDurationMs = 86400000; // 24h

  /// Returns `null` on network error or if the check failed.
  /// Throttled to once per 24h; repeat calls return the cached result.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final String currentVersion;
      if (_currentVersionOverride != null) {
        currentVersion = _currentVersionOverride;
      } else {
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;
      }

      final int? lastCheck = _prefs.getInt(_lastCheckKey);
      final int now = DateTime.now().millisecondsSinceEpoch;

      if (lastCheck != null && (now - lastCheck) < _throttleDurationMs) {
        return _getCachedResult(currentVersion);
      }

      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(
        _apiUrl,
        options: Options(
          headers: <String, String>{
            'Accept': 'application/vnd.github.v3+json',
          },
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final Map<String, dynamic> data = response.data!;
      final String tagName = data['tag_name'] as String;
      final String latestVersion = tagName.replaceFirst('v', '');
      final String releaseUrl = data['html_url'] as String;
      final String? body = data['body'] as String?;

      await _prefs.setInt(_lastCheckKey, now);
      await _prefs.setString(_latestVersionKey, latestVersion);
      await _prefs.setString(_releaseUrlKey, releaseUrl);

      final bool hasUpdate = isNewer(latestVersion, currentVersion);

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: releaseUrl,
        hasUpdate: hasUpdate,
        releaseNotes: body,
      );
    } on DioException {
      return null;
    } on Exception {
      return null;
    }
  }

  UpdateInfo? _getCachedResult(String currentVersion) {
    final String? savedVersion = _prefs.getString(_latestVersionKey);
    final String? savedUrl = _prefs.getString(_releaseUrlKey);

    if (savedVersion != null && savedUrl != null) {
      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: savedVersion,
        releaseUrl: savedUrl,
        hasUpdate: isNewer(savedVersion, currentVersion),
      );
    }
    return null;
  }

  /// Compares semver: `true` if [latest] > [current].
  bool isNewer(String latest, String current) {
    final List<int> latestParts = _parseSemver(latest);
    final List<int> currentParts = _parseSemver(current);

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  List<int> _parseSemver(String version) {
    final List<String> parts = version.split('.');
    return List<int>.generate(
      3,
      (int i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    );
  }
}

final Provider<UpdateService> updateServiceProvider =
    Provider<UpdateService>((Ref ref) {
  return UpdateService(
    prefs: ref.watch(sharedPreferencesProvider),
    dio: Dio(),
  );
});

/// Checks for an update once, on first read.
final FutureProvider<UpdateInfo?> updateCheckProvider =
    FutureProvider<UpdateInfo?>((Ref ref) {
  return ref.read(updateServiceProvider).checkForUpdate();
});
