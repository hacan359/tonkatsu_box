import 'dart:io';

import 'package:core/database/database_opener.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/database/migrations/migration_runner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String dbPath;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('opener_test');
    dbPath = '${tempDir.path}/test.db';
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<Database> open({
    void Function(Migration)? onMigrationStart,
  }) =>
      openAppDatabase(
        factory: databaseFactoryFfi,
        path: dbPath,
        onMigrationStart: onMigrationStart,
      );

  group('openAppDatabase', () {
    test('should enable foreign keys and WAL on the opened connection',
        () async {
      final Database db = await open();
      addTearDown(db.close);

      final List<Map<String, Object?>> fk =
          await db.rawQuery('PRAGMA foreign_keys');
      final List<Map<String, Object?>> journal =
          await db.rawQuery('PRAGMA journal_mode');

      expect(fk.first.values.first, 1);
      expect((journal.first.values.first as String).toLowerCase(), 'wal');
    });

    test('should give a writer a busy timeout instead of failing instantly',
        () async {
      final Database db = await open();
      addTearDown(db.close);

      final List<Map<String, Object?>> timeout =
          await db.rawQuery('PRAGMA busy_timeout');

      expect(timeout.first.values.first, kBusyTimeoutMs);
    });

    test('should cascade a delete, proving foreign keys are enforced',
        () async {
      final Database db = await open();
      addTearDown(db.close);

      final int collectionId = await db.insert('collections', <String, Object?>{
        'name': 'c',
        'author': 'a',
        'created_at': 1,
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': collectionId,
        'external_id': 1,
        'added_at': 1,
      });

      await db.delete('collections', where: 'id = ?', whereArgs: <Object?>[
        collectionId,
      ]);

      expect(await db.query('collection_items'), isEmpty);
    });

    test('should land a fresh database on the registry latest version',
        () async {
      final Database db = await open();
      addTearDown(db.close);

      expect(await db.getVersion(), MigrationRegistry.latestVersion);
    });

    test('should run only pending migrations when upgrading', () async {
      const int from = 58;
      final Database seeded = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: from,
          onCreate: (Database db, int version) => MigrationRunner.run(
            db,
            MigrationRegistry.pending(0).where((Migration m) => m.version <= from),
            fromVersion: 0,
            toVersion: from,
          ),
        ),
      );
      await seeded.close();

      final List<int> ran = <int>[];
      final Database db = await open(
        onMigrationStart: (Migration m) => ran.add(m.version),
      );
      addTearDown(db.close);

      expect(ran.first, from + 1);
      expect(ran.last, MigrationRegistry.latestVersion);
      expect(
        ran,
        MigrationRegistry.pending(from).map((Migration m) => m.version).toList(),
      );
      expect(await db.getVersion(), MigrationRegistry.latestVersion);
    });
  });
}
