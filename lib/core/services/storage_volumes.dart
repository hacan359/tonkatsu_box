import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A mounted storage volume usable as a folder-picker root.
class StorageVolume {
  const StorageVolume({required this.path, required this.isPrimary});

  final String path;

  /// Whether this is the built-in internal storage.
  final bool isPrimary;
}

/// Detects mounted storage volumes on Android.
class StorageVolumes {
  StorageVolumes._();

  static final Logger _log = Logger('StorageVolumes');

  /// Test seam: the OS query for per-volume app-specific directories.
  /// Each entry looks like `<volume>/Android/data/<pkg>/files`.
  @visibleForTesting
  static Future<List<Directory>?> Function() externalDirsProvider =
      () => getExternalStorageDirectories();

  /// Canonical primary (internal) storage path.
  static String get primaryPath => p.join('/storage', 'emulated', '0');

  /// Roots derive from [getExternalStorageDirectories] minus the app suffix —
  /// listing `/storage` is refused on Android 11+. USB OTG is SAF-only.
  static Future<List<StorageVolume>> detect() async {
    List<Directory>? appDirs;
    try {
      appDirs = await externalDirsProvider();
    } on Exception catch (e) {
      _log.warning('Failed to query external storage directories', e);
    }

    final List<StorageVolume> volumes = <StorageVolume>[];
    if (appDirs != null) {
      for (int i = 0; i < appDirs.length; i++) {
        final String? root = _volumeRoot(appDirs[i].path);
        if (root == null) continue;
        if (volumes.any((StorageVolume v) => v.path == root)) continue;
        volumes.add(StorageVolume(path: root, isPrimary: i == 0));
      }
    }

    // Fallback to canonical internal storage when the query yields nothing.
    if (volumes.isEmpty && Directory(primaryPath).existsSync()) {
      volumes.add(StorageVolume(path: primaryPath, isPrimary: true));
    }
    return volumes;
  }

  /// `/storage/XXXX/Android/data/<pkg>/files` → `/storage/XXXX`.
  static String? _volumeRoot(String appSpecificDir) {
    const String marker = '/Android/';
    final int idx = appSpecificDir.indexOf(marker);
    if (idx <= 0) return null;
    return appSpecificDir.substring(0, idx);
  }
}
