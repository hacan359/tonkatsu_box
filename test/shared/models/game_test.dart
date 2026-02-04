import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/game.dart';

void main() {
  group('Game', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1942,
          'name': 'The Witcher 3: Wild Hunt',
          'summary': 'An amazing RPG game',
          'rating': 92.5,
          'rating_count': 1500,
          'first_release_date': 1431993600, // 2015-05-19
          'cover': <String, dynamic>{
            'image_id': 'co1wyy',
          },
          'genres': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'RPG'},
            <String, dynamic>{'name': 'Adventure'},
          ],
          'platforms': <int>[6, 48, 49],
        };

        final Game game = Game.fromJson(json);

        expect(game.id, 1942);
        expect(game.name, 'The Witcher 3: Wild Hunt');
        expect(game.summary, 'An amazing RPG game');
        expect(game.rating, 92.5);
        expect(game.ratingCount, 1500);
        expect(game.coverUrl,
            'https://images.igdb.com/igdb/image/upload/t_cover_big/co1wyy.jpg');
        expect(game.genres, <String>['RPG', 'Adventure']);
        expect(game.platformIds, <int>[6, 48, 49]);
        expect(game.releaseDate, isNotNull);
        expect(game.releaseDate!.year, 2015);
        expect(game.cachedAt, isNotNull);
      });

      test('handles minimal JSON without optional fields', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 123,
          'name': 'Simple Game',
        };

        final Game game = Game.fromJson(json);

        expect(game.id, 123);
        expect(game.name, 'Simple Game');
        expect(game.summary, isNull);
        expect(game.coverUrl, isNull);
        expect(game.rating, isNull);
        expect(game.ratingCount, isNull);
        expect(game.genres, isNull);
        expect(game.platformIds, isNull);
        expect(game.releaseDate, isNull);
      });

      test('handles cover without image_id', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 123,
          'name': 'Test Game',
          'cover': <String, dynamic>{
            'id': 456,
          },
        };

        final Game game = Game.fromJson(json);

        expect(game.coverUrl, isNull);
      });
    });

    group('fromDb', () {
      test('parses database row correctly', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1942,
          'name': 'The Witcher 3',
          'summary': 'Great game',
          'cover_url': 'https://example.com/cover.jpg',
          'release_date': 1431993600,
          'rating': 92.5,
          'rating_count': 1500,
          'genres': 'RPG|Adventure',
          'platform_ids': '6,48,49',
          'cached_at': 1700000000,
        };

        final Game game = Game.fromDb(row);

        expect(game.id, 1942);
        expect(game.name, 'The Witcher 3');
        expect(game.summary, 'Great game');
        expect(game.coverUrl, 'https://example.com/cover.jpg');
        expect(game.rating, 92.5);
        expect(game.ratingCount, 1500);
        expect(game.genres, <String>['RPG', 'Adventure']);
        expect(game.platformIds, <int>[6, 48, 49]);
        expect(game.cachedAt, 1700000000);
      });

      test('handles null and empty values', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 123,
          'name': 'Simple Game',
          'summary': null,
          'cover_url': null,
          'release_date': null,
          'rating': null,
          'rating_count': null,
          'genres': '',
          'platform_ids': '',
          'cached_at': null,
        };

        final Game game = Game.fromDb(row);

        expect(game.id, 123);
        expect(game.name, 'Simple Game');
        expect(game.genres, isNull);
        expect(game.platformIds, isNull);
      });
    });

    group('toDb', () {
      test('converts to database map correctly', () {
        final Game game = Game(
          id: 1942,
          name: 'The Witcher 3',
          summary: 'Great game',
          coverUrl: 'https://example.com/cover.jpg',
          releaseDate: DateTime(2015, 5, 19),
          rating: 92.5,
          ratingCount: 1500,
          genres: <String>['RPG', 'Adventure'],
          platformIds: <int>[6, 48, 49],
          cachedAt: 1700000000,
        );

        final Map<String, dynamic> db = game.toDb();

        expect(db['id'], 1942);
        expect(db['name'], 'The Witcher 3');
        expect(db['summary'], 'Great game');
        expect(db['cover_url'], 'https://example.com/cover.jpg');
        expect(db['rating'], 92.5);
        expect(db['rating_count'], 1500);
        expect(db['genres'], 'RPG|Adventure');
        expect(db['platform_ids'], '6,48,49');
        expect(db['cached_at'], 1700000000);
      });

      test('handles null values', () {
        const Game game = Game(
          id: 123,
          name: 'Simple Game',
        );

        final Map<String, dynamic> db = game.toDb();

        expect(db['id'], 123);
        expect(db['name'], 'Simple Game');
        expect(db['summary'], isNull);
        expect(db['genres'], isNull);
        expect(db['platform_ids'], isNull);
      });
    });

    group('toJson', () {
      test('converts to JSON correctly', () {
        final Game game = Game(
          id: 1942,
          name: 'The Witcher 3',
          summary: 'Great game',
          coverUrl: 'https://example.com/cover.jpg',
          releaseDate: DateTime(2015, 5, 19),
          rating: 92.5,
          ratingCount: 1500,
          genres: <String>['RPG', 'Adventure'],
          platformIds: <int>[6, 48, 49],
        );

        final Map<String, dynamic> json = game.toJson();

        expect(json['id'], 1942);
        expect(json['name'], 'The Witcher 3');
        expect(json['genres'], <String>['RPG', 'Adventure']);
        expect(json['platform_ids'], <int>[6, 48, 49]);
      });
    });

    group('computed properties', () {
      test('releaseYear returns correct year', () {
        final Game game = Game(
          id: 1,
          name: 'Test',
          releaseDate: DateTime(2015, 5, 19),
        );

        expect(game.releaseYear, 2015);
      });

      test('releaseYear returns null when releaseDate is null', () {
        const Game game = Game(id: 1, name: 'Test');

        expect(game.releaseYear, isNull);
      });

      test('formattedRating returns scaled rating', () {
        const Game game = Game(id: 1, name: 'Test', rating: 85.0);

        expect(game.formattedRating, '8.5');
      });

      test('formattedRating returns null when rating is null', () {
        const Game game = Game(id: 1, name: 'Test');

        expect(game.formattedRating, isNull);
      });

      test('genresString joins genres with comma', () {
        const Game game = Game(
          id: 1,
          name: 'Test',
          genres: <String>['RPG', 'Adventure', 'Action'],
        );

        expect(game.genresString, 'RPG, Adventure, Action');
      });

      test('genresString returns null when genres is null', () {
        const Game game = Game(id: 1, name: 'Test');

        expect(game.genresString, isNull);
      });
    });

    group('equality', () {
      test('games with same id are equal', () {
        const Game game1 = Game(id: 1, name: 'Game 1');
        const Game game2 = Game(id: 1, name: 'Game 2');

        expect(game1, equals(game2));
        expect(game1.hashCode, equals(game2.hashCode));
      });

      test('games with different ids are not equal', () {
        const Game game1 = Game(id: 1, name: 'Test');
        const Game game2 = Game(id: 2, name: 'Test');

        expect(game1, isNot(equals(game2)));
      });
    });

    group('copyWith', () {
      test('creates copy with changed fields', () {
        const Game original = Game(
          id: 1,
          name: 'Original',
          rating: 80.0,
        );

        final Game copy = original.copyWith(
          name: 'Updated',
          rating: 90.0,
        );

        expect(copy.id, 1);
        expect(copy.name, 'Updated');
        expect(copy.rating, 90.0);
      });

      test('preserves unchanged fields', () {
        const Game original = Game(
          id: 1,
          name: 'Original',
          summary: 'Summary',
          rating: 80.0,
        );

        final Game copy = original.copyWith(name: 'Updated');

        expect(copy.summary, 'Summary');
        expect(copy.rating, 80.0);
      });
    });

    test('toString returns readable representation', () {
      const Game game = Game(id: 1942, name: 'The Witcher 3');

      expect(game.toString(), 'Game(id: 1942, name: The Witcher 3)');
    });
  });
}
