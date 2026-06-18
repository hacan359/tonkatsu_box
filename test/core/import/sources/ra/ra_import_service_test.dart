import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/ra_api.dart';
import 'package:tonkatsu_box/core/import/sources/ra/ra_import_service.dart';
import 'package:tonkatsu_box/core/services/import_service.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/game.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/ra_game_progress.dart';
import 'package:tonkatsu_box/shared/models/tracker_game_data.dart';
import 'package:tonkatsu_box/shared/models/tracker_profile.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
    registerFallbackValue(<TrackerGameData>[]);
  });

  late RaImportService sut;
  late MockRaApi mockRaApi;
  late MockIgdbApi mockIgdbApi;
  late MockDatabaseService mockDb;
  late MockTrackerDao mockTrackerDao;
  late MockGameDao mockGameDao;
  late MockCollectionRepository mockRepo;
  late MockWishlistRepository mockWishlist;

  late List<ImportProgress> progressCalls;

  // Title -> Game registry consumed by the multiquery mock below.
  final Map<String, Game?> igdbGamesByTitle = <String, Game?>{};

  void onProgress(ImportProgress p) => progressCalls.add(p);

  void setupIgdbSearchMock({
    required String query,
    List<Game>? results,
  }) {
    final List<Game> games = results ?? <Game>[];
    igdbGamesByTitle[query] = games.isNotEmpty ? games.first : null;
  }

  void setupRaApiMocks({List<RaGameProgress>? games}) {
    when(() => mockRaApi.getCompletedGames(any()))
        .thenAnswer((_) async => games ?? <RaGameProgress>[]);
  }

  setUp(() {
    mockRaApi = MockRaApi();
    mockIgdbApi = MockIgdbApi();
    mockDb = MockDatabaseService();
    mockTrackerDao = MockTrackerDao();
    mockGameDao = MockGameDao();
    when(() => mockDb.gameDao).thenReturn(mockGameDao);
    mockRepo = MockCollectionRepository();
    mockWishlist = MockWishlistRepository();
    progressCalls = <ImportProgress>[];
    igdbGamesByTitle.clear();

    when(() => mockTrackerDao.upsertGameDataBatch(any()))
        .thenAnswer((_) async {});
    when(() => mockTrackerDao.getAllGameData(any()))
        .thenAnswer((_) async => <TrackerGameData>[]);

    sut = RaImportService(
      raApi: mockRaApi,
      igdbApi: mockIgdbApi,
      database: mockDb,
      trackerDao: mockTrackerDao,
      repository: mockRepo,
      wishlistRepository: mockWishlist,
    );

    when(() => mockIgdbApi.multiSearchGamesByName(any()))
        .thenAnswer((Invocation inv) async {
      final List<({String name, int? platformId})> queries =
          inv.positionalArguments[0] as List<({String name, int? platformId})>;
      final Map<int, List<Game>> result = <int, List<Game>>{};
      for (int i = 0; i < queries.length; i++) {
        final Game? game = igdbGamesByTitle[queries[i].name];
        result[i] = game != null ? <Game>[game] : <Game>[];
      }
      return result;
    });
  });

  void setupRepoMocks() {
    when(() => mockRepo.create(
          name: any(named: 'name'),
          author: any(named: 'author'),
        )).thenAnswer((_) async => createTestCollection(id: 1));
    when(() => mockRepo.getById(any()))
        .thenAnswer((_) async => createTestCollection(id: 1));
    when(() => mockRepo.getItems(any()))
        .thenAnswer((_) async => <CollectionItem>[]);
    when(() => mockRepo.addItemsBatch(any(), any())).thenAnswer(
        (Invocation inv) async =>
            (inv.positionalArguments[1] as List<dynamic>).length);
    when(() => mockRepo.updateItemFieldsBatch(any())).thenAnswer((_) async {});
    when(() => mockGameDao.upsertGames(any())).thenAnswer((_) async {});
    when(() => mockWishlist.getAll(
          includeResolved: any(named: 'includeResolved'),
        )).thenAnswer((_) async => <WishlistItem>[]);
    when(() => mockWishlist.addWishlistItemsBatch(any())).thenAnswer(
        (Invocation inv) async =>
            (inv.positionalArguments[0] as List<dynamic>).length);
  }

  RaImportOptions opts({int? collectionId = 1, bool addToWishlist = false}) =>
      RaImportOptions(
        raUsername: 'TestUser',
        author: 'me',
        newCollectionName: 'RA',
        addToWishlist: addToWishlist,
        collectionId: collectionId,
      );

  List<Map<String, dynamic>> capturedItemRows() =>
      verify(() => mockRepo.addItemsBatch(any(), captureAny())).captured.single
          as List<Map<String, dynamic>>;

  List<(int, Map<String, dynamic>)> capturedUpdates() =>
      verify(() => mockRepo.updateItemFieldsBatch(captureAny())).captured.single
          as List<(int, Map<String, dynamic>)>;

  List<Map<String, dynamic>> capturedWishlistRows() =>
      verify(() => mockWishlist.addWishlistItemsBatch(captureAny()))
          .captured
          .single as List<Map<String, dynamic>>;

  group('RaImportService.import', () {
    test('should import games successfully', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        gameId: 1234,
        title: 'Super Mario World',
        consoleId: 3,
        numAwarded: 96,
        maxPossible: 96,
        highestAwardKind: 'mastered-hardcore',
        highestAwardDate: DateTime(2024, 5, 10),
        lastPlayedAt: DateTime(2024, 6, 15),
      );
      final Game igdbGame = createTestGame(id: 100, name: 'Super Mario World');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Super Mario World', results: <Game>[igdbGame]);
      setupRepoMocks();

      final UniversalImportResult result =
          await sut.import(opts(), onProgress: onProgress);

      expect(result.totalImported, 1);
      expect(result.totalUpdated, 0);
      expect(result.effectiveCollectionId, 1);
      verify(() => mockGameDao.upsertGames(any())).called(1);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['external_id'], 100);
      expect(row['platform_id'], 19);
      expect(row['status'], ItemStatus.completed.value);
    });

    test('should report progress ending in the completed stage', () async {
      final RaGameProgress raGame =
          createTestRaGameProgress(title: 'Test Game', consoleId: 3);
      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(
          query: 'Test Game', results: <Game>[createTestGame(name: 'Test Game')]);
      setupRepoMocks();

      await sut.import(opts(), onProgress: onProgress);

      expect(progressCalls.first.stage, ImportStage.reading);
      expect(
        progressCalls.any((ImportProgress p) => p.stage == ImportStage.fetchingGames),
        isTrue,
      );
      expect(progressCalls.last.stage, ImportStage.completed);
    });

    test('should throw on an empty RA library', () async {
      setupRaApiMocks();
      setupRepoMocks();

      expect(
        () => sut.import(opts(), onProgress: onProgress),
        throwsA(isA<RaApiException>()),
      );
    });

    test('should not write an unmatched game when wishlist is disabled',
        () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        title: 'Unknown Retro Game',
        consoleName: 'SNES',
        consoleId: 3,
      );
      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Unknown Retro Game', results: <Game>[]);
      setupRepoMocks();

      final UniversalImportResult result =
          await sut.import(opts(), onProgress: onProgress);

      expect(result.totalImported, 0);
      expect(result.totalWishlisted, 0);
      expect(capturedItemRows(), isEmpty);
    });

    test('should add unmatched games to the wishlist when enabled', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        title: 'Unknown Game',
        consoleName: 'NES',
        consoleId: 7,
        numAwarded: 5,
        maxPossible: 20,
      );
      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Unknown Game', results: <Game>[]);
      setupRepoMocks();

      await sut.import(opts(addToWishlist: true), onProgress: onProgress);

      final Map<String, dynamic> row = capturedWishlistRows().single;
      expect(row['text'], 'Unknown Game (NES)');
      expect(row['media_type_hint'], MediaType.game.value);
      expect(row['tag'], isNotNull);
    });

    test('should not touch the wishlist when disabled', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        title: 'Unknown Game',
        consoleName: 'NES',
        consoleId: 7,
      );
      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Unknown Game', results: <Game>[]);
      setupRepoMocks();

      await sut.import(opts(), onProgress: onProgress);

      verifyNever(() => mockWishlist.addWishlistItemsBatch(any()));
    });

    test('should not re-add a title already in the wishlist', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        title: 'Unknown Game',
        consoleName: 'NES',
        consoleId: 7,
      );
      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Unknown Game', results: <Game>[]);
      setupRepoMocks();
      when(() => mockWishlist.getAll(
                includeResolved: any(named: 'includeResolved'),
              ))
          .thenAnswer((_) async =>
              <WishlistItem>[createTestWishlistItem(text: 'Unknown Game (NES)')]);

      final UniversalImportResult result =
          await sut.import(opts(addToWishlist: true), onProgress: onProgress);

      expect(result.totalWishlisted, 0);
      expect(capturedWishlistRows(), isEmpty);
    });

    test('manual RA→IGDB link skips IGDB search and reuses the cached game',
        () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        gameId: 999,
        title: 'Obscure ROM Hack',
        consoleName: 'SNES',
        consoleId: 3,
      );
      final Game cachedGame = createTestGame(id: 500, name: 'Obscure ROM Hack');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupRepoMocks();
      when(() => mockTrackerDao.getAllGameData(TrackerType.ra))
          .thenAnswer((_) async => <TrackerGameData>[
                TrackerGameData(
                  id: 1,
                  trackerType: TrackerType.ra,
                  gameId: 500,
                  trackerGameId: '999',
                  trackerGameTitle: 'Obscure ROM Hack',
                  achievementsTotal: 50,
                  lastSyncedAt: DateTime(2024).millisecondsSinceEpoch ~/ 1000,
                ),
              ]);
      when(() => mockGameDao.getGameById(500))
          .thenAnswer((_) async => cachedGame);

      final UniversalImportResult result =
          await sut.import(opts(addToWishlist: true), onProgress: onProgress);

      expect(result.totalImported, 1);
      verifyNever(() => mockIgdbApi.multiSearchGamesByName(any()));
      verify(() => mockGameDao.getGameById(500)).called(1);
      verifyNever(() => mockWishlist.addWishlistItemsBatch(any()));
    });

    test('manual link with a broken cache falls back to IGDB search', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        gameId: 777,
        title: 'Cached Game',
        consoleName: 'SNES',
        consoleId: 3,
      );
      final Game freshGame = createTestGame(id: 600, name: 'Cached Game');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupRepoMocks();
      when(() => mockTrackerDao.getAllGameData(TrackerType.ra))
          .thenAnswer((_) async => <TrackerGameData>[
                TrackerGameData(
                  id: 1,
                  trackerType: TrackerType.ra,
                  gameId: 600,
                  trackerGameId: '777',
                  trackerGameTitle: 'Cached Game',
                  achievementsTotal: 50,
                  lastSyncedAt: DateTime(2024).millisecondsSinceEpoch ~/ 1000,
                ),
              ]);
      when(() => mockGameDao.getGameById(600)).thenAnswer((_) async => null);
      when(() => mockIgdbApi.searchGames(
            query: 'Cached Game',
            platformIds: any(named: 'platformIds'),
          )).thenAnswer((_) async => <Game>[freshGame]);

      final UniversalImportResult result =
          await sut.import(opts(), onProgress: onProgress);

      expect(result.totalImported, 1);
      verify(() => mockGameDao.getGameById(600)).called(1);
    });

    test('should update an existing item with a higher status', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        gameId: 1234,
        title: 'Mario',
        consoleId: 3,
        numAwarded: 96,
        maxPossible: 96,
        highestAwardKind: 'mastered-hardcore',
        highestAwardDate: DateTime(2024, 5, 10),
        lastPlayedAt: DateTime(2024, 6, 15),
      );
      final Game igdbGame = createTestGame(id: 100, name: 'Mario');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Mario', results: <Game>[igdbGame]);
      setupRepoMocks();
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 42,
              externalId: 100,
              platformId: 19,
              status: ItemStatus.inProgress,
            ),
          ]);

      final UniversalImportResult result =
          await sut.import(opts(), onProgress: onProgress);

      expect(result.totalUpdated, 1);
      expect(result.totalImported, 0);
      final (int, Map<String, dynamic>) update = capturedUpdates().single;
      expect(update.$1, 42);
      expect(update.$2['status'], ItemStatus.completed.value);
    });

    test('should sync a status downgrade from RA on existing items', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        gameId: 1234,
        title: 'Mario',
        consoleId: 3,
        numAwarded: 10,
        maxPossible: 96,
      );
      final Game igdbGame = createTestGame(id: 100, name: 'Mario');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Mario', results: <Game>[igdbGame]);
      setupRepoMocks();
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 42,
              externalId: 100,
              platformId: 19,
              status: ItemStatus.completed,
            ),
          ]);

      await sut.import(opts(), onProgress: onProgress);

      expect(capturedUpdates().single.$2['status'], ItemStatus.inProgress.value);
    });

    test('should not drop a planned item RA reports as inactive', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        gameId: 1234,
        title: 'Mario',
        consoleId: 3,
        numAwarded: 10,
        maxPossible: 96,
        lastPlayedAt: DateTime(2024).subtract(const Duration(days: 120)),
      );
      final Game igdbGame = createTestGame(id: 100, name: 'Mario');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Mario', results: <Game>[igdbGame]);
      setupRepoMocks();
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 42,
              externalId: 100,
              platformId: 19,
              status: ItemStatus.planned,
            ),
          ]);

      await sut.import(opts(), onProgress: onProgress);

      final List<(int, Map<String, dynamic>)> updates = capturedUpdates();
      if (updates.isNotEmpty) {
        expect(updates.single.$2.containsKey('status'), isFalse);
      }
    });

    test('should write award and last-played dates for a new item', () async {
      final DateTime lastPlayed = DateTime(2024, 6, 15);
      final DateTime completedAt = DateTime(2024, 5, 10);
      final RaGameProgress raGame = createTestRaGameProgress(
        gameId: 1234,
        title: 'Mario',
        consoleId: 3,
        numAwarded: 96,
        maxPossible: 96,
        highestAwardKind: 'mastered-hardcore',
        highestAwardDate: completedAt,
        lastPlayedAt: lastPlayed,
      );
      final Game igdbGame = createTestGame(id: 100, name: 'Mario');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Mario', results: <Game>[igdbGame]);
      setupRepoMocks();

      await sut.import(opts(), onProgress: onProgress);

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['completed_at'], completedAt.millisecondsSinceEpoch ~/ 1000);
      expect(row['last_activity_at'], lastPlayed.millisecondsSinceEpoch ~/ 1000);
    });

    test('should write tracker_game_data for a matched game', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        gameId: 1234,
        title: 'Mario',
        consoleId: 3,
        numAwarded: 80,
        maxPossible: 96,
        highestAwardKind: 'beaten-hardcore',
      );
      final Game igdbGame = createTestGame(id: 100, name: 'Mario');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Mario', results: <Game>[igdbGame]);
      setupRepoMocks();
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 42,
              externalId: 100,
              platformId: 19,
              status: ItemStatus.inProgress,
            ),
          ]);

      await sut.import(opts(), onProgress: onProgress);

      verify(() => mockTrackerDao.upsertGameDataBatch(any())).called(1);
    });

    test('should skip an existing item with no RA progress', () async {
      final RaGameProgress raGame = createTestRaGameProgress(
        gameId: 1234,
        title: 'Mario',
        consoleId: 3,
        numAwarded: 0,
        maxPossible: 0,
        lastPlayedAt: null,
      );
      final Game igdbGame = createTestGame(id: 100, name: 'Mario');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Mario', results: <Game>[igdbGame]);
      setupRepoMocks();
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 42,
              externalId: 100,
              platformId: 19,
              status: ItemStatus.planned,
            ),
          ]);

      final UniversalImportResult result =
          await sut.import(opts(), onProgress: onProgress);

      expect(result.totalUpdated, 0);
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
      );
      final Game igdbGame = createTestGame(id: 100, name: 'Matched Game');

      setupRaApiMocks(games: <RaGameProgress>[matched, unmatched]);
      setupIgdbSearchMock(query: 'Matched Game', results: <Game>[igdbGame]);
      setupIgdbSearchMock(query: 'Unmatched Game', results: <Game>[]);
      setupRepoMocks();

      final UniversalImportResult result =
          await sut.import(opts(), onProgress: onProgress);

      expect(result.totalImported, 1);
      expect(capturedItemRows(), hasLength(1));
    });

    test('should map the platform id from the RA console', () async {
      final RaGameProgress raGame =
          createTestRaGameProgress(title: 'Test', consoleId: 12);
      final Game igdbGame = createTestGame(id: 100, name: 'Test');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Test', results: <Game>[igdbGame]);
      setupRepoMocks();

      await sut.import(opts(), onProgress: onProgress);

      expect(capturedItemRows().single['platform_id'], 7);
    });

    test('should write a null platform id for an unknown console', () async {
      final RaGameProgress raGame =
          createTestRaGameProgress(title: 'Test', consoleId: 999);
      final Game igdbGame = createTestGame(id: 100, name: 'Test');

      setupRaApiMocks(games: <RaGameProgress>[raGame]);
      setupIgdbSearchMock(query: 'Test', results: <Game>[igdbGame]);
      setupRepoMocks();

      await sut.import(opts(), onProgress: onProgress);

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['platform_id'], isNull);
    });
  });
}
