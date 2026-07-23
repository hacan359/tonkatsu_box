import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/episode_tracker_section.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/item_mark.dart';
import 'package:tonkatsu_box/shared/models/tv_episode.dart';
import 'package:tonkatsu_box/shared/models/tv_season.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';
import 'package:tonkatsu_box/shared/widgets/cached_image.dart';

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
  });

  Future<void> pumpSeasonsList(
    WidgetTester tester,
    List<TvSeason> seasons,
  ) async {
    when(() =>
            mockTvShowDao.getTvSeasonsByShowId(DataSource.tmdb, testShowId))
        .thenAnswer((_) async => seasons);

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
      ],
      wrapInScaffold: true,
    );
  }

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

      // The overall bar (from tracker totals) plus the per-season bar on the
      // single loaded season.
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
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

      final double specialsTop =
          tester.getTopLeft(find.byKey(const ValueKey<int>(0))).dy;
      final double season1Top =
          tester.getTopLeft(find.byKey(const ValueKey<int>(1))).dy;
      expect(specialsTop, greaterThan(season1Top));
    });

    testWidgets('рендерится без Specials, если season 0 нет',
        (WidgetTester tester) async {
      await pumpSeasonsList(tester, <TvSeason>[season1]);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<int>(0)), findsNothing);
      expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
    });
  });
}
