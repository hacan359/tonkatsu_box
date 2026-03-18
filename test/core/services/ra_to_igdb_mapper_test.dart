// Тесты для RaToIgdbMapper.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/services/ra_to_igdb_mapper.dart';
import 'package:xerabora/shared/models/game.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late RaToIgdbMapper sut;
  late MockIgdbApi mockIgdbApi;

  setUp(() {
    mockIgdbApi = MockIgdbApi();
    sut = RaToIgdbMapper(mockIgdbApi);
  });

  group('RaToIgdbMapper', () {
    group('consolePlatformMap', () {
      test('should contain known RA console mappings', () {
        // SNES
        expect(RaToIgdbMapper.consolePlatformMap[3], equals(19));
        // NES
        expect(RaToIgdbMapper.consolePlatformMap[7], equals(18));
        // Genesis/Mega Drive
        expect(RaToIgdbMapper.consolePlatformMap[1], equals(29));
        // Nintendo 64
        expect(RaToIgdbMapper.consolePlatformMap[2], equals(4));
        // PlayStation
        expect(RaToIgdbMapper.consolePlatformMap[12], equals(7));
        // Game Boy
        expect(RaToIgdbMapper.consolePlatformMap[4], equals(33));
        // GBA
        expect(RaToIgdbMapper.consolePlatformMap[5], equals(24));
      });

      test('should return null for unknown console ID', () {
        expect(RaToIgdbMapper.consolePlatformMap[999], isNull);
      });
    });

    group('findIgdbGame', () {
      test('should return exact match from platform search', () async {
        final Game expectedGame = createTestGame(
          id: 100,
          name: 'Super Mario World',
        );

        when(() => mockIgdbApi.searchGames(
              query: 'Super Mario World',
              platformIds: <int>[19],
            )).thenAnswer((_) async => <Game>[expectedGame]);

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'Super Mario World',
            consoleId: 3, // SNES -> 19
          ),
        );

        expect(result, isNotNull);
        expect(result!.id, equals(100));
        expect(result.name, equals('Super Mario World'));
      });

      test('should fallback to search without platform when no results',
          () async {
        final Game expectedGame = createTestGame(
          id: 200,
          name: 'Chrono Trigger',
        );

        when(() => mockIgdbApi.searchGames(
              query: 'Chrono Trigger',
              platformIds: <int>[19],
            )).thenAnswer((_) async => <Game>[]);

        when(() => mockIgdbApi.searchGames(
              query: 'Chrono Trigger',
            )).thenAnswer((_) async => <Game>[expectedGame]);

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'Chrono Trigger',
            consoleId: 3,
          ),
        );

        expect(result, isNotNull);
        expect(result!.id, equals(200));
      });

      test('should return null when no results from both searches', () async {
        when(() => mockIgdbApi.searchGames(
              query: 'Unknown Game',
              platformIds: <int>[19],
            )).thenAnswer((_) async => <Game>[]);

        when(() => mockIgdbApi.searchGames(
              query: 'Unknown Game',
            )).thenAnswer((_) async => <Game>[]);

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'Unknown Game',
            consoleId: 3,
          ),
        );

        expect(result, isNull);
      });

      test('should return null when unknown platform and no results', () async {
        when(() => mockIgdbApi.searchGames(
              query: 'Some Game',
              platformIds: null,
            )).thenAnswer((_) async => <Game>[]);

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'Some Game',
            consoleId: 999, // Unknown console
          ),
        );

        expect(result, isNull);
      });

      test('should search without platform filter for unknown consoleId',
          () async {
        final Game expectedGame = createTestGame(name: 'Test Game');

        when(() => mockIgdbApi.searchGames(
              query: 'Test Game',
              platformIds: null,
            )).thenAnswer((_) async => <Game>[expectedGame]);

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'Test Game',
            consoleId: 999,
          ),
        );

        expect(result, isNotNull);
      });

      test('should prefer exact name match', () async {
        final Game exactMatch = createTestGame(
          id: 1,
          name: 'Super Mario World',
        );
        final Game partialMatch = createTestGame(
          id: 2,
          name: 'Super Mario World 2: Yoshi\'s Island',
        );

        when(() => mockIgdbApi.searchGames(
              query: 'Super Mario World',
              platformIds: <int>[19],
            )).thenAnswer(
          (_) async => <Game>[partialMatch, exactMatch],
        );

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'Super Mario World',
            consoleId: 3,
          ),
        );

        expect(result, isNotNull);
        expect(result!.id, equals(1));
      });

      test('should match by startsWith when no exact match', () async {
        final Game game1 = createTestGame(
          id: 1,
          name: 'Zelda: A Link to the Past',
        );
        final Game game2 = createTestGame(
          id: 2,
          name: 'The Legend of Zelda: A Link to the Past',
        );

        when(() => mockIgdbApi.searchGames(
              query: 'The Legend of Zelda: A Link to the Past',
              platformIds: <int>[19],
            )).thenAnswer(
          (_) async => <Game>[game1, game2],
        );

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'The Legend of Zelda: A Link to the Past',
            consoleId: 3,
          ),
        );

        // Exact match on normalized name.
        expect(result, isNotNull);
        expect(result!.id, equals(2));
      });

      test('should return first result as fallback when no name match',
          () async {
        final Game game1 = createTestGame(
          id: 1,
          name: 'Completely Different Name',
        );
        final Game game2 = createTestGame(
          id: 2,
          name: 'Another Different Name',
        );

        when(() => mockIgdbApi.searchGames(
              query: 'Original Title',
              platformIds: <int>[19],
            )).thenAnswer(
          (_) async => <Game>[game1, game2],
        );

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'Original Title',
            consoleId: 3,
          ),
        );

        expect(result, isNotNull);
        expect(result!.id, equals(1));
      });

      test('should normalize names ignoring special characters', () async {
        final Game game = createTestGame(
          id: 1,
          name: 'Super Mario World!',
        );

        when(() => mockIgdbApi.searchGames(
              query: 'Super Mario World',
              platformIds: <int>[19],
            )).thenAnswer((_) async => <Game>[game]);

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'Super Mario World',
            consoleId: 3,
          ),
        );

        // "supermarioworld!" normalized → "supermarioworld" matches "supermarioworld"
        expect(result, isNotNull);
        expect(result!.id, equals(1));
      });

      test(
          'should not do fallback search when platform unknown and no results',
          () async {
        when(() => mockIgdbApi.searchGames(
              query: 'Test',
              platformIds: null,
            )).thenAnswer((_) async => <Game>[]);

        final Game? result = await sut.findIgdbGame(
          createTestRaGameProgress(
            title: 'Test',
            consoleId: 999, // Unknown → igdbPlatformId = null
          ),
        );

        expect(result, isNull);
        // Verify only one search call (no fallback since platformId was null).
        verify(() => mockIgdbApi.searchGames(
              query: 'Test',
              platformIds: null,
            )).called(1);
      });
    });
  });
}
