import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_v46.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 45),
    );
  }

  group('MigrationV46', () {
    test('should create the calendar_entries table', () async {
      final Database db = await openOldDb();
      await MigrationV46().migrate(db);

      final List<Map<String, dynamic>> tables = await db.query(
        'sqlite_master',
        where: "type = 'table' AND name = 'calendar_entries'",
      );

      expect(tables, isNotEmpty);
      await db.close();
    });

    test('should let the same id coexist across providers', () async {
      final Database db = await openOldDb();
      await MigrationV46().migrate(db);

      await db.insert('calendar_entries', <String, Object?>{
        'external_id': 10,
        'source': 'anilist',
        'media_type': 'manga',
        'start_date': '2026-07-01',
        'recurrence': 'weekly',
        'created_at': 1,
      });
      await db.insert('calendar_entries', <String, Object?>{
        'external_id': 10,
        'source': 'mangabaka',
        'media_type': 'manga',
        'start_date': '2026-07-01',
        'recurrence': 'once',
        'created_at': 1,
      });

      expect((await db.query('calendar_entries')).length, 2);
      await db.close();
    });
  });
}
