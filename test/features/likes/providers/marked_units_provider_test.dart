import 'package:core/models/collection_item.dart';
import 'package:core/models/item_mark.dart';
import 'package:core/models/marked_unit.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/item_search.dart';
import 'package:core/utils/meta_search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/likes/providers/marked_units_provider.dart';

import '../../../helpers/test_helpers.dart';

MarkedUnit _unit({
  required int itemId,
  String unitType = kUnitEpisode,
  int parent = 1,
  int unit = 1,
  bool fav = true,
  String? note,
  int likedAtMs = 1000,
  int updatedAtMs = 1000,
  String? title,
}) {
  return MarkedUnit(
    mark: ItemMark(
      id: 0,
      itemId: itemId,
      unitType: unitType,
      parentNumber: parent,
      unitNumber: unit,
      isFavorite: fav,
      userComment: note,
      likedAt: fav ? DateTime.fromMillisecondsSinceEpoch(likedAtMs) : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    ),
    unitTitle: title,
  );
}

void main() {
  late MockDatabaseService mockDb;
  late MockItemMarkDao marks;
  late MockCollectionDao items;

  setUp(() {
    mockDb = MockDatabaseService();
    marks = MockItemMarkDao();
    items = MockCollectionDao();
    when(() => mockDb.itemMarkDao).thenReturn(marks);
    when(() => mockDb.collectionDao).thenReturn(items);
  });

  /// The replay half comes from the library list; these tests pin it so the
  /// whole all-items stack (sort, prefs, collections) stays out of them.
  ProviderContainer makeContainer({
    List<CollectionItem> replayed = const <CollectionItem>[],
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
        rewatchedItemsProvider.overrideWithValue(
          AsyncValue<List<CollectionItem>>.data(replayed),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('markedUnitsProvider', () {
    test('groups marks by item and orders groups by freshest mark', () async {
      when(marks.getAllMarks).thenAnswer(
        (_) async => <MarkedUnit>[
          _unit(itemId: 1, unit: 3, likedAtMs: 5000, updatedAtMs: 5000),
          _unit(itemId: 2, unit: 1, likedAtMs: 9000, updatedAtMs: 9000),
          _unit(itemId: 1, unit: 1, likedAtMs: 1000, updatedAtMs: 1000),
        ],
      );
      when(() => items.getItemsWithDataByRowIds(any())).thenAnswer(
        (_) async => <CollectionItem>[
          createTestCollectionItem(id: 1, mediaType: MediaType.tvShow),
          createTestCollectionItem(id: 2, mediaType: MediaType.anime),
        ],
      );

      final List<MarkedUnitGroup> groups =
          await makeContainer().read(markedUnitsProvider.future);

      expect(groups.map((MarkedUnitGroup g) => g.item.id), <int>[2, 1]);
      // Inside a group: reading order, not date order.
      expect(
        groups.last.units.map((MarkedUnit u) => u.mark.unitNumber),
        <int>[1, 3],
      );
      verify(() => items.getItemsWithDataByRowIds(any())).called(1);
    });

    test('skips marks whose item did not come back', () async {
      when(marks.getAllMarks).thenAnswer(
        (_) async => <MarkedUnit>[_unit(itemId: 1), _unit(itemId: 42)],
      );
      when(() => items.getItemsWithDataByRowIds(any())).thenAnswer(
        (_) async => <CollectionItem>[createTestCollectionItem(id: 1)],
      );

      final List<MarkedUnitGroup> groups =
          await makeContainer().read(markedUnitsProvider.future);

      expect(groups.single.item.id, 1);
    });

    test('does not query items when there are no marks', () async {
      when(marks.getAllMarks).thenAnswer((_) async => <MarkedUnit>[]);

      final List<MarkedUnitGroup> groups =
          await makeContainer().read(markedUnitsProvider.future);

      expect(groups, isEmpty);
      verifyNever(() => items.getItemsWithDataByRowIds(any()));
    });
  });

  group('LikesFilter.apply', () {
    final List<MarkedUnitGroup> groups = <MarkedUnitGroup>[
      MarkedUnitGroup(
        item: createTestCollectionItem(
          id: 1,
          mediaType: MediaType.tvShow,
          tvShow: createTestTvShow(title: 'Thrones'),
        ),
        units: <MarkedUnit>[
          _unit(itemId: 1, unit: 1, title: 'Winter'),
          _unit(itemId: 1, unit: 2, fav: false, note: 'Great Twist'),
        ],
      ),
      MarkedUnitGroup(
        item: createTestCollectionItem(id: 2, mediaType: MediaType.manga),
        units: <MarkedUnit>[
          _unit(itemId: 2, unitType: kUnitChapter, parent: 0, unit: 7),
        ],
      ),
    ];

    ItemSearch search(String q) => ItemSearch(
          query: q,
          mode: SearchMode.title,
          itemTags: const <int, List<int>>{},
          tagNames: const <int, String>{},
          titleLanguage: 'romaji',
        );

    test('default filter keeps everything', () {
      expect(const LikesFilter().apply(groups), hasLength(2));
    });

    test('liked kind drops note-only units', () {
      final List<MarkedUnitGroup> out =
          const LikesFilter(kinds: <LikesKind>{LikesKind.liked}).apply(groups);
      expect(out.first.units, hasLength(1));
      expect(out.first.units.single.mark.isFavorite, isTrue);
    });

    test('noted kind drops groups left without units', () {
      final List<MarkedUnitGroup> out =
          const LikesFilter(kinds: <LikesKind>{LikesKind.noted}).apply(groups);
      expect(out, hasLength(1));
      expect(out.single.item.id, 1);
    });

    test('both kinds selected keeps everything', () {
      final List<MarkedUnitGroup> out = const LikesFilter(
        kinds: <LikesKind>{LikesKind.liked, LikesKind.noted},
      ).apply(groups);
      expect(out, hasLength(2));
      expect(out.first.units, hasLength(2));
    });

    test('type filter keeps only the chosen media types', () {
      final List<MarkedUnitGroup> out =
          const LikesFilter(types: <MediaType>{MediaType.manga}).apply(groups);
      expect(out.single.item.id, 2);
    });

    test('query matches note text case-insensitively', () {
      final List<MarkedUnitGroup> out =
          LikesFilter(query: 'great', itemSearch: search('great'))
              .apply(groups);
      expect(out.single.units.single.mark.note, 'Great Twist');
    });

    test('query matches the cached unit name', () {
      final List<MarkedUnitGroup> out =
          LikesFilter(query: 'winter', itemSearch: search('winter'))
              .apply(groups);
      expect(out.single.units.single.unitTitle, 'Winter');
    });

    test('query matching the title keeps every unit of that title', () {
      final List<MarkedUnitGroup> out =
          LikesFilter(query: 'thrones', itemSearch: search('thrones'))
              .apply(groups);
      expect(out.single.item.id, 1);
      expect(out.single.units, hasLength(2));
    });

    test('query without any hit yields nothing', () {
      expect(
        LikesFilter(query: 'zzz', itemSearch: search('zzz')).apply(groups),
        isEmpty,
      );
    });
  });

  group('likesFilterProvider', () {
    test('toggleType and toggleKind add then remove, reset restores defaults',
        () {
      final ProviderContainer container = makeContainer();
      final LikesFilterNotifier n =
          container.read(likesFilterProvider.notifier);

      n.toggleType(MediaType.anime);
      expect(container.read(likesFilterProvider).types, <MediaType>{
        MediaType.anime,
      });
      n.toggleType(MediaType.anime);
      expect(container.read(likesFilterProvider).types, isEmpty);

      n.toggleKind(LikesKind.noted);
      expect(container.read(likesFilterProvider).kinds, <LikesKind>{
        LikesKind.noted,
      });
      n.toggleKind(LikesKind.noted);
      expect(container.read(likesFilterProvider).kinds, isEmpty);

      n.toggleKind(LikesKind.noted);
      n.reset();
      expect(container.read(likesFilterProvider).isDefault, isTrue);
    });
  });

  group('markedMediaTypesProvider', () {
    test('lists only types that carry marks, in enum order', () async {
      when(marks.getAllMarks).thenAnswer(
        (_) async => <MarkedUnit>[_unit(itemId: 1), _unit(itemId: 2)],
      );
      when(() => items.getItemsWithDataByRowIds(any())).thenAnswer(
        (_) async => <CollectionItem>[
          createTestCollectionItem(id: 1, mediaType: MediaType.anime),
          createTestCollectionItem(id: 2, mediaType: MediaType.movie),
        ],
      );
      final ProviderContainer container = makeContainer();
      await container.read(markedUnitsProvider.future);

      expect(
        container.read(markedMediaTypesProvider),
        <MediaType>[MediaType.movie, MediaType.anime],
      );
    });
  });

  group('likesEntriesProvider', () {
    setUp(() {
      when(marks.getAllMarks).thenAnswer(
        (_) async => <MarkedUnit>[_unit(itemId: 1)],
      );
      when(() => items.getItemsWithDataByRowIds(any())).thenAnswer(
        (_) async => <CollectionItem>[
          createTestCollectionItem(id: 1, mediaType: MediaType.anime),
        ],
      );
    });

    test('hangs the replay counter on a title that also carries marks',
        () async {
      final ProviderContainer container = makeContainer(
        replayed: <CollectionItem>[
          createTestCollectionItem(id: 1, mediaType: MediaType.anime)
              .copyWith(rewatchCount: 3),
        ],
      );
      await container.read(markedUnitsProvider.future);

      final List<MarkedUnitGroup> entries =
          container.read(likesEntriesProvider).requireValue;
      expect(entries, hasLength(1));
      expect(entries.single.rewatchCount, 3);
      expect(entries.single.units, hasLength(1));
    });

    test('orders a replay-only title by its last activity', () async {
      final ProviderContainer container = makeContainer(
        replayed: <CollectionItem>[
          createTestCollectionItem(
            id: 2,
            mediaType: MediaType.movie,
            rewatchCount: 1,
            lastActivityAt: DateTime(2030),
          ),
          createTestCollectionItem(
            id: 3,
            mediaType: MediaType.movie,
            rewatchCount: 1,
            lastActivityAt: DateTime(1960),
          ),
        ],
      );
      await container.read(markedUnitsProvider.future);

      final List<MarkedUnitGroup> entries =
          container.read(likesEntriesProvider).requireValue;
      // The mark on item 1 is dated 1970, so it lands between the two.
      expect(entries.map((MarkedUnitGroup g) => g.item.id), <int>[2, 1, 3]);
    });

    test('adds a replayed title that carries no marks at all', () async {
      final ProviderContainer container = makeContainer(
        replayed: <CollectionItem>[
          createTestCollectionItem(id: 2, mediaType: MediaType.movie)
              .copyWith(rewatchCount: 1),
        ],
      );
      await container.read(markedUnitsProvider.future);

      final List<MarkedUnitGroup> entries =
          container.read(likesEntriesProvider).requireValue;
      expect(
        entries.map((MarkedUnitGroup g) => g.item.id).toSet(),
        <int>{1, 2},
      );
      expect(
        entries.firstWhere((MarkedUnitGroup g) => g.item.id == 2).units,
        isEmpty,
      );
    });
  });

  group('LikesFilter kinds', () {
    MarkedUnitGroup liked() => MarkedUnitGroup(
          item: createTestCollectionItem(id: 1, mediaType: MediaType.anime),
          units: <MarkedUnit>[_unit(itemId: 1)],
        );
    MarkedUnitGroup replayed() => MarkedUnitGroup(
          item: createTestCollectionItem(id: 2, mediaType: MediaType.movie),
          units: const <MarkedUnit>[],
          rewatchCount: 2,
        );

    List<MarkedUnitGroup> apply(Set<LikesKind> kinds) =>
        LikesFilter(kinds: kinds).apply(<MarkedUnitGroup>[liked(), replayed()]);

    test('nothing selected keeps marks and replays', () {
      expect(apply(const <LikesKind>{}), hasLength(2));
    });

    test('replays alone drop the marked-only title', () {
      final List<MarkedUnitGroup> shown =
          apply(const <LikesKind>{LikesKind.rewatched});
      expect(shown.map((MarkedUnitGroup g) => g.item.id), <int>[2]);
      expect(shown.single.rewatchCount, 2);
    });

    test('likes alone drop the replay-only title', () {
      final List<MarkedUnitGroup> shown =
          apply(const <LikesKind>{LikesKind.liked});
      expect(shown.map((MarkedUnitGroup g) => g.item.id), <int>[1]);
    });

    test('likes and replays together keep both', () {
      expect(
        apply(const <LikesKind>{LikesKind.liked, LikesKind.rewatched}),
        hasLength(2),
      );
    });

    test('a kind that is off strips the replay row off a marked title', () {
      final MarkedUnitGroup both = MarkedUnitGroup(
        item: createTestCollectionItem(id: 3, mediaType: MediaType.anime),
        units: <MarkedUnit>[_unit(itemId: 3)],
        rewatchCount: 4,
      );
      final List<MarkedUnitGroup> shown =
          const LikesFilter(kinds: <LikesKind>{LikesKind.liked})
              .apply(<MarkedUnitGroup>[both]);
      expect(shown.single.units, hasLength(1));
      expect(shown.single.isReplayed, isFalse);
    });
  });
}
