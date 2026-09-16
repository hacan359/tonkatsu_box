import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/home/providers/all_items_provider.dart';
import 'package:tonkatsu_box/features/showcase/models/showcase_item.dart';
import 'package:tonkatsu_box/features/showcase/providers/showcase_rows_provider.dart';
import 'package:tonkatsu_box/features/showcase/providers/showcase_settings_provider.dart';
import 'package:tonkatsu_box/features/showcase/screens/showcase_screen.dart';
import 'package:tonkatsu_box/features/showcase/widgets/release_board.dart';
import 'package:tonkatsu_box/features/showcase/widgets/release_card.dart';
import 'package:tonkatsu_box/shared/widgets/in_collection_badge.dart';

import '../../../helpers/test_helpers.dart';

class _FakeCollectionsNotifier extends CollectionsNotifier {
  @override
  Future<List<Collection>> build() async => const <Collection>[];
}

ShowcaseItem _item(int id, String title, {MediaType type = MediaType.movie}) =>
    ShowcaseItem(
      media: Object(),
      mediaType: type,
      source: DataSource.tmdb,
      externalId: id,
      title: title,
    );

void main() {
  late MockDatabaseService db;
  late MockGameDao gameDao;

  setUp(() {
    db = MockDatabaseService();
    gameDao = MockGameDao();
    when(() => db.gameDao).thenReturn(gameDao);
    when(gameDao.getAllPlatforms).thenAnswer((_) async => const <Platform>[]);
  });

  /// Every row answers [rows] (empty when absent) so no test touches the
  /// network; [failing] rows throw instead.
  List<Override> overrides({
    Map<ShowcaseRowId, List<ShowcaseItem>> rows =
        const <ShowcaseRowId, List<ShowcaseItem>>{},
    Set<ShowcaseRowId> failing = const <ShowcaseRowId>{},
    List<CollectionItem> library = const <CollectionItem>[],
    ShowcaseOwnedIds owned = const ShowcaseOwnedIds(),
  }) {
    return <Override>[
      databaseServiceProvider.overrideWithValue(db),
      collectionsProvider.overrideWith(_FakeCollectionsNotifier.new),
      visibleAllItemsProvider.overrideWith(
        (Ref ref) => AsyncValue<List<CollectionItem>>.data(library),
      ),
      showcaseOwnedIdsProvider.overrideWith((Ref ref) async => owned),
      for (final ShowcaseRowId id in ShowcaseRowId.values)
        showcaseRowProvider(id).overrideWith((Ref ref) async {
          if (failing.contains(id)) throw StateError('${id.key} failed');
          return rows[id] ?? const <ShowcaseItem>[];
        }),
    ];
  }

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('ShowcaseScreen', () {
    testWidgets('a failing row shows retry while its neighbours render', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const ShowcaseScreen(),
        overrides: overrides(
          rows: <ShowcaseRowId, List<ShowcaseItem>>{
            ShowcaseRowId.nowPlaying: <ShowcaseItem>[_item(1, 'Playing Now')],
          },
          failing: <ShowcaseRowId>{ShowcaseRowId.animeThisSeason},
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Playing Now'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry re-runs only the failed row', (
      WidgetTester tester,
    ) async {
      int animeBuilds = 0;
      int moviesBuilds = 0;
      await tester.pumpApp(
        const ShowcaseScreen(),
        overrides: <Override>[
          ...overrides(),
          animeThisSeasonProvider.overrideWith((Ref ref) async {
            animeBuilds++;
            throw StateError('down');
          }),
          nowPlayingProvider.overrideWith((Ref ref) async {
            moviesBuilds++;
            return <ShowcaseItem>[_item(1, 'Playing Now')];
          }),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(animeBuilds, 2);
      expect(moviesBuilds, 1);
    });

    testWidgets('empty rows take no space and hidden rows are not built', (
      WidgetTester tester,
    ) async {
      final SharedPreferences prefs = await prefsWith(<String, Object>{
        ShowcaseSettingsKeys.hiddenRows('default'): '["now_playing"]',
      });
      await tester.pumpApp(
        const ShowcaseScreen(),
        prefs: prefs,
        overrides: overrides(
          rows: <ShowcaseRowId, List<ShowcaseItem>>{
            ShowcaseRowId.nowPlaying: <ShowcaseItem>[_item(1, 'Hidden Row')],
            ShowcaseRowId.trendingMovies: <ShowcaseItem>[_item(2, 'Shown Row')],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hidden Row'), findsNothing);
      expect(find.text('Shown Row'), findsOneWidget);
      // Rows that answered empty render no cards of their own.
      expect(find.byType(ReleaseCard), findsOneWidget);
    });

    testWidgets('hideOwned drops collected items from the row', (
      WidgetTester tester,
    ) async {
      final SharedPreferences prefs = await prefsWith(<String, Object>{
        ShowcaseSettingsKeys.hideOwned('default'): true,
      });
      await tester.pumpApp(
        const ShowcaseScreen(),
        prefs: prefs,
        overrides: overrides(
          rows: <ShowcaseRowId, List<ShowcaseItem>>{
            ShowcaseRowId.nowPlaying: <ShowcaseItem>[
              _item(1, 'Owned Movie'),
              _item(2, 'New Movie'),
            ],
          },
          owned: const ShowcaseOwnedIds(tmdbMovies: <int>{1}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Owned Movie'), findsNothing);
      expect(find.text('New Movie'), findsOneWidget);
    });

    testWidgets('should badge a collected item when hideOwned is off', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const ShowcaseScreen(),
        overrides: overrides(
          rows: <ShowcaseRowId, List<ShowcaseItem>>{
            ShowcaseRowId.nowPlaying: <ShowcaseItem>[
              _item(1, 'Owned Movie'),
              _item(2, 'New Movie'),
            ],
          },
          owned: const ShowcaseOwnedIds(tmdbMovies: <int>{1}),
        ),
      );
      await tester.pumpAndSettle();

      final Finder ownedCard = find.ancestor(
        of: find.text('Owned Movie'),
        matching: find.byType(ReleaseCard),
      );
      final Finder newCard = find.ancestor(
        of: find.text('New Movie'),
        matching: find.byType(ReleaseCard),
      );
      expect(tester.widget<ReleaseCard>(ownedCard).isOwned, isTrue);
      expect(tester.widget<ReleaseCard>(newCard).isOwned, isFalse);
      expect(
        find.descendant(
          of: ownedCard,
          matching: find.byType(InCollectionBadge),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: newCard, matching: find.byType(InCollectionBadge)),
        findsNothing,
      );
    });

    testWidgets('rows follow the library: bigger types first', (
      WidgetTester tester,
    ) async {
      final List<CollectionItem> library = <CollectionItem>[
        createTestCollectionItem(id: 1, mediaType: MediaType.game),
        createTestCollectionItem(id: 2, mediaType: MediaType.game),
        createTestCollectionItem(id: 3, mediaType: MediaType.movie),
      ];
      await tester.pumpApp(
        const ShowcaseScreen(),
        overrides: overrides(
          library: library,
          rows: <ShowcaseRowId, List<ShowcaseItem>>{
            ShowcaseRowId.nowPlaying: <ShowcaseItem>[_item(1, 'Movie Row')],
            ShowcaseRowId.upcomingGames: <ShowcaseItem>[
              _item(2, 'Game Row', type: MediaType.game),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      final double gameY = tester.getTopLeft(find.text('Game Row')).dy;
      final double movieY = tester.getTopLeft(find.text('Movie Row')).dy;
      expect(gameY, lessThan(movieY));
    });

    testWidgets('all rows hidden shows the hint instead of a list', (
      WidgetTester tester,
    ) async {
      final SharedPreferences prefs = await prefsWith(<String, Object>{
        ShowcaseSettingsKeys.hiddenRows('default'):
            '[${ShowcaseRowId.values.map((ShowcaseRowId r) => '"${r.key}"').join(',')}]',
      });
      await tester.pumpApp(
        const ShowcaseScreen(),
        prefs: prefs,
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(ReleaseBoard), findsNothing);
    });

    testWidgets('lays out on a phone without exceptions', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const ShowcaseScreen(),
        overrides: overrides(
          rows: <ShowcaseRowId, List<ShowcaseItem>>{
            ShowcaseRowId.nowPlaying: <ShowcaseItem>[_item(1, 'Playing Now')],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
