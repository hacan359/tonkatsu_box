import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_runner.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _RecordingMigration extends Migration {
  _RecordingMigration(this.version, this.log);

  @override
  final int version;

  final List<int> log;

  @override
  String get description => 'migration v$version';

  @override
  Future<void> migrate(Database db) async => log.add(version);
}

class _ThrowingMigration extends Migration {
  _ThrowingMigration(this.version, this.error);

  @override
  final int version;

  final Object error;

  @override
  String get description => 'rebuilds everything';

  @override
  Future<void> migrate(Database db) async => throw error;
}

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  Future<Database> openDb() => factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 1),
      );

  group('MigrationRunner.run', () {
    late Database db;

    setUp(() async => db = await openDb());
    tearDown(() async => db.close());

    test('runs every migration in order', () async {
      final List<int> ran = <int>[];

      await MigrationRunner.run(
        db,
        <Migration>[
          _RecordingMigration(1, ran),
          _RecordingMigration(2, ran),
          _RecordingMigration(3, ran),
        ],
        fromVersion: 0,
        toVersion: 3,
      );

      expect(ran, <int>[1, 2, 3]);
    });

    test('reports the migration that threw and stops the chain', () async {
      final List<int> ran = <int>[];

      await expectLater(
        MigrationRunner.run(
          db,
          <Migration>[
            _RecordingMigration(56, ran),
            _ThrowingMigration(57, Exception('UNIQUE constraint failed')),
            _RecordingMigration(58, ran),
          ],
          fromVersion: 55,
          toVersion: 58,
        ),
        throwsA(isA<MigrationFailure>()
            .having((MigrationFailure f) => f.version, 'version', 57)
            .having((MigrationFailure f) => f.fromVersion, 'fromVersion', 55)
            .having((MigrationFailure f) => f.toVersion, 'toVersion', 58)),
      );

      expect(ran, <int>[56], reason: 'v58 must not run after v57 failed');
    });

    test('keeps the original error as the cause', () async {
      final Exception cause = Exception('boom');

      await expectLater(
        MigrationRunner.run(
          db,
          <Migration>[_ThrowingMigration(57, cause)],
          fromVersion: 56,
          toVersion: 57,
        ),
        throwsA(isA<MigrationFailure>()
            .having((MigrationFailure f) => f.cause, 'cause', same(cause))),
      );
    });

    test('notifies onStart before each migration and onFailure once',
        () async {
      final List<int> started = <int>[];
      final List<MigrationFailure> failures = <MigrationFailure>[];

      await MigrationRunner.run(
        db,
        <Migration>[
          _ThrowingMigration(57, Exception('boom')),
        ],
        fromVersion: 56,
        toVersion: 60,
        onStart: (Migration m) => started.add(m.version),
        onFailure: (MigrationFailure f, StackTrace s) => failures.add(f),
      ).onError<MigrationFailure>((_, _) {});

      expect(started, <int>[57]);
      expect(failures, hasLength(1));
    });
  });

  group('MigrationFailure', () {
    test('upgrade message names the versions, the migration and the rollback',
        () {
      final String text = const MigrationFailure(
        version: 57,
        description: 'Show source: (tmdb_id, source) PK',
        fromVersion: 56,
        toVersion: 60,
        cause: 'UNIQUE constraint failed',
      ).toString();

      expect(text, startsWith('Database upgrade v56 → v60 failed on '
          'migration v57'));
      expect(text, contains('Show source: (tmdb_id, source) PK'));
      expect(text, contains('rolled back'));
      expect(text, contains('UNIQUE constraint failed'));
    });

    test('fresh install message does not promise a rollback', () {
      const MigrationFailure failure = MigrationFailure(
        version: 3,
        description: 'adds a table',
        fromVersion: 0,
        toVersion: 60,
        cause: 'disk full',
      );

      expect(failure.isFreshInstall, isTrue);
      expect(failure.toString(), contains('Database creation (v60) failed'));
      expect(failure.toString(), isNot(contains('rolled back')));
    });
  });
}
