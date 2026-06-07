import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/migrations/migration.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_v43.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  Future<Database> openDb() {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
  }

  group('Migration.addColumnIfAbsent', () {
    late Database db;

    setUp(() async {
      db = await openDb();
      await db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');
    });

    tearDown(() async => db.close());

    test('should add the column when absent', () async {
      await Migration.addColumnIfAbsent(db, 't', 'note', 'note TEXT');

      final List<Map<String, Object?>> cols =
          await db.rawQuery('PRAGMA table_info(t)');
      expect(cols.any((Map<String, Object?> c) => c['name'] == 'note'), isTrue);
    });

    test('should be a no-op when the column already exists', () async {
      await db.execute('ALTER TABLE t ADD COLUMN note TEXT');
      await db.insert('t', <String, Object?>{'id': 1, 'note': 'kept'});

      // Re-adding must neither throw nor wipe data.
      await Migration.addColumnIfAbsent(db, 't', 'note', 'note TEXT');

      final List<Map<String, Object?>> rows = await db.query('t');
      expect(rows.single['note'], 'kept');
    });
  });

  group('MigrationV43 (big-jump regression)', () {
    test(
        'should not throw when mood_grids already has caption_template '
        'from create*Table', () async {
      // Reproduces the upgrade path where createMoodGridsTable (today's schema)
      // already created the column, then the historical ALTER runs on top.
      final Database db = await openDb();
      addTearDown(() async => db.close());
      await db.execute('''
        CREATE TABLE mood_grids (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          caption_template TEXT
        )
      ''');

      await expectLater(MigrationV43().migrate(db), completes);

      final List<Map<String, Object?>> cols =
          await db.rawQuery('PRAGMA table_info(mood_grids)');
      expect(
        cols.where((Map<String, Object?> c) => c['name'] == 'caption_template'),
        hasLength(1),
      );
    });
  });
}
