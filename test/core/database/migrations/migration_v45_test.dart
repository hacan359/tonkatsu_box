import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_v45.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 44),
    );
  }

  group('MigrationV45', () {
    test('should create the tracked_releases table', () async {
      final Database db = await openOldDb();
      await MigrationV45().migrate(db);

      final List<Map<String, dynamic>> tables = await db.query(
        'sqlite_master',
        where: "type = 'table' AND name = 'tracked_releases'",
      );

      expect(tables, isNotEmpty);
      await db.close();
    });

    test('should let the same id coexist across providers', () async {
      final Database db = await openOldDb();
      await MigrationV45().migrate(db);

      await db.insert('tracked_releases', <String, Object?>{
        'external_id': 100,
        'source': 'anilist',
        'media_type': 'manga',
        'created_at': 1,
      });
      await db.insert('tracked_releases', <String, Object?>{
        'external_id': 100,
        'source': 'mangabaka',
        'media_type': 'manga',
        'created_at': 1,
      });

      expect((await db.query('tracked_releases')).length, 2);
      await db.close();
    });
  });
}
