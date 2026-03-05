// Тесты для модели Manga.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/manga.dart';

void main() {
  group('Manga', () {
    group('fromJson', () {
      test('должен создать Manga из полного JSON', () {
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
        expect(manga.meanScore, 85);
        expect(manga.popularity, 120000);
        expect(manga.status, 'RELEASING');
        expect(manga.startYear, 2012);
        expect(manga.startMonth, 6);
        expect(manga.startDay, 14);
        expect(manga.chapters, isNull);
        expect(manga.volumes, isNull);
        expect(manga.format, 'MANGA');
        expect(manga.countryOfOrigin, 'JP');
        expect(manga.genres, <String>['Action', 'Comedy', 'Sci-Fi']);
        expect(manga.authors, <String>['ONE', 'Yusuke Murata']);
        expect(manga.externalUrl, 'https://anilist.co/manga/30013');
        expect(manga.updatedAt, isNotNull);
      });

      test('должен создать Manga из минимального JSON', () {
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

      test('должен использовать english title как fallback', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{
            'english': 'Naruto',
          },
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.title, 'Naruto');
      });

      test('должен использовать Unknown если нет title', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.title, 'Unknown');
      });

      test('должен фильтровать авторов по роли', () {
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

      test('должен вернуть null authors при пустом списке после фильтрации',
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

      test('должен пропускать авторов с пустым именем', () {
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

      test('должен убирать HTML из описания', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'description':
              '<p>A <b>bold</b> &amp; <i>italic</i> description.</p>',
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.description, 'A bold & italic description.');
      });

      test('должен вернуть null description для пустого HTML', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'title': <String, dynamic>{'romaji': 'Test'},
          'description': '<br><br>',
        };

        final Manga manga = Manga.fromJson(json);

        expect(manga.description, isNull);
      });

      test('должен декодировать HTML entities', () {
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
      test('должен создать Manga из записи БД', () {
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

      test('должен обработать null JSON строки', () {
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

      test('должен обработать пустые JSON строки', () {
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

      test('должен обработать повреждённые JSON строки', () {
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
      test('должен сериализовать в Map', () {
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

      test('должен сериализовать null поля', () {
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
      test('должен исключить updated_at', () {
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
      test('должен создать копию с изменёнными полями', () {
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

      test('должен сохранить все поля при пустом copyWith', () {
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
      test('rating10 должен нормализовать к 0-10', () {
        const Manga manga = Manga(id: 1, title: 'T', averageScore: 84);
        expect(manga.rating10, 8.4);
      });

      test('rating10 должен вернуть null при null averageScore', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.rating10, isNull);
      });

      test('formattedRating должен форматировать до 1 знака', () {
        const Manga manga = Manga(id: 1, title: 'T', averageScore: 85);
        expect(manga.formattedRating, '8.5');
      });

      test('formattedRating должен вернуть null при null averageScore', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.formattedRating, isNull);
      });

      test('releaseYear должен вернуть startYear', () {
        const Manga manga = Manga(id: 1, title: 'T', startYear: 2012);
        expect(manga.releaseYear, 2012);
      });

      test('releaseYear должен вернуть null при null startYear', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.releaseYear, isNull);
      });

      test('genresString должен объединить жанры через запятую', () {
        const Manga manga = Manga(
          id: 1,
          title: 'T',
          genres: <String>['Action', 'Comedy'],
        );
        expect(manga.genresString, 'Action, Comedy');
      });

      test('genresString должен вернуть null при null genres', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.genresString, isNull);
      });

      test('authorsString должен объединить авторов через запятую', () {
        const Manga manga = Manga(
          id: 1,
          title: 'T',
          authors: <String>['ONE', 'Murata'],
        );
        expect(manga.authorsString, 'ONE, Murata');
      });

      test('authorsString должен вернуть null при null authors', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.authorsString, isNull);
      });

      test('formatLabel должен вернуть метку для каждого формата', () {
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

      test('formatLabel должен вернуть raw значение для неизвестного формата',
          () {
        const Manga manga = Manga(id: 1, title: 'T', format: 'WEBTOON');
        expect(manga.formatLabel, 'WEBTOON');
      });

      test('formatLabel должен вернуть null при null format', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.formatLabel, isNull);
      });

      test('statusLabel должен вернуть метку для каждого статуса', () {
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

      test('statusLabel должен вернуть raw значение для неизвестного статуса',
          () {
        const Manga manga = Manga(id: 1, title: 'T', status: 'UNKNOWN');
        expect(manga.statusLabel, 'UNKNOWN');
      });

      test('statusLabel должен вернуть null при null status', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.statusLabel, isNull);
      });

      test('progressString должен показать главы и тома', () {
        const Manga manga =
            Manga(id: 1, title: 'T', chapters: 200, volumes: 25);
        expect(manga.progressString, '200 ch · 25 vol');
      });

      test('progressString должен показать ? при null chapters', () {
        const Manga manga = Manga(id: 1, title: 'T', volumes: 10);
        expect(manga.progressString, '? ch · 10 vol');
      });

      test('progressString должен не показывать volumes при null', () {
        const Manga manga = Manga(id: 1, title: 'T', chapters: 50);
        expect(manga.progressString, '50 ch');
      });

      test('progressString должен показать ? ch при null обоих', () {
        const Manga manga = Manga(id: 1, title: 'T');
        expect(manga.progressString, '? ch');
      });
    });

    group('equality', () {
      test('должен быть равен при одинаковом id', () {
        const Manga a = Manga(id: 30013, title: 'A');
        const Manga b = Manga(id: 30013, title: 'B');
        expect(a, equals(b));
      });

      test('не должен быть равен при разных id', () {
        const Manga a = Manga(id: 30013, title: 'A');
        const Manga b = Manga(id: 1, title: 'A');
        expect(a, isNot(equals(b)));
      });

      test('hashCode должен зависеть от id', () {
        const Manga a = Manga(id: 30013, title: 'A');
        const Manga b = Manga(id: 30013, title: 'B');
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('toString', () {
      test('должен содержать id и title', () {
        const Manga manga = Manga(id: 30013, title: 'One Punch-Man');
        expect(manga.toString(), 'Manga(id: 30013, title: One Punch-Man)');
      });
    });
  });
}
