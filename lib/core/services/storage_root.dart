import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of resolving the data root.
class StorageRootResolution {
  /// Creates a [StorageRootResolution].
  const StorageRootResolution({
    required this.path,
    this.isCustom = false,
    this.fellBack = false,
  });

  /// Directory that holds `profiles.json`, profile folders and the database.
  final String path;

  /// Whether [path] is the user-selected custom directory.
  final bool isCustom;

  /// Whether a custom directory was configured but inaccessible,
  /// so [path] is the default location instead.
  final bool fellBack;
}

/// Single source of truth for the app data root.
///
/// [DatabaseService], `ProfileService` and `ImageCacheService` all resolve
/// their base directory through here, so a user-selected custom directory
/// moves the whole data tree (profiles.json, per-profile databases and
/// image caches) consistently.
class StorageRoot {
  StorageRoot._();

  /// SharedPreferences key holding the custom data root directory.
  static const String prefsKey = 'custom_storage_dir';

  /// Database file name inside the data root / a profile folder.
  static const String dbFileName = 'tonkatsu_box.db';

  /// Profile metadata file at the data root.
  static const String profilesFileName = 'profiles.json';

  /// Folder under the data root holding per-profile subfolders.
  static const String profilesFolderName = 'profiles';

  static final Logger _log = Logger('StorageRoot');

  /// Test seam: path_provider's platform channel is unavailable in unit
  /// tests, so tests inject a temp-dir provider here.
  @visibleForTesting
  static Future<String> Function()? defaultPathProvider;

  /// Default data root when no custom directory is configured.
  static Future<String> defaultPath() async {
    final Future<String> Function()? override = defaultPathProvider;
    if (override != null) return override();

    // AppSupport rather than Documents: Documents may sit under OneDrive,
    // which blocks file creation (PathAccessException).
    final Directory appDir = await getApplicationSupportDirectory();
    const String folderName =
        kReleaseMode ? 'tonkatsu_box' : 'tonkatsu_box_dev';
    return p.join(appDir.path, folderName);
  }

  /// Configured custom directory, or `null` when unset.
  static Future<String?> customDir() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(prefsKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Resolves the effective data root.
  ///
  /// A configured-but-unusable custom directory falls back to the default
  /// location so the app still boots; [StorageRootResolution.fellBack]
  /// lets the UI surface that. Unusable covers both a missing directory
  /// (unplugged drive, dead network share) and an existing-but-emptied
  /// one: opening the latter would silently spawn a fresh database,
  /// which reads as data loss.
  static Future<StorageRootResolution> resolve() async {
    final String? custom = await customDir();
    if (custom != null) {
      if (hasData(custom)) {
        return StorageRootResolution(path: custom, isCustom: true);
      }
      _log.warning(
        'Custom storage dir is inaccessible or empty, using default: '
        '$custom',
      );
      return StorageRootResolution(
        path: await defaultPath(),
        fellBack: true,
      );
    }
    return StorageRootResolution(path: await defaultPath());
  }

  /// Whether [dir] already holds app data: a database file or a profile
  /// set in the expected layout.
  static bool hasData(String dir) {
    if (!Directory(dir).existsSync()) return false;
    return File(p.join(dir, profilesFileName)).existsSync() ||
        File(p.join(dir, dbFileName)).existsSync();
  }

  /// Saves [path] as the custom data root.
  static Future<void> setCustomDir(String path) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, path);
  }

  /// Removes the custom data root, returning to the default location.
  static Future<void> clearCustomDir() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }

  /// Probes write access by creating and deleting a temp file in [dir].
  static Future<bool> isWritable(String dir) async {
    final File probe =
        File(p.join(dir, '.tonkatsu_write_probe'));
    try {
      await probe.writeAsString('probe');
      await probe.delete();
      return true;
    } on FileSystemException catch (e) {
      _log.warning('Write probe failed for $dir', e);
      return false;
    }
  }

  /// Copies database data from [sourceDir] into [targetDir]:
  /// `profiles.json` plus each profile's database (with `-wal`/`-shm`
  /// sidecars), or the single root database when the profile system is
  /// not initialised. Image caches are intentionally skipped — they
  /// re-download on demand.
  ///
  /// The caller must checkpoint the open database first (see
  /// `DatabaseService.checkpointWal`) so the copied main file is complete.
  static Future<void> copyDataTo(String sourceDir, String targetDir) async {
    await Directory(targetDir).create(recursive: true);

    final File profilesFile = File(p.join(sourceDir, profilesFileName));
    if (profilesFile.existsSync()) {
      await profilesFile.copy(p.join(targetDir, profilesFileName));

      final Directory profilesDir =
          Directory(p.join(sourceDir, profilesFolderName));
      if (profilesDir.existsSync()) {
        await for (final FileSystemEntity entity in profilesDir.list()) {
          if (entity is! Directory) continue;
          final String profileId = p.basename(entity.path);
          final String targetProfileDir =
              p.join(targetDir, profilesFolderName, profileId);
          await Directory(targetProfileDir).create(recursive: true);
          await _copyDbFiles(entity.path, targetProfileDir);
        }
      }
      return;
    }

    await _copyDbFiles(sourceDir, targetDir);
  }

  static Future<void> _copyDbFiles(String fromDir, String toDir) async {
    for (final String suffix in <String>['', '-wal', '-shm']) {
      final File file = File(p.join(fromDir, '$dbFileName$suffix'));
      if (file.existsSync()) {
        await file.copy(p.join(toDir, '$dbFileName$suffix'));
      }
    }
  }
}
