import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migrations/migration.dart';
import 'migrations/migration_registry.dart';
import 'migrations/migration_runner.dart';

/// Opens the app database at [path] and brings its schema up to date.
///
/// Deciding *where* the file lives is the caller's job — the app resolves a
/// per-profile directory, the selfhost server a container volume — so this takes
/// a ready [path] and stays free of `dart:io`.
///
/// The target version comes from [MigrationRegistry.latestVersion], so adding a
/// migration cannot drift from a hand-maintained number.
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
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        // WAL + NORMAL batches commits into one fsync per checkpoint;
        // `journal_mode` returns a row, so Android needs rawQuery.
        await db.rawQuery('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA synchronous = NORMAL');
      },
    ),
  );
}
