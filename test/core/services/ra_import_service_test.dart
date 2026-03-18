// Тесты для RaImportService.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/services/ra_import_service.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/ra_game_progress.dart';
import 'package:xerabora/shared/models/universal_import_result.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late RaImportService sut;
  late MockRaApi mockRaApi;
  late MockIgdbApi mockIgdbApi;
  late MockDatabaseService mockDb;

  /// Записанные вызовы onProgress.
  late List<RaImportProgress> progressCalls;

  void onProgress(RaImportProgress p) => progressCalls.add(p);

  setUp(() {
    mockRaApi = MockRaApi();
    mockIgdbApi = MockIgdbApi();
    mockDb = MockDatabaseService();
    progressCalls = <RaImportProgress>[];

    sut = RaImportService(
      raApi: mockRaApi,
      igdbApi: mockIgdbApi,
      database: mockDb,
    );
  });

  /// Настраивает стандартные mocks для RA API.
  void setupRaApiMocks({
    List<RaGameProgress>? games,
    Map<int, DateTime>? awardDates,
  }) {
    when(() => mockRaApi.getCompletedGames(any()))
        .thenAnswer((_) async => games ?? <RaGameProgress>[]);
    when(() => mockRaApi.getUserAwardDates(any()))
        .thenAnswer((_) async => awardDates ?? <int, DateTime>{});
  }

  /// Настраивает IGDB mock для поиска игр.
  void setupIgdbSearchMock({
    required String query,
    List<int>? platformIds,
    List<Game>? results,
  }) {
    when(() => mockIgdbApi.searchGames(
          query: query,
          platformIds: platformIds,
        )).thenAnswer((_) async => results ?? <Game>[]);
  }

  /// Настраивает DB mocks для добавления элементов.
  void setupDbMocks() {
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
          authorComment: any(named: 'authorComment'),
        )).thenAnswer((_) async => 42);

    when(() => mockDb.updateItemActivityDates(
          any(),
          startedAt: any(named: 'startedAt'),
          completedAt: any(named: 'completedAt'),
          lastActivityAt: any(named: 'lastActivityAt'),
        )).thenAnswer((_) async {});

    when(() => mockDb.updateItemStatus(
          any(),
          any(),
          mediaType: any(named: 'mediaType'),
        )).thenAnswer((_) async {});

    when(() => mockDb.updateItemUserComment(any(), any()))
        .thenAnswer((_) async {});

    when(() => mockDb.updateItemAuthorComment(any(), any()))
        .thenAnswer((_) async {});

    when(() => mockDb.findUnresolvedWishlistItem(any()))
        .thenAnswer((_) async => null);

    when(() => mockDb.addWishlistItem(
          text: any(named: 'text'),
          mediaTypeHint: any(named: 'mediaTypeHint'),
          note: any(named: 'note'),
        )).thenAnswer((_) async => createTestWishlistItem());
  }

  group('RaImportProgress', () {
    test('should create with default values', () {
      const RaImportProgress progress = RaImportProgress(
        stage: RaImportStage.fetchingLibrary,
      );

      expect(progress.stage, equals(RaImportStage.fetchingLibrary));
      expect(progress.current, equals(0));
      expect(progress.total, equals(0));
      expect(progress.currentName, isNull);
      expect(progress.addedCount, equals(0));
      expect(progress.updatedCount, equals(0));
      expect(progress.unmatchedCount, equals(0));
    });

    test('should create with all values', () {
      const RaImportProgress progress = RaImportProgress(
        stage: RaImportStage.matchingGames,
        current: 5,
        total: 10,
        currentName: 'Super Mario World',
        addedCount: 3,
        updatedCount: 1,
        unmatchedCount: 1,
      );

      expect(progress.stage, equals(RaImportStage.matchingGames));
      expect(progress.current, equals(5));
      expect(progress.total, equals(10));
      expect(progress.currentName, equals('Super Mario World'));
      expect(progress.addedCount, equals(3));
      expect(progress.updatedCount, equals(1));
      expect(progress.unmatchedCount, equals(1));
    });
  });

  group('RaImportResult', () {
    test('should create with all fields', () {
      const RaImportResult result = RaImportResult(
        totalGames: 10,
        added: 5,
        updated: 3,
        unmatched: 2,
        unmatchedTitles: <String>['Game A', 'Game B'],
        collectionId: 1,
      );

      expect(result.totalGames, equals(10));
      expect(result.added, equals(5));
      expect(result.updated, equals(3));
      expect(result.unmatched, equals(2));
      expect(result.unmatchedTitles, hasLength(2));
      expect(result.collectionId, equals(1));
    });
  });

  group('RaImportResultToUniversal', () {
    test('should convert to UniversalImportResult with added games', () {
      const RaImportResult raResult = RaImportResult(
        totalGames: 10,
        added: 5,
        updated: 3,
        unmatched: 2,
        unmatchedTitles: <String>['A', 'B'],
        collectionId: 1,
      );

      final UniversalImportResult result = raResult.toUniversal();

      expect(result.sourceName, equals('RetroAchievements'));
      expect(result.success, isTrue);
      expect(result.collectionId, equals(1));
      expect(result.importedByType[MediaType.game], equals(5));
      expect(result.updatedByType[MediaType.game], equals(3));
      expect(result.wishlistedByType[MediaType.game], equals(2));
    });

    test('should have empty maps when counts are zero', () {
      const RaImportResult raResult = RaImportResult(
        totalGames: 0,
        added: 0,
        updated: 0,
        unmatched: 0,
        unmatchedTitles: <String>[],
        collectionId: 1,
      );

      final UniversalImportResult result = raResult.toUniversal();

      expect(result.importedByType, isEmpty);
      expect(result.updatedByType, isEmpty);
      expect(result.wishlistedByType, isEmpty);
    });

    test('should include collection when provided', () {
      const RaImportResult raResult = RaImportResult(
        totalGames: 5,
        added: 3,
        updated: 0,
        unmatched: 0,
        unmatchedTitles: <String>[],
        collectionId: 1,
      );

      final Collection collection = createTestCollection(id: 1);
      final UniversalImportResult result =
          raResult.toUniversal(collection: collection);

      expect(result.collection, isNotNull);
      expect(result.collection!.id, equals(1));
    });
  });

  group('RaImportService', () {
    group('importFromProfile', () {
      test('should import games successfully', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Super Mario World',
          consoleId: 3,
          numAwarded: 96,
          maxPossible: 96,
          highestAwardKind: 'mastered-hardcore',
          lastPlayedAt: DateTime(2024, 6, 15),
        );

        final Game igdbGame = createTestGame(
          id: 100,
          name: 'Super Mario World',
        );

        setupRaApiMocks(
          games: <RaGameProgress>[raGame],
          awardDates: <int, DateTime>{1234: DateTime(2024, 5, 10)},
        );
        setupIgdbSearchMock(
          query: 'Super Mario World',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        final RaImportResult result = await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        expect(result.totalGames, equals(1));
        expect(result.added, equals(1));
        expect(result.updated, equals(0));
        expect(result.unmatched, equals(0));
        expect(result.collectionId, equals(1));

        verify(() => mockDb.upsertGame(igdbGame)).called(1);
        verify(() => mockDb.addItemToCollection(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
              platformId: 19,
              status: ItemStatus.completed,
              authorComment: any(named: 'authorComment'),
            )).called(1);
      });

      test('should report progress correctly', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          title: 'Test Game',
          consoleId: 3,
        );
        final Game igdbGame = createTestGame(name: 'Test Game');

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Test Game',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        // fetchingLibrary, matchingGames (per game), completed.
        expect(progressCalls.length, greaterThanOrEqualTo(3));
        expect(
          progressCalls.first.stage,
          equals(RaImportStage.fetchingLibrary),
        );
        expect(
          progressCalls[1].stage,
          equals(RaImportStage.matchingGames),
        );
        expect(
          progressCalls.last.stage,
          equals(RaImportStage.completed),
        );
      });

      test('should handle empty RA library', () async {
        setupRaApiMocks();

        final RaImportResult result = await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        expect(result.totalGames, equals(0));
        expect(result.added, equals(0));
        expect(result.updated, equals(0));
        expect(result.unmatched, equals(0));
      });

      test('should count unmatched games when IGDB returns no results',
          () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          title: 'Unknown Retro Game',
          consoleName: 'SNES',
          consoleId: 3,
        );

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Unknown Retro Game',
          platformIds: <int>[19],
          results: <Game>[],
        );
        // Fallback search without platform.
        when(() => mockIgdbApi.searchGames(
              query: 'Unknown Retro Game',
            )).thenAnswer((_) async => <Game>[]);
        setupDbMocks();

        final RaImportResult result = await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        expect(result.unmatched, equals(1));
        expect(
          result.unmatchedTitles,
          contains('Unknown Retro Game (SNES)'),
        );
      });

      test('should add unmatched games to wishlist when enabled', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          title: 'Unknown Game',
          consoleName: 'NES',
          consoleId: 7,
          numAwarded: 5,
          maxPossible: 20,
        );

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Unknown Game',
          platformIds: <int>[18],
          results: <Game>[],
        );
        when(() => mockIgdbApi.searchGames(
              query: 'Unknown Game',
            )).thenAnswer((_) async => <Game>[]);
        setupDbMocks();

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: true,
          onProgress: onProgress,
        );

        verify(() => mockDb.addWishlistItem(
              text: 'Unknown Game (NES)',
              mediaTypeHint: MediaType.game,
              note: any(named: 'note'),
            )).called(1);
      });

      test('should not add to wishlist when disabled', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          title: 'Unknown Game',
          consoleName: 'NES',
          consoleId: 7,
        );

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Unknown Game',
          platformIds: <int>[18],
          results: <Game>[],
        );
        when(() => mockIgdbApi.searchGames(
              query: 'Unknown Game',
            )).thenAnswer((_) async => <Game>[]);
        setupDbMocks();

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        verifyNever(() => mockDb.addWishlistItem(
              text: any(named: 'text'),
              mediaTypeHint: any(named: 'mediaTypeHint'),
              note: any(named: 'note'),
            ));
      });

      test('should not add duplicate wishlist item', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          title: 'Unknown Game',
          consoleName: 'NES',
          consoleId: 7,
        );

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Unknown Game',
          platformIds: <int>[18],
          results: <Game>[],
        );
        when(() => mockIgdbApi.searchGames(
              query: 'Unknown Game',
            )).thenAnswer((_) async => <Game>[]);
        setupDbMocks();

        // Wishlist item already exists.
        when(() => mockDb.findUnresolvedWishlistItem('Unknown Game (NES)'))
            .thenAnswer((_) async => createTestWishlistItem());

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: true,
          onProgress: onProgress,
        );

        verifyNever(() => mockDb.addWishlistItem(
              text: any(named: 'text'),
              mediaTypeHint: any(named: 'mediaTypeHint'),
              note: any(named: 'note'),
            ));
      });

      test('should update existing item with higher status', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          numAwarded: 96,
          maxPossible: 96,
          highestAwardKind: 'mastered-hardcore',
          lastPlayedAt: DateTime(2024, 6, 15),
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        final CollectionItem existing = createTestCollectionItem(
          id: 42,
          externalId: 100,
          status: ItemStatus.inProgress,
          userComment: null,
        );

        setupRaApiMocks(
          games: <RaGameProgress>[raGame],
          awardDates: <int, DateTime>{1234: DateTime(2024, 5, 10)},
        );
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        when(() => mockDb.findCollectionItem(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
            )).thenAnswer((_) async => existing);

        final RaImportResult result = await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        expect(result.updated, equals(1));
        expect(result.added, equals(0));

        verify(() => mockDb.updateItemStatus(
              42,
              ItemStatus.completed,
              mediaType: MediaType.game,
            )).called(1);
      });

      test('should not downgrade status for completed items', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          numAwarded: 10,
          maxPossible: 96,
          highestAwardKind: null,
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        final CollectionItem existing = createTestCollectionItem(
          id: 42,
          externalId: 100,
          status: ItemStatus.completed,
          userComment: null,
        );

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        when(() => mockDb.findCollectionItem(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
            )).thenAnswer((_) async => existing);

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        verifyNever(() => mockDb.updateItemStatus(
              any(),
              any(),
              mediaType: any(named: 'mediaType'),
            ));
      });

      test('should not downgrade status for dropped items', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          numAwarded: 10,
          maxPossible: 96,
          highestAwardKind: null,
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        final CollectionItem existing = createTestCollectionItem(
          id: 42,
          externalId: 100,
          status: ItemStatus.dropped,
          userComment: null,
        );

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        when(() => mockDb.findCollectionItem(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
            )).thenAnswer((_) async => existing);

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        verifyNever(() => mockDb.updateItemStatus(
              any(),
              any(),
              mediaType: any(named: 'mediaType'),
            ));
      });

      test('should update activity dates when completedAt available',
          () async {
        final DateTime lastPlayed = DateTime(2024, 6, 15);
        final DateTime completedAt = DateTime(2024, 5, 10);

        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          numAwarded: 96,
          maxPossible: 96,
          highestAwardKind: 'mastered-hardcore',
          lastPlayedAt: lastPlayed,
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        final CollectionItem existing = createTestCollectionItem(
          id: 42,
          externalId: 100,
          status: ItemStatus.completed,
          userComment: null,
        );

        setupRaApiMocks(
          games: <RaGameProgress>[raGame],
          awardDates: <int, DateTime>{1234: completedAt},
        );
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        when(() => mockDb.findCollectionItem(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
            )).thenAnswer((_) async => existing);

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        verify(() => mockDb.updateItemActivityDates(
              42,
              completedAt: completedAt,
              lastActivityAt: lastPlayed,
            )).called(1);
      });

      test('should set activity dates for new items', () async {
        final DateTime lastPlayed = DateTime(2024, 6, 15);
        final DateTime completedAt = DateTime(2024, 5, 10);

        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          lastPlayedAt: lastPlayed,
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        setupRaApiMocks(
          games: <RaGameProgress>[raGame],
          awardDates: <int, DateTime>{1234: completedAt},
        );
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        verify(() => mockDb.updateItemActivityDates(
              42, // itemId from addItemToCollection mock
              startedAt: lastPlayed,
              completedAt: completedAt,
              lastActivityAt: lastPlayed,
            )).called(1);
      });

      test('should not set activity dates when null', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          lastPlayedAt: null,
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        setupRaApiMocks(
          games: <RaGameProgress>[raGame],
          awardDates: <int, DateTime>{},
        );
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        // addItemToCollection returns 42, but no dates to set.
        verifyNever(() => mockDb.updateItemActivityDates(
              42,
              startedAt: any(named: 'startedAt'),
              completedAt: any(named: 'completedAt'),
              lastActivityAt: any(named: 'lastActivityAt'),
            ));
      });

      test('should handle null addItemToCollection result', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          lastPlayedAt: DateTime(2024, 6, 15),
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        setupRaApiMocks(
          games: <RaGameProgress>[raGame],
          awardDates: <int, DateTime>{1234: DateTime(2024, 5, 10)},
        );
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        // addItemToCollection returns null.
        when(() => mockDb.addItemToCollection(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              status: any(named: 'status'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => null);

        final RaImportResult result = await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        expect(result.added, equals(1));
        // Should not call updateItemActivityDates since itemId is null.
        verifyNever(() => mockDb.updateItemActivityDates(
              any(),
              startedAt: any(named: 'startedAt'),
              completedAt: any(named: 'completedAt'),
              lastActivityAt: any(named: 'lastActivityAt'),
            ));
      });

      test('should update authorComment with RA achievements', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          numAwarded: 50,
          maxPossible: 96,
          highestAwardKind: null,
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        final CollectionItem existing = createTestCollectionItem(
          id: 42,
          externalId: 100,
          status: ItemStatus.notStarted,
          authorComment: null,
        );

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        when(() => mockDb.findCollectionItem(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
            )).thenAnswer((_) async => existing);

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        verify(() => mockDb.updateItemAuthorComment(
              42,
              any(that: contains('RA: 50/96 achievements')),
            )).called(1);
      });

      test('should update authorComment when RA comment differs', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          numAwarded: 80,
          maxPossible: 96,
          highestAwardKind: 'beaten-hardcore',
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        final CollectionItem existing = createTestCollectionItem(
          id: 42,
          externalId: 100,
          status: ItemStatus.inProgress,
          authorComment: 'RA: 50/96 achievements (52%)',
        );

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        when(() => mockDb.findCollectionItem(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
            )).thenAnswer((_) async => existing);

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        verify(() => mockDb.updateItemAuthorComment(
              42,
              any(
                that: allOf(
                  contains('RA: 80/96 achievements'),
                  contains('beaten-hardcore'),
                ),
              ),
            )).called(1);
      });

      test('should not update comment when maxPossible is 0', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          gameId: 1234,
          title: 'Mario',
          consoleId: 3,
          numAwarded: 0,
          maxPossible: 0,
          lastPlayedAt: null,
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Mario');

        final CollectionItem existing = createTestCollectionItem(
          id: 42,
          externalId: 100,
          status: ItemStatus.planned,
          authorComment: null,
        );

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Mario',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        when(() => mockDb.findCollectionItem(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
            )).thenAnswer((_) async => existing);

        final RaImportResult result = await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        // No changes: status planned → planned (no upgrade), no comment, no dates.
        expect(result.updated, equals(0));
        verifyNever(() => mockDb.updateItemAuthorComment(any(), any()));
      });

      test('should handle multiple games with mixed results', () async {
        final RaGameProgress matched = createTestRaGameProgress(
          gameId: 1,
          title: 'Matched Game',
          consoleId: 3,
          numAwarded: 10,
          maxPossible: 20,
        );
        final RaGameProgress unmatched = createTestRaGameProgress(
          gameId: 2,
          title: 'Unmatched Game',
          consoleName: 'NES',
          consoleId: 7,
          numAwarded: 5,
          maxPossible: 10,
        );

        final Game igdbGame = createTestGame(id: 100, name: 'Matched Game');

        setupRaApiMocks(
          games: <RaGameProgress>[matched, unmatched],
        );
        setupIgdbSearchMock(
          query: 'Matched Game',
          platformIds: <int>[19],
          results: <Game>[igdbGame],
        );
        setupIgdbSearchMock(
          query: 'Unmatched Game',
          platformIds: <int>[18],
          results: <Game>[],
        );
        when(() => mockIgdbApi.searchGames(
              query: 'Unmatched Game',
            )).thenAnswer((_) async => <Game>[]);
        setupDbMocks();

        final RaImportResult result = await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        expect(result.totalGames, equals(2));
        expect(result.added, equals(1));
        expect(result.unmatched, equals(1));
      });

      test('should map platform ID from consolePlatformMap', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          title: 'Test',
          consoleId: 12, // PlayStation → IGDB 7
        );
        final Game igdbGame = createTestGame(id: 100, name: 'Test');

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Test',
          platformIds: <int>[7],
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        verify(() => mockDb.addItemToCollection(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
              platformId: 7,
              status: any(named: 'status'),
              authorComment: any(named: 'authorComment'),
            )).called(1);
      });

      test('should pass null platformId for unknown consoleId', () async {
        final RaGameProgress raGame = createTestRaGameProgress(
          title: 'Test',
          consoleId: 999, // Unknown
        );
        final Game igdbGame = createTestGame(id: 100, name: 'Test');

        setupRaApiMocks(games: <RaGameProgress>[raGame]);
        setupIgdbSearchMock(
          query: 'Test',
          platformIds: null,
          results: <Game>[igdbGame],
        );
        setupDbMocks();

        await sut.importFromProfile(
          raUsername: 'TestUser',
          collectionId: 1,
          addToWishlist: false,
          onProgress: onProgress,
        );

        verify(() => mockDb.addItemToCollection(
              collectionId: 1,
              mediaType: MediaType.game,
              externalId: 100,
              platformId: null,
              status: any(named: 'status'),
              authorComment: any(named: 'authorComment'),
            )).called(1);
      });
    });
  });
}
