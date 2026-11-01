import 'package:core/database/dao/collection_import_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/collection_import.dart';
import 'package:core/models/import_source_kind.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  late Database db;
  late CollectionImportDao dao;
  Future<int> seedCollection(String name) => db.insert(
    'collections',
    <String, Object?>{'name': name, 'author': 'me', 'created_at': 0},
  );

  late int firstId;
  late int secondId;

  setUp(() async {
    db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: MigrationRegistry.latestVersion,
        onCreate: (Database d, int _) async {
          for (final Migration m in MigrationRegistry.all) {
            await m.migrate(d);
          }
        },
        onConfigure: (Database d) => d.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    dao = CollectionImportDao(() async => db);
    firstId = await seedCollection('First');
    secondId = await seedCollection('Second');
  });

  tearDown(() async => db.close());

  CollectionImport record(
    int collectionId,
    ImportSourceKind source, {
    required int runAtSeconds,
    Map<String, Object?> options = const <String, Object?>{},
  }) => CollectionImport(
    collectionId: collectionId,
    source: source,
    options: options,
    lastRunAt: DateTime.fromMillisecondsSinceEpoch(runAtSeconds * 1000),
  );

  group('CollectionImportDao', () {
    group('upsert', () {
      test('a second run of the same source replaces the first', () async {
        await dao.upsert(
          record(
            firstId,
            ImportSourceKind.steam,
            runAtSeconds: 100,
            options: <String, Object?>{CollectionImportOption.mode: 'a'},
          ),
        );
        await dao.upsert(
          record(
            firstId,
            ImportSourceKind.steam,
            runAtSeconds: 200,
            options: <String, Object?>{CollectionImportOption.mode: 'b'},
          ),
        );

        final List<CollectionImport> rows = await dao.getForCollection(firstId);
        expect(rows, hasLength(1));
        expect(rows.single.text(CollectionImportOption.mode), 'b');
        expect(rows.single.lastRunAt.millisecondsSinceEpoch, 200 * 1000);
      });

      test('rejects a collection that does not exist', () async {
        expect(
          () =>
              dao.upsert(record(999, ImportSourceKind.steam, runAtSeconds: 1)),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('getForCollection', () {
      test('returns only that collection, newest run first', () async {
        await dao.upsert(
          record(firstId, ImportSourceKind.steam, runAtSeconds: 100),
        );
        await dao.upsert(
          record(firstId, ImportSourceKind.trakt, runAtSeconds: 300),
        );
        await dao.upsert(
          record(secondId, ImportSourceKind.mal, runAtSeconds: 500),
        );

        final List<CollectionImport> rows = await dao.getForCollection(firstId);
        expect(rows.map((CollectionImport r) => r.source), <ImportSourceKind>[
          ImportSourceKind.trakt,
          ImportSourceKind.steam,
        ]);
      });

      test('skips a row whose source this build does not know', () async {
        await dao.upsert(
          record(firstId, ImportSourceKind.steam, runAtSeconds: 100),
        );
        await db.insert('collection_imports', <String, Object?>{
          'collection_id': firstId,
          'source': 'from_the_future',
          'options': '{}',
          'last_run_at': 200,
        });

        final List<CollectionImport> rows = await dao.getForCollection(firstId);
        expect(rows.map((CollectionImport r) => r.source), <ImportSourceKind>[
          ImportSourceKind.steam,
        ]);
      });

      test(
        'returns an empty list for a collection never imported into',
        () async {
          expect(await dao.getForCollection(secondId), isEmpty);
        },
      );
    });

    group('getLatestForSource', () {
      test(
        'picks the most recent run of that source across collections',
        () async {
          await dao.upsert(
            record(firstId, ImportSourceKind.steam, runAtSeconds: 100),
          );
          await dao.upsert(
            record(secondId, ImportSourceKind.steam, runAtSeconds: 200),
          );
          await dao.upsert(
            record(firstId, ImportSourceKind.trakt, runAtSeconds: 900),
          );

          final CollectionImport? latest = await dao.getLatestForSource(
            ImportSourceKind.steam,
          );
          expect(latest?.collectionId, secondId);
        },
      );

      test('returns null when the source never ran', () async {
        expect(await dao.getLatestForSource(ImportSourceKind.mal), isNull);
      });
    });

    test('delete removes exactly one (collection, source) pair', () async {
      await dao.upsert(
        record(firstId, ImportSourceKind.steam, runAtSeconds: 100),
      );
      await dao.upsert(
        record(firstId, ImportSourceKind.trakt, runAtSeconds: 100),
      );

      await dao.delete(collectionId: firstId, source: ImportSourceKind.steam);

      final List<CollectionImport> rows = await dao.getForCollection(firstId);
      expect(rows.map((CollectionImport r) => r.source), <ImportSourceKind>[
        ImportSourceKind.trakt,
      ]);
    });

    test('deleting the collection cascades to its import records', () async {
      await dao.upsert(
        record(firstId, ImportSourceKind.steam, runAtSeconds: 100),
      );
      await db.delete(
        'collections',
        where: 'id = ?',
        whereArgs: <Object?>[firstId],
      );

      expect(await dao.getForCollection(firstId), isEmpty);
      expect(await dao.getLatestForSource(ImportSourceKind.steam), isNull);
    });
  });
}
