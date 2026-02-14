// Тесты для модели CollectionItem

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/platform.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  group('CollectionItem', () {
    // Общие тестовые данные
    final DateTime testAddedAt = DateTime(2024, 1, 15, 12, 0, 0);
    final int testAddedAtUnix = testAddedAt.millisecondsSinceEpoch ~/ 1000;

    const Game testGame = Game(
      id: 1942,
      name: 'The Witcher 3: Wild Hunt',
      coverUrl: 'https://example.com/witcher3.jpg',
    );

    const Movie testMovie = Movie(
      tmdbId: 550,
      title: 'Fight Club',
      posterUrl: 'https://example.com/fightclub.jpg',
    );

    const TvShow testTvShow = TvShow(
      tmdbId: 1399,
      title: 'Breaking Bad',
      posterUrl: 'https://example.com/breakingbad.jpg',
    );

    const Platform testPlatform = Platform(
      id: 48,
      name: 'PlayStation 4',
      abbreviation: 'PS4',
    );

    group('fromDb', () {
      test('должен создать CollectionItem из полной записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'media_type': 'game',
          'external_id': 1942,
          'platform_id': 48,
          'current_season': 0,
          'current_episode': 0,
          'status': 'completed',
          'author_comment': 'Шедевр RPG',
          'user_comment': 'Прошёл на 100%',
          'added_at': testAddedAtUnix,
        };

        final CollectionItem item = CollectionItem.fromDb(row);

        expect(item.id, 1);
        expect(item.collectionId, 10);
        expect(item.mediaType, MediaType.game);
        expect(item.externalId, 1942);
        expect(item.platformId, 48);
        expect(item.currentSeason, 0);
        expect(item.currentEpisode, 0);
        expect(item.status, ItemStatus.completed);
        expect(item.authorComment, 'Шедевр RPG');
        expect(item.userComment, 'Прошёл на 100%');
        expect(item.addedAt.year, testAddedAt.year);
        expect(item.addedAt.month, testAddedAt.month);
        expect(item.addedAt.day, testAddedAt.day);
      });

      test('должен создать CollectionItem из минимальной записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 2,
          'collection_id': 10,
          'media_type': 'movie',
          'external_id': 550,
          'platform_id': null,
          'current_season': null,
          'current_episode': null,
          'status': 'not_started',
          'author_comment': null,
          'user_comment': null,
          'added_at': testAddedAtUnix,
        };

        final CollectionItem item = CollectionItem.fromDb(row);

        expect(item.id, 2);
        expect(item.collectionId, 10);
        expect(item.mediaType, MediaType.movie);
        expect(item.externalId, 550);
        expect(item.platformId, isNull);
        expect(item.currentSeason, 0);
        expect(item.currentEpisode, 0);
        expect(item.status, ItemStatus.notStarted);
        expect(item.authorComment, isNull);
        expect(item.userComment, isNull);
      });

      test('должен обработать null в необязательных полях', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 3,
          'collection_id': 10,
          'media_type': 'tv_show',
          'external_id': 1399,
          'platform_id': null,
          'current_season': null,
          'current_episode': null,
          'status': 'in_progress',
          'author_comment': null,
          'user_comment': null,
          'added_at': testAddedAtUnix,
        };

        final CollectionItem item = CollectionItem.fromDb(row);

        expect(item.platformId, isNull);
        expect(item.currentSeason, 0);
        expect(item.currentEpisode, 0);
        expect(item.authorComment, isNull);
        expect(item.userComment, isNull);
        expect(item.game, isNull);
        expect(item.movie, isNull);
        expect(item.tvShow, isNull);
        expect(item.platform, isNull);
      });

    });

    group('fromDbWithJoins', () {
      test('должен создать CollectionItem с объектом Game', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'media_type': 'game',
          'external_id': 1942,
          'platform_id': 48,
          'current_season': null,
          'current_episode': null,
          'status': 'completed',
          'author_comment': null,
          'user_comment': null,
          'added_at': testAddedAtUnix,
        };

        final CollectionItem item = CollectionItem.fromDbWithJoins(
          row,
          game: testGame,
          platform: testPlatform,
        );

        expect(item.game, testGame);
        expect(item.platform, testPlatform);
        expect(item.movie, isNull);
        expect(item.tvShow, isNull);
      });

      test('должен создать CollectionItem с объектом Movie', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 2,
          'collection_id': 10,
          'media_type': 'movie',
          'external_id': 550,
          'platform_id': null,
          'current_season': null,
          'current_episode': null,
          'status': 'completed',
          'author_comment': null,
          'user_comment': null,
          'added_at': testAddedAtUnix,
        };

        final CollectionItem item = CollectionItem.fromDbWithJoins(
          row,
          movie: testMovie,
        );

        expect(item.movie, testMovie);
        expect(item.game, isNull);
        expect(item.tvShow, isNull);
        expect(item.platform, isNull);
      });

      test('должен создать CollectionItem с объектом TvShow', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 3,
          'collection_id': 10,
          'media_type': 'tv_show',
          'external_id': 1399,
          'platform_id': null,
          'current_season': 3,
          'current_episode': 5,
          'status': 'in_progress',
          'author_comment': null,
          'user_comment': null,
          'added_at': testAddedAtUnix,
        };

        final CollectionItem item = CollectionItem.fromDbWithJoins(
          row,
          tvShow: testTvShow,
        );

        expect(item.tvShow, testTvShow);
        expect(item.currentSeason, 3);
        expect(item.currentEpisode, 5);
        expect(item.game, isNull);
        expect(item.movie, isNull);
      });

      test('должен создать CollectionItem с объектом Platform', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'media_type': 'game',
          'external_id': 1942,
          'platform_id': 48,
          'current_season': null,
          'current_episode': null,
          'status': 'not_started',
          'author_comment': null,
          'user_comment': null,
          'added_at': testAddedAtUnix,
        };

        final CollectionItem item = CollectionItem.fromDbWithJoins(
          row,
          platform: testPlatform,
        );

        expect(item.platform, testPlatform);
        expect(item.platformName, 'PS4');
      });
    });

    group('toDb', () {
      test('должен конвертировать полный элемент в Map для БД', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          platformId: 48,
          currentSeason: 0,
          currentEpisode: 0,
          status: ItemStatus.completed,
          authorComment: 'Шедевр',
          userComment: 'Отлично',
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> db = item.toDb();

        expect(db['id'], 1);
        expect(db['collection_id'], 10);
        expect(db['media_type'], 'game');
        expect(db['external_id'], 1942);
        expect(db['platform_id'], 48);
        expect(db['current_season'], 0);
        expect(db['current_episode'], 0);
        expect(db['status'], 'completed');
        expect(db['author_comment'], 'Шедевр');
        expect(db['user_comment'], 'Отлично');
        expect(db['added_at'], testAddedAtUnix);
      });

      test('должен конвертировать минимальный элемент в Map для БД', () {
        final CollectionItem item = CollectionItem(
          id: 2,
          collectionId: 10,
          mediaType: MediaType.movie,
          externalId: 550,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> db = item.toDb();

        expect(db['id'], 2);
        expect(db['collection_id'], 10);
        expect(db['media_type'], 'movie');
        expect(db['external_id'], 550);
        expect(db['platform_id'], isNull);
        expect(db['current_season'], 0);
        expect(db['current_episode'], 0);
        expect(db['status'], 'not_started');
        expect(db['author_comment'], isNull);
        expect(db['user_comment'], isNull);
      });

      test('должен использовать status.value для game inProgress', () {
        final CollectionItem item = CollectionItem(
          id: 3,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          status: ItemStatus.inProgress,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> db = item.toDb();

        expect(db['status'], 'in_progress');
      });

      test('должен использовать status.value для movie inProgress', () {
        final CollectionItem item = CollectionItem(
          id: 4,
          collectionId: 10,
          mediaType: MediaType.movie,
          externalId: 550,
          status: ItemStatus.inProgress,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> db = item.toDb();

        expect(db['status'], 'in_progress');
      });
    });

    group('toExport', () {
      test('должен конвертировать game элемент в JSON', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          platformId: 48,
          status: ItemStatus.completed,
          authorComment: 'Шедевр',
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> json = item.toExport();

        expect(json['media_type'], 'game');
        expect(json['external_id'], 1942);
        expect(json['platform_id'], 48);
        expect(json['comment'], 'Шедевр');
        expect(json.containsKey('status'), isFalse);
        expect(json.containsKey('current_season'), isFalse);
        expect(json.containsKey('current_episode'), isFalse);
      });

      test('должен конвертировать movie элемент в JSON', () {
        final CollectionItem item = CollectionItem(
          id: 2,
          collectionId: 10,
          mediaType: MediaType.movie,
          externalId: 550,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> json = item.toExport();

        expect(json['media_type'], 'movie');
        expect(json['external_id'], 550);
        expect(json['platform_id'], isNull);
        expect(json['comment'], isNull);
        expect(json.containsKey('status'), isFalse);
        expect(json.containsKey('current_season'), isFalse);
        expect(json.containsKey('current_episode'), isFalse);
      });

      test('должен конвертировать tvShow элемент в JSON без status/season/episode', () {
        final CollectionItem item = CollectionItem(
          id: 3,
          collectionId: 10,
          mediaType: MediaType.tvShow,
          externalId: 1399,
          currentSeason: 3,
          currentEpisode: 5,
          status: ItemStatus.inProgress,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> json = item.toExport();

        expect(json['media_type'], 'tv_show');
        expect(json['external_id'], 1399);
        expect(json.containsKey('status'), isFalse);
        expect(json.containsKey('current_season'), isFalse);
        expect(json.containsKey('current_episode'), isFalse);
      });

      test('должен включать platform_id как null если не задан', () {
        final CollectionItem item = CollectionItem(
          id: 4,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> json = item.toExport();

        expect(json.containsKey('platform_id'), isTrue);
        expect(json['platform_id'], isNull);
      });

      test('должен включать comment как null если authorComment null', () {
        final CollectionItem item = CollectionItem(
          id: 5,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> json = item.toExport();

        expect(json.containsKey('comment'), isTrue);
        expect(json['comment'], isNull);
      });
    });

    group('fromExport', () {
      test('должен создать CollectionItem из полных экспортных данных', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'media_type': 'game',
          'external_id': 1942,
          'platform_id': 48,
          'comment': 'Шедевр RPG',
        };

        final CollectionItem item = CollectionItem.fromExport(
          json,
          id: 1,
          collectionId: 10,
        );

        expect(item.id, 1);
        expect(item.collectionId, 10);
        expect(item.mediaType, MediaType.game);
        expect(item.externalId, 1942);
        expect(item.platformId, 48);
        expect(item.authorComment, 'Шедевр RPG');
        expect(item.status, ItemStatus.notStarted);
        expect(item.currentSeason, 0);
        expect(item.currentEpisode, 0);
      });

      test('должен создать CollectionItem из минимальных экспортных данных', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'media_type': 'movie',
          'external_id': 550,
        };

        final CollectionItem item = CollectionItem.fromExport(json);

        expect(item.id, 0);
        expect(item.collectionId, 0);
        expect(item.mediaType, MediaType.movie);
        expect(item.externalId, 550);
        expect(item.platformId, isNull);
        expect(item.authorComment, isNull);
        expect(item.status, ItemStatus.notStarted);
      });

      test('должен использовать дефолтный статус notStarted когда status отсутствует', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'media_type': 'game',
          'external_id': 100,
          'platform_id': null,
          'comment': null,
        };

        final CollectionItem item = CollectionItem.fromExport(json);

        expect(item.status, ItemStatus.notStarted);
      });

      test('должен корректно парсить status из JSON для обратной совместимости', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'media_type': 'game',
          'external_id': 1942,
          'platform_id': 48,
          'comment': 'Шедевр',
          'status': 'completed',
          'current_season': 0,
          'current_episode': 0,
        };

        final CollectionItem item = CollectionItem.fromExport(json);

        expect(item.status, ItemStatus.completed);
        expect(item.currentSeason, 0);
        expect(item.currentEpisode, 0);
      });

      test('должен парсить все значения status для обратной совместимости', () {
        for (final ItemStatus status in ItemStatus.values) {
          final Map<String, dynamic> json = <String, dynamic>{
            'media_type': 'game',
            'external_id': 100,
            'status': status.value,
          };

          final CollectionItem item = CollectionItem.fromExport(json);

          expect(
            item.status,
            status,
            reason: 'status ${status.value} должен быть корректно распарсен',
          );
        }
      });

      test('должен парсить tvShow с season/episode для обратной совместимости', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'media_type': 'tv_show',
          'external_id': 1399,
          'status': 'in_progress',
          'current_season': 3,
          'current_episode': 5,
        };

        final CollectionItem item = CollectionItem.fromExport(json);

        expect(item.mediaType, MediaType.tvShow);
        expect(item.status, ItemStatus.inProgress);
        expect(item.currentSeason, 3);
        expect(item.currentEpisode, 5);
      });

      test('должен использовать переданный addedAt', () {
        final DateTime customDate = DateTime(2023, 6, 15);
        final Map<String, dynamic> json = <String, dynamic>{
          'media_type': 'movie',
          'external_id': 550,
        };

        final CollectionItem item = CollectionItem.fromExport(
          json,
          addedAt: customDate,
        );

        expect(item.addedAt, customDate);
      });
    });

    group('copyWith', () {
      test('должен создать копию с изменёнными полями', () {
        final CollectionItem original = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          platformId: 48,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        final CollectionItem copy = original.copyWith(
          status: ItemStatus.completed,
          userComment: 'Пройдено!',
        );

        expect(copy.id, 1);
        expect(copy.collectionId, 10);
        expect(copy.mediaType, MediaType.game);
        expect(copy.externalId, 1942);
        expect(copy.platformId, 48);
        expect(copy.status, ItemStatus.completed);
        expect(copy.userComment, 'Пройдено!');
        expect(copy.addedAt, testAddedAt);
      });

      test('должен сохранить неизменённые поля', () {
        final CollectionItem original = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.tvShow,
          externalId: 1399,
          currentSeason: 2,
          currentEpisode: 8,
          status: ItemStatus.inProgress,
          authorComment: 'Отличный сериал',
          addedAt: testAddedAt,
          tvShow: testTvShow,
        );

        final CollectionItem copy = original.copyWith(
          currentEpisode: 9,
        );

        expect(copy.id, original.id);
        expect(copy.collectionId, original.collectionId);
        expect(copy.mediaType, original.mediaType);
        expect(copy.externalId, original.externalId);
        expect(copy.currentSeason, original.currentSeason);
        expect(copy.currentEpisode, 9);
        expect(copy.status, original.status);
        expect(copy.authorComment, original.authorComment);
        expect(copy.addedAt, original.addedAt);
        expect(copy.tvShow, original.tvShow);
      });

      test('должен позволять изменять joined объекты', () {
        final CollectionItem original = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        final CollectionItem copy = original.copyWith(
          game: testGame,
          platform: testPlatform,
        );

        expect(copy.game, testGame);
        expect(copy.platform, testPlatform);
      });
    });

    group('equality', () {
      test('должен быть равен другому CollectionItem с тем же id', () {
        final CollectionItem item1 = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );
        final CollectionItem item2 = CollectionItem(
          id: 1,
          collectionId: 20,
          mediaType: MediaType.movie,
          externalId: 550,
          status: ItemStatus.completed,
          addedAt: DateTime(2025, 6, 1),
        );

        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('не должен быть равен CollectionItem с другим id', () {
        final CollectionItem item1 = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );
        final CollectionItem item2 = CollectionItem(
          id: 2,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('должен быть равен самому себе (identical)', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        expect(item == item, isTrue);
      });

      test('не должен быть равен объекту другого типа', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        expect(item == Object(), isFalse);
      });
    });

    group('toString', () {
      test('должен вернуть читаемое строковое представление', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          status: ItemStatus.completed,
          addedAt: testAddedAt,
        );

        final String result = item.toString();

        expect(result, contains('CollectionItem'));
        expect(result, contains('id: 1'));
        expect(result, contains('type: game'));
        expect(result, contains('externalId: 1942'));
        expect(result, contains('status: completed'));
      });
    });

    group('геттеры', () {
      group('igdbId', () {
        test('должен вернуть externalId', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.igdbId, 1942);
          expect(item.igdbId, item.externalId);
        });
      });

      group('itemName', () {
        test('должен вернуть имя игры когда game присутствует', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            game: testGame,
          );

          expect(item.itemName, 'The Witcher 3: Wild Hunt');
        });

        test('должен вернуть "Unknown Game" когда game null', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.itemName, 'Unknown Game');
        });

        test('должен вернуть название фильма когда movie присутствует', () {
          final CollectionItem item = CollectionItem(
            id: 2,
            collectionId: 10,
            mediaType: MediaType.movie,
            externalId: 550,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            movie: testMovie,
          );

          expect(item.itemName, 'Fight Club');
        });

        test('должен вернуть "Unknown Movie" когда movie null', () {
          final CollectionItem item = CollectionItem(
            id: 2,
            collectionId: 10,
            mediaType: MediaType.movie,
            externalId: 550,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.itemName, 'Unknown Movie');
        });

        test('должен вернуть название сериала когда tvShow присутствует', () {
          final CollectionItem item = CollectionItem(
            id: 3,
            collectionId: 10,
            mediaType: MediaType.tvShow,
            externalId: 1399,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            tvShow: testTvShow,
          );

          expect(item.itemName, 'Breaking Bad');
        });

        test('должен вернуть "Unknown TV Show" когда tvShow null', () {
          final CollectionItem item = CollectionItem(
            id: 3,
            collectionId: 10,
            mediaType: MediaType.tvShow,
            externalId: 1399,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.itemName, 'Unknown TV Show');
        });

        test('должен вернуть название фильма для анимации с источником movie', () {
          final CollectionItem item = CollectionItem(
            id: 4,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 550,
            platformId: AnimationSource.movie,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            movie: testMovie,
          );

          expect(item.itemName, 'Fight Club');
        });

        test('должен вернуть название сериала для анимации с источником tvShow', () {
          final CollectionItem item = CollectionItem(
            id: 5,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 1399,
            platformId: AnimationSource.tvShow,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            tvShow: testTvShow,
          );

          expect(item.itemName, 'Breaking Bad');
        });

        test('должен вернуть "Unknown Animation" когда movie null для анимации movie', () {
          final CollectionItem item = CollectionItem(
            id: 6,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 550,
            platformId: AnimationSource.movie,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.itemName, 'Unknown Animation');
        });

        test('должен вернуть "Unknown Animation" когда tvShow null для анимации tvShow', () {
          final CollectionItem item = CollectionItem(
            id: 7,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 1399,
            platformId: AnimationSource.tvShow,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.itemName, 'Unknown Animation');
        });
      });

      group('platformName', () {
        test('должен вернуть displayName платформы когда platform присутствует', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            platformId: 48,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            platform: testPlatform,
          );

          expect(item.platformName, 'PS4');
        });

        test('должен вернуть "Unknown Platform" когда platform null', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.platformName, 'Unknown Platform');
        });
      });

      group('coverUrl', () {
        test('должен вернуть coverUrl игры', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            game: testGame,
          );

          expect(item.coverUrl, 'https://example.com/witcher3.jpg');
        });

        test('должен вернуть posterUrl фильма', () {
          final CollectionItem item = CollectionItem(
            id: 2,
            collectionId: 10,
            mediaType: MediaType.movie,
            externalId: 550,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            movie: testMovie,
          );

          expect(item.coverUrl, 'https://example.com/fightclub.jpg');
        });

        test('должен вернуть posterUrl сериала', () {
          final CollectionItem item = CollectionItem(
            id: 3,
            collectionId: 10,
            mediaType: MediaType.tvShow,
            externalId: 1399,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            tvShow: testTvShow,
          );

          expect(item.coverUrl, 'https://example.com/breakingbad.jpg');
        });

        test('должен вернуть null когда joined объект отсутствует', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.coverUrl, isNull);
        });

        test('должен вернуть posterUrl фильма для анимации с источником movie', () {
          final CollectionItem item = CollectionItem(
            id: 4,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 550,
            platformId: AnimationSource.movie,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            movie: testMovie,
          );

          expect(item.coverUrl, 'https://example.com/fightclub.jpg');
        });

        test('должен вернуть posterUrl сериала для анимации с источником tvShow', () {
          final CollectionItem item = CollectionItem(
            id: 5,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 1399,
            platformId: AnimationSource.tvShow,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            tvShow: testTvShow,
          );

          expect(item.coverUrl, 'https://example.com/breakingbad.jpg');
        });
      });

      group('thumbnailUrl', () {
        test('должен вернуть posterThumbUrl фильма для анимации с источником movie', () {
          final CollectionItem item = CollectionItem(
            id: 4,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 550,
            platformId: AnimationSource.movie,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            movie: testMovie,
          );

          expect(item.thumbnailUrl, testMovie.posterThumbUrl);
        });

        test('должен вернуть posterThumbUrl сериала для анимации с источником tvShow', () {
          final CollectionItem item = CollectionItem(
            id: 5,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 1399,
            platformId: AnimationSource.tvShow,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
            tvShow: testTvShow,
          );

          expect(item.thumbnailUrl, testTvShow.posterThumbUrl);
        });

        test('должен вернуть null когда movie null для анимации movie', () {
          final CollectionItem item = CollectionItem(
            id: 6,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 550,
            platformId: AnimationSource.movie,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.thumbnailUrl, isNull);
        });

        test('должен вернуть null когда tvShow null для анимации tvShow', () {
          final CollectionItem item = CollectionItem(
            id: 7,
            collectionId: 10,
            mediaType: MediaType.animation,
            externalId: 1399,
            platformId: AnimationSource.tvShow,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.thumbnailUrl, isNull);
        });
      });

      group('hasAuthorComment', () {
        test('должен вернуть true когда authorComment не пустой', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            authorComment: 'Отличная игра',
            addedAt: testAddedAt,
          );

          expect(item.hasAuthorComment, isTrue);
        });

        test('должен вернуть false когда authorComment null', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.hasAuthorComment, isFalse);
        });

        test('должен вернуть false когда authorComment пустая строка', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            authorComment: '',
            addedAt: testAddedAt,
          );

          expect(item.hasAuthorComment, isFalse);
        });
      });

      group('hasUserComment', () {
        test('должен вернуть true когда userComment не пустой', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            userComment: 'Моё мнение',
            addedAt: testAddedAt,
          );

          expect(item.hasUserComment, isTrue);
        });

        test('должен вернуть false когда userComment null', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            addedAt: testAddedAt,
          );

          expect(item.hasUserComment, isFalse);
        });

        test('должен вернуть false когда userComment пустая строка', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.notStarted,
            userComment: '',
            addedAt: testAddedAt,
          );

          expect(item.hasUserComment, isFalse);
        });
      });

      group('isCompleted', () {
        test('должен вернуть true когда статус completed', () {
          final CollectionItem item = CollectionItem(
            id: 1,
            collectionId: 10,
            mediaType: MediaType.game,
            externalId: 1942,
            status: ItemStatus.completed,
            addedAt: testAddedAt,
          );

          expect(item.isCompleted, isTrue);
        });

        test('должен вернуть false когда статус не completed', () {
          for (final ItemStatus status in ItemStatus.values) {
            if (status == ItemStatus.completed) continue;

            final CollectionItem item = CollectionItem(
              id: 1,
              collectionId: 10,
              mediaType: MediaType.game,
              externalId: 1942,
              status: status,
              addedAt: testAddedAt,
            );

            expect(
              item.isCompleted,
              isFalse,
              reason: '${status.name} не должен быть isCompleted',
            );
          }
        });
      });
    });

    group('toDb/fromDb round-trip', () {
      test('должен сохранить данные game элемента при round-trip', () {
        final CollectionItem original = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 1942,
          platformId: 48,
          currentSeason: 0,
          currentEpisode: 0,
          status: ItemStatus.completed,
          authorComment: 'Шедевр RPG',
          userComment: 'Прошёл на 100%',
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> db = original.toDb();
        final CollectionItem restored = CollectionItem.fromDb(db);

        expect(restored.id, original.id);
        expect(restored.collectionId, original.collectionId);
        expect(restored.mediaType, original.mediaType);
        expect(restored.externalId, original.externalId);
        expect(restored.platformId, original.platformId);
        expect(restored.currentSeason, original.currentSeason);
        expect(restored.currentEpisode, original.currentEpisode);
        expect(restored.status, original.status);
        expect(restored.authorComment, original.authorComment);
        expect(restored.userComment, original.userComment);
      });

      test('должен сохранить данные movie элемента при round-trip', () {
        final CollectionItem original = CollectionItem(
          id: 2,
          collectionId: 10,
          mediaType: MediaType.movie,
          externalId: 550,
          status: ItemStatus.inProgress,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> db = original.toDb();
        final CollectionItem restored = CollectionItem.fromDb(db);

        expect(restored.id, original.id);
        expect(restored.mediaType, original.mediaType);
        expect(restored.externalId, original.externalId);
        expect(restored.status, original.status);
      });

      test('должен сохранить данные tvShow элемента при round-trip', () {
        final CollectionItem original = CollectionItem(
          id: 3,
          collectionId: 10,
          mediaType: MediaType.tvShow,
          externalId: 1399,
          currentSeason: 5,
          currentEpisode: 16,
          status: ItemStatus.onHold,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> db = original.toDb();
        final CollectionItem restored = CollectionItem.fromDb(db);

        expect(restored.id, original.id);
        expect(restored.mediaType, original.mediaType);
        expect(restored.externalId, original.externalId);
        expect(restored.currentSeason, original.currentSeason);
        expect(restored.currentEpisode, original.currentEpisode);
        expect(restored.status, original.status);
      });

      test('должен корректно обработать game inProgress при round-trip', () {
        final CollectionItem original = CollectionItem(
          id: 4,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          status: ItemStatus.inProgress,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> db = original.toDb();
        expect(db['status'], 'in_progress');

        final CollectionItem restored = CollectionItem.fromDb(db);
        expect(restored.status, ItemStatus.inProgress);
      });
    });

    group('sortOrder', () {
      test('должен иметь sortOrder по умолчанию 0', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        expect(item.sortOrder, 0);
      });

      test('должен создаваться с кастомным sortOrder', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          sortOrder: 5,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        expect(item.sortOrder, 5);
      });

      test('fromDb должен читать sort_order', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'media_type': 'game',
          'external_id': 100,
          'platform_id': null,
          'current_season': null,
          'current_episode': null,
          'sort_order': 3,
          'status': 'not_started',
          'author_comment': null,
          'user_comment': null,
          'added_at': testAddedAtUnix,
        };

        final CollectionItem item = CollectionItem.fromDb(row);
        expect(item.sortOrder, 3);
      });

      test('fromDb должен использовать 0 при отсутствии sort_order', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'media_type': 'game',
          'external_id': 100,
          'platform_id': null,
          'current_season': null,
          'current_episode': null,
          'status': 'not_started',
          'author_comment': null,
          'user_comment': null,
          'added_at': testAddedAtUnix,
        };

        final CollectionItem item = CollectionItem.fromDb(row);
        expect(item.sortOrder, 0);
      });

      test('toDb должен включать sort_order', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          sortOrder: 7,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> db = item.toDb();
        expect(db['sort_order'], 7);
      });

      test('copyWith должен изменять sortOrder', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          sortOrder: 2,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        final CollectionItem copy = item.copyWith(sortOrder: 8);
        expect(copy.sortOrder, 8);
        expect(item.sortOrder, 2); // Оригинал не изменился
      });

      test('sort_order должен быть в internalDbFields', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        expect(item.internalDbFields, contains('sort_order'));
      });

      test('status, current_season, current_episode должны быть в internalDbFields', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          status: ItemStatus.notStarted,
          addedAt: testAddedAt,
        );

        expect(item.internalDbFields, contains('status'));
        expect(item.internalDbFields, contains('current_season'));
        expect(item.internalDbFields, contains('current_episode'));
      });

      test('toExport не должен содержать sort_order, status, current_season, current_episode', () {
        final CollectionItem item = CollectionItem(
          id: 1,
          collectionId: 10,
          mediaType: MediaType.game,
          externalId: 100,
          sortOrder: 5,
          currentSeason: 2,
          currentEpisode: 3,
          status: ItemStatus.inProgress,
          addedAt: testAddedAt,
        );

        final Map<String, dynamic> exported = item.toExport();
        expect(exported.containsKey('sort_order'), isFalse);
        expect(exported.containsKey('status'), isFalse);
        expect(exported.containsKey('current_season'), isFalse);
        expect(exported.containsKey('current_episode'), isFalse);
      });
    });
  });
}
