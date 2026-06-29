import 'dart:io';

import 'package:archive/archive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../shared/constants/platform_features.dart';
import '../../shared/models/sync_manifest.dart';
import '../database/database_service.dart';
import '../database/migrations/migration_registry.dart';
import '../database/sqlite_health.dart';
import 'image_cache_service.dart';
import 'storage_root.dart';

final Provider<DbSyncService> dbSyncServiceProvider =
    Provider<DbSyncService>((Ref ref) {
  return DbSyncService(database: ref.watch(databaseServiceProvider));
});

/// Device identity stamped into a snapshot manifest.
class SyncDeviceMeta {
  /// Creates a [SyncDeviceMeta].
  const SyncDeviceMeta({required this.deviceName, required this.appVersion});

  /// Human-readable device name.
  final String deviceName;

  /// App version string.
  final String appVersion;
}

/// Pre-flight verdict on a snapshot found in the sync folder.
class SyncSnapshotInfo {
  /// Creates a [SyncSnapshotInfo].
  const SyncSnapshotInfo({
    required this.exists,
    this.manifest,
    this.schemaVersion = 0,
    this.integrityOk = false,
    this.tooNew = false,
  });

  /// Whether a snapshot file is present in the folder.
  final bool exists;

  /// Manifest contents; `null` when missing or malformed.
  final SyncManifest? manifest;

  /// `PRAGMA user_version` read from the snapshot itself.
  final int schemaVersion;

  /// Whether `PRAGMA quick_check` passed — guards against a snapshot a
  /// cloud client delivered half-written.
  final bool integrityOk;

  /// Snapshot schema is newer than this build can open.
  final bool tooNew;

  /// Snapshot can be safely received.
  bool get receivable => exists && integrityOk && !tooNew;
}

/// Transport-agnostic snapshot engine for whole-database transfer.
///
/// No merge by design: a consistent snapshot of the current profile's
/// database is written into a directory ("send"), validated
/// ("inspect") and swapped in place of the live database ("receive").
/// A transport (LAN sync) moves the snapshot directory contents
/// between devices.
class DbSyncService {
  /// Creates a [DbSyncService].
  DbSyncService({
    required DatabaseService database,
    Future<SyncDeviceMeta> Function()? metaProvider,
  })  : _database = database,
        _metaProvider = metaProvider;

  /// Snapshot file name inside the sync folder.
  static const String snapshotFileName = 'xerabora-sync.db';

  /// Manifest file name inside the sync folder.
  static const String manifestFileName = 'xerabora-sync.json';

  /// SharedPreferences keys for the last exchange timestamps.
  static const String prefsLastSentKey = 'sync_last_sent_at';
  static const String prefsLastReceivedKey = 'sync_last_received_at';

  static final Logger _log = Logger('DbSyncService');

  final DatabaseService _database;
  final Future<SyncDeviceMeta> Function()? _metaProvider;

  /// Modification time of the backup next to the active database, or
  /// `null` when there is none. Resolves the path without opening the
  /// database so it is safe on any screen.
  Future<DateTime?> backupTimestamp() async {
    final StorageRootResolution root = await StorageRoot.resolve();
    final File bak = File('${StorageRoot.activeDbPath(root.path)}.bak');
    if (!bak.existsSync()) return null;
    return bak.lastModifiedSync();
  }

  /// Swaps the live database with its `.bak` neighbour.
  ///
  /// The replaced database becomes the new backup, so restoring twice
  /// undoes itself. The caller must restart the app afterwards.
  ///
  /// Throws [StateError] when no backup exists or it fails validation.
  Future<void> restoreBackup() async {
    final Database db = await _database.database;
    final String dbPath = db.path;
    final File bak = File('$dbPath.bak');
    if (!bak.existsSync()) {
      throw StateError('No backup next to $dbPath');
    }

    Database? probe;
    try {
      probe = await databaseFactory.openDatabase(
        bak.path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      if (await readUserVersion(probe) > MigrationRegistry.latestVersion ||
          !await quickCheckOk(probe)) {
        throw StateError('Backup failed validation');
      }
    } on DatabaseException catch (e) {
      throw StateError('Backup failed validation: $e');
    } finally {
      await probe?.close();
    }

    await _database.checkpointWal();
    await _database.close();
    for (final String suffix in <String>['-wal', '-shm']) {
      final File sidecar = File('$dbPath$suffix');
      if (sidecar.existsSync()) {
        await sidecar.delete();
      }
    }
    final String swapPath = '$dbPath.swap';
    await File(dbPath).rename(swapPath);
    await bak.rename(dbPath);
    await File(swapPath).rename('$dbPath.bak');
    _log.info('Backup restored into $dbPath');
  }

  bool? _vacuumIntoSupported;

  /// `VACUUM INTO` needs SQLite 3.27+; probing the version up front
  /// avoids tripping a native `near "INTO": syntax error` log line on
  /// older firmwares.
  Future<bool> _supportsVacuumInto(Database db) async {
    final bool? cached = _vacuumIntoSupported;
    if (cached != null) return cached;

    final List<Map<String, Object?>> rows =
        await db.rawQuery('SELECT sqlite_version() AS v');
    final String version =
        rows.isNotEmpty ? rows.first.values.first as String? ?? '0' : '0';
    final List<int> parts = version
        .split('.')
        .map((String part) => int.tryParse(part) ?? 0)
        .toList();
    final int major = parts.isNotEmpty ? parts[0] : 0;
    final int minor = parts.length > 1 ? parts[1] : 0;
    final bool supported = major > 3 || (major == 3 && minor >= 27);
    if (!supported) {
      _log.info('SQLite $version: VACUUM INTO unavailable, '
          'snapshots fall back to file copy');
    }
    _vacuumIntoSupported = supported;
    return supported;
  }

  /// Timestamp of the last successful send, or `null`.
  Future<DateTime?> lastSentAt() => _readTimestamp(prefsLastSentKey);

  /// Timestamp of the last successful receive, or `null`.
  Future<DateTime?> lastReceivedAt() => _readTimestamp(prefsLastReceivedKey);

  /// Writes a consistent snapshot of the live database plus a manifest
  /// into [folder] and returns the manifest.
  ///
  /// `VACUUM INTO` snapshots an open database atomically, so no WAL
  /// handling is needed; the temp-then-rename dance keeps a concurrently
  /// syncing cloud client from ever seeing a half-written snapshot under
  /// the final name.
  Future<SyncManifest> sendSnapshot(String folder, {String? profileName}) async {
    final Database db = await _database.database;

    final String snapshotPath = p.join(folder, snapshotFileName);
    final String tmpPath = '$snapshotPath.tmp';
    final File tmpFile = File(tmpPath);
    if (tmpFile.existsSync()) {
      await tmpFile.delete();
    }

    if (await _supportsVacuumInto(db)) {
      final String escaped = tmpPath.replaceAll("'", "''");
      await db.execute("VACUUM INTO '$escaped'");
    } else {
      // Old firmwares ship SQLite < 3.27 without VACUUM INTO (seen on
      // EMUI 10). Checkpoint empties the WAL into the main file, after
      // which a plain copy is consistent as long as nothing writes
      // concurrently — and the user is sitting on the sync screen. The
      // receiving side's quick_check guards the remaining risk.
      await _database.checkpointWal();
      await File(db.path).copy(tmpPath);
    }
    await _replace(tmpPath, snapshotPath);

    final SyncManifest manifest = await buildManifest(
      profileName: profileName,
    );

    final String manifestPath = p.join(folder, manifestFileName);
    final String manifestTmp = '$manifestPath.tmp';
    await File(manifestTmp).writeAsString(manifest.toJsonString());
    await _replace(manifestTmp, manifestPath);

    await _writeTimestamp(prefsLastSentKey, manifest.createdAt);
    _log.info('Snapshot sent to $snapshotPath');
    return manifest;
  }

  /// Describes the live database without snapshotting it.
  Future<SyncManifest> buildManifest({String? profileName}) async {
    final Database db = await _database.database;
    final SyncDeviceMeta meta = await deviceMeta();
    return SyncManifest(
      deviceName: meta.deviceName,
      createdAt: DateTime.now(),
      schemaVersion: await readUserVersion(db),
      appVersion: meta.appVersion,
      collections: await _database.getCollectionCount(),
      items: await _database.getTotalItemCount(),
      profileName: profileName,
      supportsSettingsTransfer: true,
    );
  }

  /// Validates the snapshot in [folder] without touching the live data.
  Future<SyncSnapshotInfo> inspectSnapshot(String folder) async {
    final String snapshotPath = p.join(folder, snapshotFileName);
    if (!File(snapshotPath).existsSync()) {
      return const SyncSnapshotInfo(exists: false);
    }

    SyncManifest? manifest;
    final File manifestFile = File(p.join(folder, manifestFileName));
    if (manifestFile.existsSync()) {
      try {
        manifest =
            SyncManifest.fromJsonString(await manifestFile.readAsString());
      } on FormatException catch (e) {
        _log.warning('Malformed sync manifest', e);
      }
    }

    int schemaVersion = 0;
    bool integrityOk = false;
    try {
      final Database snapshot = await databaseFactory.openDatabase(
        snapshotPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      try {
        schemaVersion = await readUserVersion(snapshot);
        integrityOk = await quickCheckOk(snapshot);
      } finally {
        await snapshot.close();
      }
    } on Exception catch (e) {
      _log.warning('Snapshot inspection failed for $snapshotPath', e);
    }

    return SyncSnapshotInfo(
      exists: true,
      manifest: manifest,
      schemaVersion: schemaVersion,
      integrityOk: integrityOk,
      tooNew: schemaVersion > MigrationRegistry.latestVersion,
    );
  }

  /// Replaces the live database with the snapshot from [folder].
  ///
  /// The previous database stays next to the new one as a `.bak` file for
  /// a manual rollback. The caller must restart the app afterwards — an
  /// older snapshot schema is migrated by the normal chain on reopen.
  ///
  /// Throws [StateError] when the snapshot fails [inspectSnapshot] checks.
  Future<void> receiveSnapshot(String folder) async {
    final SyncSnapshotInfo info = await inspectSnapshot(folder);
    if (!info.receivable) {
      throw StateError(
        info.tooNew
            ? 'Snapshot schema ${info.schemaVersion} is newer than '
                '${MigrationRegistry.latestVersion}'
            : 'Snapshot is missing or corrupted',
      );
    }

    final Database db = await _database.database;
    final String dbPath = db.path;
    await _database.checkpointWal();
    await _database.close();

    await File(dbPath).copy('$dbPath.bak');
    for (final String suffix in <String>['-wal', '-shm']) {
      final File sidecar = File('$dbPath$suffix');
      if (sidecar.existsSync()) {
        await sidecar.delete();
      }
    }
    await File(p.join(folder, snapshotFileName)).copy(dbPath);

    await _writeTimestamp(prefsLastReceivedKey, DateTime.now());
    _log.info('Snapshot received into $dbPath (backup at $dbPath.bak)');
  }

  /// Image-cache subfolders that hold user-supplied, non-re-downloadable
  /// images (everything else under `image_cache` re-fetches from its URL).
  static final List<String> _userImageFolders = <String>[
    ImageType.customCover.folder,
    ImageType.canvasImage.folder,
  ];

  /// Builds a ZIP of the user-supplied images that cannot be re-downloaded:
  /// collection hero banners plus the custom-cover and canvas-image caches of
  /// the current profile. The re-downloadable cover cache is left out — the
  /// receiving device re-fetches it from the source URLs.
  Future<List<int>> buildUserImagesArchive() async {
    final StorageRootResolution root = await StorageRoot.resolve();
    final String profileBase = p.dirname(StorageRoot.activeDbPath(root.path));
    final Archive archive = Archive();

    _addDirToArchive(
      archive,
      dir: p.join(root.path, StorageRoot.collectionsFolderName),
      prefix: StorageRoot.collectionsFolderName,
    );
    for (final String folder in _userImageFolders) {
      _addDirToArchive(
        archive,
        dir: p.join(profileBase, StorageRoot.imageCacheFolderName, folder),
        prefix: p.posix.join(StorageRoot.imageCacheFolderName, folder),
      );
    }
    return ZipEncoder().encode(archive);
  }

  /// Extracts an archive from [buildUserImagesArchive] over the current data
  /// root: `collections/` at the root, `image_cache/<sub>` under the current
  /// profile. Existing files are overwritten; unrelated local files are left
  /// in place (merge, not mirror).
  Future<void> applyUserImagesArchive(List<int> bytes) async {
    final StorageRootResolution root = await StorageRoot.resolve();
    final String profileBase = p.dirname(StorageRoot.activeDbPath(root.path));
    final Archive archive = ZipDecoder().decodeBytes(bytes);

    for (final ArchiveFile file in archive) {
      if (!file.isFile) continue;
      final List<String> parts = p.posix.split(file.name);
      if (parts.isEmpty) continue;
      final String base;
      if (parts.first == StorageRoot.collectionsFolderName) {
        base = root.path;
      } else if (parts.first == StorageRoot.imageCacheFolderName) {
        base = profileBase;
      } else {
        continue;
      }
      final File out = File(p.joinAll(<String>[base, ...parts]));
      await out.parent.create(recursive: true);
      await out.writeAsBytes(file.content as List<int>);
    }
  }

  static void _addDirToArchive(
    Archive archive, {
    required String dir,
    required String prefix,
  }) {
    final Directory source = Directory(dir);
    if (!source.existsSync()) return;
    for (final FileSystemEntity entity
        in source.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final List<int> bytes = entity.readAsBytesSync();
      final String rel = p.relative(entity.path, from: dir);
      final String name = p.posix.joinAll(<String>[prefix, ...p.split(rel)]);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
  }

  /// Identity of this device for manifests and network announcements.
  Future<SyncDeviceMeta> deviceMeta() async {
    final Future<SyncDeviceMeta> Function()? override = _metaProvider;
    if (override != null) return override();

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String deviceName;
    if (kIsMobile) {
      final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      deviceName = info.model;
    } else {
      deviceName = Platform.localHostname;
    }
    return SyncDeviceMeta(
      deviceName: deviceName,
      appVersion: packageInfo.version,
    );
  }


  /// Rename with delete-first: Windows refuses to rename over an
  /// existing file.
  static Future<void> _replace(String from, String to) async {
    final File target = File(to);
    if (target.existsSync()) {
      await target.delete();
    }
    await File(from).rename(to);
  }

  Future<DateTime?> _readTimestamp(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(key);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _writeTimestamp(String key, DateTime value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value.toIso8601String());
  }
}
