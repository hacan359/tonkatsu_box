// Тесты для SteamImportService.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/core/api/steam_api.dart';
import 'package:xerabora/core/services/steam_import_service.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

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

    when(() => mockDb.findUnresolvedWishlistItem(any()))
        .thenAnswer((_) async => null);

    when(() => mockDb.updateWishlistItem(
          any(),
          note: any(named: 'note'),
        )).thenAnswer((_) async {});

    when(() => mockDb.updateItemStatus(
          any(),
          any(),
          mediaType: any(named: 'mediaType'),
        )).thenAnswer((_) async {});
  }

  group('SteamImportService', () {
    group('importLibrary', () {
      test('should import found games into collection', () async {
        setupStandardMocks();

        final SteamImportResult result = await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          collectionId: 1,
          onProgress: (_) {},
        );

        expect(result.imported, 2);
        expect(result.wishlisted, 0);
        expect(result.updated, 0);
        expect(result.total, 2);
        expect(result.collectionId, 1);
      });

      test('should set inProgress for played games', () async {
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
          collectionId: 1,
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

      test('should set notStarted for unplayed games', () async {
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
          collectionId: 1,
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

      test('should save playtime as user comment', () async {
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
          collectionId: 1,
          onProgress: (_) {},
        );

        verify(() => mockDb.updateItemUserComment(100, 'Steam: 2.1h'))
            .called(1);
      });

      test('should save lastPlayed as startedAt', () async {
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
          collectionId: 1,
          onProgress: (_) {},
        );

        verify(() => mockDb.updateItemActivityDates(
              100,
              startedAt: lastPlayed,
            )).called(1);
      });

      test('should not update comment for zero playtime', () async {
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
          collectionId: 1,
          onProgress: (_) {},
        );

        verifyNever(() => mockDb.updateItemUserComment(any(), any()));
      });

      test('should filter DLC and soundtracks', () async {
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
          collectionId: 1,
          onProgress: (_) {},
        );

        // Only "Real Game" passes filter
        expect(result.total, 1);
        expect(result.imported, 1);
      });

      test('should update duplicates instead of skipping', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(
              name: 'Already Added',
              playtimeMinutes: 300,
              lastPlayed: DateTime(2024, 6, 15),
            ),
          ],
        );

        // Override findCollectionItem to return existing item
        final CollectionItem collectionItem = createTestCollectionItem(
          status: ItemStatus.notStarted,
        );
        when(() => mockDb.findCollectionItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
            )).thenAnswer((_) async => collectionItem);

        final SteamImportResult result = await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          collectionId: 1,
          onProgress: (_) {},
        );

        expect(result.updated, 1);
        expect(result.imported, 0);
        // Should update status, comment, and dates
        verify(() => mockDb.updateItemStatus(
              collectionItem.id,
              ItemStatus.inProgress,
              mediaType: MediaType.game,
            )).called(1);
        verify(() => mockDb.updateItemUserComment(
              collectionItem.id,
              'Steam: 5.0h',
            )).called(1);
        verify(() => mockDb.updateItemActivityDates(
              collectionItem.id,
              startedAt: DateTime(2024, 6, 15),
            )).called(1);
        verifyNever(() => mockDb.addItemToCollection(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              status: any(named: 'status'),
            ));
      });

      test('should not downgrade status from completed', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(
              name: 'Completed Game',
              playtimeMinutes: 100,
            ),
          ],
        );

        when(() => mockDb.findCollectionItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
            )).thenAnswer((_) async => createTestCollectionItem(
              status: ItemStatus.completed,
            ));

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          collectionId: 1,
          onProgress: (_) {},
        );

        verifyNever(() => mockDb.updateItemStatus(
              any(),
              any(),
              mediaType: any(named: 'mediaType'),
            ));
      });

      test('should not downgrade status from inProgress', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(
              name: 'In Progress Game',
              playtimeMinutes: 100,
            ),
          ],
        );

        when(() => mockDb.findCollectionItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
            )).thenAnswer((_) async => createTestCollectionItem(
              status: ItemStatus.inProgress,
            ));

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          collectionId: 1,
          onProgress: (_) {},
        );

        verifyNever(() => mockDb.updateItemStatus(
              any(),
              any(),
              mediaType: any(named: 'mediaType'),
            ));
      });

      test('should add to wishlist when IGDB returns empty', () async {
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
          collectionId: 1,
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

      test('should add to wishlist on IGDB API error', () async {
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
          collectionId: 1,
          onProgress: (_) {},
        );

        expect(result.wishlisted, 1);
        expect(result.imported, 0);
      });

      test('should throw on empty library', () async {
        when(() => mockSteamApi.getOwnedGames(
              apiKey: any(named: 'apiKey'),
              steamId: any(named: 'steamId'),
            )).thenAnswer((_) async => <SteamOwnedGame>[]);

        expect(
          () => sut.importLibrary(
            apiKey: 'key',
            steamId: '123',
            collectionId: 1,
            onProgress: (_) {},
          ),
          throwsA(isA<SteamApiException>()),
        );
      });

      test('should call onProgress callback', () async {
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
          collectionId: 1,
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

      test('should prefer exact match over first result', () async {
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
          collectionId: 1,
          onProgress: (_) {},
        );

        // Should pick id: 2 (exact match "Portal")
        verify(() => mockDb.upsertGame(
              any(that: predicate<Game>((Game g) => g.id == 2)),
            )).called(1);
      });
    });

    group('wishlist deduplication', () {
      test('should skip adding when unresolved wishlist item exists', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(name: 'Unknown Game'),
          ],
        );

        when(() => mockIgdbApi.searchGames(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => <Game>[]);

        // Existing wishlist item
        when(() => mockDb.findUnresolvedWishlistItem('Unknown Game'))
            .thenAnswer((_) async => createTestWishlistItem(
                  text: 'Unknown Game',
                ));

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          collectionId: 1,
          onProgress: (_) {},
        );

        verifyNever(() => mockDb.addWishlistItem(
              text: any(named: 'text'),
              mediaTypeHint: any(named: 'mediaTypeHint'),
              note: any(named: 'note'),
            ));
      });

      test('should update wishlist note when playtime changed', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(
              name: 'Unknown Game',
              playtimeMinutes: 90,
            ),
          ],
        );

        when(() => mockIgdbApi.searchGames(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => <Game>[]);

        final WishlistItem existingItem = createTestWishlistItem(
          id: 42,
          text: 'Unknown Game',
          note: 'Steam: 0.5h',
        );
        when(() => mockDb.findUnresolvedWishlistItem('Unknown Game'))
            .thenAnswer((_) async => existingItem);

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          collectionId: 1,
          onProgress: (_) {},
        );

        verify(() => mockDb.updateWishlistItem(42, note: 'Steam: 1.5h'))
            .called(1);
        verifyNever(() => mockDb.addWishlistItem(
              text: any(named: 'text'),
              mediaTypeHint: any(named: 'mediaTypeHint'),
              note: any(named: 'note'),
            ));
      });

      test('should create wishlist item when no duplicate exists', () async {
        setupStandardMocks(
          library: <SteamOwnedGame>[
            createTestSteamOwnedGame(name: 'New Game'),
          ],
        );

        when(() => mockIgdbApi.searchGames(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => <Game>[]);

        when(() => mockDb.findUnresolvedWishlistItem('New Game'))
            .thenAnswer((_) async => null);

        await sut.importLibrary(
          apiKey: 'key',
          steamId: '123',
          collectionId: 1,
          onProgress: (_) {},
        );

        verify(() => mockDb.addWishlistItem(
              text: 'New Game',
              mediaTypeHint: MediaType.game,
              note: any(named: 'note'),
            )).called(1);
      });
    });
  });

  group('SteamImportProgress', () {
    test('should return 0 when total is 0', () {
      const SteamImportProgress progress = SteamImportProgress(
        stage: SteamImportStage.fetchingLibrary,
        current: 0,
        total: 0,
      );

      expect(progress.progress, 0.0);
    });

    test('should return fraction when total > 0', () {
      const SteamImportProgress progress = SteamImportProgress(
        stage: SteamImportStage.matchingGames,
        current: 50,
        total: 200,
      );

      expect(progress.progress, 0.25);
    });
  });

  group('SteamImportResult', () {
    test('should store all fields', () {
      const SteamImportResult result = SteamImportResult(
        imported: 10,
        wishlisted: 5,
        updated: 2,
        total: 17,
        collectionId: 42,
      );

      expect(result.imported, 10);
      expect(result.wishlisted, 5);
      expect(result.updated, 2);
      expect(result.total, 17);
      expect(result.collectionId, 42);
    });
  });
}
