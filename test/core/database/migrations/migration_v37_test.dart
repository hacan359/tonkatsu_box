import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xerabora/core/database/migrations/migration_v37.dart';

Future<Database> _openDb({required bool withPlatformIdColumn}) async {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;
  return factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (Database db, int version) async {
        final String platformCol =
            withPlatformIdColumn ? 'platform_id INTEGER,' : '';
        await db.execute('''
          CREATE TABLE tracker_game_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tracker_type TEXT NOT NULL,
            game_id INTEGER NOT NULL,
            $platformCol
            tracker_game_id TEXT NOT NULL,
            last_synced_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE UNIQUE INDEX idx_tracker_game_data_unique
          ON tracker_game_data(tracker_type, game_id)
        ''');
      },
    ),
  );
}

Future<List<String>> _columnsOf(Database db, String table) async {
  final List<Map<String, Object?>> info =
      await db.rawQuery('PRAGMA table_info($table)');
  return info.map((Map<String, Object?> r) => r['name']! as String).toList();
}

Future<String?> _indexSql(Database db, String name) async {
  final List<Map<String, Object?>> rows = await db.rawQuery(
    "SELECT sql FROM sqlite_master WHERE type='index' AND name = ?",
    <Object?>[name],
  );
  if (rows.isEmpty) return null;
  return rows.first['sql'] as String?;
}

void main() {
  group('MigrationV37', () {
    test('adds platform_id and the COALESCE unique index on a v36 DB',
        () async {
      final Database db = await _openDb(withPlatformIdColumn: false);
      addTearDown(db.close);

      await MigrationV37().migrate(db);

      expect(await _columnsOf(db, 'tracker_game_data'),
          contains('platform_id'));
      final String? sql = await _indexSql(db, 'idx_tracker_game_data_unique');
      expect(sql, isNotNull);
      expect(sql, contains('COALESCE(platform_id, -1)'));
    });

    test('is idempotent when platform_id already exists on disk', () async {
      final Database db = await _openDb(withPlatformIdColumn: true);
      addTearDown(db.close);

      await expectLater(MigrationV37().migrate(db), completes);

      expect(await _columnsOf(db, 'tracker_game_data'),
          contains('platform_id'));
      final String? sql = await _indexSql(db, 'idx_tracker_game_data_unique');
      expect(sql, contains('COALESCE(platform_id, -1)'));
    });

    test('replaces the old (tracker_type, game_id) index even when the '
        'column was already present', () async {
      final Database db = await _openDb(withPlatformIdColumn: true);
      addTearDown(db.close);
      final String? before =
          await _indexSql(db, 'idx_tracker_game_data_unique');
      expect(before, isNotNull);
      expect(before, isNot(contains('COALESCE')));

      await MigrationV37().migrate(db);

      final String? after =
          await _indexSql(db, 'idx_tracker_game_data_unique');
      expect(after, contains('COALESCE(platform_id, -1)'));
    });
  });
}
