// Тесты для SteamImportService.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/core/api/steam_api.dart';
import 'package:xerabora/core/services/steam_import_service.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late SteamImportService sut;
  late MockSteamApi mockSteamApi;
  late MockIgdbApi mockIgdbApi;
  late MockDatabaseService mockDb;

  setUp(() {
    mockSteamApi = MockSteamApi();
    mockIgdbApi = MockIgdbApi();
    mockDb = MockDatabaseService();

    sut = SteamImportService(
      steamApi: mockSteamApi,
      igdbApi: mockIgdbApi,
      database: mockDb,
    );
  });

  /// Подготавливает стандартные mock-ответы для успешного импорта.
  void setupStandardMocks({
    List<SteamOwnedGame>? library,
    int collectionId = 1,
  }) {
    final List<SteamOwnedGame> games = library ??
        <SteamOwnedGame>[
          createTestSteamOwnedGame(
            appId: 440,
            name: 'Team Fortress 2',
            playtimeMinutes: 1250,
            lastPlayed: DateTime(2024, 1, 28),
          ),
          createTestSteamOwnedGame(
            appId: 570,
            name: 'Dota 2',
            playtimeMinutes: 0,
          ),
        ];

    when(() => mockSteamApi.getOwnedGames(
          apiKey: any(named: 'apiKey'),
          steamId: any(named: 'steamId'),
        )).thenAnswer((_) async => games);

    when(() => mockDb.createCollection(
          name: any(named: 'name'),
          author: any(named: 'author'),
        )).thenAnswer((_) async => createTestCollection(id: collectionId));

    when(() => mockIgdbApi.searchGames(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
        )).thenAnswer((Invocation inv) async {
      final String query = inv.namedArguments[#query] as String;
      return <Game>[
        Game(id: query.hashCode.abs(), name: query),
      ];
    });

    when(() => mockDb.findCollectionItem(
          collectionId: any(named: 'collectionId'),
          mediaType: any(named: 'mediaType'),
          externalId: any(named: 'externalId'),
        )).thenAnswer((_) async => null);

    when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});

    when(() => mockDb.addItemToCollection(
          collectionId: any(named: 'collectionId'),
          mediaType: any(named: 'mediaType'),
          externalId: any(named: 'externalId'),
          platformId: any(named: 'platformId'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => 100);

    when(() => mockDb.updateItemUserComment(any(), any()))
        .thenAnswer((_) async {});

    when(() => mockDb.updateItemActivityDates(
          any(),
          startedAt: any(named: 'startedAt'),
        )).thenAnswer((_) async {});

    when(() => mockDb.addWishlistItem(
          text: any(named: 'text'),
          mediaTypeHint: any(named: 'mediaTypeHint'),
          note: any(named: 'note'),
        )).thenAnswer((_) async => createTestWishlistItem());
  }

  group('SteamImportService', () {
    group('importLibrary', () {
      test('creates "Steam Library" collection', () async {
        setupStandardMocks();

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Test Author',
          onProgress: (_) {},
        );

        verify(() => mockDb.createCollection(
              name: 'Steam Library',
              author: 'Test Author',
            )).called(1);
      });

      test('imports found games into collection', () async {
        setupStandardMocks();

        final SteamImportResult result = await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        expect(result.imported, 2);
        expect(result.wishlisted, 0);
        expect(result.skipped, 0);
        expect(result.total, 2);
        expect(result.collectionId, 1);
      });

      test('sets inProgress for played games', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(
              name: 'Played Game',
              playtimeMinutes: 120,
            ),
          ],
        );

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        verify(() => mockDb.addItemToCollection(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: any(named: 'externalId'),
              platformId: 6,
              status: ItemStatus.inProgress,
            )).called(1);
      });

      test('sets notStarted for unplayed games', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(
              name: 'Unplayed Game',
              playtimeMinutes: 0,
            ),
          ],
        );

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        verify(() => mockDb.addItemToCollection(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: any(named: 'externalId'),
              platformId: 6,
              status: ItemStatus.notStarted,
            )).called(1);
      });

      test('saves playtime as user comment', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(
              name: 'Game',
              playtimeMinutes: 125,
            ),
          ],
        );

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        verify(() => mockDb.updateItemUserComment(100, 'Steam: 2.1h'))
            .called(1);
      });

      test('saves lastPlayed as startedAt', () async {
        final DateTime lastPlayed = DateTime(2024, 1, 28);
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(
              name: 'Game',
              playtimeMinutes: 60,
              lastPlayed: lastPlayed,
            ),
          ],
        );

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        verify(() => mockDb.updateItemActivityDates(
              100,
              startedAt: lastPlayed,
            )).called(1);
      });

      test('does not update comment for zero playtime', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(
              name: 'Game',
              playtimeMinutes: 0,
            ),
          ],
        );

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        verifyNever(() => mockDb.updateItemUserComment(any(), any()));
      });

      test('filters DLC and soundtracks', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(name: 'Real Game'),
            createTestSteamOwnedGame(name: 'Game Soundtrack'),
            createTestSteamOwnedGame(name: 'Game Demo'),
          ],
        );

        final SteamImportResult result = await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        // Only "Real Game" passes filter
        expect(result.total, 1);
        expect(result.imported, 1);
      });

      test('skips duplicates already in collection', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(name: 'Already Added'),
          ],
        );

        // Override findCollectionItem to return existing item
        when(() => mockDb.findCollectionItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
            )).thenAnswer((_) async => createTestCollectionItem());

        final SteamImportResult result = await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        expect(result.skipped, 1);
        expect(result.imported, 0);
        verifyNever(() => mockDb.addItemToCollection(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              status: any(named: 'status'),
            ));
      });

      test('adds to wishlist when IGDB returns empty', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(name: 'Unknown Game'),
          ],
        );

        // Override IGDB to return empty
        when(() => mockIgdbApi.searchGames(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => <Game>[]);

        final SteamImportResult result = await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        expect(result.wishlisted, 1);
        expect(result.imported, 0);
        verify(() => mockDb.addWishlistItem(
              text: 'Unknown Game',
              mediaTypeHint: MediaType.game,
              note: any(named: 'note'),
            )).called(1);
      });

      test('adds to wishlist on IGDB API error', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(name: 'Error Game'),
          ],
        );

        when(() => mockIgdbApi.searchGames(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
            )).thenThrow(const IgdbApiException('Rate limited'));

        final SteamImportResult result = await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        expect(result.wishlisted, 1);
        expect(result.imported, 0);
      });

      test('throws on empty library', () async {
        when(() => mockSteamApi.getOwnedGames(
              apiKey: any(named: 'apiKey'),
              steamId: any(named: 'steamId'),
            )).thenAnswer((_) async => <SteamOwnedGame>[]);

        expect(
          () => sut.importLibrary(
            apiKey: 'key',
            steamId: '123',
            authorName: 'Author',
            onProgress: (_) {},
          ),
          throwsA(isA<SteamApiException>()),
        );
      });

      test('calls onProgress callback', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(name: 'Game 1'),
          ],
        );

        final List<SteamImportProgress> progressUpdates =
            <SteamImportProgress>[];

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: progressUpdates.add,
        );

        expect(progressUpdates.length, greaterThanOrEqualTo(3));
        expect(
          progressUpdates.first.stage,
          SteamImportStage.fetchingLibrary,
        );
        expect(
          progressUpdates[1].stage,
          SteamImportStage.matchingGames,
        );
        expect(
          progressUpdates.last.stage,
          SteamImportStage.completed,
        );
      });

      test('prefers exact match over first result', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(name: 'Portal'),
          ],
        );

        // Override IGDB to return multiple results where exact match is second
        when(() => mockIgdbApi.searchGames(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => const <Game>[
              Game(id: 1, name: 'Portal 2'),
              Game(id: 2, name: 'Portal'),
            ]);

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          authorName: 'Author',
          onProgress: (_) {},
        );

        // Should pick id: 2 (exact match "Portal")
        verify(() => mockDb.upsertGame(
              any(that: predicate<Game>((Game g) => g.id == 2)),
            )).called(1);
      });
    });
  });

  group('SteamImportProgress', () {
    test('progress returns 0 when total is 0', () {
      const SteamImportProgress progress = SteamImportProgress(
        stage: SteamImportStage.fetchingLibrary,
        current: 0,
        total: 0,
      );

      expect(progress.progress, 0.0);
    });

    test('progress returns fraction when total > 0', () {
      const SteamImportProgress progress = SteamImportProgress(
        stage: SteamImportStage.matchingGames,
        current: 50,
        total: 200,
      );

      expect(progress.progress, 0.25);
    });
  });

  group('SteamImportResult', () {
    test('stores all fields', () {
      const SteamImportResult result = SteamImportResult(
        imported: 10,
        wishlisted: 5,
        skipped: 2,
        total: 17,
        collectionId: 42,
      );

      expect(result.imported, 10);
      expect(result.wishlisted, 5);
      expect(result.skipped, 2);
      expect(result.total, 17);
      expect(result.collectionId, 42);
    });
  });
}
