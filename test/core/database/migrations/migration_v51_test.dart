import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_v51.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  /// Pre-v51 `custom_items`: the shape after v28 (display_type added) but
  /// without `platform_id` / `format`.
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 50,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE custom_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              display_type TEXT,
              alt_title TEXT,
              description TEXT,
              cover_url TEXT,
              year INTEGER,
              genres TEXT,
              platform_name TEXT,
              external_url TEXT,
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

  group('MigrationV51', () {
    late Database db;

    setUp(() async {
      db = await openOldDb();
      await db.insert('custom_items', <String, Object?>{
        'title': 'Homebrew Game',
        'display_type': 'game',
        'platform_name': 'My Console',
        'cached_at': 1700000000,
      });
      await MigrationV51().migrate(db);
    });

    tearDown(() async => db.close());

    test('adds the platform_id and format columns', () async {
      expect(await hasColumn(db, 'platform_id'), isTrue);
      expect(await hasColumn(db, 'format'), isTrue);
    });

    test('existing rows default the new columns to null', () async {
      final List<Map<String, Object?>> rows = await db.query('custom_items');
      expect(rows.single['platform_id'], isNull);
      expect(rows.single['format'], isNull);
    });

    test('is idempotent — re-running does not throw', () async {
      await MigrationV51().migrate(db);
      expect(await hasColumn(db, 'platform_id'), isTrue);
      expect(await hasColumn(db, 'format'), isTrue);
    });

    test('new rows can store platform_id and format', () async {
      await db.insert('custom_items', <String, Object?>{
        'title': 'Custom Manhwa',
        'display_type': 'manga',
        'format': 'MANHWA',
        'platform_id': null,
        'cached_at': 1700000001,
      });
      final List<Map<String, Object?>> rows = await db.query(
        'custom_items',
        where: 'title = ?',
        whereArgs: <Object?>['Custom Manhwa'],
      );
      expect(rows.single['format'], 'MANHWA');
    });
  });
}
