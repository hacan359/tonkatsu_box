import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../shared/models/profile.dart';
import '../database/migrations/migration_registry.dart';
import '../database/sqlite_health.dart';

/// Verdict on whether a data directory's database can be opened by this
/// build.
enum DataDirVerdict {
  /// Database is absent or opens cleanly with a supported schema.
  ok,

  /// Database schema is newer than this build can open.
  tooNew,

  /// Database fails the integrity check (e.g. a sync client delivered
  /// it half-written).
  corrupted,
}

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

  /// Folder under the data root holding collection hero images.
  static const String collectionsFolderName = 'collections';

  /// Folder (per profile) holding the on-disk image cache.
  static const String imageCacheFolderName = 'image_cache';

  static final Logger _log = Logger('StorageRoot');

  /// Test seam: path_provider's platform channel is unavailable in unit
  /// tests, so tests inject a temp-dir provider here.
  @visibleForTesting
  static Future<String> Function()? defaultPathProvider;

  /// Test seam: real SQLite IO never completes inside widget tests'
  /// FakeAsync zone, so widget tests stub the verdict here.
  @visibleForTesting
  static Future<DataDirVerdict> Function(String dir)? validateDataDirOverride;

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

  // Validation verdict is memoized per session: resolve() sits on hot
  // paths (every image load), while opening the DB read-only for
  // validation is only affordable once. setCustomDir/clearCustomDir
  // reset the memo; a process restart revalidates naturally.
  static String? _validatedCustomDir;
  static String? _rejectedCustomDir;

  /// Clears the per-session validation memo.
  @visibleForTesting
  static void resetSessionCache() {
    _validatedCustomDir = null;
    _rejectedCustomDir = null;
  }

  /// Resolves the effective data root.
  ///
  /// A configured-but-unusable custom directory falls back to the default
  /// location so the app still boots; [StorageRootResolution.fellBack]
  /// lets the UI surface that. Unusable covers a missing directory
  /// (unplugged drive, dead network share), an existing-but-emptied one
  /// (opening it would silently spawn a fresh database, which reads as
  /// data loss), and a database that fails [validateDataDir] — e.g. a
  /// sync client delivered a newer-schema or half-written file.
  static Future<StorageRootResolution> resolve() async {
    final String? custom = await customDir();
    if (custom == null) {
      return StorageRootResolution(path: await defaultPath());
    }
    if (custom == _validatedCustomDir) {
      return StorageRootResolution(path: custom, isCustom: true);
    }
    if (custom != _rejectedCustomDir) {
      if (hasData(custom) &&
          await validateDataDir(custom) == DataDirVerdict.ok) {
        _validatedCustomDir = custom;
        return StorageRootResolution(path: custom, isCustom: true);
      }
      _rejectedCustomDir = custom;
      _log.warning(
        'Custom storage dir is missing, empty or holds an unusable '
        'database, using default: $custom',
      );
    }
    return StorageRootResolution(
      path: await defaultPath(),
      fellBack: true,
    );
  }

  /// Database file the app would open for the data root [root],
  /// honouring the profile layout.
  static String activeDbPath(String root) {
    final File profilesFile = File(p.join(root, profilesFileName));
    if (profilesFile.existsSync()) {
      try {
        final ProfilesData data =
            ProfilesData.fromJsonString(profilesFile.readAsStringSync());
        return p.join(
          root,
          profilesFolderName,
          data.currentProfileId,
          dbFileName,
        );
      } on Exception catch (e) {
        _log.warning('Unreadable profiles.json under $root', e);
      }
    }
    return p.join(root, dbFileName);
  }

  /// Checks that the database [dir] would be opened with is usable:
  /// schema not newer than this build and `PRAGMA quick_check` clean.
  /// An absent database is [DataDirVerdict.ok] — a fresh one gets
  /// created on open.
  static Future<DataDirVerdict> validateDataDir(String dir) async {
    final Future<DataDirVerdict> Function(String dir)? override =
        validateDataDirOverride;
    if (override != null) return override(dir);

    final String dbPath = activeDbPath(dir);
    if (!File(dbPath).existsSync()) return DataDirVerdict.ok;

    try {
      final Database db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      try {
        final int version = await readUserVersion(db);
        if (version > MigrationRegistry.latestVersion) {
          _log.warning(
            'Database at $dbPath has schema $version, newer than '
            '${MigrationRegistry.latestVersion}',
          );
          return DataDirVerdict.tooNew;
        }

        if (!await quickCheckOk(db)) {
          _log.warning('quick_check failed for $dbPath');
          return DataDirVerdict.corrupted;
        }
        return DataDirVerdict.ok;
      } finally {
        await db.close();
      }
    } on Exception catch (e) {
      _log.warning('Database validation failed for $dbPath', e);
      return DataDirVerdict.corrupted;
    }
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
    resetSessionCache();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, path);
  }

  /// Removes the custom data root, returning to the default location.
  static Future<void> clearCustomDir() async {
    resetSessionCache();
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
  /// not initialised.
  ///
  /// When [includeImages] is set, the `collections` hero images and each
  /// profile's `image_cache` are copied too — a full offline mirror. By
  /// default images are skipped: the re-downloadable cover cache re-fetches
  /// on demand, so most folder moves need not haul it along.
  ///
  /// [flushDatabase] runs before any file is copied; pass
  /// `DatabaseService.checkpointWal` when the live database is open so
  /// the copied main file is complete.
  static Future<void> copyDataTo(
    String sourceDir,
    String targetDir, {
    Future<void> Function()? flushDatabase,
    bool includeImages = false,
  }) async {
    if (flushDatabase != null) {
      await flushDatabase();
    }
    await Directory(targetDir).create(recursive: true);

    if (includeImages) {
      // Hero images live at the data-root level, shared across profiles.
      await _copyTree(
        p.join(sourceDir, collectionsFolderName),
        p.join(targetDir, collectionsFolderName),
      );
    }

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
          if (includeImages) {
            await _copyTree(
              p.join(entity.path, imageCacheFolderName),
              p.join(targetProfileDir, imageCacheFolderName),
            );
          }
        }
      }
      return;
    }

    await _copyDbFiles(sourceDir, targetDir);
    if (includeImages) {
      await _copyTree(
        p.join(sourceDir, imageCacheFolderName),
        p.join(targetDir, imageCacheFolderName),
      );
    }
  }

  /// Recursively copies the tree at [fromDir] into [toDir]. A no-op when
  /// [fromDir] is absent, so callers need not pre-check optional folders.
  static Future<void> _copyTree(String fromDir, String toDir) async {
    final Directory src = Directory(fromDir);
    if (!src.existsSync()) return;
    await Directory(toDir).create(recursive: true);
    await for (final FileSystemEntity entity
        in src.list(recursive: true, followLinks: false)) {
      final String rel = p.relative(entity.path, from: fromDir);
      final String dest = p.join(toDir, rel);
      if (entity is Directory) {
        await Directory(dest).create(recursive: true);
      } else if (entity is File) {
        await Directory(p.dirname(dest)).create(recursive: true);
        await entity.copy(dest);
      }
    }
  }

  static Future<void> _copyDbFiles(String fromDir, String toDir) async {
    // `.bak` travels along: it may be the only good copy after a sync
    // the user regrets, and the restore flow looks for it next to the
    // active database.
    for (final String suffix in <String>['', '-wal', '-shm', '.bak']) {
      final File file = File(p.join(fromDir, '$dbFileName$suffix'));
      if (file.existsSync()) {
        await file.copy(p.join(toDir, '$dbFileName$suffix'));
      }
    }
  }
}
