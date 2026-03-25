import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/anime.dart';

void main() {
  group('Anime', () {
    group('fromJson', () {
      test('parses full AniList response', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{
            'romaji': 'Cowboy Bebop',
            'english': 'Cowboy Bebop',
            'native': 'カウボーイビバップ',
          },
          'coverImage': <String, dynamic>{
            'large': 'https://img.anilist.co/large.jpg',
            'medium': 'https://img.anilist.co/medium.jpg',
          },
          'description': 'A space bounty hunter crew.',
          'genres': <String>['Action', 'Adventure', 'Sci-Fi'],
          'averageScore': 86,
          'meanScore': 85,
          'popularity': 190000,
          'status': 'FINISHED',
          'season': 'SPRING',
          'seasonYear': 1998,
          'startDate': <String, dynamic>{
            'year': 1998,
            'month': 4,
            'day': 3,
          },
          'episodes': 26,
          'format': 'TV',
          'studios': <String, dynamic>{
            'nodes': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Sunrise'},
            ],
          },
        };

        final Anime anime = Anime.fromJson(json);

        expect(anime.id, 1);
        expect(anime.title, 'Cowboy Bebop');
        expect(anime.titleEnglish, 'Cowboy Bebop');
        expect(anime.titleNative, 'カウボーイビバップ');
        expect(anime.coverUrl, 'https://img.anilist.co/large.jpg');
        expect(anime.coverUrlMedium, 'https://img.anilist.co/medium.jpg');
        expect(anime.description, 'A space bounty hunter crew.');
        expect(anime.genres, <String>['Action', 'Adventure', 'Sci-Fi']);
        expect(anime.averageScore, 86);
        expect(anime.meanScore, 85);
        expect(anime.popularity, 190000);
        expect(anime.status, 'FINISHED');
        expect(anime.season, 'SPRING');
        expect(anime.seasonYear, 1998);
        expect(anime.startYear, 1998);
        expect(anime.startMonth, 4);
        expect(anime.startDay, 3);
        expect(anime.episodes, 26);
        expect(anime.format, 'TV');
        expect(anime.studios, <String>['Sunrise']);
        expect(anime.externalUrl, 'https://anilist.co/anime/1');
      });

      test('handles missing optional fields', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 99,
          'title': <String, dynamic>{'romaji': 'Test Anime'},
        };

        final Anime anime = Anime.fromJson(json);

        expect(anime.id, 99);
        expect(anime.title, 'Test Anime');
        expect(anime.titleEnglish, isNull);
        expect(anime.coverUrl, isNull);
        expect(anime.description, isNull);
        expect(anime.genres, isNull);
        expect(anime.episodes, isNull);
        expect(anime.studios, isNull);
      });

      test('strips HTML from description', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'description': '<b>Bold</b> &amp; <i>italic</i>',
        };

        final Anime anime = Anime.fromJson(json);
        expect(anime.description, 'Bold & italic');
      });

      test('falls back to english title when romaji is null', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'english': 'English Title'},
        };

        final Anime anime = Anime.fromJson(json);
        expect(anime.title, 'English Title');
      });

      test('falls back to Unknown when no title', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{},
        };

        final Anime anime = Anime.fromJson(json);
        expect(anime.title, 'Unknown');
      });

      test('ignores empty studios', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'studios': <String, dynamic>{
            'nodes': <Map<String, dynamic>>[],
          },
        };

        final Anime anime = Anime.fromJson(json);
        expect(anime.studios, isNull);
      });
    });

    group('fromDb', () {
      test('parses database row', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'title': 'Cowboy Bebop',
          'title_english': 'Cowboy Bebop',
          'title_native': null,
          'description': 'A show.',
          'cover_url': 'https://example.com/large.jpg',
          'cover_url_medium': null,
          'average_score': 86,
          'mean_score': null,
          'popularity': 190000,
          'status': 'FINISHED',
          'season': 'SPRING',
          'season_year': 1998,
          'start_year': 1998,
          'start_month': 4,
          'start_day': 3,
          'episodes': 26,
          'format': 'TV',
          'genres': jsonEncode(<String>['Action']),
          'studios': jsonEncode(<String>['Sunrise']),
          'external_url': 'https://anilist.co/anime/1',
          'updated_at': 1000,
        };

        final Anime anime = Anime.fromDb(row);

        expect(anime.id, 1);
        expect(anime.title, 'Cowboy Bebop');
        expect(anime.genres, <String>['Action']);
        expect(anime.studios, <String>['Sunrise']);
        expect(anime.episodes, 26);
      });

      test('handles null genres and studios', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'title': 'Test',
          'title_english': null,
          'title_native': null,
          'description': null,
          'cover_url': null,
          'cover_url_medium': null,
          'average_score': null,
          'mean_score': null,
          'popularity': null,
          'status': null,
          'season': null,
          'season_year': null,
          'start_year': null,
          'start_month': null,
          'start_day': null,
          'episodes': null,
          'format': null,
          'genres': null,
          'studios': null,
          'external_url': null,
          'updated_at': null,
        };

        final Anime anime = Anime.fromDb(row);
        expect(anime.genres, isNull);
        expect(anime.studios, isNull);
      });
    });

    group('toDb', () {
      test('round-trips through fromDb', () {
        const Anime original = Anime(
          id: 42,
          title: 'Test',
          genres: <String>['Action', 'Drama'],
          studios: <String>['MAPPA'],
          episodes: 12,
          format: 'TV',
          status: 'RELEASING',
        );

        final Map<String, dynamic> db = original.toDb();
        final Anime restored = Anime.fromDb(db);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.genres, original.genres);
        expect(restored.studios, original.studios);
        expect(restored.episodes, original.episodes);
      });
    });

    group('computed properties', () {
      test('rating10 converts from 0-100 to 0-10', () {
        const Anime anime = Anime(id: 1, title: 'T', averageScore: 85);
        expect(anime.rating10, 8.5);
      });

      test('rating10 is null when averageScore is null', () {
        const Anime anime = Anime(id: 1, title: 'T');
        expect(anime.rating10, isNull);
      });

      test('releaseYear prefers seasonYear', () {
        const Anime anime = Anime(
          id: 1,
          title: 'T',
          seasonYear: 2020,
          startYear: 2019,
        );
        expect(anime.releaseYear, 2020);
      });

      test('releaseYear falls back to startYear', () {
        const Anime anime = Anime(id: 1, title: 'T', startYear: 2019);
        expect(anime.releaseYear, 2019);
      });

      test('formatLabel maps known formats', () {
        expect(
          const Anime(id: 1, title: 'T', format: 'TV').formatLabel,
          'TV',
        );
        expect(
          const Anime(id: 1, title: 'T', format: 'MOVIE').formatLabel,
          'Movie',
        );
        expect(
          const Anime(id: 1, title: 'T', format: 'OVA').formatLabel,
          'OVA',
        );
        expect(
          const Anime(id: 1, title: 'T', format: 'ONA').formatLabel,
          'ONA',
        );
      });

      test('statusLabel maps known statuses', () {
        expect(
          const Anime(id: 1, title: 'T', status: 'RELEASING').statusLabel,
          'Airing',
        );
        expect(
          const Anime(id: 1, title: 'T', status: 'FINISHED').statusLabel,
          'Finished',
        );
      });

      test('seasonLabel combines season and year', () {
        const Anime anime = Anime(
          id: 1,
          title: 'T',
          season: 'WINTER',
          seasonYear: 2024,
        );
        expect(anime.seasonLabel, 'Winter 2024');
      });

      test('seasonLabel without year', () {
        const Anime anime = Anime(id: 1, title: 'T', season: 'FALL');
        expect(anime.seasonLabel, 'Fall');
      });

      test('episodesString', () {
        expect(
          const Anime(id: 1, title: 'T', episodes: 24).episodesString,
          '24 ep',
        );
        expect(
          const Anime(id: 1, title: 'T').episodesString,
          '? ep',
        );
      });

      test('genresString joins with comma', () {
        const Anime anime = Anime(
          id: 1,
          title: 'T',
          genres: <String>['Action', 'Drama'],
        );
        expect(anime.genresString, 'Action, Drama');
      });
    });

    group('equality', () {
      test('same id means equal', () {
        const Anime a = Anime(id: 1, title: 'A');
        const Anime b = Anime(id: 1, title: 'B');
        expect(a, equals(b));
      });

      test('different id means not equal', () {
        const Anime a = Anime(id: 1, title: 'A');
        const Anime b = Anime(id: 2, title: 'A');
        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('creates copy with changed fields', () {
        const Anime original = Anime(id: 1, title: 'Original', episodes: 12);
        final Anime copy = original.copyWith(title: 'Changed', episodes: 24);

        expect(copy.id, 1);
        expect(copy.title, 'Changed');
        expect(copy.episodes, 24);
      });

      test('preserves unchanged fields', () {
        const Anime original = Anime(
          id: 1,
          title: 'Test',
          format: 'TV',
          status: 'FINISHED',
        );
        final Anime copy = original.copyWith(title: 'New');

        expect(copy.format, 'TV');
        expect(copy.status, 'FINISHED');
      });
    });

    group('toExport', () {
      test('excludes updated_at', () {
        const Anime anime = Anime(id: 1, title: 'T', updatedAt: 12345);
        final Map<String, dynamic> exported = anime.toExport();

        expect(exported.containsKey('updated_at'), isFalse);
        expect(exported['id'], 1);
      });
    });
  });
}
