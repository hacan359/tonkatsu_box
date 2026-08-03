import 'package:core/database/dao/wishlist_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/wishlist_item.dart';
import 'package:core/models/wishlist_tag.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late WishlistDao dao;

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
      ),
    );
    dao = WishlistDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> add(String text, {String? tag}) async {
    final WishlistItem item =
        await dao.addWishlistItem(text: text, tag: tag);
    return item.id;
  }

  List<String> textsOf(List<WishlistItem> items) =>
      items.map((WishlistItem i) => i.text).toList();

  group('WishlistDao tags', () {
    group('updateWishlistItem', () {
      test('assigns a tag', () async {
        final int id = await add('Elden Ring');

        await dao.updateWishlistItem(id, tag: 'games');

        expect(
          (await dao.getWishlistItems()).single.tag,
          'games',
        );
      });

      test('clears the tag on the explicit clear flag', () async {
        final int id = await add('Elden Ring', tag: 'games');

        await dao.updateWishlistItem(id, clearTag: true);

        expect((await dao.getWishlistItems()).single.tag, isNull);
      });

      test('clearTag wins over a tag passed alongside it', () async {
        final int id = await add('Elden Ring', tag: 'games');

        await dao.updateWishlistItem(id, tag: 'other', clearTag: true);

        expect((await dao.getWishlistItems()).single.tag, isNull);
      });
    });

    group('getWishlistItemsFiltered', () {
      test('returns everything under the default filter', () async {
        await add('a', tag: 'games');
        await add('b');

        expect(await dao.getWishlistItemsFiltered(), hasLength(2));
      });

      test('drops resolved items when includeResolved is false', () async {
        final int id = await add('resolved');
        await add('active');
        await dao.resolveWishlistItem(id);

        final List<WishlistItem> items =
            await dao.getWishlistItemsFiltered(includeResolved: false);

        expect(textsOf(items), <String>['active']);
      });

      test('untagged filter returns only rows with a NULL tag', () async {
        await add('tagged', tag: 'games');
        await add('plain');

        final List<WishlistItem> items = await dao.getWishlistItemsFiltered(
          tagFilter: const WishlistTagFilter.untagged(),
        );

        expect(textsOf(items), <String>['plain']);
      });

      test('named filter matches the tag exactly', () async {
        await add('a', tag: 'games');
        await add('b', tag: 'movies');
        await add('c');

        final List<WishlistItem> items = await dao.getWishlistItemsFiltered(
          tagFilter: const WishlistTagFilter.named('games'),
        );

        expect(textsOf(items), <String>['a']);
      });

      test('combines the resolved and tag filters', () async {
        final int resolved = await add('resolved', tag: 'games');
        await add('active', tag: 'games');
        await add('other', tag: 'movies');
        await dao.resolveWishlistItem(resolved);

        final List<WishlistItem> items = await dao.getWishlistItemsFiltered(
          includeResolved: false,
          tagFilter: const WishlistTagFilter.named('games'),
        );

        expect(textsOf(items), <String>['active']);
      });

      test('orders active items before resolved ones', () async {
        final int resolved = await add('resolved');
        await add('active');
        await dao.resolveWishlistItem(resolved);

        final List<WishlistItem> items = await dao.getWishlistItemsFiltered();

        expect(items.first.text, 'active');
        expect(items.last.text, 'resolved');
      });

      test('returns empty when no row carries the tag', () async {
        await add('a', tag: 'games');

        expect(
          await dao.getWishlistItemsFiltered(
            tagFilter: const WishlistTagFilter.named('nope'),
          ),
          isEmpty,
        );
      });
    });

    group('deleteWishlistItemsByTag', () {
      test('deletes rows carrying the tag and returns the count', () async {
        await add('a', tag: 'games');
        await add('b', tag: 'games');
        await add('c', tag: 'movies');

        expect(await dao.deleteWishlistItemsByTag('games'), 2);
        expect(textsOf(await dao.getWishlistItems()), <String>['c']);
      });

      test('a null tag deletes the untagged rows', () async {
        await add('plain');
        await add('tagged', tag: 'games');

        expect(await dao.deleteWishlistItemsByTag(null), 1);
        expect(textsOf(await dao.getWishlistItems()), <String>['tagged']);
      });

      test('returns zero when nothing carries the tag', () async {
        await add('a', tag: 'games');

        expect(await dao.deleteWishlistItemsByTag('nope'), 0);
      });
    });

    group('renameWishlistTag', () {
      test('renames every row carrying the tag and returns the count',
          () async {
        await add('a', tag: 'games');
        await add('b', tag: 'games');
        await add('c', tag: 'movies');

        expect(await dao.renameWishlistTag('games', 'backlog'), 2);
        expect(
          await dao.getWishlistItemsFiltered(
            tagFilter: const WishlistTagFilter.named('backlog'),
          ),
          hasLength(2),
        );
      });

      test('a null source tags the previously untagged rows', () async {
        await add('plain');
        await add('tagged', tag: 'games');

        expect(await dao.renameWishlistTag(null, 'imported'), 1);
        expect(
          textsOf(await dao.getWishlistItemsFiltered(
            tagFilter: const WishlistTagFilter.named('imported'),
          )),
          <String>['plain'],
        );
      });

      test('returns zero when nothing carries the source tag', () async {
        await add('a', tag: 'games');

        expect(await dao.renameWishlistTag('nope', 'backlog'), 0);
      });

      test('merges into an existing tag', () async {
        await add('a', tag: 'games');
        await add('b', tag: 'movies');

        await dao.renameWishlistTag('movies', 'games');

        expect(
          await dao.getWishlistItemsFiltered(
            tagFilter: const WishlistTagFilter.named('games'),
          ),
          hasLength(2),
        );
      });
    });
  });
}
