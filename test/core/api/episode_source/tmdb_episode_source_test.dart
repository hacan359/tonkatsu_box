import 'package:core/models/data_source.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/episode_source/tmdb_episode_source.dart';
import 'package:tonkatsu_box/core/api/episode_source/tv_episode_source.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockTmdbApi mockApi;
  late TmdbEpisodeSource source;

  setUp(() {
    mockApi = MockTmdbApi();
    source = TmdbEpisodeSource(mockApi);
  });

  group('TmdbEpisodeSource', () {
    test('getShow delegates to TmdbApi.getTvShow', () async {
      const TvShow show = TvShow(tmdbId: 100, title: 'Show');
      when(() => mockApi.getTvShow(100)).thenAnswer((_) async => show);

      expect(await source.getShow(100), show);
    });

    test('getSeasons delegates to TmdbApi.getTvSeasons', () async {
      const List<TvSeason> seasons = <TvSeason>[
        TvSeason(tmdbShowId: 100, seasonNumber: 1),
      ];
      when(() => mockApi.getTvSeasons(100)).thenAnswer((_) async => seasons);

      expect(await source.getSeasons(100), seasons);
    });

    test('getSeasonEpisodes delegates to TmdbApi.getSeasonEpisodes', () async {
      const List<TvEpisode> episodes = <TvEpisode>[
        TvEpisode(
          tmdbShowId: 100,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Pilot',
        ),
      ];
      when(() => mockApi.getSeasonEpisodes(100, 1))
          .thenAnswer((_) async => episodes);

      expect(await source.getSeasonEpisodes(100, 1), episodes);
    });
  });

  group('tvEpisodeSourceResolverProvider', () {
    test('resolves every source to an implementation', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          tmdbApiProvider.overrideWithValue(mockApi),
        ],
      );
      addTearDown(container.dispose);

      final TvEpisodeSource Function(DataSource) resolve =
          container.read(tvEpisodeSourceResolverProvider);

      for (final DataSource s in DataSource.values) {
        expect(resolve(s), isA<TvEpisodeSource>());
      }
    });
  });
}
