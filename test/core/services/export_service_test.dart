import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/export_service.dart';
import 'package:xerabora/core/services/rcoll_file.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_game.dart';

void main() {
  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

  Collection createTestCollection({
    int id = 1,
    String name = 'Test Collection',
    String author = 'Test Author',
    CollectionType type = CollectionType.own,
  }) {
    return Collection(
      id: id,
      name: name,
      author: author,
      type: type,
      createdAt: testDate,
    );
  }

  CollectionGame createTestGame({
    int id = 1,
    int collectionId = 1,
    int igdbId = 100,
    int platformId = 18,
    String? authorComment,
    GameStatus status = GameStatus.notStarted,
  }) {
    return CollectionGame(
      id: id,
      collectionId: collectionId,
      igdbId: igdbId,
      platformId: platformId,
      authorComment: authorComment,
      status: status,
      addedAt: testDate,
    );
  }

  group('ExportResult', () {
    test('ExportResult.success должен создать успешный результат', () {
      const ExportResult result = ExportResult.success('/path/to/file.rcoll');

      expect(result.success, isTrue);
      expect(result.filePath, equals('/path/to/file.rcoll'));
      expect(result.error, isNull);
      expect(result.isCancelled, isFalse);
    });

    test('ExportResult.failure должен создать неуспешный результат', () {
      const ExportResult result = ExportResult.failure('Error message');

      expect(result.success, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, equals('Error message'));
      expect(result.isCancelled, isFalse);
    });

    test('ExportResult.cancelled должен создать отменённый результат', () {
      const ExportResult result = ExportResult.cancelled();

      expect(result.success, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, isNull);
      expect(result.isCancelled, isTrue);
    });

    test('isCancelled должен быть false при ошибке', () {
      const ExportResult result = ExportResult(
        success: false,
        error: 'Some error',
      );

      expect(result.isCancelled, isFalse);
    });
  });

  group('ExportService', () {
    late ExportService sut;

    setUp(() {
      sut = ExportService();
    });

    group('createRcollFile', () {
      test('должен создать RcollFile из коллекции без игр', () {
        final Collection collection = createTestCollection();
        final List<CollectionGame> games = <CollectionGame>[];

        final RcollFile rcoll = sut.createRcollFile(collection, games);

        expect(rcoll.version, equals(rcollFormatVersion));
        expect(rcoll.name, equals('Test Collection'));
        expect(rcoll.author, equals('Test Author'));
        expect(rcoll.created, equals(testDate));
        expect(rcoll.games, isEmpty);
      });

      test('должен создать RcollFile с играми', () {
        final Collection collection = createTestCollection();
        final List<CollectionGame> games = <CollectionGame>[
          createTestGame(igdbId: 100, platformId: 18, authorComment: 'Comment 1'),
          createTestGame(id: 2, igdbId: 200, platformId: 19),
        ];

        final RcollFile rcoll = sut.createRcollFile(collection, games);

        expect(rcoll.games.length, equals(2));
        expect(rcoll.games[0].igdbId, equals(100));
        expect(rcoll.games[0].platformId, equals(18));
        expect(rcoll.games[0].comment, equals('Comment 1'));
        expect(rcoll.games[1].igdbId, equals(200));
        expect(rcoll.games[1].comment, isNull);
      });

      test('должен использовать authorComment а не userComment', () {
        final Collection collection = createTestCollection();
        final CollectionGame game = CollectionGame(
          id: 1,
          collectionId: 1,
          igdbId: 100,
          platformId: 18,
          authorComment: 'Author says',
          userComment: 'User says',
          status: GameStatus.notStarted,
          addedAt: testDate,
        );

        final RcollFile rcoll = sut.createRcollFile(collection, <CollectionGame>[game]);

        expect(rcoll.games[0].comment, equals('Author says'));
      });
    });

    group('exportToJson', () {
      test('должен вернуть валидный JSON', () {
        final Collection collection = createTestCollection(name: 'JSON Export');
        final List<CollectionGame> games = <CollectionGame>[
          createTestGame(igdbId: 500, platformId: 20),
        ];

        final String json = sut.exportToJson(collection, games);

        // Проверяем что это валидный JSON
        final Map<String, dynamic> parsed =
            jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['name'], equals('JSON Export'));
        expect(parsed['version'], equals(rcollFormatVersion));
        expect((parsed['games'] as List<dynamic>).length, equals(1));
      });

      test('должен создать форматированный JSON с отступами', () {
        final Collection collection = createTestCollection();
        final List<CollectionGame> games = <CollectionGame>[];

        final String json = sut.exportToJson(collection, games);

        // Проверяем наличие отступов
        expect(json, contains('\n'));
        expect(json, contains('  ')); // Двойной пробел для отступа
      });

      test('должен корректно экспортировать пустую коллекцию', () {
        final Collection collection = createTestCollection(name: 'Empty');
        final List<CollectionGame> games = <CollectionGame>[];

        final String json = sut.exportToJson(collection, games);
        final RcollFile restored = RcollFile.fromJsonString(json);

        expect(restored.name, equals('Empty'));
        expect(restored.games, isEmpty);
      });

      test('должен сохранять все данные игр при round-trip', () {
        final Collection collection = createTestCollection();
        final List<CollectionGame> games = <CollectionGame>[
          createTestGame(
            igdbId: 111,
            platformId: 22,
            authorComment: 'Fantastic game',
          ),
        ];

        final String json = sut.exportToJson(collection, games);
        final RcollFile restored = RcollFile.fromJsonString(json);

        expect(restored.games[0].igdbId, equals(111));
        expect(restored.games[0].platformId, equals(22));
        expect(restored.games[0].comment, equals('Fantastic game'));
      });
    });
  });
}
