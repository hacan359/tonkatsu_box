import 'dart:convert';
import 'dart:io';

import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/rpc/generated/remote_daos.rpc.dart';
import 'package:core/rpc/protocol.dart';
import 'package:core/rpc/rpc_codec.dart';
import 'package:core/rpc/rpc_transport.dart';
import 'package:core/testing/builders.dart';
import 'package:shelf/shelf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/database_bootstrap.dart';
import 'package:tonkatsu_server/src/rpc_handler.dart';

/// The browser side minus the socket: the payload is really encoded to JSON and
/// decoded again, which is where a wire rule would break.
class _HandlerTransport implements RpcTransport {
  _HandlerTransport(this._handler);

  final Handler _handler;
  String? lastRequestJson;

  @override
  Future<Object?> call(
    String dao,
    String method,
    Map<String, Object?> args,
  ) async {
    lastRequestJson = jsonEncode(<String, Object?>{
      'protocol': kProtocolVersion,
      'dao': dao,
      'method': method,
      'args': args,
    });
    final Response response = await _handler(Request(
      'POST',
      Uri.parse('http://localhost/rpc'),
      body: lastRequestJson,
    ));
    final Map<String, Object?> body =
        asObject(jsonDecode(await response.readAsString()));
    if (body['ok'] == true) return body['result'];

    final Map<String, Object?> error = asObject(body['error']);
    throw RpcException(
      error['kind'] as String? ?? 'internal',
      error['message'] as String? ?? '',
    );
  }
}

void main() {
  // Above 2^53 and not renumberable: exactly what forces ids onto the wire as
  // strings. See PROTOCOL.md.
  const int bigExternalId = 9007199254740993;

  late Directory dataDir;
  late DatabaseBootstrap bootstrap;
  late _HandlerTransport transport;
  late RemoteDaoSet daos;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    dataDir = Directory.systemTemp.createTempSync('tonkatsu_rpc_roundtrip');
    bootstrap = await bootstrapDatabase(
      factory: databaseFactoryFfi,
      dataDir: dataDir.path,
    );
    transport = _HandlerTransport(buildAppHandler(
      schemaVersion: bootstrap.schemaVersion,
      daos: DaoRegistry(bootstrap.db),
      logger: (Handler inner) => inner,
    ));
    daos = RemoteDaoSet(transport);
  });

  tearDown(() async {
    await bootstrap.db.close();
    if (dataDir.existsSync()) dataDir.deleteSync(recursive: true);
  });

  group('generated DAO stubs over the dispatcher', () {
    test('should carry a model back with every field it left with', () async {
      final DateTime createdAt = DateTime.utc(2026, 3, 4, 5, 6, 7);

      final Collection created = await daos.collectionDao.createCollection(
        name: 'Shelf',
        author: 'ann',
        type: CollectionType.own,
        createdAt: createdAt,
        isHidden: true,
      );

      expect(created.name, 'Shelf');
      expect(created.author, 'ann');
      expect(created.type, CollectionType.own);
      expect(created.isHidden, isTrue);
      expect(created.createdAt, createdAt);

      final List<Collection> all = await daos.collectionDao.getAllCollections();
      expect(all.single.id, created.id);
      expect(all.single.createdAt, createdAt);
    });

    test('should keep a 63-bit external id exact, as a string on the wire',
        () async {
      final Collection shelf = await daos.collectionDao.createCollection(
        name: 'Shelf',
        author: 'ann',
      );

      final int? itemId = await daos.collectionDao.addItemToCollection(
        collectionId: shelf.id,
        mediaType: MediaType.movie,
        externalId: bigExternalId,
        status: ItemStatus.planned,
      );
      expect(transport.lastRequestJson, contains('"$bigExternalId"'));
      expect(itemId, isNotNull);

      final CollectionItem? found = await daos.collectionDao
          .findCollectionItem(
        collectionId: shelf.id,
        mediaType: MediaType.movie,
        externalId: bigExternalId,
      );
      expect(found?.externalId, bigExternalId);
    });

    test('should decode a record-returning method', () async {
      final Collection shelf = await daos.collectionDao.createCollection(
        name: 'Shelf',
        author: 'ann',
      );
      await daos.collectionDao.addItemToCollection(
        collectionId: shelf.id,
        mediaType: MediaType.movie,
        externalId: bigExternalId,
      );

      final List<({int id, int? collectionId, int? platformId})> ids =
          await daos.collectionDao.getItemIdsByExternalId(
        bigExternalId,
        MediaType.movie.value,
      );

      expect(ids.single.collectionId, shelf.id);
      expect(ids.single.platformId, isNull);
    });

    test('should hydrate a joined model the storage row does not hold',
        () async {
      final Movie movie = createTestMovie(title: 'Fight Club');
      await daos.movieDao.upsertMovie(movie);

      final Collection shelf = await daos.collectionDao.createCollection(
        name: 'Shelf',
        author: 'ann',
      );
      await daos.collectionDao.addItemToCollection(
        collectionId: shelf.id,
        mediaType: MediaType.movie,
        externalId: movie.tmdbId,
      );

      final List<CollectionItem> items =
          await daos.collectionDao.getCollectionItemsWithData(shelf.id);

      // toDb() would have dropped this — the wire format is the constructor.
      expect(items.single.movie?.title, 'Fight Club');
    });

    test('should insert a batch of raw rows and return their ids', () async {
      final Collection shelf = await daos.collectionDao.createCollection(
        name: 'Shelf',
        author: 'ann',
      );

      final List<int?> ids =
          await daos.collectionDao.addItemsBatchReturningIds(
        shelf.id,
        <Map<String, dynamic>>[
          <String, dynamic>{
            'media_type': MediaType.movie.value,
            'external_id': bigExternalId,
            'status': ItemStatus.planned.value,
          },
          <String, dynamic>{
            'media_type': MediaType.movie.value,
            'external_id': 550,
            'status': ItemStatus.planned.value,
          },
        ],
      );

      expect(ids, hasLength(2));
      expect(ids.whereType<int>(), hasLength(2));

      final List<CollectionItem> items =
          await daos.collectionDao.getCollectionItems(shelf.id);
      expect(
        items.map((CollectionItem i) => i.externalId),
        containsAll(<int>[bigExternalId, 550]),
      );
    });

    test('should roll a failed batch back whole and raise the DAO failure',
        () async {
      await expectLater(
        daos.collectionDao.addItemsBatchReturningIds(
          999,
          <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': MediaType.movie.value,
              'external_id': 550,
              'status': ItemStatus.planned.value,
            },
          ],
        ),
        throwsA(
          isA<RpcException>()
              .having((RpcException e) => e.kind, 'kind', 'database'),
        ),
      );

      expect(await daos.collectionDao.getAllCollectionItems(), isEmpty);
    });

    test('should route a DAO other than CollectionDao', () async {
      await daos.wishlistDao.addWishlistItem(text: 'later');

      expect(await daos.wishlistDao.getWishlistItems(), hasLength(1));
    });
  });
}
