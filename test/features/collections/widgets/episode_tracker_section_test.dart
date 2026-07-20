import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/widgets/episode_tracker_section.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/item_mark.dart';
import 'package:tonkatsu_box/shared/models/tv_episode.dart';
import 'package:tonkatsu_box/shared/models/tv_season.dart';

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

  group('SeasonsListWidget', () {
    testWidgets('показывает Specials (season 0) в списке сезонов',
        (WidgetTester tester) async {
      await pumpSeasonsList(tester, <TvSeason>[specialsSeason, season1]);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<int>(0)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
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
