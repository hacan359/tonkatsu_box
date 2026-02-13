import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/xcoll_file.dart';

void main() {
  group('ExportFormat', () {
    test('fromString должен вернуть light по умолчанию', () {
      final ExportFormat format = ExportFormat.fromString('unknown');

      expect(format, equals(ExportFormat.light));
    });

    test('fromString должен распознать light', () {
      final ExportFormat format = ExportFormat.fromString('light');

      expect(format, equals(ExportFormat.light));
    });

    test('fromString должен распознать full', () {
      final ExportFormat format = ExportFormat.fromString('full');

      expect(format, equals(ExportFormat.full));
    });
  });

  group('ExportCanvas', () {
    test('должен создать ExportCanvas из валидного JSON', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'viewport': <String, dynamic>{'x': 0, 'y': 0, 'zoom': 1.0},
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'id': '1', 'type': 'game'},
        ],
        'connections': <Map<String, dynamic>>[
          <String, dynamic>{'from': '1', 'to': '2'},
        ],
      };

      final ExportCanvas canvas = ExportCanvas.fromJson(json);

      expect(canvas.viewport, isNotNull);
      expect(canvas.items.length, equals(1));
      expect(canvas.connections.length, equals(1));
    });

    test('должен создать ExportCanvas с пустыми значениями по умолчанию', () {
      final Map<String, dynamic> json = <String, dynamic>{};

      final ExportCanvas canvas = ExportCanvas.fromJson(json);

      expect(canvas.viewport, isNull);
      expect(canvas.items, isEmpty);
      expect(canvas.connections, isEmpty);
    });

    test('toJson должен сериализовать ExportCanvas', () {
      const ExportCanvas canvas = ExportCanvas(
        viewport: <String, dynamic>{'x': 10, 'y': 20},
        items: <Map<String, dynamic>>[
          <String, dynamic>{'id': 'item1'},
        ],
        connections: <Map<String, dynamic>>[],
      );

      final Map<String, dynamic> json = canvas.toJson();

      expect(json['viewport'], isNotNull);
      expect((json['items'] as List<dynamic>).length, equals(1));
      expect(json['connections'] as List<dynamic>, isEmpty);
    });

    test('toJson должен исключить viewport если он null', () {
      const ExportCanvas canvas = ExportCanvas();

      final Map<String, dynamic> json = canvas.toJson();

      expect(json.containsKey('viewport'), isFalse);
      expect(json['items'], isEmpty);
      expect(json['connections'], isEmpty);
    });
  });

  group('XcollFile', () {
    final DateTime testDate = DateTime.utc(2024, 1, 15, 12, 0, 0);

    group('fromJson', () {
      test('должен создать XcollFile из полного v2 JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 2,
          'format': 'light',
          'name': 'My Collection',
          'author': 'TestUser',
          'created': '2024-01-15T12:00:00.000Z',
          'description': 'Test description',
          'items': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'item1', 'type': 'game', 'igdbId': 123},
            <String, dynamic>{'id': 'item2', 'type': 'game', 'igdbId': 456},
          ],
        };

        final XcollFile xcoll = XcollFile.fromJson(json);

        expect(xcoll.version, equals(2));
        expect(xcoll.format, equals(ExportFormat.light));
        expect(xcoll.name, equals('My Collection'));
        expect(xcoll.author, equals('TestUser'));
        expect(xcoll.created, equals(testDate));
        expect(xcoll.description, equals('Test description'));
        expect(xcoll.items.length, equals(2));
      });

      test('должен создать XcollFile из full формата с canvas и images', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 2,
          'format': 'full',
          'name': 'Full Collection',
          'author': 'Author',
          'created': '2024-01-15T12:00:00.000Z',
          'items': <Map<String, dynamic>>[],
          'canvas': <String, dynamic>{
            'viewport': <String, dynamic>{'x': 0, 'y': 0},
            'items': <Map<String, dynamic>>[],
            'connections': <Map<String, dynamic>>[],
          },
          'images': <String, dynamic>{
            'game_covers/123': 'base64data',
          },
        };

        final XcollFile xcoll = XcollFile.fromJson(json);

        expect(xcoll.format, equals(ExportFormat.full));
        expect(xcoll.isFull, isTrue);
        expect(xcoll.canvas, isNotNull);
        expect(xcoll.images.length, equals(1));
        expect(xcoll.images['game_covers/123'], equals('base64data'));
      });

      test('должен использовать значения по умолчанию для v2', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 2,
        };

        final XcollFile xcoll = XcollFile.fromJson(json);

        expect(xcoll.version, equals(2));
        expect(xcoll.name, equals('Unnamed Collection'));
        expect(xcoll.author, equals('Unknown'));
        expect(xcoll.format, equals(ExportFormat.light));
        expect(xcoll.description, isNull);
        expect(xcoll.items, isEmpty);
        expect(xcoll.canvas, isNull);
        expect(xcoll.images, isEmpty);
      });

      test('должен выбросить FormatException для v1 формата', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 1,
          'name': 'Old Collection',
          'author': 'Author',
          'created': '2024-01-15T12:00:00.000Z',
          'games': <Map<String, dynamic>>[
            <String, dynamic>{'igdb_id': 1, 'platform_id': 18},
          ],
        };

        expect(
          () => XcollFile.fromJson(json),
          throwsA(isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('Unsupported file version: 1'),
          )),
        );
      });

      test('должен выбросить FormatException при версии выше поддерживаемой', () {
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

      test('должен выбросить FormatException при отсутствии версии (default 1)', () {
        // Если version не указан, он по умолчанию 1, что < xcollFormatVersion
        final Map<String, dynamic> json = <String, dynamic>{};

        expect(
          () => XcollFile.fromJson(json),
          throwsA(isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('Unsupported file version: 1'),
          )),
        );
      });

      test('должен использовать DateTime.now при невалидной дате', () {
        final DateTime before = DateTime.now();
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 2,
          'name': 'Test',
          'created': 'invalid-date-format',
        };

        final XcollFile xcoll = XcollFile.fromJson(json);
        final DateTime after = DateTime.now();

        // Дата должна быть между before и after
        expect(
          xcoll.created.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          xcoll.created.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('должен использовать DateTime.now при отсутствии даты', () {
        final DateTime before = DateTime.now();
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 2,
          'name': 'Test',
        };

        final XcollFile xcoll = XcollFile.fromJson(json);
        final DateTime after = DateTime.now();

        expect(
          xcoll.created.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          xcoll.created.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });

    group('fromJsonString', () {
      test('должен парсить валидную JSON строку v2', () {
        const String jsonString = '''
{
  "version": 2,
  "format": "light",
  "name": "Test Collection",
  "author": "Author",
  "created": "2024-01-15T12:00:00.000Z",
  "items": []
}
''';

        final XcollFile xcoll = XcollFile.fromJsonString(jsonString);

        expect(xcoll.name, equals('Test Collection'));
        expect(xcoll.author, equals('Author'));
        expect(xcoll.version, equals(2));
        expect(xcoll.format, equals(ExportFormat.light));
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
        // JSON валидный, но структура неправильная (items должен быть списком)
        const String invalidStructure = '{"version": 2, "items": "not a list"}';

        expect(
          () => XcollFile.fromJsonString(invalidStructure),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('toJson', () {
      test('должен сериализовать XcollFile полностью (light)', () {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'Export Test',
          author: 'Exporter',
          created: testDate,
          description: 'Desc',
          items: const <Map<String, dynamic>>[
            <String, dynamic>{'id': 'item1', 'type': 'game'},
          ],
        );

        final Map<String, dynamic> json = xcoll.toJson();

        expect(json['version'], equals(2));
        expect(json['format'], equals('light'));
        expect(json['name'], equals('Export Test'));
        expect(json['author'], equals('Exporter'));
        expect(json['created'], equals('2024-01-15T12:00:00.000Z'));
        expect(json['description'], equals('Desc'));
        expect((json['items'] as List<dynamic>).length, equals(1));
        expect(json.containsKey('canvas'), isFalse);
        expect(json.containsKey('images'), isFalse);
      });

      test('должен сериализовать XcollFile полностью (full)', () {
        const ExportCanvas canvas = ExportCanvas(
          viewport: <String, dynamic>{'x': 0, 'y': 0},
          items: <Map<String, dynamic>>[],
          connections: <Map<String, dynamic>>[],
        );

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Full Export',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[],
          canvas: canvas,
          images: const <String, String>{
            'game_covers/123': 'base64data',
          },
        );

        final Map<String, dynamic> json = xcoll.toJson();

        expect(json['format'], equals('full'));
        expect(json.containsKey('canvas'), isTrue);
        expect(json.containsKey('images'), isTrue);
      });

      test('должен исключить description если он null', () {
        final XcollFile xcoll = XcollFile(
          version: 2,
          name: 'No Desc',
          author: 'Author',
          created: testDate,
        );

        final Map<String, dynamic> json = xcoll.toJson();

        expect(json.containsKey('description'), isFalse);
      });

      test('должен исключить images если пустой', () {
        final XcollFile xcoll = XcollFile(
          version: 2,
          name: 'No Images',
          author: 'Author',
          created: testDate,
        );

        final Map<String, dynamic> json = xcoll.toJson();

        expect(json.containsKey('images'), isFalse);
      });
    });

    group('toJsonString', () {
      test('должен возвращать отформатированный JSON', () {
        final XcollFile xcoll = XcollFile(
          version: 2,
          name: 'Formatted',
          author: 'Auth',
          created: testDate,
        );

        final String jsonString = xcoll.toJsonString();

        // Проверяем что содержит отступы (форматирование)
        expect(jsonString, contains('  '));
        // Проверяем что можно обратно распарсить
        final Map<String, dynamic> parsed =
            jsonDecode(jsonString) as Map<String, dynamic>;
        expect(parsed['name'], equals('Formatted'));
      });
    });

    group('isFull', () {
      test('должен возвращать true для full формата', () {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Full',
          author: 'Author',
          created: testDate,
        );

        expect(xcoll.isFull, isTrue);
      });

      test('должен возвращать false для light формата', () {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'Light',
          author: 'Author',
          created: testDate,
        );

        expect(xcoll.isFull, isFalse);
      });
    });

    test('fromJsonString/toJsonString round-trip', () {
      const ExportCanvas canvas = ExportCanvas(
        viewport: <String, dynamic>{'x': 5, 'y': 10, 'zoom': 1.5},
        items: <Map<String, dynamic>>[
          <String, dynamic>{'id': 'g1', 'type': 'game'},
        ],
        connections: <Map<String, dynamic>>[],
      );

      final XcollFile original = XcollFile(
        version: 2,
        format: ExportFormat.full,
        name: 'Round Trip Test',
        author: 'Tester',
        created: testDate,
        description: 'Testing round trip',
        items: const <Map<String, dynamic>>[
          <String, dynamic>{'id': 'item1', 'igdbId': 111},
          <String, dynamic>{'id': 'item2', 'igdbId': 222},
        ],
        canvas: canvas,
        images: const <String, String>{
          'game_covers/111': 'imgdata1',
        },
      );

      final String jsonString = original.toJsonString();
      final XcollFile restored = XcollFile.fromJsonString(jsonString);

      expect(restored.version, equals(original.version));
      expect(restored.format, equals(original.format));
      expect(restored.name, equals(original.name));
      expect(restored.author, equals(original.author));
      expect(restored.created, equals(original.created));
      expect(restored.description, equals(original.description));
      expect(restored.items.length, equals(original.items.length));
      expect(restored.canvas, isNotNull);
      expect(restored.canvas!.items.length, equals(1));
      expect(restored.images.length, equals(1));
      expect(restored.images['game_covers/111'], equals('imgdata1'));
    });
  });

  group('xcollFormatVersion', () {
    test('должен быть равен 2', () {
      expect(xcollFormatVersion, equals(2));
    });
  });
}
