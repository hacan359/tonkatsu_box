import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/item_mark.dart';
import 'package:core/models/marked_unit.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/item_tags_provider.dart';
import 'package:tonkatsu_box/features/home/providers/all_items_provider.dart';
import 'package:tonkatsu_box/features/likes/providers/marked_units_provider.dart';
import 'package:tonkatsu_box/features/likes/screens/likes_screen.dart';
import 'package:tonkatsu_box/features/likes/widgets/marked_group_tile.dart';
import 'package:tonkatsu_box/shared/navigation/search_providers.dart';

import '../../../helpers/test_helpers.dart';

class _FakeMarkedUnits extends MarkedUnitsNotifier {
  _FakeMarkedUnits(this.groups);

  final List<MarkedUnitGroup> groups;

  @override
  Future<List<MarkedUnitGroup>> build() async => groups;
}

class _FakeCollections extends CollectionsNotifier {
  @override
  Future<List<Collection>> build() async => <Collection>[
        createTestCollection(id: 1, name: 'Shelf'),
      ];
}

class _NoItemTags extends ItemTagsNotifier {
  @override
  Future<Map<int, List<int>>> build() async => <int, List<int>>{};
}

MarkedUnit _unit({
  required int itemId,
  String unitType = kUnitEpisode,
  int parent = 1,
  int unit = 1,
  bool fav = true,
  String? note,
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
      likedAt: fav ? DateTime.fromMillisecondsSinceEpoch(1000) : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
    ),
    unitTitle: title,
  );
}

void main() {
  final List<MarkedUnitGroup> sample = <MarkedUnitGroup>[
    MarkedUnitGroup(
      item: createTestCollectionItem(
        id: 1,
        collectionId: 1,
        mediaType: MediaType.tvShow,
        tvShow: createTestTvShow(title: 'Thrones'),
      ),
      units: <MarkedUnit>[
        _unit(itemId: 1, parent: 2, unit: 5, title: 'Rains'),
        _unit(itemId: 1, parent: 2, unit: 6, fav: false, note: 'sad one'),
      ],
    ),
    MarkedUnitGroup(
      item: createTestCollectionItem(
        id: 2,
        collectionId: null,
        mediaType: MediaType.manga,
      ),
      units: <MarkedUnit>[
        _unit(itemId: 2, unitType: kUnitChapter, parent: 0, unit: 12),
      ],
    ),
  ];

  List<Override> overrides(
    List<MarkedUnitGroup> groups, {
    String query = '',
    List<CollectionItem> replayed = const <CollectionItem>[],
  }) =>
      <Override>[
        markedUnitsProvider.overrideWith(() => _FakeMarkedUnits(groups)),
        rewatchedItemsProvider.overrideWithValue(
          AsyncValue<List<CollectionItem>>.data(replayed),
        ),
        collectionsProvider.overrideWith(_FakeCollections.new),
        itemTagsProvider.overrideWith(_NoItemTags.new),
        allTagsMapProvider.overrideWith((Ref ref) => <int, Tag>{}),
        likesSearchQueryProvider.overrideWith((Ref ref) => query),
      ];

  Finder kindChip(LikesKind kind) => find.byKey(ValueKey<LikesKind>(kind));
  Finder typeChip(MediaType type) => find.byKey(ValueKey<MediaType>(type));

  group('LikesScreen', () {
    testWidgets('shows the empty state when nothing is marked', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const LikesScreen(),
        overrides: overrides(const <MarkedUnitGroup>[]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MarkedGroupTile), findsNothing);
    });

    testWidgets('renders one tile per title with every unit', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(const LikesScreen(), overrides: overrides(sample));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MarkedGroupTile), findsNWidgets(2));
      expect(find.textContaining('Rains'), findsOneWidget);
      expect(find.text('sad one'), findsOneWidget);
      // No search field of its own: the shared top-bar field serves the page.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('claims the top-bar search while mounted and releases it', (
      WidgetTester tester,
    ) async {
      // A host that can drop the page while the ProviderScope stays alive —
      // the flag must be released, not the whole scope.
      final ValueNotifier<bool> showPage = ValueNotifier<bool>(true);
      addTearDown(showPage.dispose);
      await tester.pumpApp(
        ValueListenableBuilder<bool>(
          valueListenable: showPage,
          builder: (BuildContext _, bool show, Widget? _) =>
              show ? const LikesScreen() : const SizedBox.shrink(),
        ),
        overrides: overrides(sample),
      );
      await tester.pumpAndSettle();
      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(LikesScreen)));
      expect(container.read(likesSearchActiveProvider), isTrue);

      showPage.value = false;
      await tester.pumpAndSettle();
      expect(find.byType(LikesScreen), findsNothing);
      expect(container.read(likesSearchActiveProvider), isFalse);
    });

    testWidgets('liked toggle hides note-only units', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(const LikesScreen(), overrides: overrides(sample));
      await tester.pumpAndSettle();

      await tester.tap(kindChip(LikesKind.liked));
      await tester.pumpAndSettle();

      expect(find.text('sad one'), findsNothing);
      expect(find.textContaining('Rains'), findsOneWidget);
    });

    testWidgets('noted toggle drops titles left without units', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(const LikesScreen(), overrides: overrides(sample));
      await tester.pumpAndSettle();

      await tester.tap(kindChip(LikesKind.noted));
      await tester.pumpAndSettle();

      expect(find.byType(MarkedGroupTile), findsOneWidget);
      expect(find.text('sad one'), findsOneWidget);
    });

    testWidgets('both toggles selected show everything again', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(const LikesScreen(), overrides: overrides(sample));
      await tester.pumpAndSettle();

      await tester.tap(kindChip(LikesKind.liked));
      await tester.pumpAndSettle();
      await tester.tap(kindChip(LikesKind.noted));
      await tester.pumpAndSettle();

      expect(find.byType(MarkedGroupTile), findsNWidgets(2));
      expect(find.text('sad one'), findsOneWidget);
    });

    testWidgets('type chip narrows to that media type', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(const LikesScreen(), overrides: overrides(sample));
      await tester.pumpAndSettle();

      await tester.tap(typeChip(MediaType.manga));
      await tester.pumpAndSettle();

      expect(find.byType(MarkedGroupTile), findsOneWidget);
      expect(find.textContaining('Rains'), findsNothing);
    });

    testWidgets('hides the filter row while nothing is marked', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const LikesScreen(),
        overrides: overrides(const <MarkedUnitGroup>[]),
      );
      await tester.pumpAndSettle();

      expect(kindChip(LikesKind.liked), findsNothing);
    });

    testWidgets('top-bar query narrows to matching notes', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const LikesScreen(),
        overrides: overrides(sample, query: 'SAD'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MarkedGroupTile), findsOneWidget);
      expect(find.text('sad one'), findsOneWidget);
      expect(find.textContaining('Rains'), findsNothing);
    });

    testWidgets('top-bar query matching the title keeps all its units', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const LikesScreen(),
        overrides: overrides(sample, query: 'thrones'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MarkedGroupTile), findsOneWidget);
      expect(find.textContaining('Rains'), findsOneWidget);
      expect(find.text('sad one'), findsOneWidget);
    });

    testWidgets('reports no matches instead of the empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const LikesScreen(),
        overrides: overrides(sample, query: 'nothing here'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MarkedGroupTile), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a phone without exceptions', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(const LikesScreen(), overrides: overrides(sample));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MarkedGroupTile), findsNWidgets(2));
    });

    testWidgets('the replay chip narrows to titles that were replayed', (
      WidgetTester tester,
    ) async {
      final CollectionItem replayed = createTestCollectionItem(
        id: 3,
        collectionId: 1,
        mediaType: MediaType.movie,
      ).copyWith(rewatchCount: 2);
      await tester.pumpApp(
        const LikesScreen(),
        overrides: overrides(sample, replayed: <CollectionItem>[replayed]),
      );
      await tester.pumpAndSettle();

      // Marks and replays share the list until a chip narrows it.
      expect(find.byType(MarkedGroupTile), findsNWidgets(3));

      await tester.tap(kindChip(LikesKind.rewatched));
      await tester.pumpAndSettle();
      expect(find.byType(MarkedGroupTile), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(3)), findsOneWidget);

      // Replays and likes together bring the marked titles back.
      await tester.tap(kindChip(LikesKind.liked));
      await tester.pumpAndSettle();
      expect(find.byType(MarkedGroupTile), findsNWidgets(3));
    });

    testWidgets('a replayed title drops out when only likes are picked', (
      WidgetTester tester,
    ) async {
      final CollectionItem replayed = createTestCollectionItem(
        id: 3,
        collectionId: 1,
        mediaType: MediaType.movie,
      ).copyWith(rewatchCount: 2);
      await tester.pumpApp(
        const LikesScreen(),
        overrides: overrides(sample, replayed: <CollectionItem>[replayed]),
      );
      await tester.pumpAndSettle();

      await tester.tap(kindChip(LikesKind.liked));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<int>(3)), findsNothing);
    });
  });
}
