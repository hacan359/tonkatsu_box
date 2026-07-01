import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/import/sources/igdb_list/igdb_list_import_service.dart';
import 'package:tonkatsu_box/core/services/import_service.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/game.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late IgdbListImportService sut;
  late MockIgdbApi mockIgdbApi;
  late MockDatabaseService mockDb;
  late MockGameDao mockGameDao;
  late MockCollectionRepository mockRepo;
  late MockWishlistRepository mockWishlist;

  late Directory tempDir;
  late String csvPath;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<int>[]);
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
  });

  setUp(() {
    mockIgdbApi = MockIgdbApi();
    mockDb = MockDatabaseService();
    mockGameDao = MockGameDao();
    when(() => mockDb.gameDao).thenReturn(mockGameDao);
    mockRepo = MockCollectionRepository();
    mockWishlist = MockWishlistRepository();

    sut = IgdbListImportService(
      igdbApi: mockIgdbApi,
      database: mockDb,
      repository: mockRepo,
      wishlistRepository: mockWishlist,
    );

    tempDir = Directory.systemTemp.createTempSync('igdb_list_test');
    csvPath = '${tempDir.path}/list.csv';

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

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void writeCsv(String content) {
    File(csvPath).writeAsStringSync(content);
  }

  void setupMatches(List<Game> games) {
    when(() => mockIgdbApi.getGamesByIds(any())).thenAnswer((_) async => games);
  }

  IgdbListImportOptions opts({
    int? collectionId = 1,
    ItemStatus status = ItemStatus.notStarted,
    int platformId = 6,
  }) =>
      IgdbListImportOptions(
        filePath: csvPath,
        author: 'me',
        status: status,
        platformId: platformId,
        wishlistReason: 'Not found on IGDB',
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

  group('IgdbListImportService.import', () {
    test('imports games matched by their IGDB id', () async {
      writeCsv('id,game\n10,One\n20,Two');
      setupMatches(<Game>[
        createTestGame(id: 10, name: 'One'),
        createTestGame(id: 20, name: 'Two'),
      ]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.success, isTrue);
      expect(result.totalImported, 2);
      expect(result.totalWishlisted, 0);
      final List<Map<String, dynamic>> rows = capturedItemRows();
      expect(rows, hasLength(2));
      expect(rows.first['external_id'], 10);
    });

    test('defaults to notStarted with no activity dates', () async {
      writeCsv('id,game\n10,One');
      setupMatches(<Game>[createTestGame(id: 10)]);

      await sut.import(opts());

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['status'], ItemStatus.notStarted.value);
      expect(row.containsKey('completed_at'), isFalse);
      expect(row.containsKey('started_at'), isFalse);
    });

    test('stamps completed_at when the chosen status is completed', () async {
      writeCsv('id,game\n10,One');
      setupMatches(<Game>[createTestGame(id: 10)]);

      await sut.import(opts(status: ItemStatus.completed));

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['status'], ItemStatus.completed.value);
      expect(row['completed_at'], isNotNull);
      expect(row['started_at'], isNotNull);
      expect(row['last_activity_at'], isNotNull);
    });

    test('applies the chosen platform id to every row', () async {
      writeCsv('id,game\n10,One');
      setupMatches(<Game>[createTestGame(id: 10)]);

      await sut.import(opts(platformId: 48));

      expect(capturedItemRows().single['platform_id'], 48);
    });

    test('sends ids IGDB no longer returns to the wishlist', () async {
      writeCsv('id,game\n10,Present\n999,Missing');
      setupMatches(<Game>[createTestGame(id: 10, name: 'Present')]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.totalImported, 1);
      expect(result.totalWishlisted, 1);
      final Map<String, dynamic> row = capturedWishlistRows().single;
      expect(row['text'], 'Missing');
      expect(row['media_type_hint'], MediaType.game.value);
      expect(row['note'], 'Not found on IGDB');
      expect(row['tag'], startsWith('IGDB-'));
    });

    test('dedupes repeated ids within the same file', () async {
      writeCsv('id,game\n10,One\n10,One again');
      setupMatches(<Game>[createTestGame(id: 10, name: 'One')]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.totalImported, 1);
      verify(() => mockIgdbApi.getGamesByIds(<int>[10])).called(1);
    });

    test('an unset re-import never disturbs an existing item', () async {
      writeCsv('id,game\n10,One');
      setupMatches(<Game>[createTestGame(id: 10)]);
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.game,
              externalId: 10,
              platformId: 6,
              status: ItemStatus.inProgress,
            ),
          ]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.totalImported, 0);
      expect(result.totalUpdated, 0);
      expect(capturedUpdates(), isEmpty);
    });

    test('re-import upgrades an existing status upward', () async {
      writeCsv('id,game\n10,One');
      setupMatches(<Game>[createTestGame(id: 10)]);
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.game,
              externalId: 10,
              platformId: 6,
              status: ItemStatus.notStarted,
            ),
          ]);

      final UniversalImportResult result =
          await sut.import(opts(status: ItemStatus.completed));

      expect(result.totalUpdated, 1);
      final (int, Map<String, dynamic>) update = capturedUpdates().single;
      expect(update.$1, 7);
      expect(update.$2['status'], ItemStatus.completed.value);
    });

    test('does not downgrade a completed item', () async {
      writeCsv('id,game\n10,One');
      setupMatches(<Game>[createTestGame(id: 10)]);
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.game,
              externalId: 10,
              platformId: 6,
              status: ItemStatus.completed,
            ),
          ]);

      final UniversalImportResult result =
          await sut.import(opts(status: ItemStatus.inProgress));

      expect(result.totalUpdated, 0);
      expect(capturedUpdates(), isEmpty);
    });

    test('batch-upserts matched games into the cache', () async {
      writeCsv('id,game\n10,One');
      setupMatches(<Game>[createTestGame(id: 10)]);

      await sut.import(opts());

      verify(() => mockGameDao.upsertGames(
            any(
              that: predicate<List<Game>>(
                (List<Game> games) => games.any((Game g) => g.id == 10),
              ),
            ),
          )).called(1);
    });

    test('fails on an empty file', () async {
      writeCsv('id,game\n');
      setupMatches(<Game>[]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.success, isFalse);
      expect(result.fatalError, isNotNull);
    });

    test('fails on a file with no id column', () async {
      writeCsv('game,url\nPortal,x');

      final UniversalImportResult result = await sut.import(opts());

      expect(result.success, isFalse);
      expect(result.fatalError, isNotNull);
    });

    test('reports progress ending in the completed stage', () async {
      writeCsv('id,game\n10,One');
      setupMatches(<Game>[createTestGame(id: 10)]);
      final List<ImportProgress> updates = <ImportProgress>[];

      await sut.import(opts(), onProgress: updates.add);

      expect(updates.last.stage, ImportStage.completed);
    });
  });
}
