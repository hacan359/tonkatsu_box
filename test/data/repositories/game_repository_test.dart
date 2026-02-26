import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/game_repository.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/platform.dart';

class MockIgdbApi extends Mock implements IgdbApi {}

class MockDatabaseService extends Mock implements DatabaseService {}

class FakeGame extends Fake implements Game {}

void main() {
  late MockIgdbApi mockApi;
  late MockDatabaseService mockDb;
  late GameRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeGame());
    registerFallbackValue(<Game>[]);
    registerFallbackValue(<int>[]);
    registerFallbackValue(<Platform>[]);
  });

  setUp(() {
    mockApi = MockIgdbApi();
    mockDb = MockDatabaseService();
    repository = GameRepository(api: mockApi, db: mockDb);
  });

  group('GameRepository', () {
    group('searchGames', () {
      test('searches via API and caches results', () async {
        final List<Game> apiResults = <Game>[
          const Game(id: 1, name: 'Game 1'),
          const Game(id: 2, name: 'Game 2'),
        ];

        when(() => mockApi.searchGames(
              query: any(named: 'query'),
              platformIds: any(named: 'platformIds'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => apiResults);

        when(() => mockDb.upsertGames(any())).thenAnswer((_) async {});
        when(() => mockDb.getPlatformsByIds(any()))
            .thenAnswer((_) async => <Platform>[]);

        final List<Game> result = await repository.searchGames(query: 'test');

        expect(result, equals(apiResults));
        verify(() => mockDb.upsertGames(apiResults)).called(1);
      });

      test('does not cache empty results', () async {
        when(() => mockApi.searchGames(
              query: any(named: 'query'),
              platformIds: any(named: 'platformIds'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => <Game>[]);

        final List<Game> result = await repository.searchGames(query: 'xyz');

        expect(result, isEmpty);
        verifyNever(() => mockDb.upsertGames(any()));
      });

      test('passes platformIds to API', () async {
        when(() => mockApi.searchGames(
              query: any(named: 'query'),
              platformIds: any(named: 'platformIds'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => <Game>[]);

        await repository.searchGames(
          query: 'zelda',
          platformIds: <int>[130, 48],
        );

        verify(() => mockApi.searchGames(
              query: 'zelda',
              platformIds: <int>[130, 48],
              limit: 50,
            )).called(1);
      });

      test('passes limit to API', () async {
        when(() => mockApi.searchGames(
              query: any(named: 'query'),
              platformIds: any(named: 'platformIds'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => <Game>[]);

        await repository.searchGames(query: 'test', limit: 50);

        verify(() => mockApi.searchGames(
              query: 'test',
              platformIds: null,
              limit: 50,
            )).called(1);
      });
    });

    group('getGameById', () {
      test('returns cached game if valid', () async {
        final int validCachedAt =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600; // 1 hour ago
        final Game cachedGame = Game(
          id: 1942,
          name: 'Cached Game',
          cachedAt: validCachedAt,
        );

        when(() => mockDb.getGameById(1942))
            .thenAnswer((_) async => cachedGame);

        final Game? result = await repository.getGameById(1942);

        expect(result, equals(cachedGame));
        verifyNever(() => mockApi.getGameById(any()));
      });

      test('fetches from API if cache is stale', () async {
        final int staleCachedAt =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 -
                (86400 * 8); // 8 days ago
        final Game staleGame = Game(
          id: 1942,
          name: 'Stale Game',
          cachedAt: staleCachedAt,
        );
        const Game freshGame = Game(id: 1942, name: 'Fresh Game');

        when(() => mockDb.getGameById(1942)).thenAnswer((_) async => staleGame);
        when(() => mockApi.getGameById(1942))
            .thenAnswer((_) async => freshGame);
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});

        final Game? result = await repository.getGameById(1942);

        expect(result?.name, 'Fresh Game');
        verify(() => mockApi.getGameById(1942)).called(1);
        verify(() => mockDb.upsertGame(freshGame)).called(1);
      });

      test('fetches from API if not in cache', () async {
        const Game apiGame = Game(id: 1942, name: 'API Game');

        when(() => mockDb.getGameById(1942)).thenAnswer((_) async => null);
        when(() => mockApi.getGameById(1942)).thenAnswer((_) async => apiGame);
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});

        final Game? result = await repository.getGameById(1942);

        expect(result, equals(apiGame));
        verify(() => mockApi.getGameById(1942)).called(1);
        verify(() => mockDb.upsertGame(apiGame)).called(1);
      });

      test('forces refresh when forceRefresh is true', () async {
        final int validCachedAt =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;
        final Game cachedGame = Game(
          id: 1942,
          name: 'Cached Game',
          cachedAt: validCachedAt,
        );
        const Game freshGame = Game(id: 1942, name: 'Fresh Game');

        when(() => mockDb.getGameById(1942))
            .thenAnswer((_) async => cachedGame);
        when(() => mockApi.getGameById(1942))
            .thenAnswer((_) async => freshGame);
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});

        final Game? result =
            await repository.getGameById(1942, forceRefresh: true);

        expect(result?.name, 'Fresh Game');
        verify(() => mockApi.getGameById(1942)).called(1);
      });

      test('returns null when game not found in API', () async {
        when(() => mockDb.getGameById(99999)).thenAnswer((_) async => null);
        when(() => mockApi.getGameById(99999)).thenAnswer((_) async => null);

        final Game? result = await repository.getGameById(99999);

        expect(result, isNull);
        verifyNever(() => mockDb.upsertGame(any()));
      });
    });

    group('getGamesByIds', () {
      test('returns cached games and fetches missing ones', () async {
        final int validCachedAt =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;

        final List<Game> cachedGames = <Game>[
          Game(id: 1, name: 'Cached 1', cachedAt: validCachedAt),
          Game(id: 2, name: 'Cached 2', cachedAt: validCachedAt),
        ];
        final List<Game> apiGames = <Game>[
          const Game(id: 3, name: 'API 3'),
        ];

        when(() => mockDb.getGamesByIds(any()))
            .thenAnswer((_) async => cachedGames);
        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => apiGames);
        when(() => mockDb.upsertGames(any())).thenAnswer((_) async {});

        final List<Game> result =
            await repository.getGamesByIds(<int>[1, 2, 3]);

        expect(result, hasLength(3));
        expect(result.map((Game g) => g.id), containsAll(<int>[1, 2, 3]));
        verify(() => mockApi.getGamesByIds(<int>[3])).called(1);
      });

      test('returns empty list for empty ids', () async {
        final List<Game> result = await repository.getGamesByIds(<int>[]);

        expect(result, isEmpty);
        verifyNever(() => mockDb.getGamesByIds(any()));
        verifyNever(() => mockApi.getGamesByIds(any()));
      });

      test('fetches all from API when forceRefresh is true', () async {
        final List<Game> apiGames = <Game>[
          const Game(id: 1, name: 'API 1'),
          const Game(id: 2, name: 'API 2'),
        ];

        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => apiGames);
        when(() => mockDb.upsertGames(any())).thenAnswer((_) async {});

        final List<Game> result =
            await repository.getGamesByIds(<int>[1, 2], forceRefresh: true);

        expect(result, hasLength(2));
        verify(() => mockApi.getGamesByIds(<int>[1, 2])).called(1);
        verifyNever(() => mockDb.getGamesByIds(any()));
      });
    });

    group('searchInCache', () {
      test('delegates to database service', () async {
        final List<Game> cachedGames = <Game>[
          const Game(id: 1, name: 'Game 1'),
        ];

        when(() => mockDb.searchGamesInCache(any(), limit: any(named: 'limit')))
            .thenAnswer((_) async => cachedGames);

        final List<Game> result = await repository.searchInCache('game');

        expect(result, equals(cachedGames));
        verify(() => mockDb.searchGamesInCache('game', limit: 20)).called(1);
      });
    });

    group('clearStaleCache', () {
      test('delegates to database service', () async {
        when(() => mockDb.clearStaleGames(maxAgeSeconds: any(named: 'maxAgeSeconds')))
            .thenAnswer((_) async => 5);

        final int deleted = await repository.clearStaleCache();

        expect(deleted, 5);
        verify(() => mockDb.clearStaleGames(
              maxAgeSeconds: GameRepository.cacheMaxAge,
            )).called(1);
      });
    });

    group('getCacheSize', () {
      test('returns game count from database', () async {
        when(() => mockDb.getGameCount()).thenAnswer((_) async => 150);

        final int size = await repository.getCacheSize();

        expect(size, 150);
        verify(() => mockDb.getGameCount()).called(1);
      });
    });

    group('ensurePlatformsCached', () {
      test('does nothing for games without platformIds', () async {
        const List<Game> games = <Game>[
          Game(id: 1, name: 'No Platforms'),
        ];

        await repository.ensurePlatformsCached(games);

        verifyNever(() => mockDb.getPlatformsByIds(any()));
        verifyNever(() => mockApi.fetchPlatformsByIds(any()));
      });

      test('does nothing for empty games list', () async {
        await repository.ensurePlatformsCached(<Game>[]);

        verifyNever(() => mockDb.getPlatformsByIds(any()));
      });

      test('skips fetch when all platforms already cached', () async {
        const List<Game> games = <Game>[
          Game(id: 1, name: 'Game 1', platformIds: <int>[6, 48]),
        ];

        when(() => mockDb.getPlatformsByIds(any()))
            .thenAnswer((_) async => const <Platform>[
                  Platform(id: 6, name: 'PC'),
                  Platform(id: 48, name: 'PS4'),
                ]);

        await repository.ensurePlatformsCached(games);

        verify(() => mockDb.getPlatformsByIds(any())).called(1);
        verifyNever(() => mockApi.fetchPlatformsByIds(any()));
      });

      test('fetches missing platforms from API', () async {
        const List<Game> games = <Game>[
          Game(id: 1, name: 'Game 1', platformIds: <int>[6, 48, 130]),
        ];

        when(() => mockDb.getPlatformsByIds(any()))
            .thenAnswer((_) async => const <Platform>[
                  Platform(id: 6, name: 'PC'),
                ]);
        when(() => mockApi.fetchPlatformsByIds(any()))
            .thenAnswer((_) async => const <Platform>[
                  Platform(id: 48, name: 'PS4'),
                  Platform(id: 130, name: 'Switch'),
                ]);
        when(() => mockDb.upsertPlatforms(any())).thenAnswer((_) async {});

        await repository.ensurePlatformsCached(games);

        verify(() => mockDb.getPlatformsByIds(any())).called(1);
        verify(() => mockApi.fetchPlatformsByIds(any())).called(1);
        verify(() => mockDb.upsertPlatforms(any())).called(1);
      });

      test('collects unique platformIds across multiple games', () async {
        const List<Game> games = <Game>[
          Game(id: 1, name: 'Game 1', platformIds: <int>[6, 48]),
          Game(id: 2, name: 'Game 2', platformIds: <int>[48, 130]),
        ];

        when(() => mockDb.getPlatformsByIds(any()))
            .thenAnswer((_) async => <Platform>[]);
        when(() => mockApi.fetchPlatformsByIds(any()))
            .thenAnswer((_) async => const <Platform>[
                  Platform(id: 6, name: 'PC'),
                  Platform(id: 48, name: 'PS4'),
                  Platform(id: 130, name: 'Switch'),
                ]);
        when(() => mockDb.upsertPlatforms(any())).thenAnswer((_) async {});

        await repository.ensurePlatformsCached(games);

        verify(() => mockDb.getPlatformsByIds(any())).called(1);
        verify(() => mockApi.fetchPlatformsByIds(any())).called(1);
      });

      test('silently handles API errors', () async {
        const List<Game> games = <Game>[
          Game(id: 1, name: 'Game 1', platformIds: <int>[6]),
        ];

        when(() => mockDb.getPlatformsByIds(any()))
            .thenAnswer((_) async => <Platform>[]);
        when(() => mockApi.fetchPlatformsByIds(any()))
            .thenThrow(Exception('Network error'));

        // Не должен выбрасывать исключение
        await repository.ensurePlatformsCached(games);

        verify(() => mockApi.fetchPlatformsByIds(any())).called(1);
        verifyNever(() => mockDb.upsertPlatforms(any()));
      });
    });

    group('searchGames calls ensurePlatformsCached', () {
      test('caches platforms after search with results', () async {
        const List<Game> apiResults = <Game>[
          Game(id: 1, name: 'Game 1', platformIds: <int>[6, 48]),
        ];

        when(() => mockApi.searchGames(
              query: any(named: 'query'),
              platformIds: any(named: 'platformIds'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => apiResults);
        when(() => mockDb.upsertGames(any())).thenAnswer((_) async {});
        when(() => mockDb.getPlatformsByIds(any()))
            .thenAnswer((_) async => const <Platform>[
                  Platform(id: 6, name: 'PC'),
                  Platform(id: 48, name: 'PS4'),
                ]);

        await repository.searchGames(query: 'test');

        verify(() => mockDb.getPlatformsByIds(any())).called(1);
      });
    });
  });
}
