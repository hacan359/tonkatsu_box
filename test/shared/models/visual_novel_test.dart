// Тесты для модели VisualNovel и VndbTag

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/visual_novel.dart';

void main() {
  group('VisualNovel', () {
    group('fromJson', () {
      test('должен создать VisualNovel из полного JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'v17',
          'title': 'Ever17',
          'alttitle': 'Ever17 -the out of infinity-',
          'description':
              'A [url=https://vndb.org]visual novel[/url] about time.',
          'image': <String, dynamic>{
            'url': 'https://example.com/cover.jpg',
          },
          'rating': 85.5,
          'votecount': 1200,
          'released': '2002-08-29',
          'length_minutes': 3000,
          'length': 4,
          'tags': <dynamic>[
            <String, dynamic>{
              'name': 'Sci-fi',
              'rating': 3.0,
            },
            <String, dynamic>{
              'name': 'Mystery',
              'rating': 2.5,
            },
          ],
          'developers': <dynamic>[
            <String, dynamic>{'name': 'KID'},
          ],
          'platforms': <dynamic>['win', 'ps2', 'psp'],
        };

        final VisualNovel vn = VisualNovel.fromJson(json);

        expect(vn.id, 'v17');
        expect(vn.title, 'Ever17');
        expect(vn.altTitle, 'Ever17 -the out of infinity-');
        expect(vn.description, 'A visual novel about time.');
        expect(vn.imageUrl, 'https://example.com/cover.jpg');
        expect(vn.rating, 85.5);
        expect(vn.voteCount, 1200);
        expect(vn.released, '2002-08-29');
        expect(vn.lengthMinutes, 3000);
        expect(vn.length, 4);
        expect(vn.tags, <String>['Sci-fi', 'Mystery']);
        expect(vn.developers, <String>['KID']);
        expect(vn.platforms, <String>['win', 'ps2', 'psp']);
        expect(vn.externalUrl, 'https://vndb.org/v17');
      });

      test('должен создать VisualNovel из минимального JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'v2',
          'title': 'Kanon',
        };

        final VisualNovel vn = VisualNovel.fromJson(json);

        expect(vn.id, 'v2');
        expect(vn.title, 'Kanon');
        expect(vn.altTitle, isNull);
        expect(vn.description, isNull);
        expect(vn.imageUrl, isNull);
        expect(vn.rating, isNull);
        expect(vn.voteCount, isNull);
        expect(vn.released, isNull);
        expect(vn.lengthMinutes, isNull);
        expect(vn.length, isNull);
        expect(vn.tags, isNull);
        expect(vn.developers, isNull);
        expect(vn.platforms, isNull);
        expect(vn.externalUrl, 'https://vndb.org/v2');
      });

      test('должен сортировать теги по rating (убывание)', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'v1',
          'title': 'Test',
          'tags': <dynamic>[
            <String, dynamic>{'name': 'Low', 'rating': 1.0},
            <String, dynamic>{'name': 'High', 'rating': 3.0},
            <String, dynamic>{'name': 'Mid', 'rating': 2.0},
          ],
        };

        final VisualNovel vn = VisualNovel.fromJson(json);

        expect(vn.tags, <String>['High', 'Mid', 'Low']);
      });

      test('должен пропускать теги и девелоперов с null name', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'v1',
          'title': 'Test',
          'tags': <dynamic>[
            <String, dynamic>{'name': 'Valid', 'rating': 3.0},
            <String, dynamic>{'rating': 2.0},
          ],
          'developers': <dynamic>[
            <String, dynamic>{'name': 'Dev1'},
            <String, dynamic>{'other': 'value'},
          ],
        };

        final VisualNovel vn = VisualNovel.fromJson(json);

        expect(vn.tags, <String>['Valid']);
        expect(vn.developers, <String>['Dev1']);
      });

      test('должен убирать BBCode разметку из описания', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'v1',
          'title': 'Test',
          'description':
              '[b]Bold[/b] and [i]italic[/i] with [url=http://x]link[/url] '
                  'and [spoiler]hidden[/spoiler].',
        };

        final VisualNovel vn = VisualNovel.fromJson(json);

        expect(vn.description, 'Bold and italic with link and hidden.');
      });

      test('должен вернуть null description для пустого текста после очистки',
          () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'v1',
          'title': 'Test',
          'description': '[spoiler][/spoiler]',
        };

        final VisualNovel vn = VisualNovel.fromJson(json);

        expect(vn.description, isNull);
      });
    });

    group('fromDb', () {
      test('должен создать VisualNovel из записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 'v17',
          'title': 'Ever17',
          'alt_title': 'Ever17 JP',
          'description': 'A visual novel',
          'image_url': 'https://example.com/cover.jpg',
          'rating': 85.5,
          'vote_count': 1200,
          'released': '2002-08-29',
          'length_minutes': 3000,
          'length': 4,
          'tags': jsonEncode(<String>['Sci-fi', 'Mystery']),
          'developers': jsonEncode(<String>['KID']),
          'platforms': jsonEncode(<String>['win', 'ps2']),
          'external_url': 'https://vndb.org/v17',
          'updated_at': 1700000000,
        };

        final VisualNovel vn = VisualNovel.fromDb(row);

        expect(vn.id, 'v17');
        expect(vn.title, 'Ever17');
        expect(vn.altTitle, 'Ever17 JP');
        expect(vn.tags, <String>['Sci-fi', 'Mystery']);
        expect(vn.developers, <String>['KID']);
        expect(vn.platforms, <String>['win', 'ps2']);
        expect(vn.updatedAt, 1700000000);
      });

      test('должен обработать null JSON строки', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 'v1',
          'title': 'Test',
          'alt_title': null,
          'description': null,
          'image_url': null,
          'rating': null,
          'vote_count': null,
          'released': null,
          'length_minutes': null,
          'length': null,
          'tags': null,
          'developers': null,
          'platforms': null,
          'external_url': null,
          'updated_at': null,
        };

        final VisualNovel vn = VisualNovel.fromDb(row);

        expect(vn.tags, isNull);
        expect(vn.developers, isNull);
        expect(vn.platforms, isNull);
      });

      test('должен обработать пустые JSON строки', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 'v1',
          'title': 'Test',
          'alt_title': null,
          'description': null,
          'image_url': null,
          'rating': null,
          'vote_count': null,
          'released': null,
          'length_minutes': null,
          'length': null,
          'tags': '',
          'developers': '',
          'platforms': '',
          'external_url': null,
          'updated_at': null,
        };

        final VisualNovel vn = VisualNovel.fromDb(row);

        expect(vn.tags, isNull);
        expect(vn.developers, isNull);
        expect(vn.platforms, isNull);
      });

      test('должен обработать повреждённые JSON строки', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 'v1',
          'title': 'Test',
          'alt_title': null,
          'description': null,
          'image_url': null,
          'rating': null,
          'vote_count': null,
          'released': null,
          'length_minutes': null,
          'length': null,
          'tags': 'not-valid-json',
          'developers': '{broken}',
          'platforms': '[unclosed',
          'external_url': null,
          'updated_at': null,
        };

        final VisualNovel vn = VisualNovel.fromDb(row);

        expect(vn.tags, isNull);
        expect(vn.developers, isNull);
        expect(vn.platforms, isNull);
      });
    });

    group('toDb', () {
      test('должен сериализовать в Map', () {
        const VisualNovel vn = VisualNovel(
          id: 'v17',
          title: 'Ever17',
          altTitle: 'JP Title',
          description: 'Desc',
          imageUrl: 'https://example.com/cover.jpg',
          rating: 85.5,
          voteCount: 1200,
          released: '2002-08-29',
          lengthMinutes: 3000,
          length: 4,
          tags: <String>['Sci-fi'],
          developers: <String>['KID'],
          platforms: <String>['win'],
          externalUrl: 'https://vndb.org/v17',
          updatedAt: 1700000000,
        );

        final Map<String, dynamic> db = vn.toDb();

        expect(db['id'], 'v17');
        expect(db['numeric_id'], 17);
        expect(db['title'], 'Ever17');
        expect(db['alt_title'], 'JP Title');
        expect(db['tags'], jsonEncode(<String>['Sci-fi']));
        expect(db['developers'], jsonEncode(<String>['KID']));
        expect(db['platforms'], jsonEncode(<String>['win']));
        expect(db['updated_at'], 1700000000);
      });

      test('должен сериализовать null поля', () {
        const VisualNovel vn = VisualNovel(
          id: 'v1',
          title: 'Test',
        );

        final Map<String, dynamic> db = vn.toDb();

        expect(db['alt_title'], isNull);
        expect(db['tags'], isNull);
        expect(db['developers'], isNull);
        expect(db['platforms'], isNull);
      });
    });

    group('toExport', () {
      test('должен исключить updated_at', () {
        const VisualNovel vn = VisualNovel(
          id: 'v17',
          title: 'Ever17',
          updatedAt: 1700000000,
        );

        final Map<String, dynamic> exported = vn.toExport();

        expect(exported.containsKey('updated_at'), isFalse);
        expect(exported['id'], 'v17');
      });
    });

    group('copyWith', () {
      test('должен создать копию с изменёнными полями', () {
        const VisualNovel original = VisualNovel(
          id: 'v17',
          title: 'Ever17',
          rating: 85.5,
        );

        final VisualNovel copy = original.copyWith(title: 'New Title');

        expect(copy.id, 'v17');
        expect(copy.title, 'New Title');
        expect(copy.rating, 85.5);
      });

      test('должен сохранить все поля при пустом copyWith', () {
        const VisualNovel original = VisualNovel(
          id: 'v17',
          title: 'Ever17',
          altTitle: 'JP',
          rating: 85.5,
        );

        final VisualNovel copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.altTitle, original.altTitle);
        expect(copy.rating, original.rating);
      });
    });

    group('computed getters', () {
      test('numericId должен извлечь число из ID', () {
        const VisualNovel vn = VisualNovel(id: 'v17', title: 'Test');
        expect(vn.numericId, 17);
      });

      test('numericId должен выбросить FormatException для невалидного ID',
          () {
        const VisualNovel vn = VisualNovel(id: 'invalid', title: 'Test');
        expect(() => vn.numericId, throwsA(isA<FormatException>()));
      });

      test('rating10 должен нормализовать к 0-10', () {
        const VisualNovel vn =
            VisualNovel(id: 'v1', title: 'Test', rating: 85.0);
        expect(vn.rating10, 8.5);
      });

      test('rating10 должен вернуть null при null rating', () {
        const VisualNovel vn = VisualNovel(id: 'v1', title: 'Test');
        expect(vn.rating10, isNull);
      });

      test('formattedRating должен форматировать до 1 знака', () {
        const VisualNovel vn =
            VisualNovel(id: 'v1', title: 'Test', rating: 85.53);
        expect(vn.formattedRating, '8.6');
      });

      test('formattedRating должен вернуть null при null rating', () {
        const VisualNovel vn = VisualNovel(id: 'v1', title: 'Test');
        expect(vn.formattedRating, isNull);
      });

      test('releaseYear должен извлечь год', () {
        const VisualNovel vn =
            VisualNovel(id: 'v1', title: 'Test', released: '2002-08-29');
        expect(vn.releaseYear, 2002);
      });

      test('releaseYear должен вернуть null для короткой строки', () {
        const VisualNovel vn =
            VisualNovel(id: 'v1', title: 'Test', released: '20');
        expect(vn.releaseYear, isNull);
      });

      test('releaseYear должен вернуть null при null released', () {
        const VisualNovel vn = VisualNovel(id: 'v1', title: 'Test');
        expect(vn.releaseYear, isNull);
      });

      test('genresString должен объединить теги через запятую', () {
        const VisualNovel vn = VisualNovel(
          id: 'v1',
          title: 'Test',
          tags: <String>['Sci-fi', 'Mystery'],
        );
        expect(vn.genresString, 'Sci-fi, Mystery');
      });

      test('genresString должен вернуть null при null tags', () {
        const VisualNovel vn = VisualNovel(id: 'v1', title: 'Test');
        expect(vn.genresString, isNull);
      });

      test('lengthLabel должен вернуть метку для каждой категории', () {
        for (final MapEntry<int, String> entry
            in <int, String>{
              1: '< 2h',
              2: '2-10h',
              3: '10-30h',
              4: '30-50h',
              5: '> 50h',
            }.entries) {
          final VisualNovel vn =
              VisualNovel(id: 'v1', title: 'T', length: entry.key);
          expect(vn.lengthLabel, entry.value);
        }
      });

      test('lengthLabel должен вернуть null для неизвестной категории', () {
        const VisualNovel vn =
            VisualNovel(id: 'v1', title: 'Test', length: 99);
        expect(vn.lengthLabel, isNull);
      });

      test('lengthLabel должен вернуть null при null length', () {
        const VisualNovel vn = VisualNovel(id: 'v1', title: 'Test');
        expect(vn.lengthLabel, isNull);
      });

      test('developersString должен объединить разработчиков', () {
        const VisualNovel vn = VisualNovel(
          id: 'v1',
          title: 'Test',
          developers: <String>['KID', 'Cyberfront'],
        );
        expect(vn.developersString, 'KID, Cyberfront');
      });

      test('platformsString должен конвертировать коды в названия', () {
        const VisualNovel vn = VisualNovel(
          id: 'v1',
          title: 'Test',
          platforms: <String>['win', 'ps2', 'psp'],
        );
        expect(vn.platformsString, 'Windows, PS2, PSP');
      });

      test('platformsString должен использовать uppercase для неизвестных', () {
        const VisualNovel vn = VisualNovel(
          id: 'v1',
          title: 'Test',
          platforms: <String>['xyz'],
        );
        expect(vn.platformsString, 'XYZ');
      });
    });

    group('equality', () {
      test('должен быть равен при одинаковом id', () {
        const VisualNovel a = VisualNovel(id: 'v17', title: 'A');
        const VisualNovel b = VisualNovel(id: 'v17', title: 'B');
        expect(a, equals(b));
      });

      test('не должен быть равен при разных id', () {
        const VisualNovel a = VisualNovel(id: 'v17', title: 'A');
        const VisualNovel b = VisualNovel(id: 'v2', title: 'A');
        expect(a, isNot(equals(b)));
      });

      test('hashCode должен зависеть от id', () {
        const VisualNovel a = VisualNovel(id: 'v17', title: 'A');
        const VisualNovel b = VisualNovel(id: 'v17', title: 'B');
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('toString', () {
      test('должен содержать id и title', () {
        const VisualNovel vn = VisualNovel(id: 'v17', title: 'Ever17');
        expect(vn.toString(), 'VisualNovel(id: v17, title: Ever17)');
      });
    });
  });

  group('VndbTag', () {
    group('fromJson', () {
      test('должен создать VndbTag из JSON', () {
        final VndbTag tag = VndbTag.fromJson(<String, dynamic>{
          'id': 'g7',
          'name': 'Sci-fi',
        });
        expect(tag.id, 'g7');
        expect(tag.name, 'Sci-fi');
      });
    });

    group('fromDb', () {
      test('должен создать VndbTag из записи БД', () {
        final VndbTag tag = VndbTag.fromDb(<String, dynamic>{
          'id': 'g7',
          'name': 'Sci-fi',
        });
        expect(tag.id, 'g7');
        expect(tag.name, 'Sci-fi');
      });
    });

    group('toDb', () {
      test('должен сериализовать в Map', () {
        const VndbTag tag = VndbTag(id: 'g7', name: 'Sci-fi');
        final Map<String, dynamic> db = tag.toDb();
        expect(db['id'], 'g7');
        expect(db['name'], 'Sci-fi');
      });
    });

    group('equality', () {
      test('должен быть равен при одинаковом id', () {
        const VndbTag a = VndbTag(id: 'g7', name: 'A');
        const VndbTag b = VndbTag(id: 'g7', name: 'B');
        expect(a, equals(b));
      });

      test('не должен быть равен при разных id', () {
        const VndbTag a = VndbTag(id: 'g7', name: 'A');
        const VndbTag b = VndbTag(id: 'g8', name: 'A');
        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('должен содержать id и name', () {
        const VndbTag tag = VndbTag(id: 'g7', name: 'Sci-fi');
        expect(tag.toString(), 'VndbTag(id: g7, name: Sci-fi)');
      });
    });
  });
}
