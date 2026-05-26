import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/manga.dart';

void main() {
  group('Manga', () {
    group('fromJson', () {
      test('should create Manga from full JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 30013,
          'title': <String, dynamic>{
            'romaji': 'One Punch-Man',
            'english': 'One-Punch Man',
            'native': 'ワンパンマン',
          },
          'description': '<p>A <b>superhero</b> parody manga.</p>',
          'coverImage': <String, dynamic>{
            'large': 'https://example.com/large.jpg',
            'medium': 'https://example.com/medium.jpg',
          },
          'averageScore': 84,
          'meanScore': 85,
          'popularity': 120000,
          'status': 'RELEASING',
          'startDate': <String, dynamic>{
            'year': 2012,
            'month': 6,
            'day': 14,
          },
          'chapters': null,
          'volumes': null,
          'format': 'MANGA',
          'countryOfOrigin': 'JP',
          'genres': <dynamic>['Action', 'Comedy', 'Sci-Fi'],
          'staff': <String, dynamic>{
            'edges': <dynamic>[
              <String, dynamic>{
                'node': <String, dynamic>{
                  'name': <String, dynamic>{'full': 'ONE'},
                },
                'role': 'Story',
              },
              <String, dynamic>{
                'node': <String, dynamic>{
                  'name': <String, dynamic>{'full': 'Yusuke Murata'},
                },
                'role': 'Art',
              },
              <String, dynamic>{
                'node': <String, dynamic>{
                  'name': <String, dynamic>{'full': 'Some Editor'},
                },
                'role': 'Editor',
              },
            ],
          },
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.id, 30013);
        expect(manga.title, 'One Punch-Man');
        expect(manga.titleEnglish, 'One-Punch Man');
        expect(manga.titleNative, 'ワンパンマン');
        expect(manga.description, 'A superhero parody manga.');
        expect(manga.coverUrl, 'https://example.com/large.jpg');
        expect(manga.coverUrlMedium, 'https://example.com/medium.jpg');
        expect(manga.averageScore, 84);
        expect(manga.status, 'RELEASING');
        expect(manga.startYear, 2012);
        expect(manga.startMonth, 6);
        expect(manga.startDay, 14);
        expect(manga.chapters, isNull);
        expect(manga.volumes, isNull);
        expect(manga.format, 'MANGA');
        expect(manga.genres, <String>['Action', 'Comedy', 'Sci-Fi']);
        expect(manga.authors, <String>['ONE', 'Yusuke Murata']);
        expect(manga.externalUrl, 'https://anilist.co/manga/30013');
        expect(manga.updatedAt, isNotNull);
      });

      test('should create Manga from minimal JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{
            'romaji': 'Naruto',
          },
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.id, 1);
        expect(manga.title, 'Naruto');
        expect(manga.titleEnglish, isNull);
        expect(manga.titleNative, isNull);
        expect(manga.description, isNull);
        expect(manga.coverUrl, isNull);
        expect(manga.coverUrlMedium, isNull);
        expect(manga.averageScore, isNull);
        expect(manga.meanScore, isNull);
        expect(manga.popularity, isNull);
        expect(manga.status, isNull);
        expect(manga.startYear, isNull);
        expect(manga.startMonth, isNull);
        expect(manga.startDay, isNull);
        expect(manga.chapters, isNull);
        expect(manga.volumes, isNull);
        expect(manga.format, isNull);
        expect(manga.countryOfOrigin, isNull);
        expect(manga.genres, isNull);
        expect(manga.authors, isNull);
        expect(manga.externalUrl, 'https://anilist.co/manga/1');
      });

      test('should use english title as fallback', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{
            'english': 'Naruto',
          },
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.title, 'Naruto');
      });

      test('should use Unknown when title is missing', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.title, 'Unknown');
      });

      test('should filter authors by role', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'staff': <String, dynamic>{
            'edges': <dynamic>[
              <String, dynamic>{
                'node': <String, dynamic>{
                  'name': <String, dynamic>{'full': 'Author'},
                },
                'role': 'Story & Art',
              },
              <String, dynamic>{
                'node': <String, dynamic>{
                  'name': <String, dynamic>{'full': 'Editor'},
                },
                'role': 'Editor',
              },
            ],
          },
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.authors, <String>['Author']);
      });

      test('should return null authors when list is empty after filtering',
          () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'staff': <String, dynamic>{
            'edges': <dynamic>[
              <String, dynamic>{
                'node': <String, dynamic>{
                  'name': <String, dynamic>{'full': 'Editor'},
                },
                'role': 'Editor',
              },
            ],
          },
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.authors, isNull);
      });

      test('should skip authors with empty names', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'staff': <String, dynamic>{
            'edges': <dynamic>[
              <String, dynamic>{
                'node': <String, dynamic>{
                  'name': <String, dynamic>{'full': ''},
                },
                'role': 'Story',
              },
              <String, dynamic>{
                'node': <String, dynamic>{
                  'name': <String, dynamic>{},
                },
                'role': 'Art',
              },
            ],
          },
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.authors, isNull);
      });

      test('should strip HTML from description', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'description':
              '<p>A <b>bold</b> &amp; <i>italic</i> description.</p>',
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.description, 'A bold & italic description.');
      });

      test('should return null description from empty HTML', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'description': '<br><br>',
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.description, isNull);
      });

      test('should decode HTML entities', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'description': 'He said &quot;hello&quot; &amp; &#39;bye&#39;',
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.description, 'He said "hello" & \'bye\'');
      });
    });

    group('fromDb', () {
      test('should create Manga from DB row', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 30013,
          'title': 'One Punch-Man',
          'title_english': 'One-Punch Man',
          'title_native': 'ワンパンマン',
          'description': 'A superhero parody manga.',
          'cover_url': 'https://example.com/large.jpg',
          'cover_url_medium': 'https://example.com/medium.jpg',
          'average_score': 84,
          'mean_score': 85,
          'popularity': 120000,
          'status': 'RELEASING',
          'start_year': 2012,
          'start_month': 6,
          'start_day': 14,
          'chapters': 200,
          'volumes': 25,
          'format': 'MANGA',
          'country_of_origin': 'JP',
          'genres': jsonEncode(<String>['Action', 'Comedy']),
          'authors': jsonEncode(<String>['ONE', 'Murata']),
          'external_url': 'https://anilist.co/manga/30013',
          'updated_at': 1700000000,
        };

        final Manga manga = Manga.fromDb(row);

        expect(manga.id, 30013);
        expect(manga.title, 'One Punch-Man');
        expect(manga.titleEnglish, 'One-Punch Man');
        expect(manga.titleNative, 'ワンパンマン');
        expect(manga.genres, <String>['Action', 'Comedy']);
        expect(manga.authors, <String>['ONE', 'Murata']);
        expect(manga.chapters, 200);
        expect(manga.volumes, 25);
        expect(manga.updatedAt, 1700000000);
      });

      test('should handle null JSON strings', () {
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
          'start_year': null,
          'start_month': null,
          'start_day': null,
          'chapters': null,
          'volumes': null,
          'format': null,
          'country_of_origin': null,
          'genres': null,
          'authors': null,
          'external_url': null,
          'updated_at': null,
        };

        final Manga manga = Manga.fromDb(row);

        expect(manga.genres, isNull);
        expect(manga.authors, isNull);
      });

      test('should handle empty JSON strings', () {
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
          'start_year': null,
          'start_month': null,
          'start_day': null,
          'chapters': null,
          'volumes': null,
          'format': null,
          'country_of_origin': null,
          'genres': '',
          'authors': '',
          'external_url': null,
          'updated_at': null,
        };

        final Manga manga = Manga.fromDb(row);

        expect(manga.genres, isNull);
        expect(manga.authors, isNull);
      });

      test('should handle malformed JSON strings', () {
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
          'start_year': null,
          'start_month': null,
          'start_day': null,
          'chapters': null,
          'volumes': null,
          'format': null,
          'country_of_origin': null,
          'genres': 'not-valid-json',
          'authors': '{broken}',
          'external_url': null,
          'updated_at': null,
        };

        final Manga manga = Manga.fromDb(row);

        expect(manga.genres, isNull);
        expect(manga.authors, isNull);
      });
    });

    group('toDb', () {
      test('should serialize to Map', () {
        const Manga manga = Manga(
          id: 30013,
          title: 'One Punch-Man',
          titleEnglish: 'One-Punch Man',
          titleNative: 'ワンパンマン',
          description: 'Desc',
          coverUrl: 'https://example.com/large.jpg',
          coverUrlMedium: 'https://example.com/medium.jpg',
          averageScore: 84,
          meanScore: 85,
          popularity: 120000,
          status: 'RELEASING',
          startYear: 2012,
          startMonth: 6,
          startDay: 14,
          chapters: 200,
          volumes: 25,
          format: 'MANGA',
          countryOfOrigin: 'JP',
          genres: <String>['Action', 'Comedy'],
          authors: <String>['ONE'],
          externalUrl: 'https://anilist.co/manga/30013',
          updatedAt: 1700000000,
        );

        final Map<String, dynamic> db = manga.toDb();

        expect(db['id'], 30013);
        expect(db['title'], 'One Punch-Man');
        expect(db['title_english'], 'One-Punch Man');
        expect(db['title_native'], 'ワンパンマン');
        expect(db['average_score'], 84);
        expect(db['genres'], jsonEncode(<String>['Action', 'Comedy']));
        expect(db['authors'], jsonEncode(<String>['ONE']));
        expect(db['updated_at'], 1700000000);
      });

      test('should serialize null fields', () {
        const Manga manga = Manga(
          id: 1,
          title: 'Test',
        );

        final Map<String, dynamic> db = manga.toDb();

        expect(db['title_english'], isNull);
        expect(db['genres'], isNull);
        expect(db['authors'], isNull);
      });
    });

    group('toExport', () {
      test('should exclude updated_at', () {
        const Manga manga = Manga(
          id: 30013,
          title: 'One Punch-Man',
          updatedAt: 1700000000,
        );

        final Map<String, dynamic> exported = manga.toExport();

        expect(exported.containsKey('updated_at'), isFalse);
        expect(exported['id'], 30013);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        const Manga original = Manga(
          id: 30013,
          title: 'One Punch-Man',
          averageScore: 84,
        );

        final Manga copy = original.copyWith(title: 'New Title');

        expect(copy.id, 30013);
        expect(copy.title, 'New Title');
        expect(copy.averageScore, 84);
      });

      test('should preserve all fields with empty copyWith', () {
        const Manga original = Manga(
          id: 30013,
          title: 'One Punch-Man',
          titleEnglish: 'One-Punch Man',
          averageScore: 84,
          chapters: 200,
        );

        final Manga copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.titleEnglish, original.titleEnglish);
        expect(copy.averageScore, original.averageScore);
        expect(copy.chapters, original.chapters);
      });
    });

    group('computed getters', () {
      test('rating10 should normalize to 0-10', () {
        const Manga manga = Manga(id: 1, title: 'T', averageScore: 84);
        expect(manga.rating10, 8.4);
      });

      test('rating10 should return null when null averageScore', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.rating10, isNull);
      });

      test('formattedRating should format with 1 decimal', () {
        const Manga manga = Manga(id: 1, title: 'T', averageScore: 85);
        expect(manga.formattedRating, '8.5');
      });

      test('formattedRating should return null when null averageScore', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.formattedRating, isNull);
      });

      test('releaseYear should return startYear', () {
        const Manga manga = Manga(id: 1, title: 'T', startYear: 2012);
        expect(manga.releaseYear, 2012);
      });

      test('releaseYear should return null when null startYear', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.releaseYear, isNull);
      });

      test('genresString should join genres with comma', () {
        const Manga manga = Manga(
          id: 1,
          title: 'T',
          genres: <String>['Action', 'Comedy'],
        );
        expect(manga.genresString, 'Action, Comedy');
      });

      test('genresString should return null when null genres', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.genresString, isNull);
      });

      test('authorsString should join authors with comma', () {
        const Manga manga = Manga(
          id: 1,
          title: 'T',
          authors: <String>['ONE', 'Murata'],
        );
        expect(manga.authorsString, 'ONE, Murata');
      });

      test('authorsString should return null when null authors', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.authorsString, isNull);
      });

      test('formatLabel should return the label for each format', () {
        for (final MapEntry<String, String> entry
            in <String, String>{
              'MANGA': 'Manga',
              'NOVEL': 'Novel',
              'ONE_SHOT': 'One-shot',
              'MANHWA': 'Manhwa',
              'MANHUA': 'Manhua',
              'LIGHT_NOVEL': 'Light Novel',
            }.entries) {
          final Manga manga = Manga(id: 1, title: 'T', format: entry.key);
          expect(manga.formatLabel, entry.value);
        }
      });

      test('formatLabel should return the raw value for an unknown format',
          () {
        const Manga manga = Manga(id: 1, title: 'T', format: 'WEBTOON');
        expect(manga.formatLabel, 'WEBTOON');
      });

      test('formatLabel should return null when null format', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.formatLabel, isNull);
      });

      test('statusLabel should return the label for each status', () {
        for (final MapEntry<String, String> entry
            in <String, String>{
              'FINISHED': 'Finished',
              'RELEASING': 'Releasing',
              'NOT_YET_RELEASED': 'Not Yet Released',
              'CANCELLED': 'Cancelled',
              'HIATUS': 'Hiatus',
            }.entries) {
          final Manga manga = Manga(id: 1, title: 'T', status: entry.key);
          expect(manga.statusLabel, entry.value);
        }
      });

      test('statusLabel should return the raw value for an unknown status',
          () {
        const Manga manga = Manga(id: 1, title: 'T', status: 'UNKNOWN');
        expect(manga.statusLabel, 'UNKNOWN');
      });

      test('statusLabel should return null when null status', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.statusLabel, isNull);
      });

      test('progressString should show chapters and volumes', () {
        const Manga manga =
            Manga(id: 1, title: 'T', chapters: 200, volumes: 25);
        expect(manga.progressString, '200 ch · 25 vol');
      });

      test('progressString should show ? when chapters is null', () {
        const Manga manga = Manga(id: 1, title: 'T', volumes: 10);
        expect(manga.progressString, '? ch · 10 vol');
      });

      test('progressString should skip volumes when null', () {
        const Manga manga = Manga(id: 1, title: 'T', chapters: 50);
        expect(manga.progressString, '50 ch');
      });

      test('progressString should show "? ch" when both are null', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.progressString, '? ch');
      });
    });

    group('equality', () {
      test('should be equal for same id', () {
        const Manga a = Manga(id: 30013, title: 'A');
        const Manga b = Manga(id: 30013, title: 'B');
        expect(a, equals(b));
      });

      test('should not be equal for different ids', () {
        const Manga a = Manga(id: 30013, title: 'A');
        const Manga b = Manga(id: 1, title: 'A');
        expect(a, isNot(equals(b)));
      });

      test('hashCode should depend by id', () {
        const Manga a = Manga(id: 30013, title: 'A');
        const Manga b = Manga(id: 30013, title: 'B');
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('toString', () {
      test('should contain id and title', () {
        const Manga manga = Manga(id: 30013, title: 'One Punch-Man');
        expect(manga.toString(), 'Manga(id: 30013, title: One Punch-Man)');
      });
    });

    group('titleByLanguage', () {
      const Manga full = Manga(
        id: 1,
        title: 'Romaji Title',
        titleEnglish: 'English Title',
        titleNative: 'ネイティブ',
      );

      test('returns romaji when lang=romaji', () {
        expect(full.titleByLanguage('romaji'), 'Romaji Title');
      });

      test('returns english when lang=english', () {
        expect(full.titleByLanguage('english'), 'English Title');
      });

      test('returns native when lang=native', () {
        expect(full.titleByLanguage('native'), 'ネイティブ');
      });

      test('falls back to romaji when requested variant missing', () {
        const Manga a = Manga(id: 1, title: 'R');
        expect(a.titleByLanguage('english'), 'R');
        expect(a.titleByLanguage('native'), 'R');
      });

      test('unknown lang code falls back to romaji', () {
        expect(full.titleByLanguage('klingon'), 'Romaji Title');
      });
    });

    group('tags', () {
      test('fromJson parses tags array of {name} objects', () {
        final Manga manga = Manga.fromJson(<String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'X'},
          'tags': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'Slice of Life'},
            <String, dynamic>{'name': 'School'},
          ],
        });
        expect(manga.tags, <String>['Slice of Life', 'School']);
      });

      test('fromJson returns null when tags missing or empty', () {
        final Manga missing = Manga.fromJson(<String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'X'},
        });
        expect(missing.tags, isNull);
      });

      test('toDb / fromDb round-trip preserves tags', () {
        const Manga original =
            Manga(id: 1, title: 'X', tags: <String>['A', 'B', 'C']);
        final Map<String, dynamic> row = original.toDb();
        final Manga back = Manga.fromDb(row);
        expect(back.tags, original.tags);
      });

      test('copyWith replaces tags', () {
        const Manga original = Manga(id: 1, title: 'X', tags: <String>['A']);
        final Manga updated = original.copyWith(tags: <String>['B', 'C']);
        expect(updated.tags, <String>['B', 'C']);
      });

      test('tagsString joins with comma', () {
        const Manga manga =
            Manga(id: 1, title: 'X', tags: <String>['A', 'B']);
        expect(manga.tagsString, 'A, B');
      });
    });
  });
}
