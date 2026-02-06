import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/steamgriddb_game.dart';

void main() {
  group('SteamGridDbGame', () {
    group('fromJson', () {
      test('парсит полный JSON корректно', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 2590,
          'name': 'The Witcher 3: Wild Hunt',
          'types': <String>['steam', 'gog'],
          'verified': true,
        };

        final SteamGridDbGame game = SteamGridDbGame.fromJson(json);

        expect(game.id, 2590);
        expect(game.name, 'The Witcher 3: Wild Hunt');
        expect(game.types, <String>['steam', 'gog']);
        expect(game.verified, true);
      });

      test('парсит минимальный JSON без опциональных полей', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 123,
          'name': 'Simple Game',
        };

        final SteamGridDbGame game = SteamGridDbGame.fromJson(json);

        expect(game.id, 123);
        expect(game.name, 'Simple Game');
        expect(game.types, isNull);
        expect(game.verified, false);
      });

      test('обрабатывает null types', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 456,
          'name': 'Test Game',
          'types': null,
          'verified': false,
        };

        final SteamGridDbGame game = SteamGridDbGame.fromJson(json);

        expect(game.types, isNull);
      });

      test('обрабатывает пустой массив types', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 789,
          'name': 'No Types',
          'types': <String>[],
        };

        final SteamGridDbGame game = SteamGridDbGame.fromJson(json);

        expect(game.types, isEmpty);
      });

      test('обрабатывает отсутствующий verified как false', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 100,
          'name': 'Unverified',
        };

        final SteamGridDbGame game = SteamGridDbGame.fromJson(json);

        expect(game.verified, false);
      });
    });

    group('copyWith', () {
      test('создаёт копию с изменёнными полями', () {
        const SteamGridDbGame original = SteamGridDbGame(
          id: 1,
          name: 'Original',
          verified: false,
        );

        final SteamGridDbGame copy = original.copyWith(
          name: 'Updated',
          verified: true,
        );

        expect(copy.id, 1);
        expect(copy.name, 'Updated');
        expect(copy.verified, true);
      });

      test('сохраняет неизменённые поля', () {
        const SteamGridDbGame original = SteamGridDbGame(
          id: 1,
          name: 'Original',
          types: <String>['steam'],
          verified: true,
        );

        final SteamGridDbGame copy = original.copyWith(name: 'New Name');

        expect(copy.id, 1);
        expect(copy.types, <String>['steam']);
        expect(copy.verified, true);
      });
    });

    group('equality', () {
      test('игры с одинаковым id равны', () {
        const SteamGridDbGame game1 = SteamGridDbGame(id: 1, name: 'Game 1');
        const SteamGridDbGame game2 = SteamGridDbGame(id: 1, name: 'Game 2');

        expect(game1, equals(game2));
        expect(game1.hashCode, equals(game2.hashCode));
      });

      test('игры с разными id не равны', () {
        const SteamGridDbGame game1 = SteamGridDbGame(id: 1, name: 'Game');
        const SteamGridDbGame game2 = SteamGridDbGame(id: 2, name: 'Game');

        expect(game1, isNot(equals(game2)));
      });
    });

    group('toString', () {
      test('возвращает читаемое представление', () {
        const SteamGridDbGame game = SteamGridDbGame(
          id: 42,
          name: 'Test Game',
        );

        expect(game.toString(), 'SteamGridDbGame(id: 42, name: Test Game)');
      });
    });
  });
}
