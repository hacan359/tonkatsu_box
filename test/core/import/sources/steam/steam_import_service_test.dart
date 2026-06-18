import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/steam_api.dart';
import 'package:tonkatsu_box/core/import/sources/steam/steam_import_service.dart';
import 'package:tonkatsu_box/core/services/import_service.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/game.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late SteamImportService sut;
  late MockSteamApi mockSteamApi;
  late MockIgdbApi mockIgdbApi;
  late MockDatabaseService mockDb;
  late MockGameDao mockGameDao;
  late MockCollectionRepository mockRepo;
  late MockWishlistRepository mockWishlist;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
  });

  setUp(() {
    mockSteamApi = MockSteamApi();
    mockIgdbApi = MockIgdbApi();
    mockDb = MockDatabaseService();
    mockGameDao = MockGameDao();
    when(() => mockDb.gameDao).thenReturn(mockGameDao);
    mockRepo = MockCollectionRepository();
    mockWishlist = MockWishlistRepository();

    sut = SteamImportService(
      steamApi: mockSteamApi,
      igdbApi: mockIgdbApi,
      database: mockDb,
      repository: mockRepo,
      wishlistRepository: mockWishlist,
    );

    when(() => mockRepo.create(
          name: any(named: 'name'),
          author: any(named: 'author'),
        )).thenAnswer((_) async => createTestCollection());
    when(() => mockRepo.getById(any()))
        .thenAnswer((_) async => createTestCollection());
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
  });

  void setupLibrary(
    List<SteamOwnedGame> games, {
    Map<String, Game>? matches,
  }) {
    when(() => mockSteamApi.getOwnedGames(
          apiKey: any(named: 'apiKey'),
          steamId: any(named: 'steamId'),
        )).thenAnswer((_) async => games);
    when(() => mockIgdbApi.lookupSteamGames(any()))
        .thenAnswer((Invocation inv) async {
      if (matches != null) return matches;
      final List<String> appIds = inv.positionalArguments[0] as List<String>;
      return <String, Game>{
        for (final String id in appIds)
          id: Game(id: id.hashCode.abs(), name: 'Game $id'),
      };
    });
  }

  SteamImportOptions opts({int? collectionId = 1}) => SteamImportOptions(
        apiKey: 'key',
        steamId: '123',
        author: 'me',
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

  group('SteamImportService.import', () {
    test('should import found games into the collection', () async {
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(appId: 440, name: 'Team Fortress 2'),
        createTestSteamOwnedGame(appId: 570, name: 'Dota 2'),
      ]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.success, isTrue);
      expect(result.totalImported, 2);
      expect(result.totalWishlisted, 0);
      expect(result.totalUpdated, 0);
      expect(capturedItemRows(), hasLength(2));
    });

    test('should set inProgress for played games', () async {
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(name: 'Played', playtimeMinutes: 120),
      ]);

      await sut.import(opts());

      expect(capturedItemRows().single['status'], ItemStatus.inProgress.value);
    });

    test('should set notStarted for unplayed games', () async {
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(name: 'Unplayed', playtimeMinutes: 0),
      ]);

      await sut.import(opts());

      expect(capturedItemRows().single['status'], ItemStatus.notStarted.value);
    });

    test('should save playtime into time_spent_minutes, not a comment',
        () async {
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(name: 'Game', playtimeMinutes: 125),
      ]);

      await sut.import(opts());

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['time_spent_minutes'], 125);
      expect(row.containsKey('user_comment'), isFalse);
    });

    test('should save lastPlayed as last_activity_at', () async {
      final DateTime lastPlayed = DateTime(2024, 1, 28);
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(
          name: 'Game',
          playtimeMinutes: 60,
          lastPlayed: lastPlayed,
        ),
      ]);

      await sut.import(opts());

      expect(
        capturedItemRows().single['last_activity_at'],
        lastPlayed.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('should not write time_spent for zero playtime', () async {
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(name: 'Game', playtimeMinutes: 0),
      ]);

      await sut.import(opts());

      expect(capturedItemRows().single.containsKey('time_spent_minutes'),
          isFalse);
    });

    test('should filter DLC and soundtracks', () async {
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(name: 'Real Game'),
        createTestSteamOwnedGame(name: 'Game Soundtrack'),
        createTestSteamOwnedGame(name: 'Game Demo'),
      ]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.totalImported, 1);
      expect(capturedItemRows(), hasLength(1));
    });

    test('should update an existing item instead of re-adding it', () async {
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(
          appId: 10,
          name: 'Already Added',
          playtimeMinutes: 300,
          lastPlayed: DateTime(2024, 6, 15),
        ),
      ], matches: <String, Game>{'10': const Game(id: 99, name: 'Match')});
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.game,
              externalId: 99,
              platformId: 6,
              status: ItemStatus.notStarted,
            ),
          ]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.totalUpdated, 1);
      expect(result.totalImported, 0);
      expect(capturedItemRows(), isEmpty);
      final (int, Map<String, dynamic>) update = capturedUpdates().single;
      expect(update.$1, 7);
      expect(update.$2['status'], ItemStatus.inProgress.value);
      expect(update.$2['time_spent_minutes'], 300);
      expect(
        update.$2['last_activity_at'],
        DateTime(2024, 6, 15).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('should skip an item whose playtime and status are unchanged',
        () async {
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(
          appId: 10,
          name: 'Already Added',
          playtimeMinutes: 300,
        ),
      ], matches: <String, Game>{'10': const Game(id: 99, name: 'Match')});
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.game,
              externalId: 99,
              platformId: 6,
              status: ItemStatus.inProgress,
              timeSpentMinutes: 300,
            ),
          ]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.totalUpdated, 0);
      expect(result.skipped, greaterThanOrEqualTo(1));
      expect(capturedUpdates(), isEmpty);
    });

    test('should not downgrade status from completed', () async {
      setupLibrary(<SteamOwnedGame>[
        createTestSteamOwnedGame(
          appId: 10,
          name: 'Completed',
          playtimeMinutes: 100,
        ),
      ], matches: <String, Game>{'10': const Game(id: 99, name: 'Match')});
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.game,
              externalId: 99,
              platformId: 6,
              status: ItemStatus.completed,
            ),
          ]);

      await sut.import(opts());

      expect(capturedUpdates().single.$2.containsKey('status'), isFalse);
    });

    test('should add unmatched games to the wishlist under one tag', () async {
      setupLibrary(
        <SteamOwnedGame>[createTestSteamOwnedGame(name: 'Unknown Game')],
        matches: <String, Game>{},
      );

      final UniversalImportResult result = await sut.import(opts());

      expect(result.totalWishlisted, 1);
      expect(result.totalImported, 0);
      final Map<String, dynamic> row = capturedWishlistRows().single;
      expect(row['text'], 'Unknown Game');
      expect(row['media_type_hint'], MediaType.game.value);
      expect(row['tag'], isNotNull);
    });

    test('should return a failure result on an empty library', () async {
      when(() => mockSteamApi.getOwnedGames(
            apiKey: any(named: 'apiKey'),
            steamId: any(named: 'steamId'),
          )).thenAnswer((_) async => <SteamOwnedGame>[]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.success, isFalse);
      expect(result.fatalError, isNotNull);
    });

    test('should report progress ending in the completed stage', () async {
      setupLibrary(<SteamOwnedGame>[createTestSteamOwnedGame(name: 'Game 1')]);
      final List<ImportProgress> updates = <ImportProgress>[];

      await sut.import(opts(), onProgress: updates.add);

      expect(updates.length, greaterThanOrEqualTo(2));
      expect(updates.last.stage, ImportStage.completed);
    });

    test('should batch-upsert matched games by IGDB id', () async {
      setupLibrary(
        <SteamOwnedGame>[createTestSteamOwnedGame(appId: 400, name: 'Portal')],
        matches: <String, Game>{'400': const Game(id: 2, name: 'Portal')},
      );

      await sut.import(opts());

      verify(() => mockGameDao.upsertGames(
            any(
              that: predicate<List<Game>>(
                (List<Game> games) => games.any((Game g) => g.id == 2),
              ),
            ),
          )).called(1);
    });

    test('should skip wishlisting a title that already exists unresolved',
        () async {
      setupLibrary(
        <SteamOwnedGame>[createTestSteamOwnedGame(name: 'Unknown Game')],
        matches: <String, Game>{},
      );
      when(() => mockWishlist.getAll(
            includeResolved: any(named: 'includeResolved'),
          )).thenAnswer((_) async =>
          <WishlistItem>[createTestWishlistItem(text: 'Unknown Game')]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.totalWishlisted, 0);
      expect(capturedWishlistRows(), isEmpty);
    });
  });
}
