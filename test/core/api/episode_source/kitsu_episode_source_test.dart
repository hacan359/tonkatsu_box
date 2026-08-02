import 'package:core/models/anime.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/episode_source/kitsu_episode_source.dart';
import 'package:tonkatsu_box/core/api/episode_source/tmdb_episode_source.dart';
import 'package:tonkatsu_box/core/api/episode_source/tv_episode_source.dart';
import 'package:tonkatsu_box/core/api/kitsu_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/api/tvmaze_api.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockKitsuApi mockApi;
  late KitsuEpisodeSource source;

  setUp(() {
    mockApi = MockKitsuApi();
    source = KitsuEpisodeSource(mockApi);
  });

  TvEpisode ep(int season, int number) => TvEpisode(
        tmdbShowId: 7442,
        seasonNumber: season,
        episodeNumber: number,
        name: 'S${season}E$number',
        source: DataSource.kitsu,
      );

  group('getSeasons', () {
    test('one season for a record whose episodes are all season 1', () async {
      when(() => mockApi.getAnimeById(7442)).thenAnswer(
        (_) async => createTestAnime(
          id: 7442,
          source: DataSource.kitsu,
          episodes: 25,
          coverUrl: 'https://kitsu/poster.jpg',
        ),
      );
      when(() => mockApi.getAnimeEpisodes(7442))
          .thenAnswer((_) async => <TvEpisode>[ep(1, 1), ep(1, 2)]);

      final List<TvSeason> seasons = await source.getSeasons(7442);

      expect(seasons, hasLength(1));
      expect(seasons.single.seasonNumber, 1);
      expect(seasons.single.episodeCount, 2);
      expect(seasons.single.posterUrl, 'https://kitsu/poster.jpg');
      expect(seasons.single.source, DataSource.kitsu);
    });

    test('real seasons, ordered, with their own episode counts', () async {
      // Bleach-shaped: several seasons, absolute episode numbering.
      when(() => mockApi.getAnimeById(244)).thenAnswer(
        (_) async =>
            createTestAnime(id: 244, source: DataSource.kitsu, episodes: 366),
      );
      when(() => mockApi.getAnimeEpisodes(244)).thenAnswer(
        (_) async => <TvEpisode>[
          ep(2, 21),
          ep(1, 1),
          ep(3, 42),
          ep(2, 22),
        ],
      );

      final List<TvSeason> seasons = await source.getSeasons(244);

      expect(seasons.map((TvSeason s) => s.seasonNumber), <int>[1, 2, 3]);
      expect(seasons.map((TvSeason s) => s.episodeCount), <int>[1, 2, 1]);
    });

    test('shares the fetch with getSeasonEpisodes — one request', () async {
      when(() => mockApi.getAnimeById(7442)).thenAnswer(
        (_) async =>
            createTestAnime(id: 7442, source: DataSource.kitsu, episodes: 2),
      );
      when(() => mockApi.getAnimeEpisodes(7442))
          .thenAnswer((_) async => <TvEpisode>[ep(1, 1), ep(2, 2)]);

      await source.getSeasons(7442);
      await source.getSeasonEpisodes(7442, 2);

      verify(() => mockApi.getAnimeEpisodes(7442)).called(1);
    });

    test('falls back to one season when the episode list fails', () async {
      when(() => mockApi.getAnimeById(1)).thenAnswer(
        (_) async =>
            createTestAnime(id: 1, source: DataSource.kitsu, episodes: 12),
      );
      when(() => mockApi.getAnimeEpisodes(1)).thenThrow(Exception('offline'));

      final List<TvSeason> seasons = await source.getSeasons(1);

      expect(seasons, hasLength(1));
      expect(seasons.single.seasonNumber, 1);
      expect(seasons.single.episodeCount, 12);
    });

    test('asks for the count when the record has none and the list is empty',
        () async {
      when(() => mockApi.getAnimeById(1)).thenAnswer(
        (_) async => createTestAnime(id: 1, source: DataSource.kitsu),
      );
      when(() => mockApi.getAnimeEpisodes(1))
          .thenAnswer((_) async => <TvEpisode>[]);
      when(() => mockApi.getAnimeEpisodeCount(1)).thenAnswer((_) async => 1390);

      final List<TvSeason> seasons = await source.getSeasons(1);

      expect(seasons.single.episodeCount, 1390);
    });

    test('still yields a season when the anime is unknown', () async {
      when(() => mockApi.getAnimeById(1)).thenAnswer((_) async => null);
      when(() => mockApi.getAnimeEpisodes(1))
          .thenAnswer((_) async => <TvEpisode>[]);
      when(() => mockApi.getAnimeEpisodeCount(1)).thenAnswer((_) async => null);

      final List<TvSeason> seasons = await source.getSeasons(1);

      expect(seasons, hasLength(1));
      expect(seasons.single.episodeCount, isNull);
    });
  });

  group('getSeasonEpisodes', () {
    test('filters the flat list by season number', () async {
      when(() => mockApi.getAnimeEpisodes(7442)).thenAnswer(
        (_) async => <TvEpisode>[ep(1, 1), ep(2, 1), ep(2, 2)],
      );

      final List<TvEpisode> season2 = await source.getSeasonEpisodes(7442, 2);

      expect(season2, hasLength(2));
      expect(season2.every((TvEpisode e) => e.seasonNumber == 2), isTrue);
    });

    test('returns everything when no episode carries the synthesized season',
        () async {
      when(() => mockApi.getAnimeEpisodes(7442))
          .thenAnswer((_) async => <TvEpisode>[ep(2, 1), ep(2, 2)]);

      final List<TvEpisode> season1 = await source.getSeasonEpisodes(7442, 1);

      expect(season1, hasLength(2));
    });

    test('an empty other season stays empty', () async {
      when(() => mockApi.getAnimeEpisodes(7442))
          .thenAnswer((_) async => <TvEpisode>[ep(1, 1)]);

      expect(await source.getSeasonEpisodes(7442, 3), isEmpty);
    });

    test('fetches the list once across seasons of the same anime', () async {
      when(() => mockApi.getAnimeEpisodes(7442))
          .thenAnswer((_) async => <TvEpisode>[ep(1, 1), ep(2, 1)]);

      await source.getSeasonEpisodes(7442, 1);
      await source.getSeasonEpisodes(7442, 2);

      verify(() => mockApi.getAnimeEpisodes(7442)).called(1);
    });

    test('re-fetches after a failure instead of caching the error', () async {
      int calls = 0;
      when(() => mockApi.getAnimeEpisodes(7442)).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('network');
        return <TvEpisode>[ep(1, 1)];
      });

      await expectLater(
        source.getSeasonEpisodes(7442, 1),
        throwsA(isA<Exception>()),
      );
      expect(await source.getSeasonEpisodes(7442, 1), hasLength(1));
      expect(calls, 2);
    });

    test('a different anime refetches', () async {
      when(() => mockApi.getAnimeEpisodes(any()))
          .thenAnswer((_) async => <TvEpisode>[ep(1, 1)]);

      await source.getSeasonEpisodes(7442, 1);
      await source.getSeasonEpisodes(1, 1);

      verify(() => mockApi.getAnimeEpisodes(7442)).called(1);
      verify(() => mockApi.getAnimeEpisodes(1)).called(1);
    });
  });

  group('getShow', () {
    test('maps the anime record onto TvShow', () async {
      when(() => mockApi.getAnimeById(7442)).thenAnswer(
        (_) async => const Anime(
          id: 7442,
          source: DataSource.kitsu,
          title: 'Shingeki no Kyojin',
          titleNative: '進撃の巨人',
          description: 'Titans.',
          coverUrl: 'https://kitsu/poster.jpg',
          bannerUrl: 'https://kitsu/banner.jpg',
          averageScore: 84,
          episodes: 25,
          status: 'FINISHED',
          startYear: 2013,
          genres: <String>['Action'],
          externalUrl: 'https://kitsu.io/anime/attack-on-titan',
        ),
      );

      final TvShow? show = await source.getShow(7442);

      expect(show, isNotNull);
      expect(show!.tmdbId, 7442);
      expect(show.title, 'Shingeki no Kyojin');
      expect(show.originalTitle, '進撃の巨人');
      expect(show.posterUrl, 'https://kitsu/poster.jpg');
      expect(show.backdropUrl, 'https://kitsu/banner.jpg');
      expect(show.totalSeasons, isNull);
      expect(show.totalEpisodes, 25);
      expect(show.rating, closeTo(8.4, 0.001));
      expect(show.firstAirYear, 2013);
      expect(show.genres, <String>['Action']);
      expect(show.externalUrl, 'https://kitsu.io/anime/attack-on-titan');
      expect(show.source, DataSource.kitsu);
    });

    test('null when the anime is gone', () async {
      when(() => mockApi.getAnimeById(1)).thenAnswer((_) async => null);
      expect(await source.getShow(1), isNull);
    });

    test('shares the record with getSeasons — one request', () async {
      when(() => mockApi.getAnimeById(7442)).thenAnswer(
        (_) async =>
            createTestAnime(id: 7442, source: DataSource.kitsu, episodes: 25),
      );
      when(() => mockApi.getAnimeEpisodes(7442))
          .thenAnswer((_) async => <TvEpisode>[ep(1, 1)]);

      await source.getShow(7442);
      await source.getSeasons(7442);

      verify(() => mockApi.getAnimeById(7442)).called(1);
    });
  });

  group('tvEpisodeSourceResolverProvider', () {
    test('routes kitsu to KitsuEpisodeSource, others unchanged', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          tmdbApiProvider.overrideWithValue(MockTmdbApi()),
          tvMazeApiProvider.overrideWithValue(MockTvMazeApi()),
          kitsuApiProvider.overrideWithValue(mockApi),
        ],
      );
      addTearDown(container.dispose);

      final TvEpisodeSource Function(DataSource) resolve =
          container.read(tvEpisodeSourceResolverProvider);

      expect(resolve(DataSource.kitsu), isA<KitsuEpisodeSource>());
      expect(resolve(DataSource.tmdb), isA<TmdbEpisodeSource>());
      expect(resolve(DataSource.anilist), isA<TmdbEpisodeSource>());
    });
  });
}
