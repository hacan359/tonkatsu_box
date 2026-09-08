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

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[databaseServiceProvider.overrideWithValue(mockDb)],
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
}
