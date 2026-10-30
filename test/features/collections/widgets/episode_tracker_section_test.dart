import 'dart:async';

import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_mark.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/data/repositories/game_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/episode_tracker_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/item_marks_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/episode_tracker_section.dart';
import 'package:tonkatsu_box/shared/widgets/cached_image.dart';
import 'package:tonkatsu_box/shared/widgets/fractional_star_rating.dart';
import 'package:tonkatsu_box/shared/widgets/rating_badge.dart';

import '../../../helpers/test_helpers.dart';

const int testShowId = 63145;
const int testCollectionId = 1;
const int testItemId = 10;

const TvSeason specialsSeason = TvSeason(
  tmdbShowId: testShowId,
  seasonNumber: 0,
  name: 'Specials',
  episodeCount: 2,
);

const TvSeason season1 = TvSeason(
  tmdbShowId: testShowId,
  seasonNumber: 1,
  name: 'Season 1',
  episodeCount: 13,
);

void main() {
  late MockDatabaseService mockDb;
  late MockTvShowDao mockTvShowDao;
  late MockItemMarkDao mockItemMarkDao;
  late MockTmdbApi mockTmdbApi;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDb = MockDatabaseService();
    mockTvShowDao = MockTvShowDao();
    mockItemMarkDao = MockItemMarkDao();
    mockTmdbApi = MockTmdbApi();
    when(() => mockDb.tvShowDao).thenReturn(mockTvShowDao);
    when(() => mockDb.itemMarkDao).thenReturn(mockItemMarkDao);
    when(() => mockTvShowDao.getWatchedEpisodes(
            testCollectionId, DataSource.tmdb, testShowId))
        .thenAnswer((_) async => <(int, int), DateTime?>{});
    when(() => mockTvShowDao.getEpisodesByShowId(DataSource.tmdb, testShowId))
        .thenAnswer((_) async => <TvEpisode>[]);
    when(() => mockTvShowDao.getTvShowByTmdbId(any(),
        source: any(named: 'source'))).thenAnswer((_) async => null);
    when(() => mockTvShowDao.getTvSeasonsByShowId(any(), any()))
        .thenAnswer((_) async => <TvSeason>[]);
    when(() => mockItemMarkDao.getMarksForItem(testItemId))
        .thenAnswer((_) async => <ItemMark>[]);
    // The picked season's panel loads its episodes as soon as it appears.
    when(() => mockTvShowDao.getEpisodesByShowAndSeason(any(), any(), any()))
        .thenAnswer((_) async => <TvEpisode>[]);
    when(() => mockTmdbApi.getSeasonEpisodes(any(), any()))
        .thenAnswer((_) async => <TvEpisode>[]);
  });

  Future<void> pumpSeasonsList(
    WidgetTester tester,
    List<TvSeason> seasons, {
    List<Override> extraOverrides = const <Override>[],
  }) async {
    when(() =>
            mockTvShowDao.getTvSeasonsByShowId(DataSource.tmdb, testShowId))
        .thenAnswer((_) async => seasons);
    // Auto-status reads the collection list after a mark; still loading, it
    // bails before touching anything else.
    final MockCollectionRepository repository = MockCollectionRepository();
    when(() => repository.getItemsWithData(any()))
        .thenAnswer((_) => Completer<List<CollectionItem>>().future);

    await tester.pumpApp(
      const SingleChildScrollView(
        child: SeasonsListWidget(
          showId: testShowId,
          source: DataSource.tmdb,
          collectionId: testCollectionId,
          itemId: testItemId,
          accentColor: Colors.blue,
        ),
      ),
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
        tmdbApiProvider.overrideWithValue(mockTmdbApi),
        collectionRepositoryProvider.overrideWithValue(repository),
        gameRepositoryProvider.overrideWithValue(MockGameRepository()),
        ...extraOverrides,
      ],
      wrapInScaffold: true,
    );
  }

  EpisodeTrackerNotifier trackerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(SeasonsListWidget)))
          .read(episodeTrackerNotifierProvider((
            collectionId: testCollectionId,
            showId: testShowId,
            source: DataSource.tmdb,
          )).notifier);

  group('EpisodeTrackerSection', () {
    testWidgets('should render the header without overflow when narrow',
        (WidgetTester tester) async {
      when(() =>
              mockTvShowDao.getTvSeasonsByShowId(DataSource.tmdb, testShowId))
          .thenAnswer((_) async => <TvSeason>[season1]);

      await tester.pumpApp(
        const SingleChildScrollView(
          child: SizedBox(
            width: 240,
            child: EpisodeTrackerSection(
              collectionId: testCollectionId,
              itemId: testItemId,
              externalId: testShowId,
              source: DataSource.tmdb,
              tvShow: TvShow(
                tmdbId: testShowId,
                title: 'Test Show',
                totalEpisodes: 22,
                totalSeasons: 2,
              ),
              accentColor: Colors.blue,
            ),
          ),
        ),
        overrides: <Override>[
          databaseServiceProvider.overrideWithValue(mockDb),
          tmdbApiProvider.overrideWithValue(mockTmdbApi),
        ],
        wrapInScaffold: true,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'рисует прогресс-бар из totals трекера, когда карточка шоу без них',
        (WidgetTester tester) async {
      when(() =>
              mockTvShowDao.getTvSeasonsByShowId(DataSource.tmdb, testShowId))
          .thenAnswer((_) async => <TvSeason>[season1]);

      await tester.pumpApp(
        const SingleChildScrollView(
          child: EpisodeTrackerSection(
            collectionId: testCollectionId,
            itemId: testItemId,
            externalId: testShowId,
            source: DataSource.tmdb,
            tvShow: TvShow(tmdbId: testShowId, title: 'Sparse Show'),
            accentColor: Colors.blue,
          ),
        ),
        overrides: <Override>[
          databaseServiceProvider.overrideWithValue(mockDb),
          tmdbApiProvider.overrideWithValue(mockTmdbApi),
        ],
        wrapInScaffold: true,
      );
      await tester.pumpAndSettle();

      // Only the overall bar from the tracker totals: no season is open, so
      // no per-season bar yet.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('EpisodeTile', () {
    const TvEpisode episodeWithStill = TvEpisode(
      tmdbShowId: testShowId,
      seasonNumber: 1,
      episodeNumber: 1,
      name: 'Pilot',
      overview: 'The one where it all starts.',
      stillUrl: 'https://image.tmdb.org/t/p/w300/pilot.jpg',
      airDate: '2023-01-01',
      runtime: 45,
    );

    const TvEpisode episodeWithoutStill = TvEpisode(
      tmdbShowId: testShowId,
      seasonNumber: 1,
      episodeNumber: 2,
      name: 'Second',
    );

    Future<void> pumpTile(
      WidgetTester tester,
      TvEpisode episode, {
      bool isWatched = false,
    }) async {
      final MockImageCacheService mockImageCache = MockImageCacheService();
      when(() => mockImageCache.getImageUri(
            type: any(named: 'type'),
            imageId: any(named: 'imageId'),
            remoteUrl: any(named: 'remoteUrl'),
          )).thenAnswer((Invocation invocation) async => ImageResult(
            uri: invocation.namedArguments[#remoteUrl] as String?,
            isLocal: false,
            isMissing: false,
          ));

      await tester.pumpApp(
        SingleChildScrollView(
          child: EpisodeTile(
            episode: episode,
            isWatched: isWatched,
            trackerArg: (
              collectionId: testCollectionId,
              showId: testShowId,
              source: DataSource.tmdb,
            ),
            itemId: testItemId,
            accentColor: Colors.blue,
          ),
        ),
        overrides: <Override>[
          databaseServiceProvider.overrideWithValue(mockDb),
          tmdbApiProvider.overrideWithValue(mockTmdbApi),
          imageCacheServiceProvider.overrideWithValue(mockImageCache),
          collectionItemsNotifierProvider.overrideWith(
            MockCollectionItemsNotifier.new,
          ),
        ],
        wrapInScaffold: true,
      );
      await tester.pump();
    }

    testWidgets('should show the still when the episode has one',
        (WidgetTester tester) async {
      await pumpTile(tester, episodeWithStill);

      expect(tester.takeException(), isNull);
      expect(find.byType(CachedImage), findsOneWidget);
    });

    testWidgets('should not build an image when the episode has no still',
        (WidgetTester tester) async {
      await pumpTile(tester, episodeWithoutStill);

      expect(tester.takeException(), isNull);
      expect(find.byType(CachedImage), findsNothing);
    });

    testWidgets('should render the overview text', (WidgetTester tester) async {
      await pumpTile(tester, episodeWithStill);

      expect(find.text(episodeWithStill.overview!), findsOneWidget);
    });

    testWidgets('should toggle the episode when the row is tapped',
        (WidgetTester tester) async {
      when(() => mockTvShowDao.markEpisodeWatched(
            any(), any(), any(), any(), any()))
          .thenAnswer((_) async {});

      await pumpTile(tester, episodeWithoutStill);
      await tester.tap(find.text('E2: Second'));
      await tester.pump();

      verify(() => mockTvShowDao.markEpisodeWatched(
            testCollectionId,
            DataSource.tmdb,
            testShowId,
            1,
            2,
          )).called(1);
    });

    testWidgets(
        'renders long texts without exception on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final TvEpisode verboseEpisode = TvEpisode(
        tmdbShowId: testShowId,
        seasonNumber: 1,
        episodeNumber: 3,
        name: 'A very long episode title that keeps going and going far '
            'beyond what any phone row could ever hope to fit on one line',
        overview: 'An extremely long synopsis sentence repeated many times. ' *
            30,
        stillUrl: 'https://image.tmdb.org/t/p/w300/e3.jpg',
        airDate: '2023-01-15',
        runtime: 62,
      );

      await pumpTile(tester, verboseEpisode);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should not toggle the episode when the overview is tapped',
        (WidgetTester tester) async {
      when(() => mockTvShowDao.markEpisodeWatched(
            any(), any(), any(), any(), any()))
          .thenAnswer((_) async {});

      await pumpTile(tester, episodeWithStill);
      await tester.tap(find.text(episodeWithStill.overview!));
      await tester.pump();

      verifyNever(() => mockTvShowDao.markEpisodeWatched(
            any(), any(), any(), any(), any()));
    });
  });

  group('seasonPostersPerRow', () {
    test('should never drop below one poster', () {
      expect(seasonPostersPerRow(0), 1);
      expect(seasonPostersPerRow(50), 1);
      expect(seasonPostersPerRow(double.infinity), 1);
    });

    test('should count the gap only between posters', () {
      // 92 px posters with 8 px gaps: 3 posters take 292 px.
      expect(seasonPostersPerRow(291), 2);
      expect(seasonPostersPerRow(292), 3);
      expect(seasonPostersPerRow(400), 4);
    });
  });

  group('SeasonsListWidget', () {
    testWidgets('показывает Specials (season 0) в списке сезонов',
        (WidgetTester tester) async {
      await pumpSeasonsList(tester, <TvSeason>[specialsSeason, season1]);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<int>(0)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
    });

    testWidgets('should load the cached episode metadata once on mount',
        (WidgetTester tester) async {
      await pumpSeasonsList(tester, <TvSeason>[season1]);

      verify(() =>
              mockTvShowDao.getEpisodesByShowId(DataSource.tmdb, testShowId))
          .called(1);
    });

    testWidgets('should show the season poster when the season has one',
        (WidgetTester tester) async {
      const TvSeason seasonWithPoster = TvSeason(
        tmdbShowId: testShowId,
        seasonNumber: 1,
        name: 'Season 1',
        episodeCount: 13,
        posterUrl: 'https://image.tmdb.org/t/p/w342/s1.jpg',
      );
      final MockImageCacheService mockImageCache = MockImageCacheService();
      when(() => mockImageCache.getImageUri(
            type: any(named: 'type'),
            imageId: any(named: 'imageId'),
            remoteUrl: any(named: 'remoteUrl'),
          )).thenAnswer((Invocation invocation) async => ImageResult(
            uri: invocation.namedArguments[#remoteUrl] as String?,
            isLocal: false,
            isMissing: false,
          ));

      when(() =>
              mockTvShowDao.getTvSeasonsByShowId(DataSource.tmdb, testShowId))
          .thenAnswer((_) async => <TvSeason>[seasonWithPoster]);

      await tester.pumpApp(
        const SingleChildScrollView(
          child: SeasonsListWidget(
            showId: testShowId,
            source: DataSource.tmdb,
            collectionId: testCollectionId,
            itemId: testItemId,
            accentColor: Colors.blue,
          ),
        ),
        overrides: <Override>[
          databaseServiceProvider.overrideWithValue(mockDb),
          tmdbApiProvider.overrideWithValue(mockTmdbApi),
          imageCacheServiceProvider.overrideWithValue(mockImageCache),
        ],
        wrapInScaffold: true,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CachedImage), findsOneWidget);
    });

    testWidgets('Specials идут после обычных сезонов',
        (WidgetTester tester) async {
      // TMDB returns season 0 first — the widget must reorder it to the end.
      await pumpSeasonsList(tester, <TvSeason>[specialsSeason, season1]);

      // Posters wrap, so "after" is reading order: a later row, or further
      // right on the same one.
      final Offset specialsAt =
          tester.getTopLeft(find.byKey(const ValueKey<int>(0)));
      final Offset season1At =
          tester.getTopLeft(find.byKey(const ValueKey<int>(1)));
      expect(
        specialsAt.dy > season1At.dy ||
            (specialsAt.dy == season1At.dy && specialsAt.dx > season1At.dx),
        isTrue,
      );
    });

    testWidgets('длинное название сезона не ломает вёрстку на телефоне',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const TvSeason verboseSeason = TvSeason(
        tmdbShowId: testShowId,
        seasonNumber: 1,
        name: 'The First and Extraordinarily Verbosely Named Season of the '
            'Show That Never Learned Brevity',
        episodeCount: 13,
        airDate: '2023-01-01',
      );

      await pumpSeasonsList(tester, <TvSeason>[verboseSeason]);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should open the episode panel under the tapped row',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final List<TvSeason> seasons = <TvSeason>[
        for (int n = 1; n <= 8; n++)
          TvSeason(
            tmdbShowId: testShowId,
            seasonNumber: n,
            name: 'Season $n',
            episodeCount: 10,
          ),
      ];
      await pumpSeasonsList(tester, seasons);
      await tester.pumpAndSettle();

      // Nothing opens on its own.
      expect(find.byType(SeasonPanel), findsNothing);

      await tester.tap(find.byKey(const ValueKey<int>(1)));
      await tester.pumpAndSettle();

      // Season 1 sits in the first row: its panel lands above the last row.
      final Finder firstPanel =
          find.byKey(const ValueKey<String>('season-panel-1'));
      expect(firstPanel, findsOneWidget);
      final double lastSeasonTop =
          tester.getTopLeft(find.byKey(const ValueKey<int>(8))).dy;
      expect(tester.getTopLeft(firstPanel).dy, lessThan(lastSeasonTop));

      await tester.tap(find.byKey(const ValueKey<int>(8)));
      await tester.pumpAndSettle();

      final Finder lastPanel =
          find.byKey(const ValueKey<String>('season-panel-8'));
      expect(firstPanel, findsNothing);
      expect(lastPanel, findsOneWidget);
      expect(tester.getTopLeft(lastPanel).dy,
          greaterThan(tester.getBottomLeft(find.byKey(const ValueKey<int>(8))).dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should wrap many seasons inside a desktop card column',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      const int seasonCount = 25;
      when(() =>
              mockTvShowDao.getTvSeasonsByShowId(DataSource.tmdb, testShowId))
          .thenAnswer((_) async => <TvSeason>[
                for (int n = 1; n <= seasonCount; n++)
                  TvSeason(
                    tmdbShowId: testShowId,
                    seasonNumber: n,
                    name: 'Season $n',
                    episodeCount: 10,
                  ),
              ]);

      // Same shape as the desktop card: an aside, then the main column.
      await tester.pumpApp(
        const SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 300),
              Expanded(
                child: SeasonsListWidget(
                  showId: testShowId,
                  source: DataSource.tmdb,
                  collectionId: testCollectionId,
                  itemId: testItemId,
                  accentColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        overrides: <Override>[
          databaseServiceProvider.overrideWithValue(mockDb),
          tmdbApiProvider.overrideWithValue(mockTmdbApi),
        ],
        wrapInScaffold: true,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (int n = 1; n <= seasonCount; n++) {
        expect(
          tester.getTopRight(find.byKey(ValueKey<int>(n))).dx,
          lessThanOrEqualTo(1280),
          reason: 'season $n',
        );
      }
      expect(
        tester.getTopLeft(find.byKey(const ValueKey<int>(seasonCount))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey<int>(1))).dy),
      );
    });

    testWidgets('should keep every season poster mounted when a mark changes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final MockImageCacheService mockImageCache = MockImageCacheService();
      when(() => mockImageCache.getImageUri(
            type: any(named: 'type'),
            imageId: any(named: 'imageId'),
            remoteUrl: any(named: 'remoteUrl'),
          )).thenAnswer((Invocation invocation) async => ImageResult(
            uri: invocation.namedArguments[#remoteUrl] as String?,
            isLocal: false,
            isMissing: false,
          ));
      when(() => mockImageCache.localPathIfCached(any(), any()))
          .thenReturn(null);
      when(() => mockTvShowDao.markEpisodeWatched(
          any(), any(), any(), any(), any())).thenAnswer((_) async {});

      await pumpSeasonsList(
        tester,
        <TvSeason>[
          for (int n = 1; n <= 6; n++)
            TvSeason(
              tmdbShowId: testShowId,
              seasonNumber: n,
              name: 'Season $n',
              episodeCount: 10,
              posterUrl: 'https://image.tmdb.org/t/p/w342/s$n.jpg',
            ),
        ],
        extraOverrides: <Override>[
          imageCacheServiceProvider.overrideWithValue(mockImageCache),
        ],
      );
      await tester.pumpAndSettle();

      Map<int, State<StatefulWidget>> posterStates() =>
          <int, State<StatefulWidget>>{
            for (int n = 1; n <= 6; n++)
              n: tester.state(find.descendant(
                of: find.byKey(ValueKey<int>(n)),
                matching: find.byType(CachedImage),
              )),
          };
      final Map<int, State<StatefulWidget>> before = posterStates();

      await trackerOf(tester).toggleEpisode(1, 1);
      await tester.pumpAndSettle();

      final Map<int, State<StatefulWidget>> after = posterStates();
      for (int n = 1; n <= 6; n++) {
        expect(identical(before[n], after[n]), isTrue, reason: 'season $n');
      }
    });

    testWidgets(
        'should keep the open season after marking it all watched instead of '
        'jumping to the next one', (WidgetTester tester) async {
      when(() => mockTvShowDao.getEpisodesByShowAndSeason(
              DataSource.tmdb, testShowId, 1))
          .thenAnswer((_) async => <TvEpisode>[
                for (int e = 1; e <= 2; e++)
                  TvEpisode(
                    tmdbShowId: testShowId,
                    seasonNumber: 1,
                    episodeNumber: e,
                    name: 'Episode $e',
                  ),
              ]);
      when(() => mockTvShowDao.markSeasonWatched(
          any(), any(), any(), any(), any())).thenAnswer((_) async {});
      await pumpSeasonsList(tester, <TvSeason>[
        for (int n = 1; n <= 2; n++)
          TvSeason(
            tmdbShowId: testShowId,
            seasonNumber: n,
            name: 'Season $n',
            episodeCount: 2,
          ),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(1)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('season-panel-1')),
          findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byKey(const ValueKey<String>('season-panel-1')),
        matching: find.byIcon(Icons.done_all),
      ));
      await tester.pumpAndSettle();

      verify(() => mockTvShowDao.markSeasonWatched(
          testCollectionId, DataSource.tmdb, testShowId, 1, <int>[1, 2]))
          .called(1);
      expect(find.byKey(const ValueKey<String>('season-panel-1')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('season-panel-2')),
          findsNothing);
    });

    testWidgets('should open no panel until a season is tapped',
        (WidgetTester tester) async {
      await pumpSeasonsList(tester, <TvSeason>[season1, specialsSeason]);
      await tester.pumpAndSettle();

      expect(find.byType(SeasonPanel), findsNothing);
      verifyNever(() =>
          mockTvShowDao.getEpisodesByShowAndSeason(any(), any(), any()));
    });

    testWidgets('should collapse the panel when the open season is tapped',
        (WidgetTester tester) async {
      await pumpSeasonsList(tester, <TvSeason>[season1]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(1)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('season-panel-1')),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<int>(1)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('season-panel-1')),
          findsNothing);
    });

    testWidgets('рендерится без Specials, если season 0 нет',
        (WidgetTester tester) async {
      await pumpSeasonsList(tester, <TvSeason>[season1]);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<int>(0)), findsNothing);
      expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
    });
  });

  group('season rating', () {
    ItemMark seasonMark(int season, double rating) => ItemMark(
          id: 1,
          itemId: testItemId,
          unitType: kUnitSeason,
          parentNumber: season,
          unitNumber: 0,
          isFavorite: false,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          userRating: rating,
        );

    testWidgets('should show the badge on the poster and the value in the '
        'header of a rated season', (WidgetTester tester) async {
      when(() => mockItemMarkDao.getMarksForItem(testItemId))
          .thenAnswer((_) async => <ItemMark>[seasonMark(1, 8.5)]);

      await pumpSeasonsList(tester, <TvSeason>[season1]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(1)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(1)),
          matching: find.byType(RatingBadge),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('season-panel-1')),
          matching: find.text('8.5'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should show no badge and an outlined star when unrated',
        (WidgetTester tester) async {
      await pumpSeasonsList(tester, <TvSeason>[season1]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(1)));
      await tester.pumpAndSettle();

      expect(find.byType(RatingBadge), findsNothing);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('should open the picker and write the picked rating',
        (WidgetTester tester) async {
      when(() => mockItemMarkDao.setRating(any(), any(), any(), any(), any()))
          .thenAnswer((Invocation i) async =>
              seasonMark(1, i.positionalArguments[4] as double));

      await pumpSeasonsList(tester, <TvSeason>[season1]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();
      expect(find.byType(FractionalStarRating), findsOneWidget);

      await tester.tap(find.byType(FractionalStarRating));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final double written = verify(() => mockItemMarkDao.setRating(
            testItemId,
            kUnitSeason,
            1,
            0,
            captureAny(),
          )).captured.single as double;
      expect(written, inInclusiveRange(1.0, 10.0));
      expect(find.byType(FractionalStarRating), findsNothing);
      expect(find.byType(RatingBadge), findsOneWidget);
    });

    testWidgets('should keep the picker on screen at phone width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpSeasonsList(tester, <TvSeason>[season1]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final Rect picker =
          tester.getRect(find.byType(FractionalStarRating));
      expect(picker.left, greaterThanOrEqualTo(0));
      expect(picker.right, lessThanOrEqualTo(360));
    });

    testWidgets('should keep the posters mounted when a rating is set',
        (WidgetTester tester) async {
      final MockImageCacheService mockImageCache = MockImageCacheService();
      when(() => mockImageCache.getImageUri(
            type: any(named: 'type'),
            imageId: any(named: 'imageId'),
            remoteUrl: any(named: 'remoteUrl'),
          )).thenAnswer((Invocation invocation) async => ImageResult(
            uri: invocation.namedArguments[#remoteUrl] as String?,
            isLocal: false,
            isMissing: false,
          ));
      when(() => mockImageCache.localPathIfCached(any(), any()))
          .thenReturn(null);
      when(() => mockItemMarkDao.setRating(any(), any(), any(), any(), any()))
          .thenAnswer((_) async => seasonMark(1, 7.0));

      await pumpSeasonsList(
        tester,
        <TvSeason>[
          const TvSeason(
            tmdbShowId: testShowId,
            seasonNumber: 1,
            name: 'Season 1',
            episodeCount: 13,
            posterUrl: 'https://image.tmdb.org/t/p/w342/s1.jpg',
          ),
        ],
        extraOverrides: <Override>[
          imageCacheServiceProvider.overrideWithValue(mockImageCache),
        ],
      );
      await tester.pumpAndSettle();

      Finder poster() => find.descendant(
            of: find.byKey(const ValueKey<int>(1)),
            matching: find.byType(CachedImage),
          );
      final State<StatefulWidget> before = tester.state(poster());

      await ProviderScope.containerOf(
              tester.element(find.byType(SeasonsListWidget)))
          .read(itemMarksProvider(testItemId).notifier)
          .setRating(kUnitSeason, 1, 0, 7.0);
      await tester.pumpAndSettle();

      expect(identical(before, tester.state(poster())), isTrue);
      expect(find.byType(RatingBadge), findsOneWidget);
    });
  });
}
