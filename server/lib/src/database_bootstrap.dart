import 'dart:io';

import 'package:core/database/database_opener.dart';
import 'package:core/database/db_file.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/database/sqlite_health.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';

/// Raised when the data directory cannot be turned into a usable database.
class ServerBootstrapException implements Exception {
  const ServerBootstrapException(this.message);

  final String message;

  @override
  String toString() => 'ServerBootstrapException: $message';
}

/// The opened database plus what had to happen to get there.
class DatabaseBootstrap {
  const DatabaseBootstrap({
    required this.db,
    required this.path,
    required this.schemaVersion,
    required this.previousVersion,
    this.snapshotPath,
  });

  final Database db;
  final String path;
  final int schemaVersion;

  /// Schema version found on disk, or `null` when the database was created.
  final int? previousVersion;

  /// Copy taken before pending migrations ran; `null` when none were pending.
  final String? snapshotPath;

  bool get wasCreated => previousVersion == null;
}

/// Opens `<dataDir>/tonkatsu_box.db`, replaying the shared migration chain.
/// A corrupt or too-new file aborts the boot instead of being migrated.
Future<DatabaseBootstrap> bootstrapDatabase({
  required DatabaseFactory factory,
  required String dataDir,
  void Function(String message)? onInfo,
}) async {
  final Directory dir = Directory(dataDir);
  await dir.create(recursive: true);

  final String path = p.join(dir.path, kDatabaseFileName);
  final int target = MigrationRegistry.latestVersion;

  int? previousVersion;
  String? snapshotPath;
  if (File(path).existsSync()) {
    final int onDisk = await _probe(factory, path);
    if (onDisk > target) {
      throw ServerBootstrapException(
        'Database schema v$onDisk is newer than this build (v$target)'
        ' — update the server image.',
      );
    }
    // Version 0 is a file the chain never touched: nothing to preserve, and
    // the open below builds it from scratch.
    if (onDisk > 0) {
      previousVersion = onDisk;
      if (onDisk < target) {
        snapshotPath = await _snapshot(path, onDisk, onInfo);
      }
    }
  }

  final Database db = await openAppDatabase(
    factory: factory,
    path: path,
    onInfo: onInfo,
  );

  return DatabaseBootstrap(
    db: db,
    path: path,
    schemaVersion: target,
    previousVersion: previousVersion,
    snapshotPath: snapshotPath,
  );
}

/// Reads the on-disk schema version and checkpoints the WAL, so a later
/// snapshot is a single self-contained file.
Future<int> _probe(DatabaseFactory factory, String path) async {
  Database? db;
  try {
    db = await factory.openDatabase(path);
    // The probe runs before openAppDatabase, so it configures itself.
    await db.rawQuery('PRAGMA busy_timeout = $kBusyTimeoutMs');
    if (!await quickCheckOk(db)) {
      throw const ServerBootstrapException(
        'Database failed the integrity check — restore a backup.',
      );
    }
    final int version = await readUserVersion(db);
    await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    return version;
  } on ServerBootstrapException {
    rethrow;
  } on Object catch (e) {
    throw ServerBootstrapException('Cannot open $path: $e');
  } finally {
    await db?.close();
  }
}

Future<String> _snapshot(
  String dbPath,
  int fromVersion,
  void Function(String message)? onInfo,
) async {
  final Directory dir = Directory(p.join(p.dirname(dbPath), 'snapshots'));
  await dir.create(recursive: true);

  final String stamp = DateTime.now().toUtc().toIso8601String().split('.').first;
  final String target = p.join(
    dir.path,
    '${p.basenameWithoutExtension(dbPath)}.v$fromVersion.'
    '${stamp.replaceAll(RegExp('[:-]'), '')}.db',
  );
  await File(dbPath).copy(target);
  onInfo?.call('Snapshot of v$fromVersion saved to $target');
  return target;
}
