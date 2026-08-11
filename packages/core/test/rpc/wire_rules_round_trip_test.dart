import 'dart:convert';

import 'package:core/database/dao/global_tag_dao.dart';
import 'package:core/database/dao/stats_dao.dart';
import 'package:core/database/dao/tv_show_dao.dart';
import 'package:core/database/dao/wishlist_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/wishlist_item.dart';
import 'package:core/models/wishlist_tag.dart';
import 'package:core/rpc/generated/global_tag_dao.dispatch.rpc.dart';
import 'package:core/rpc/generated/global_tag_dao.remote.rpc.dart';
import 'package:core/rpc/generated/stats_dao.dispatch.rpc.dart';
import 'package:core/rpc/generated/stats_dao.remote.rpc.dart';
import 'package:core/rpc/generated/tv_show_dao.dispatch.rpc.dart';
import 'package:core/rpc/generated/tv_show_dao.remote.rpc.dart';
import 'package:core/rpc/generated/wishlist_dao.dispatch.rpc.dart';
import 'package:core/rpc/generated/wishlist_dao.remote.rpc.dart';
import 'package:core/rpc/rpc_codec.dart';
import 'package:core/rpc/rpc_transport.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

typedef _Dispatch = Future<Object?> Function(
  String method,
  Map<String, Object?> args,
);

/// Forces every payload through real JSON, so a rule that cannot survive the
/// wire fails here and not in a browser.
class _JsonLoopback implements RpcTransport {
  _JsonLoopback(this.dispatch);

  final _Dispatch dispatch;

  @override
  Future<Object?> call(
    String dao,
    String method,
    Map<String, Object?> args,
  ) async {
    final Object? sent = jsonDecode(jsonEncode(args));
    final Object? result = await dispatch(method, asObject(sent));
    return jsonDecode(jsonEncode(result));
  }
}

void main() {
  late Database db;

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
  });

  tearDown(() => db.close());

  Future<Database> getDb() async => db;

  group('sealed hierarchy', () {
    late WishlistDao dao;
    late RemoteWishlistDao remote;

    setUp(() {
      dao = WishlistDao(getDb);
      remote = RemoteWishlistDao(_JsonLoopback(
        (String m, Map<String, Object?> a) => dispatchWishlistDao(dao, m, a),
      ));
    });

    test('should carry the variant that has no fields', () async {
      await dao.addWishlistItem(text: 'untagged one');
      await dao.addWishlistItem(text: 'tagged one', tag: 'mal');

      final List<WishlistItem> all = await remote.getWishlistItemsFiltered();
      final List<WishlistItem> untagged = await remote
          .getWishlistItemsFiltered(
        tagFilter: const WishlistTagFilter.untagged(),
      );

      expect(all, hasLength(2));
      expect(untagged, hasLength(1));
      expect(untagged.single.text, 'untagged one');
    });

    test('should carry the variant that has a field', () async {
      await dao.addWishlistItem(text: 'tagged one', tag: 'mal');
      await dao.addWishlistItem(text: 'other', tag: 'anilist');

      final List<WishlistItem> named = await remote.getWishlistItemsFiltered(
        tagFilter: const WishlistTagFilter.named('mal'),
      );

      expect(named, hasLength(1));
      expect(named.single.text, 'tagged one');
    });
  });

  group('map keys', () {
    test('should round-trip an enum key and a nullable outer key', () async {
      final StatsDao dao = StatsDao(getDb);
      final RemoteStatsDao remote = RemoteStatsDao(_JsonLoopback(
        (String m, Map<String, Object?> a) => dispatchStatsDao(dao, m, a),
      ));
      await db.insert('collection_items', <String, Object?>{
        'media_type': 'game',
        'external_id': 42,
        'status': ItemStatus.completed.value,
        'added_at': 0,
      });

      final Map<int?, Map<ItemStatus, int>> counts =
          await remote.getGamePlatformStatusCounts();

      // No platform_id on the row, so the outer key is genuinely null.
      expect(counts.keys, contains(null));
      expect(counts[null], containsPair(ItemStatus.completed, 1));
    });

    test('should round-trip a record key', () async {
      final TvShowDao dao = TvShowDao(getDb);
      final RemoteTvShowDao remote = RemoteTvShowDao(_JsonLoopback(
        (String m, Map<String, Object?> a) => dispatchTvShowDao(dao, m, a),
      ));
      // watched_episodes carries an FK, and foreign_keys is ON here.
      final int collectionId = await db.insert('collections', <String, Object?>{
        'name': 'Shows',
        'author': 'ann',
        'type': 'own',
        'created_at': 0,
      });
      await dao.markEpisodeWatchedAt(
        collectionId,
        DataSource.tmdb,
        1399,
        2,
        7,
        1700000000000,
      );

      final Map<(int, int), DateTime?> watched =
          await remote.getWatchedEpisodes(collectionId, DataSource.tmdb, 1399);

      expect(watched.keys, contains((2, 7)));
      expect(watched[(2, 7)], isNotNull);
    });
  });

  group('Iterable parameter', () {
    test('should round-trip a lazy iterable of records', () async {
      final GlobalTagDao dao = GlobalTagDao(getDb);
      final RemoteGlobalTagDao remote = RemoteGlobalTagDao(_JsonLoopback(
        (String m, Map<String, Object?> a) => dispatchGlobalTagDao(dao, m, a),
      ));

      final Map<String, int> ids = await remote.resolveOrCreateAll(
        <String>['alpha', 'beta'].map(
          (String name) => (name: name, color: null, textColor: null),
        ),
      );

      expect(ids.keys, containsAll(<String>['alpha', 'beta']));
      expect(ids.values.toSet(), hasLength(2));
    });
  });
}
