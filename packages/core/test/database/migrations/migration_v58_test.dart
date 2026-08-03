import 'package:core/database/migrations/migration_v58.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  Future<Database> openDb() {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
  }

  group('MigrationV58', () {
    test('adds cell_label_template to mood_grids', () async {
      final Database db = await openDb();
      addTearDown(() async => db.close());
      await db.execute('''
        CREATE TABLE mood_grids (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          caption_template TEXT
        )
      ''');

      await MigrationV58().migrate(db);

      final List<Map<String, Object?>> cols =
          await db.rawQuery('PRAGMA table_info(mood_grids)');
      expect(
        cols.where(
          (Map<String, Object?> c) => c['name'] == 'cell_label_template',
        ),
        hasLength(1),
      );
    });

    test('is idempotent when the column already exists', () async {
      final Database db = await openDb();
      addTearDown(() async => db.close());
      await db.execute('''
        CREATE TABLE mood_grids (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          cell_label_template TEXT
        )
      ''');
      await db.insert('mood_grids', <String, Object?>{
        'name': 'G',
        'cell_label_template': '{{name}}',
      });

      await expectLater(MigrationV58().migrate(db), completes);

      final List<Map<String, Object?>> rows = await db.query('mood_grids');
      expect(rows.single['cell_label_template'], '{{name}}');
    });
  });
}
