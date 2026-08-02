import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Names the failing migration, which the raw SQLite error does not. On the
/// startup error screen that is "the v57 upgrade failed" versus a wall of SQL.
class MigrationFailure implements Exception {
  const MigrationFailure({
    required this.version,
    required this.description,
    required this.fromVersion,
    required this.toVersion,
    required this.cause,
  });

  /// Version of the migration that threw.
  final int version;

  /// That migration's own description.
  final String description;

  /// Schema version the run started from; 0 for a database built from scratch.
  final int fromVersion;

  /// Schema version the run was heading to.
  final int toVersion;

  /// The original error.
  final Object cause;

  /// True when the run was building a fresh database rather than upgrading.
  bool get isFreshInstall => fromVersion == 0;

  @override
  String toString() {
    final String headline = isFreshInstall
        ? 'Database creation (v$toVersion) failed on migration v$version'
        : 'Database upgrade v$fromVersion → v$toVersion failed on '
            'migration v$version';
    final String reassurance = isFreshInstall
        ? 'The database was not created.'
        : 'Your data was not changed — the upgrade was rolled back.';
    return '$headline\n($description)\n$reassurance\n\n$cause';
  }
}

/// Shared by the app's `onCreate` / `onUpgrade` and, later, the selfhost server,
/// so both surface the same message.
abstract final class MigrationRunner {
  /// [onStart] fires before each migration, for logging. Throws
  /// [MigrationFailure] with the original stack trace.
  static Future<void> run(
    Database db,
    Iterable<Migration> migrations, {
    required int fromVersion,
    required int toVersion,
    void Function(Migration migration)? onStart,
    void Function(MigrationFailure failure, StackTrace stack)? onFailure,
  }) async {
    for (final Migration migration in migrations) {
      onStart?.call(migration);
      try {
        await migration.migrate(db);
      } catch (error, stack) {
        final MigrationFailure failure = MigrationFailure(
          version: migration.version,
          description: migration.description,
          fromVersion: fromVersion,
          toVersion: toVersion,
          cause: error,
        );
        onFailure?.call(failure, stack);
        // Keep the original stack: its frames name the failing statement.
        Error.throwWithStackTrace(failure, stack);
      }
    }
  }
}
