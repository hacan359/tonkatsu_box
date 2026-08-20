import 'package:core/models/data_source.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/episode_source/tmdb_episode_source.dart';
import 'package:tonkatsu_box/core/api/episode_source/tv_episode_source.dart';
import 'package:tonkatsu_box/core/api/episode_source/tvdb_episode_source.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/api/tvdb_api.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockTvdbApi mockApi;
  late TvdbEpisodeSource source;

  TvEpisode episode(int season, int number) => TvEpisode(
        tmdbShowId: 1,
        seasonNumber: season,
        episodeNumber: number,
        name: 'S${season}E$number',
        source: DataSource.tvdb,
      );

  setUp(() {
    mockApi = MockTvdbApi();
    source = TvdbEpisodeSource(mockApi);
  });

  group('TvdbEpisodeSource', () {
    group('getShow', () {
      test('counts the episode list when the record has no total', () async {
        when(() => mockApi.getSeries(1)).thenAnswer((_) async =>
            const TvShow(tmdbId: 1, title: 'S', source: DataSource.tvdb));
        when(() => mockApi.getAllEpisodes(1)).thenAnswer((_) async =>
            <TvEpisode>[episode(1, 1), episode(1, 2), episode(2, 1)]);

        expect((await source.getShow(1))?.totalEpisodes, 3);
      });

      test('leaves specials out of the total', () async {
        when(() => mockApi.getSeries(1)).thenAnswer((_) async =>
            const TvShow(tmdbId: 1, title: 'S', source: DataSource.tvdb));
        when(() => mockApi.getAllEpisodes(1)).thenAnswer(
            (_) async => <TvEpisode>[episode(0, 1), episode(1, 1)]);

        expect((await source.getShow(1))?.totalEpisodes, 1);
      });

      test('keeps a total the record already states', () async {
        when(() => mockApi.getSeries(1)).thenAnswer((_) async => const TvShow(
              tmdbId: 1,
              title: 'S',
              totalEpisodes: 42,
              source: DataSource.tvdb,
            ));

        expect((await source.getShow(1))?.totalEpisodes, 42);
        verifyNever(() => mockApi.getAllEpisodes(any()));
      });

      test('leaves the total unknown when the episode list fails', () async {
        when(() => mockApi.getSeries(1)).thenAnswer((_) async =>
            const TvShow(tmdbId: 1, title: 'S', source: DataSource.tvdb));
        when(() => mockApi.getAllEpisodes(1))
            .thenAnswer((_) async => throw Exception('offline'));

        expect((await source.getShow(1))?.totalEpisodes, isNull);
      });
    });

    group('getSeasons', () {
      test('fills the episode count TheTVDB does not state', () async {
        when(() => mockApi.getSeasons(1)).thenAnswer((_) async =>
            const <TvSeason>[
              TvSeason(tmdbShowId: 1, seasonNumber: 1, source: DataSource.tvdb),
              TvSeason(tmdbShowId: 1, seasonNumber: 2, source: DataSource.tvdb),
            ]);
        when(() => mockApi.getAllEpisodes(1)).thenAnswer((_) async =>
            <TvEpisode>[episode(1, 1), episode(1, 2), episode(2, 1)]);

        final List<TvSeason> seasons = await source.getSeasons(1);

        expect(seasons.map((TvSeason s) => s.episodeCount), <int>[2, 1]);
      });

      test('reports a season with no episodes as zero', () async {
        when(() => mockApi.getSeasons(1)).thenAnswer((_) async =>
            const <TvSeason>[
              TvSeason(tmdbShowId: 1, seasonNumber: 9, source: DataSource.tvdb),
            ]);
        when(() => mockApi.getAllEpisodes(1))
            .thenAnswer((_) async => <TvEpisode>[episode(1, 1)]);

        expect((await source.getSeasons(1)).single.episodeCount, 0);
      });

      test('returns the seasons unchanged when the episode list fails',
          () async {
        when(() => mockApi.getSeasons(1)).thenAnswer((_) async =>
            const <TvSeason>[
              TvSeason(tmdbShowId: 1, seasonNumber: 1, source: DataSource.tvdb),
            ]);
        when(() => mockApi.getAllEpisodes(1))
            .thenAnswer((_) async => throw Exception('offline'));

        expect((await source.getSeasons(1)).single.episodeCount, isNull);
      });
    });

    test('getSeasonEpisodes filters the flat list by season number', () async {
      when(() => mockApi.getAllEpisodes(1)).thenAnswer(
          (_) async => <TvEpisode>[episode(1, 1), episode(2, 1)]);

      final List<TvEpisode> season2 = await source.getSeasonEpisodes(1, 2);

      expect(season2, hasLength(1));
      expect(season2.single.name, 'S2E1');
    });
  });

  group('tvEpisodeSourceResolverProvider', () {
    test('routes tvdb to TvdbEpisodeSource', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          tmdbApiProvider.overrideWithValue(MockTmdbApi()),
          tvdbApiProvider.overrideWithValue(mockApi),
        ],
      );
      addTearDown(container.dispose);

      final TvEpisodeSource Function(DataSource) resolve =
          container.read(tvEpisodeSourceResolverProvider);

      expect(resolve(DataSource.tvdb), isA<TvdbEpisodeSource>());
      expect(resolve(DataSource.tmdb), isA<TmdbEpisodeSource>());
    });
  });
}
