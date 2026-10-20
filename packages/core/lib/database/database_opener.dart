import 'package:sqflite_common/sqlite_api.dart';

import 'migrations/migration.dart';
import 'migrations/migration_registry.dart';
import 'migrations/migration_runner.dart';

/// How long a writer waits for the lock before `SQLITE_BUSY`. WAL still allows
/// exactly one writer, and the default of 0 fails the loser instantly.
const int kBusyTimeoutMs = 5000;

/// Without an `onDowngrade`, sqflite silently stamps the lower version onto a
/// newer schema; the next up-to-date build then replays migrations and fails.
class DatabaseTooNewException implements Exception {
  const DatabaseTooNewException({
    required this.fileVersion,
    required this.appVersion,
  });

  final int fileVersion;

  final int appVersion;

  @override
  String toString() =>
      'Database schema v$fileVersion is newer than this build supports '
      '(v$appVersion). Update the app — the file was left untouched.';
}

/// Takes a ready [path] — where the file lives is the caller's job — so this
/// stays free of `dart:io`. Target version is [MigrationRegistry.latestVersion].
Future<Database> openAppDatabase({
  required DatabaseFactory factory,
  required String path,
  void Function(String message)? onInfo,
  void Function(Migration migration)? onMigrationStart,
  void Function(MigrationFailure failure, StackTrace stack)? onMigrationFailure,
}) {
  final int target = MigrationRegistry.latestVersion;
  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: target,
      onCreate: (Database db, int version) async {
        onInfo?.call('Creating database schema v$version');
        // Single source of truth: a fresh DB runs the whole chain (v1..N) in
        // order, exactly like an upgrade from zero.
        await MigrationRunner.run(
          db,
          MigrationRegistry.all,
          fromVersion: 0,
          toVersion: version,
          onStart: onMigrationStart,
          onFailure: onMigrationFailure,
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        onInfo?.call('Upgrading database from v$oldVersion to v$newVersion');
        await MigrationRunner.run(
          db,
          MigrationRegistry.pending(oldVersion),
          fromVersion: oldVersion,
          toVersion: newVersion,
          onStart: onMigrationStart,
          onFailure: onMigrationFailure,
        );
        onInfo?.call('Database upgrade complete');
      },
      onDowngrade: (Database db, int oldVersion, int newVersion) {
        throw DatabaseTooNewException(
          fileVersion: oldVersion,
          appVersion: newVersion,
        );
      },
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        // WAL + NORMAL batches commits into one fsync per checkpoint;
        // `journal_mode` returns a row, so Android needs rawQuery.
        await db.rawQuery('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA synchronous = NORMAL');
        await db.rawQuery('PRAGMA busy_timeout = $kBusyTimeoutMs');
      },
    ),
  );
}
