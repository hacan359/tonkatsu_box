import 'dart:convert';

import 'package:core/database/dao/collection_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/rpc/generated/collection_dao.dispatch.rpc.dart';
import 'package:core/rpc/generated/collection_dao.remote.rpc.dart';
import 'package:core/rpc/rpc_codec.dart';
import 'package:core/rpc/rpc_transport.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

/// Runs the dispatcher in-process but forces every payload through real JSON,
/// so anything the wire cannot carry fails here instead of in a browser.
class _JsonLoopbackTransport implements RpcTransport {
  _JsonLoopbackTransport(this.dao);

  final CollectionDao dao;

  @override
  Future<Object?> call(
    String daoName,
    String method,
    Map<String, Object?> args,
  ) async {
    final Object? sent = jsonDecode(jsonEncode(args));
    final Object? result = await dispatchCollectionDao(
      dao,
      method,
      asObject(sent),
    );
    return jsonDecode(jsonEncode(result));
  }
}

void main() {
  late Database db;
  late CollectionDao dao;
  late RemoteCollectionDao remote;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
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
    dao = CollectionDao.withMediaDaos(() async => db);
    remote = RemoteCollectionDao(_JsonLoopbackTransport(dao));
  });

  tearDown(() => db.close());

  group('CollectionDao over RPC', () {
    test('should round-trip a collection through create and read', () async {
      final Collection created = await remote.createCollection(
        name: 'Shelf',
        author: 'ann',
      );

      expect(created.name, 'Shelf');

      final List<Collection> all = await remote.getAllCollections();
      expect(all, hasLength(1));
      expect(all.first.id, created.id);
      expect(all.first.author, 'ann');
    });

    test('should keep hydrated media on getCollectionItemsWithData', () async {
      final Collection c =
          await remote.createCollection(name: 'Films', author: 'ann');
      await db.insert('movies_cache', <String, Object?>{
        'tmdb_id': 603,
        'source': DataSource.tmdb.name,
        'title': 'The Matrix',
      });
      await remote.addItemToCollection(
        collectionId: c.id,
        mediaType: MediaType.movie,
        externalId: 603,
        source: DataSource.tmdb,
        status: ItemStatus.completed,
      );

      final List<CollectionItem> viaRpc =
          await remote.getCollectionItemsWithData(c.id);
      final List<CollectionItem> direct =
          await dao.getCollectionItemsWithData(c.id);

      expect(viaRpc, hasLength(1));
      // The regression that `toDb()` would have caused: media stripped.
      expect(viaRpc.first.movie, isNotNull);
      expect(viaRpc.first.movie!.title, direct.first.movie!.title);
      expect(viaRpc.first.status, ItemStatus.completed);
      expect(viaRpc.first.source, DataSource.tmdb);
    });

    test('should carry a 63-bit id through an untyped row', () async {
      // fnv1a64 range: a bare JSON number would round to something else in a
      // browser, and the row map is `dynamic` so no static rule sees it.
      const int stableId = 8747386780253552735;
      final Collection c =
          await remote.createCollection(name: 'Books', author: 'ann');

      final List<int?> ids = await remote.addItemsBatchReturningIds(
        c.id,
        <Map<String, dynamic>>[
          <String, dynamic>{
            'media_type': MediaType.book.value,
            'external_id': stableId,
            'status': ItemStatus.planned.value,
          },
        ],
      );

      expect(ids, hasLength(1));
      final List<CollectionItem> items = await remote.getCollectionItems(c.id);
      expect(items.single.externalId, stableId);
    });

    test('should round-trip a record-returning query', () async {
      final Collection c =
          await remote.createCollection(name: 'Games', author: 'ann');
      await remote.addItemToCollection(
        collectionId: c.id,
        mediaType: MediaType.game,
        externalId: 42,
        platformId: 6,
        status: ItemStatus.planned,
      );

      final List<({int? collectionId, int id, int? platformId})> rows =
          await remote.getItemIdsByExternalId(42, MediaType.game.value);

      expect(rows, hasLength(1));
      expect(rows.single.collectionId, c.id);
      expect(rows.single.platformId, 6);
    });

    test('should round-trip a map keyed by int', () async {
      final Collection c =
          await remote.createCollection(name: 'Shows', author: 'ann');
      await remote.addItemToCollection(
        collectionId: c.id,
        mediaType: MediaType.tvShow,
        externalId: 1399,
        status: ItemStatus.inProgress,
      );

      final Map<int, List<dynamic>> infos =
          await remote.getCollectedItemInfos(MediaType.tvShow);

      expect(infos.keys, contains(1399));
      expect(infos[1399], hasLength(1));
    });

    test('should propagate a void call and an empty result', () async {
      final Collection c =
          await remote.createCollection(name: 'Temp', author: 'ann');

      await remote.clearCollectionItems(c.id);

      expect(await remote.getCollectionItems(c.id), isEmpty);
    });

    test('should reject a method the DAO does not have', () async {
      expect(
        () => dispatchCollectionDao(dao, 'noSuchMethod', <String, Object?>{}),
        throwsA(isA<RpcCodecException>()),
      );
    });
  });
}
