import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/xcoll_file.dart';

void main() {
  group('RcollGame', () {
    group('fromJson', () {
      test('должен создать RcollGame из валидного JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'igdb_id': 123,
          'platform_id': 18,
          'comment': 'Great game!',
        };

        final RcollGame game = RcollGame.fromJson(json);

        expect(game.igdbId, equals(123));
        expect(game.platformId, equals(18));
        expect(game.comment, equals('Great game!'));
      });

      test('должен создать RcollGame с null comment', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'igdb_id': 456,
          'platform_id': 19,
        };

        final RcollGame game = RcollGame.fromJson(json);

        expect(game.igdbId, equals(456));
        expect(game.platformId, equals(19));
        expect(game.comment, isNull);
      });
    });

    group('toJson', () {
      test('должен сериализовать RcollGame с комментарием', () {
        const RcollGame game = RcollGame(
          igdbId: 100,
          platformId: 20,
          comment: 'Best RPG',
        );

        final Map<String, dynamic> json = game.toJson();

        expect(json['igdb_id'], equals(100));
        expect(json['platform_id'], equals(20));
        expect(json['comment'], equals('Best RPG'));
      });

      test('должен исключить comment если он null', () {
        const RcollGame game = RcollGame(
          igdbId: 100,
          platformId: 20,
          comment: null,
        );

        final Map<String, dynamic> json = game.toJson();

        expect(json.containsKey('comment'), isFalse);
      });

      test('должен исключить comment если он пустой', () {
        const RcollGame game = RcollGame(
          igdbId: 100,
          platformId: 20,
          comment: '',
        );

        final Map<String, dynamic> json = game.toJson();

        expect(json.containsKey('comment'), isFalse);
      });
    });

    test('fromJson/toJson round-trip должен сохранять данные', () {
      const RcollGame original = RcollGame(
        igdbId: 999,
        platformId: 21,
        comment: 'Test comment',
      );

      final Map<String, dynamic> json = original.toJson();
      final RcollGame restored = RcollGame.fromJson(json);

      expect(restored.igdbId, equals(original.igdbId));
      expect(restored.platformId, equals(original.platformId));
      expect(restored.comment, equals(original.comment));
    });
  });

  group('XcollFile', () {
    final DateTime testDate = DateTime.utc(2024, 1, 15, 12, 0, 0);

    group('fromJson', () {
      test('должен создать XcollFile из полного JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 1,
          'name': 'My Collection',
          'author': 'TestUser',
          'created': '2024-01-15T12:00:00.000Z',
          'description': 'Test description',
          'games': <Map<String, dynamic>>[
            <String, dynamic>{'igdb_id': 1, 'platform_id': 18},
            <String, dynamic>{'igdb_id': 2, 'platform_id': 19, 'comment': 'Good'},
          ],
        };

        final XcollFile rcoll = XcollFile.fromJson(json);

        expect(rcoll.version, equals(1));
        expect(rcoll.name, equals('My Collection'));
        expect(rcoll.author, equals('TestUser'));
        expect(rcoll.created, equals(testDate));
        expect(rcoll.description, equals('Test description'));
        expect(rcoll.legacyGames.length, equals(2));
        expect(rcoll.legacyGames[0].igdbId, equals(1));
        expect(rcoll.legacyGames[1].comment, equals('Good'));
      });

      test('должен использовать значения по умолчанию', () {
        final Map<String, dynamic> json = <String, dynamic>{};

        final XcollFile rcoll = XcollFile.fromJson(json);

        expect(rcoll.version, equals(1));
        expect(rcoll.name, equals('Unnamed Collection'));
        expect(rcoll.author, equals('Unknown'));
        expect(rcoll.description, isNull);
        expect(rcoll.legacyGames, isEmpty);
      });

      test('должен выбросить исключение при неподдерживаемой версии', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 999,
          'name': 'Test',
        };

        expect(
          () => XcollFile.fromJson(json),
          throwsA(isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('Unsupported file version'),
          )),
        );
      });

      test('должен использовать DateTime.now при невалидной дате', () {
        final DateTime before = DateTime.now();
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 1,
          'name': 'Test',
          'created': 'invalid-date-format',
        };

        final XcollFile rcoll = XcollFile.fromJson(json);
        final DateTime after = DateTime.now();

        // Дата должна быть между before и after
        expect(rcoll.created.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(rcoll.created.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('fromJsonString', () {
      test('должен парсить валидную JSON строку', () {
        const String jsonString = '''
{
  "version": 1,
  "name": "Test Collection",
  "author": "Author",
  "created": "2024-01-15T12:00:00.000Z",
  "games": []
}
''';

        final XcollFile rcoll = XcollFile.fromJsonString(jsonString);

        expect(rcoll.name, equals('Test Collection'));
        expect(rcoll.author, equals('Author'));
      });

      test('должен выбросить FormatException при невалидном JSON', () {
        const String invalidJson = 'not a json';

        expect(
          () => XcollFile.fromJsonString(invalidJson),
          throwsA(isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('Invalid JSON format'),
          )),
        );
      });

      test('должен выбросить FormatException при некорректной структуре', () {
        // JSON валидный, но структура неправильная (games должен быть списком)
        const String invalidStructure = '{"games": "not a list"}';

        expect(
          () => XcollFile.fromJsonString(invalidStructure),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('toJson', () {
      test('должен сериализовать XcollFile полностью', () {
        final XcollFile rcoll = XcollFile(
          version: 1,
          name: 'Export Test',
          author: 'Exporter',
          created: testDate,
          description: 'Desc',
          legacyGames: const <RcollGame>[
            RcollGame(igdbId: 10, platformId: 5),
          ],
        );

        final Map<String, dynamic> json = rcoll.toJson();

        expect(json['version'], equals(1));
        expect(json['name'], equals('Export Test'));
        expect(json['author'], equals('Exporter'));
        expect(json['created'], equals('2024-01-15T12:00:00.000Z'));
        expect(json['description'], equals('Desc'));
        expect((json['games'] as List<dynamic>).length, equals(1));
      });

      test('должен исключить description если он null', () {
        final XcollFile rcoll = XcollFile(
          version: 1,
          name: 'No Desc',
          author: 'Author',
          created: testDate,
          legacyGames: const <RcollGame>[],
        );

        final Map<String, dynamic> json = rcoll.toJson();

        expect(json.containsKey('description'), isFalse);
      });
    });

    group('toJsonString', () {
      test('должен возвращать отформатированный JSON', () {
        final XcollFile rcoll = XcollFile(
          version: 1,
          name: 'Formatted',
          author: 'Auth',
          created: testDate,
          legacyGames: const <RcollGame>[],
        );

        final String jsonString = rcoll.toJsonString();

        // Проверяем что содержит отступы (форматирование)
        expect(jsonString, contains('  '));
        // Проверяем что можно обратно распарсить
        final Map<String, dynamic> parsed =
            jsonDecode(jsonString) as Map<String, dynamic>;
        expect(parsed['name'], equals('Formatted'));
      });
    });

    group('gameIds', () {
      test('должен возвращать список ID игр', () {
        final XcollFile rcoll = XcollFile(
          version: 1,
          name: 'Test',
          author: 'Author',
          created: testDate,
          legacyGames: const <RcollGame>[
            RcollGame(igdbId: 100, platformId: 1),
            RcollGame(igdbId: 200, platformId: 2),
            RcollGame(igdbId: 300, platformId: 3),
          ],
        );

        final List<int> ids = rcoll.gameIds;

        expect(ids, equals(<int>[100, 200, 300]));
      });

      test('должен возвращать пустой список при отсутствии игр', () {
        final XcollFile rcoll = XcollFile(
          version: 1,
          name: 'Empty',
          author: 'Author',
          created: testDate,
          legacyGames: const <RcollGame>[],
        );

        expect(rcoll.gameIds, isEmpty);
      });
    });

    test('fromJsonString/toJsonString round-trip', () {
      final XcollFile original = XcollFile(
        version: 1,
        name: 'Round Trip Test',
        author: 'Tester',
        created: testDate,
        description: 'Testing round trip',
        legacyGames: const <RcollGame>[
          RcollGame(igdbId: 111, platformId: 11, comment: 'Comment 1'),
          RcollGame(igdbId: 222, platformId: 22),
        ],
      );

      final String jsonString = original.toJsonString();
      final XcollFile restored = XcollFile.fromJsonString(jsonString);

      expect(restored.version, equals(original.version));
      expect(restored.name, equals(original.name));
      expect(restored.author, equals(original.author));
      expect(restored.created, equals(original.created));
      expect(restored.description, equals(original.description));
      expect(restored.legacyGames.length, equals(original.legacyGames.length));
      expect(restored.legacyGames[0].igdbId, equals(original.legacyGames[0].igdbId));
      expect(restored.legacyGames[0].comment, equals(original.legacyGames[0].comment));
      expect(restored.legacyGames[1].comment, isNull);
    });
  });

  group('xcollFormatVersion', () {
    test('должен быть равен 2', () {
      expect(xcollFormatVersion, equals(2));
    });

    test('xcollLegacyVersion должен быть равен 1', () {
      expect(xcollLegacyVersion, equals(1));
    });
  });
}
