import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

/// The partial unique indexes on `collection_items` are the only thing stopping
/// a duplicate row, and each media type is covered by a hand-written `WHERE`.
/// A type falling through every one, or into two, is silent corruption.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: MigrationRegistry.all.last.version,
        onCreate: (Database d, int _) async {
          for (final Migration m in MigrationRegistry.all) {
            await m.migrate(d);
          }
        },
        onConfigure: (Database d) => d.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db.insert('collections', <String, Object?>{
      'id': 1,
      'name': 'C',
      'author': 'tester',
      'created_at': 1700000000,
    });
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertItem({
    required MediaType type,
    required int externalId,
    int? collectionId = 1,
    int? platformId,
    String? source,
  }) {
    return db.insert('collection_items', <String, Object?>{
      'collection_id': collectionId,
      'media_type': type.value,
      'external_id': externalId,
      'platform_id': platformId,
      'source': source,
      'status': 'not_started',
      'sort_order': 0,
      'added_at': 1700000000,
    });
  }

  group('collection_items unique indexes', () {
    test('every media type is covered exactly once, in both scopes', () async {
      final List<Map<String, Object?>> rows = await db.rawQuery(
        "SELECT name, sql FROM sqlite_master WHERE type = 'index' "
        "AND tbl_name = 'collection_items' AND sql LIKE '%UNIQUE%'",
      );

      for (final MediaType type in MediaType.values) {
        for (final String scope in <String>[
          'collection_id IS NOT NULL',
          'collection_id IS NULL',
        ]) {
          final Iterable<String> matching = rows
              .map((Map<String, Object?> r) =>
                  (r['sql'] as String).replaceAll(RegExp(r'\s+'), ' '))
              .where((String sql) => sql.contains(scope))
              .where((String sql) => sql.contains("= '${type.value}'")
                  ? true
                  : sql.contains('NOT IN') && !sql.contains("'${type.value}'"));

          expect(
            matching.length,
            1,
            reason: '${type.value} / $scope is covered by ${matching.length} '
                'unique indexes, expected exactly 1',
          );
        }
      }
    });

    test('the same film from two providers coexists', () async {
      await insertItem(
        type: MediaType.movie,
        externalId: 113,
        source: DataSource.tmdb.name,
      );
      await insertItem(
        type: MediaType.movie,
        externalId: 113,
        source: DataSource.tvdb.name,
      );

      final List<Map<String, Object?>> rows = await db.query(
        'collection_items',
        where: 'external_id = ?',
        whereArgs: <Object?>[113],
      );
      expect(rows, hasLength(2));
    });

    test('a legacy null source collides with an explicit tmdb row', () async {
      await insertItem(type: MediaType.movie, externalId: 550);

      expect(
        () => insertItem(
          type: MediaType.movie,
          externalId: 550,
          source: DataSource.tmdb.name,
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('the same film twice from one provider still collides', () async {
      await insertItem(
        type: MediaType.movie,
        externalId: 113,
        source: DataSource.tvdb.name,
      );

      expect(
        () => insertItem(
          type: MediaType.movie,
          externalId: 113,
          source: DataSource.tvdb.name,
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('the uncategorized scope enforces the same rule', () async {
      await insertItem(
        type: MediaType.movie,
        externalId: 113,
        collectionId: null,
        source: DataSource.tmdb.name,
      );
      await insertItem(
        type: MediaType.movie,
        externalId: 113,
        collectionId: null,
        source: DataSource.tvdb.name,
      );

      expect(
        () => insertItem(
          type: MediaType.movie,
          externalId: 113,
          collectionId: null,
          source: DataSource.tvdb.name,
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('two collections may each hold the same film', () async {
      await db.insert('collections', <String, Object?>{
        'id': 2,
        'name': 'D',
        'author': 'tester',
        'created_at': 1700000000,
      });

      await insertItem(
        type: MediaType.movie,
        externalId: 113,
        source: DataSource.tvdb.name,
      );
      await insertItem(
        type: MediaType.movie,
        externalId: 113,
        collectionId: 2,
        source: DataSource.tvdb.name,
      );

      expect(
        await db.query('collection_items', where: 'external_id = 113'),
        hasLength(2),
      );
    });
  });
}
