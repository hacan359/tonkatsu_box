import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_v52.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  /// Pre-v52 `custom_items`: the shape after v51 (platform_id / format) but
  /// without the unit-total columns.
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 51,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE custom_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              display_type TEXT,
              format TEXT,
              platform_id INTEGER,
              cached_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<bool> hasColumn(Database db, String column) async {
    final List<Map<String, Object?>> columns =
        await db.rawQuery('PRAGMA table_info(custom_items)');
    return columns.any((Map<String, Object?> c) => c['name'] == column);
  }

  group('MigrationV52', () {
    late Database db;

    setUp(() async {
      db = await openOldDb();
      await db.insert('custom_items', <String, Object?>{
        'title': 'Homebrew Manga',
        'display_type': 'manga',
        'cached_at': 1700000000,
      });
      await MigrationV52().migrate(db);
    });

    tearDown(() async => db.close());

    test('adds unit_total and unit_group_total columns', () async {
      expect(await hasColumn(db, 'unit_total'), isTrue);
      expect(await hasColumn(db, 'unit_group_total'), isTrue);
    });

    test('existing rows default the new columns to null', () async {
      final List<Map<String, Object?>> rows = await db.query('custom_items');
      expect(rows.single['unit_total'], isNull);
      expect(rows.single['unit_group_total'], isNull);
    });

    test('is idempotent — re-running does not throw', () async {
      await MigrationV52().migrate(db);
      expect(await hasColumn(db, 'unit_total'), isTrue);
      expect(await hasColumn(db, 'unit_group_total'), isTrue);
    });

    test('new rows can store unit totals', () async {
      await db.insert('custom_items', <String, Object?>{
        'title': 'Custom Series',
        'display_type': 'tv_show',
        'unit_total': 24,
        'unit_group_total': 2,
        'cached_at': 1700000001,
      });
      final List<Map<String, Object?>> rows = await db.query(
        'custom_items',
        where: 'title = ?',
        whereArgs: <Object?>['Custom Series'],
      );
      expect(rows.single['unit_total'], 24);
      expect(rows.single['unit_group_total'], 2);
    });
  });
}
