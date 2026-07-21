import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/tv_show_dao.dart';
import 'package:tonkatsu_box/core/database/migrations/migration.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_registry.dart';
import 'package:tonkatsu_box/core/services/tv_show_cache_warmer.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/tv_episode.dart';
import 'package:tonkatsu_box/shared/models/tv_season.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const int showId = 45016;

  const TvShow fullShow = TvShow(
    tmdbId: showId,
    title: 'The Bridge',
    totalSeasons: 1,
    totalEpisodes: 2,
    status: 'Ended',
  );

  const List<TvSeason> apiSeasons = <TvSeason>[
    TvSeason(tmdbShowId: showId, seasonNumber: 1, episodeCount: 2),
  ];

  const List<TvEpisode> apiEpisodes = <TvEpisode>[
    TvEpisode(
      tmdbShowId: showId,
      seasonNumber: 1,
      episodeNumber: 1,
      name: 'Ep1',
    ),
    TvEpisode(
      tmdbShowId: showId,
      seasonNumber: 1,
      episodeNumber: 2,
      name: 'Ep2',
    ),
  ];

  late Database db;
  late TvShowDao dao;
  late MockTmdbApi tmdb;
  late MockDatabaseService dbService;
  late TvShowCacheWarmer warmer;

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
    dao = TvShowDao(() async => db);
    tmdb = MockTmdbApi();
    dbService = MockDatabaseService();
    when(() => dbService.tvShowDao).thenReturn(dao);
    warmer = TvShowCacheWarmer(tmdb: tmdb, db: dbService);
  });

  tearDown(() async {
    await db.close();
  });

  group('TvShowCacheWarmer', () {
    test('replaces a sparse show row and caches seasons with episodes',
        () async {
      // The row as written from a search/recommendation list: no totals.
      await dao.upsertTvShow(const TvShow(tmdbId: showId, title: 'Sparse'));
      when(() => tmdb.getTvShowWithSeasons(showId))
          .thenAnswer((_) async => (fullShow, apiSeasons));
      when(() => tmdb.getSeasonEpisodes(showId, 1))
          .thenAnswer((_) async => apiEpisodes);

      await warmer.warm(showId);

      final TvShow? show = await dao.getTvShowByTmdbId(showId);
      expect(show!.totalEpisodes, 2);
      expect(show.status, 'Ended');
      final List<TvSeason> seasons =
          await dao.getTvSeasonsByShowId(DataSource.tmdb, showId);
      expect(seasons, hasLength(1));
      final List<TvEpisode> episodes =
          await dao.getEpisodesByShowId(DataSource.tmdb, showId);
      expect(episodes, hasLength(2));
    });

    test('skips episode fetch for seasons already cached', () async {
      await dao.upsertTvSeasons(apiSeasons);
      await dao.upsertEpisodes(apiEpisodes);
      when(() => tmdb.getTvShowWithSeasons(showId))
          .thenAnswer((_) async => (fullShow, apiSeasons));

      await warmer.warm(showId);

      verifyNever(() => tmdb.getSeasonEpisodes(any(), any()));
    });

    test('swallows API failures and leaves the cache untouched', () async {
      await dao.upsertTvShow(const TvShow(tmdbId: showId, title: 'Sparse'));
      when(() => tmdb.getTvShowWithSeasons(showId))
          .thenThrow(Exception('network down'));

      await warmer.warm(showId);

      final TvShow? show = await dao.getTvShowByTmdbId(showId);
      expect(show!.totalEpisodes, isNull);
      expect(show.title, 'Sparse');
    });
  });
}
