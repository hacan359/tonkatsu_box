import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/collection_game.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/platform.dart';

void main() {
  group('GameStatus', () {
    test('должен иметь правильные строковые значения', () {
      expect(GameStatus.notStarted.value, 'not_started');
      expect(GameStatus.playing.value, 'playing');
      expect(GameStatus.completed.value, 'completed');
      expect(GameStatus.dropped.value, 'dropped');
      expect(GameStatus.planned.value, 'planned');
    });

    test('должен иметь правильные labels', () {
      expect(GameStatus.notStarted.label, 'Not Started');
      expect(GameStatus.playing.label, 'Playing');
      expect(GameStatus.completed.label, 'Completed');
      expect(GameStatus.dropped.label, 'Dropped');
      expect(GameStatus.planned.label, 'Planned');
    });

    test('должен иметь правильные иконки', () {
      expect(GameStatus.notStarted.icon, '⬜');
      expect(GameStatus.playing.icon, '🎮');
      expect(GameStatus.completed.icon, '✅');
      expect(GameStatus.dropped.icon, '⏸️');
      expect(GameStatus.planned.icon, '📋');
    });

    test('fromString должен возвращать правильный статус', () {
      expect(GameStatus.fromString('not_started'), GameStatus.notStarted);
      expect(GameStatus.fromString('playing'), GameStatus.playing);
      expect(GameStatus.fromString('completed'), GameStatus.completed);
      expect(GameStatus.fromString('dropped'), GameStatus.dropped);
      expect(GameStatus.fromString('planned'), GameStatus.planned);
    });

    test('fromString должен возвращать notStarted для неизвестного значения', () {
      expect(GameStatus.fromString('unknown'), GameStatus.notStarted);
      expect(GameStatus.fromString(''), GameStatus.notStarted);
    });

    test('displayText должен возвращать иконку и label', () {
      expect(GameStatus.notStarted.displayText, '⬜ Not Started');
      expect(GameStatus.playing.displayText, '🎮 Playing');
      expect(GameStatus.completed.displayText, '✅ Completed');
    });
  });

  group('CollectionGame', () {
    final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);
    final int testTimestamp = testDate.millisecondsSinceEpoch ~/ 1000;

    CollectionGame createTestGame({
      int id = 1,
      int collectionId = 10,
      int igdbId = 100,
      int platformId = 18,
      GameStatus status = GameStatus.notStarted,
      DateTime? addedAt,
      String? authorComment,
      String? userComment,
      Game? game,
      Platform? platform,
    }) {
      return CollectionGame(
        id: id,
        collectionId: collectionId,
        igdbId: igdbId,
        platformId: platformId,
        status: status,
        addedAt: addedAt ?? testDate,
        authorComment: authorComment,
        userComment: userComment,
        game: game,
        platform: platform,
      );
    }

    group('constructor', () {
      test('должен создавать экземпляр с обязательными полями', () {
        final CollectionGame cg = createTestGame();

        expect(cg.id, 1);
        expect(cg.collectionId, 10);
        expect(cg.igdbId, 100);
        expect(cg.platformId, 18);
        expect(cg.status, GameStatus.notStarted);
        expect(cg.addedAt, testDate);
      });

      test('должен создавать экземпляр с опциональными полями', () {
        const Game game = Game(id: 100, name: 'Test Game');
        const Platform platform = Platform(id: 18, name: 'NES');

        final CollectionGame cg = createTestGame(
          authorComment: 'Great game!',
          userComment: 'My notes',
          game: game,
          platform: platform,
        );

        expect(cg.authorComment, 'Great game!');
        expect(cg.userComment, 'My notes');
        expect(cg.game, game);
        expect(cg.platform, platform);
      });
    });

    group('fromDb', () {
      test('должен создавать CollectionGame из записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'igdb_id': 100,
          'platform_id': 18,
          'author_comment': 'Comment',
          'user_comment': 'Notes',
          'status': 'playing',
          'added_at': testTimestamp,
        };

        final CollectionGame cg = CollectionGame.fromDb(row);

        expect(cg.id, 1);
        expect(cg.collectionId, 10);
        expect(cg.igdbId, 100);
        expect(cg.platformId, 18);
        expect(cg.authorComment, 'Comment');
        expect(cg.userComment, 'Notes');
        expect(cg.status, GameStatus.playing);
        expect(cg.addedAt.millisecondsSinceEpoch ~/ 1000, testTimestamp);
      });

      test('должен обрабатывать null комментарии', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'igdb_id': 100,
          'platform_id': 18,
          'author_comment': null,
          'user_comment': null,
          'status': 'not_started',
          'added_at': testTimestamp,
        };

        final CollectionGame cg = CollectionGame.fromDb(row);

        expect(cg.authorComment, null);
        expect(cg.userComment, null);
      });
    });

    group('fromDbWithJoins', () {
      test('должен создавать CollectionGame с joined данными', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'igdb_id': 100,
          'platform_id': 18,
          'author_comment': null,
          'user_comment': null,
          'status': 'completed',
          'added_at': testTimestamp,
        };

        const Game game = Game(id: 100, name: 'Super Mario');
        const Platform platform = Platform(id: 18, name: 'NES');

        final CollectionGame cg = CollectionGame.fromDbWithJoins(
          row,
          game: game,
          platform: platform,
        );

        expect(cg.game, game);
        expect(cg.platform, platform);
        expect(cg.status, GameStatus.completed);
      });
    });

    group('gameName', () {
      test('должен возвращать название игры', () {
        const Game game = Game(id: 100, name: 'Zelda');
        final CollectionGame cg = createTestGame(game: game);

        expect(cg.gameName, 'Zelda');
      });

      test('должен возвращать Unknown Game когда game = null', () {
        final CollectionGame cg = createTestGame();

        expect(cg.gameName, 'Unknown Game');
      });
    });

    group('platformName', () {
      test('должен возвращать displayName платформы', () {
        const Platform platform = Platform(id: 18, name: 'Nintendo Entertainment System', abbreviation: 'NES');
        final CollectionGame cg = createTestGame(platform: platform);

        expect(cg.platformName, 'NES');
      });

      test('должен возвращать Unknown Platform когда platform = null', () {
        final CollectionGame cg = createTestGame();

        expect(cg.platformName, 'Unknown Platform');
      });
    });

    group('hasAuthorComment', () {
      test('должен возвращать true когда есть комментарий', () {
        final CollectionGame cg = createTestGame(authorComment: 'Comment');
        expect(cg.hasAuthorComment, true);
      });

      test('должен возвращать false когда комментарий null', () {
        final CollectionGame cg = createTestGame(authorComment: null);
        expect(cg.hasAuthorComment, false);
      });

      test('должен возвращать false когда комментарий пустой', () {
        final CollectionGame cg = createTestGame(authorComment: '');
        expect(cg.hasAuthorComment, false);
      });
    });

    group('hasUserComment', () {
      test('должен возвращать true когда есть комментарий', () {
        final CollectionGame cg = createTestGame(userComment: 'Notes');
        expect(cg.hasUserComment, true);
      });

      test('должен возвращать false когда комментарий null', () {
        final CollectionGame cg = createTestGame(userComment: null);
        expect(cg.hasUserComment, false);
      });

      test('должен возвращать false когда комментарий пустой', () {
        final CollectionGame cg = createTestGame(userComment: '');
        expect(cg.hasUserComment, false);
      });
    });

    group('isCompleted', () {
      test('должен возвращать true для completed статуса', () {
        final CollectionGame cg = createTestGame(status: GameStatus.completed);
        expect(cg.isCompleted, true);
      });

      test('должен возвращать false для других статусов', () {
        expect(createTestGame(status: GameStatus.notStarted).isCompleted, false);
        expect(createTestGame(status: GameStatus.playing).isCompleted, false);
        expect(createTestGame(status: GameStatus.dropped).isCompleted, false);
        expect(createTestGame(status: GameStatus.planned).isCompleted, false);
      });
    });

    group('toDb', () {
      test('должен возвращать корректную Map для БД', () {
        final CollectionGame cg = createTestGame(
          authorComment: 'Auth comment',
          userComment: 'User comment',
          status: GameStatus.playing,
        );

        final Map<String, dynamic> db = cg.toDb();

        expect(db['id'], 1);
        expect(db['collection_id'], 10);
        expect(db['igdb_id'], 100);
        expect(db['platform_id'], 18);
        expect(db['author_comment'], 'Auth comment');
        expect(db['user_comment'], 'User comment');
        expect(db['status'], 'playing');
        expect(db['added_at'], testTimestamp);
      });
    });

    group('toJson', () {
      test('должен возвращать корректный JSON для экспорта', () {
        final CollectionGame cg = createTestGame(
          authorComment: 'Comment for export',
        );

        final Map<String, dynamic> json = cg.toJson();

        expect(json['igdb_id'], 100);
        expect(json['platform_id'], 18);
        expect(json['comment'], 'Comment for export');
        expect(json.containsKey('id'), false);
        expect(json.containsKey('collection_id'), false);
        expect(json.containsKey('user_comment'), false);
        expect(json.containsKey('status'), false);
      });
    });

    group('copyWith', () {
      test('должен создавать копию с изменённым статусом', () {
        final CollectionGame original = createTestGame(status: GameStatus.notStarted);
        final CollectionGame copy = original.copyWith(status: GameStatus.completed);

        expect(copy.status, GameStatus.completed);
        expect(copy.id, original.id);
        expect(copy.collectionId, original.collectionId);
      });

      test('должен создавать копию с изменённым комментарием', () {
        final CollectionGame original = createTestGame(authorComment: 'Old');
        final CollectionGame copy = original.copyWith(authorComment: 'New');

        expect(copy.authorComment, 'New');
      });

      test('должен создавать копию со всеми изменёнными полями', () {
        const Game newGame = Game(id: 200, name: 'New Game');
        const Platform newPlatform = Platform(id: 7, name: 'SNES');
        final DateTime newDate = DateTime(2025, 6, 1);

        final CollectionGame original = createTestGame();
        final CollectionGame copy = original.copyWith(
          id: 99,
          collectionId: 20,
          igdbId: 200,
          platformId: 7,
          authorComment: 'Author',
          userComment: 'User',
          status: GameStatus.dropped,
          addedAt: newDate,
          game: newGame,
          platform: newPlatform,
        );

        expect(copy.id, 99);
        expect(copy.collectionId, 20);
        expect(copy.igdbId, 200);
        expect(copy.platformId, 7);
        expect(copy.authorComment, 'Author');
        expect(copy.userComment, 'User');
        expect(copy.status, GameStatus.dropped);
        expect(copy.addedAt, newDate);
        expect(copy.game, newGame);
        expect(copy.platform, newPlatform);
      });
    });

    group('equality', () {
      test('должен быть равен при одинаковом id', () {
        final CollectionGame a = createTestGame(id: 1, status: GameStatus.notStarted);
        final CollectionGame b = createTestGame(id: 1, status: GameStatus.completed);

        expect(a == b, true);
        expect(a.hashCode, b.hashCode);
      });

      test('должен быть не равен при разных id', () {
        final CollectionGame a = createTestGame(id: 1);
        final CollectionGame b = createTestGame(id: 2);

        expect(a == b, false);
      });

      test('должен быть равен самому себе', () {
        final CollectionGame cg = createTestGame();
        expect(cg == cg, true);
      });

      test('должен быть не равен объекту другого типа', () {
        final CollectionGame cg = createTestGame();
        // ignore: unrelated_type_equality_checks
        expect(cg == 'string', false);
      });
    });

    group('toString', () {
      test('должен возвращать корректную строку', () {
        final CollectionGame cg = createTestGame(
          id: 5,
          igdbId: 123,
          status: GameStatus.playing,
        );

        expect(cg.toString(), 'CollectionGame(id: 5, igdbId: 123, status: playing)');
      });
    });
  });
}
