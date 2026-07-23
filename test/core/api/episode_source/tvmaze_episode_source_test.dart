import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/episode_source/tmdb_episode_source.dart';
import 'package:tonkatsu_box/core/api/episode_source/tv_episode_source.dart';
import 'package:tonkatsu_box/core/api/episode_source/tvmaze_episode_source.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/api/tvmaze_api.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/tv_episode.dart';
import 'package:tonkatsu_box/shared/models/tv_season.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockTvMazeApi mockApi;
  late TvMazeEpisodeSource source;

  setUp(() {
    mockApi = MockTvMazeApi();
    source = TvMazeEpisodeSource(mockApi);
  });

  group('TvMazeEpisodeSource', () {
    test('getShow delegates to TvMazeApi.getShow', () async {
      const TvShow show =
          TvShow(tmdbId: 1, title: 'S', source: DataSource.tvmaze);
      when(() => mockApi.getShow(1)).thenAnswer((_) async => show);
      expect(await source.getShow(1), show);
    });

    test('getSeasons delegates to TvMazeApi.getSeasons', () async {
      const List<TvSeason> seasons = <TvSeason>[
        TvSeason(tmdbShowId: 1, seasonNumber: 1, source: DataSource.tvmaze),
      ];
      when(() => mockApi.getSeasons(1)).thenAnswer((_) async => seasons);
      expect(await source.getSeasons(1), seasons);
    });

    test('getSeasonEpisodes filters the flat list by season number', () async {
      const List<TvEpisode> all = <TvEpisode>[
        TvEpisode(
          tmdbShowId: 1,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'S1E1',
          source: DataSource.tvmaze,
        ),
        TvEpisode(
          tmdbShowId: 1,
          seasonNumber: 2,
          episodeNumber: 1,
          name: 'S2E1',
          source: DataSource.tvmaze,
        ),
      ];
      when(() => mockApi.getAllEpisodes(1)).thenAnswer((_) async => all);

      final List<TvEpisode> season2 = await source.getSeasonEpisodes(1, 2);
      expect(season2, hasLength(1));
      expect(season2.first.name, 'S2E1');
    });
  });

  group('tvEpisodeSourceResolverProvider', () {
    test('routes tvmaze to TvMazeEpisodeSource and others to TMDB', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          tmdbApiProvider.overrideWithValue(MockTmdbApi()),
          tvMazeApiProvider.overrideWithValue(mockApi),
        ],
      );
      addTearDown(container.dispose);

      final TvEpisodeSource Function(DataSource) resolve =
          container.read(tvEpisodeSourceResolverProvider);

      expect(resolve(DataSource.tvmaze), isA<TvMazeEpisodeSource>());
      expect(resolve(DataSource.tmdb), isA<TmdbEpisodeSource>());
      expect(resolve(DataSource.anilist), isA<TmdbEpisodeSource>());
    });
  });
}
