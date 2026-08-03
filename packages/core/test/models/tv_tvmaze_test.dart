import 'package:core/models/data_source.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:test/test.dart';

void main() {
  group('TvShow.fromTvMaze', () {
    Map<String, dynamic> showJson() => <String, dynamic>{
          'id': 169,
          'name': 'Breaking Bad',
          'genres': <String>['Drama', 'Crime'],
          'status': 'Ended',
          'premiered': '2008-01-20',
          'rating': <String, dynamic>{'average': 9.2},
          'image': <String, dynamic>{
            'medium': 'm.jpg',
            'original': 'o.jpg',
          },
          'summary': '<p>A teacher turns to crime.</p>',
          'url': 'https://www.tvmaze.com/shows/169/breaking-bad',
        };

    test('maps core fields and stamps the tvmaze source', () {
      final TvShow show = TvShow.fromTvMaze(showJson());

      expect(show.tmdbId, 169);
      expect(show.title, 'Breaking Bad');
      expect(show.genres, <String>['Drama', 'Crime']);
      expect(show.status, 'Ended');
      expect(show.firstAirYear, 2008);
      expect(show.rating, 9.2);
      expect(show.posterUrl, 'o.jpg');
      expect(show.externalUrl,
          'https://www.tvmaze.com/shows/169/breaking-bad');
      expect(show.source, DataSource.tvmaze);
      expect(show.cachedAt, isNotNull);
    });

    test('strips HTML from the summary', () {
      final TvShow show = TvShow.fromTvMaze(showJson());
      expect(show.overview, 'A teacher turns to crime.');
    });

    test('leaves genres null when the list is empty', () {
      final Map<String, dynamic> json = showJson()..['genres'] = <String>[];
      expect(TvShow.fromTvMaze(json).genres, isNull);
    });

    test('derives season and episode totals from embedded seasons', () {
      final Map<String, dynamic> json = showJson()
        ..['_embedded'] = <String, dynamic>{
          'seasons': <Map<String, dynamic>>[
            <String, dynamic>{'episodeOrder': 7},
            <String, dynamic>{'episodeOrder': 13},
          ],
        };
      final TvShow show = TvShow.fromTvMaze(json);
      expect(show.totalSeasons, 2);
      expect(show.totalEpisodes, 20);
    });

    test('leaves totals null without embedded seasons', () {
      final TvShow show = TvShow.fromTvMaze(showJson());
      expect(show.totalSeasons, isNull);
      expect(show.totalEpisodes, isNull);
    });

    test('survives a round-trip through the DB with source preserved', () {
      final TvShow show = TvShow.fromTvMaze(showJson());
      final TvShow restored = TvShow.fromDb(show.toDb());
      expect(restored.source, DataSource.tvmaze);
      expect(restored.tmdbId, 169);
    });
  });

  group('TvSeason.fromTvMaze', () {
    test('maps number, episode order, air date and normalises empty name', () {
      final TvSeason season = TvSeason.fromTvMaze(
        <String, dynamic>{
          'number': 1,
          'name': '',
          'episodeOrder': 7,
          'premiereDate': '2008-01-20',
          'image': <String, dynamic>{'original': 'o.jpg'},
        },
        showId: 169,
      );

      expect(season.tmdbShowId, 169);
      expect(season.seasonNumber, 1);
      expect(season.name, isNull);
      expect(season.episodeCount, 7);
      expect(season.airDate, '2008-01-20');
      expect(season.posterUrl, 'o.jpg');
      expect(season.source, DataSource.tvmaze);
    });
  });

  group('TvEpisode.tryFromTvMaze', () {
    Map<String, dynamic> episodeJson() => <String, dynamic>{
          'season': 1,
          'number': 1,
          'name': 'Pilot',
          'airdate': '2008-01-20',
          'runtime': 60,
          'image': <String, dynamic>{'original': 'still.jpg'},
          'summary': '<p>The first episode.</p>',
        };

    test('maps fields, strips summary and stamps source', () {
      final TvEpisode? ep = TvEpisode.tryFromTvMaze(episodeJson(), showId: 169);

      expect(ep, isNotNull);
      expect(ep!.tmdbShowId, 169);
      expect(ep.seasonNumber, 1);
      expect(ep.episodeNumber, 1);
      expect(ep.name, 'Pilot');
      expect(ep.overview, 'The first episode.');
      expect(ep.airDate, '2008-01-20');
      expect(ep.runtime, 60);
      expect(ep.stillUrl, 'still.jpg');
      expect(ep.source, DataSource.tvmaze);
    });

    test('normalises an empty air date to null', () {
      final Map<String, dynamic> json = episodeJson()..['airdate'] = '';
      expect(TvEpisode.tryFromTvMaze(json, showId: 169)!.airDate, isNull);
    });

    test('returns null when season or number is missing', () {
      final Map<String, dynamic> noSeason = episodeJson()..['season'] = null;
      final Map<String, dynamic> noNumber = episodeJson()..['number'] = null;
      expect(TvEpisode.tryFromTvMaze(noSeason, showId: 169), isNull);
      expect(TvEpisode.tryFromTvMaze(noNumber, showId: 169), isNull);
    });
  });
}
