import 'package:core/database/dao/tv_show_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/api/episode_source/tv_episode_source.dart';
import 'package:tonkatsu_box/core/services/tv_show_cache_warmer.dart';

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
  late _MockTvEpisodeSource episodeSource;
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
    episodeSource = _MockTvEpisodeSource();
    dbService = MockDatabaseService();
    when(() => dbService.tvShowDao).thenReturn(dao);
    warmer = TvShowCacheWarmer(
      resolveSource: (DataSource _) => episodeSource,
      db: dbService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('TvShowCacheWarmer', () {
    test('replaces a sparse show row and caches seasons with episodes',
        () async {
      // The row as written from a search/recommendation list: no totals.
      await dao.upsertTvShow(const TvShow(tmdbId: showId, title: 'Sparse'));
      when(() => episodeSource.getShow(showId))
          .thenAnswer((_) async => fullShow);
      when(() => episodeSource.getSeasons(showId))
          .thenAnswer((_) async => apiSeasons);
      when(() => episodeSource.getSeasonEpisodes(showId, 1))
          .thenAnswer((_) async => apiEpisodes);

      await warmer.warm(showId, DataSource.tmdb);

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

    test('warms a TVmaze show from the resolved TVmaze source', () async {
      const TvShow tvmazeShow = TvShow(
        tmdbId: showId,
        title: 'The Bridge',
        totalSeasons: 1,
        source: DataSource.tvmaze,
      );
      when(() => episodeSource.getShow(showId))
          .thenAnswer((_) async => tvmazeShow);
      when(() => episodeSource.getSeasons(showId))
          .thenAnswer((_) async => const <TvSeason>[
                TvSeason(
                  tmdbShowId: showId,
                  seasonNumber: 1,
                  source: DataSource.tvmaze,
                ),
              ]);
      when(() => episodeSource.getSeasonEpisodes(showId, 1))
          .thenAnswer((_) async => const <TvEpisode>[]);

      await warmer.warm(showId, DataSource.tvmaze);

      final TvShow? show =
          await dao.getTvShowByTmdbId(showId, source: DataSource.tvmaze);
      expect(show, isNotNull);
      expect(show!.source, DataSource.tvmaze);
    });

    test('skips episode fetch for seasons already cached', () async {
      await dao.upsertTvSeasons(apiSeasons);
      await dao.upsertEpisodes(apiEpisodes);
      when(() => episodeSource.getShow(showId))
          .thenAnswer((_) async => fullShow);

      await warmer.warm(showId, DataSource.tmdb);

      verifyNever(() => episodeSource.getSeasonEpisodes(any(), any()));
      verifyNever(() => episodeSource.getSeasons(any()));
    });

    test('swallows API failures and leaves the cache untouched', () async {
      await dao.upsertTvShow(const TvShow(tmdbId: showId, title: 'Sparse'));
      when(() => episodeSource.getShow(showId))
          .thenThrow(Exception('network down'));

      await warmer.warm(showId, DataSource.tmdb);

      final TvShow? show = await dao.getTvShowByTmdbId(showId);
      expect(show!.totalEpisodes, isNull);
      expect(show.title, 'Sparse');
    });
  });
}

class _MockTvEpisodeSource extends Mock implements TvEpisodeSource {}
