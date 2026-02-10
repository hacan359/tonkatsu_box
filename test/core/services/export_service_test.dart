import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/services/export_service.dart';
import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/core/services/xcoll_file.dart';
import 'package:xerabora/data/repositories/canvas_repository.dart';
import 'package:xerabora/shared/models/canvas_connection.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/canvas_viewport.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_game.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

class MockCanvasRepository extends Mock implements CanvasRepository {}

class MockImageCacheService extends Mock implements ImageCacheService {}

void main() {
  setUpAll(() {
    registerFallbackValue(ImageType.gameCover);
    registerFallbackValue(Uint8List(0));
  });

  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

  Collection createTestCollection({
    int id = 1,
    String name = 'Test Collection',
    String author = 'Test Author',
    CollectionType type = CollectionType.own,
  }) {
    return Collection(
      id: id,
      name: name,
      author: author,
      type: type,
      createdAt: testDate,
    );
  }

  CollectionGame createTestGame({
    int id = 1,
    int collectionId = 1,
    int igdbId = 100,
    int platformId = 18,
    String? authorComment,
    GameStatus status = GameStatus.notStarted,
  }) {
    return CollectionGame(
      id: id,
      collectionId: collectionId,
      igdbId: igdbId,
      platformId: platformId,
      authorComment: authorComment,
      status: status,
      addedAt: testDate,
    );
  }

  CollectionItem createTestItem({
    int id = 1,
    int collectionId = 1,
    MediaType mediaType = MediaType.game,
    int externalId = 100,
    int? platformId = 18,
    ItemStatus status = ItemStatus.notStarted,
    String? authorComment,
    int currentSeason = 0,
    int currentEpisode = 0,
  }) {
    return CollectionItem(
      id: id,
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      status: status,
      authorComment: authorComment,
      currentSeason: currentSeason,
      currentEpisode: currentEpisode,
      addedAt: testDate,
    );
  }

  group('ExportResult', () {
    test('ExportResult.success должен создать успешный результат', () {
      const ExportResult result = ExportResult.success('/path/to/file.xcoll');

      expect(result.success, isTrue);
      expect(result.filePath, equals('/path/to/file.xcoll'));
      expect(result.error, isNull);
      expect(result.isCancelled, isFalse);
    });

    test('ExportResult.failure должен создать неуспешный результат', () {
      const ExportResult result = ExportResult.failure('Error message');

      expect(result.success, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, equals('Error message'));
      expect(result.isCancelled, isFalse);
    });

    test('ExportResult.cancelled должен создать отменённый результат', () {
      const ExportResult result = ExportResult.cancelled();

      expect(result.success, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, isNull);
      expect(result.isCancelled, isTrue);
    });

    test('isCancelled должен быть false при ошибке', () {
      const ExportResult result = ExportResult(
        success: false,
        error: 'Some error',
      );

      expect(result.isCancelled, isFalse);
    });
  });

  group('ExportService', () {
    late ExportService sut;

    setUp(() {
      sut = ExportService();
    });

    group('createXcollFile (legacy v1)', () {
      test('должен создать XcollFile v1 из коллекции без игр', () {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[];

        final XcollFile rcoll = sut.createXcollFile(collection, items);

        expect(rcoll.version, equals(xcollLegacyVersion));
        expect(rcoll.isV1, isTrue);
        expect(rcoll.name, equals('Test Collection'));
        expect(rcoll.author, equals('Test Author'));
        expect(rcoll.created, equals(testDate));
        expect(rcoll.legacyGames, isEmpty);
      });

      test('должен создать XcollFile v1 с играми', () {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionGame>[
          createTestGame(
              igdbId: 100, platformId: 18, authorComment: 'Comment 1'),
          createTestGame(id: 2, igdbId: 200, platformId: 19),
        ].map((CollectionGame g) => g.toCollectionItem()).toList();

        final XcollFile rcoll = sut.createXcollFile(collection, items);

        expect(rcoll.legacyGames.length, equals(2));
        expect(rcoll.legacyGames[0].igdbId, equals(100));
        expect(rcoll.legacyGames[0].platformId, equals(18));
        expect(rcoll.legacyGames[0].comment, equals('Comment 1'));
        expect(rcoll.legacyGames[1].igdbId, equals(200));
        expect(rcoll.legacyGames[1].comment, isNull);
      });

      test('должен использовать authorComment а не userComment', () {
        final Collection collection = createTestCollection();
        final CollectionGame game = CollectionGame(
          id: 1,
          collectionId: 1,
          igdbId: 100,
          platformId: 18,
          authorComment: 'Author says',
          userComment: 'User says',
          status: GameStatus.notStarted,
          addedAt: testDate,
        );

        final XcollFile rcoll = sut.createXcollFile(
          collection,
          <CollectionGame>[game]
              .map((CollectionGame g) => g.toCollectionItem())
              .toList(),
        );

        expect(rcoll.legacyGames[0].comment, equals('Author says'));
      });

      test('должен фильтровать только игры в v1', () {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
              mediaType: MediaType.game, externalId: 100, platformId: 18),
          createTestItem(
              id: 2, mediaType: MediaType.movie, externalId: 550,
              platformId: null),
          createTestItem(
              id: 3, mediaType: MediaType.tvShow, externalId: 1399,
              platformId: null),
        ];

        final XcollFile rcoll = sut.createXcollFile(collection, items);

        expect(rcoll.legacyGames.length, equals(1));
        expect(rcoll.legacyGames[0].igdbId, equals(100));
      });
    });

    group('createLightExport (v2 light)', () {
      test('должен создать XcollFile v2 из пустой коллекции', () {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[];

        final XcollFile xcoll = sut.createLightExport(collection, items);

        expect(xcoll.version, equals(xcollFormatVersion));
        expect(xcoll.isV2, isTrue);
        expect(xcoll.format, equals(ExportFormat.light));
        expect(xcoll.name, equals('Test Collection'));
        expect(xcoll.author, equals('Test Author'));
        expect(xcoll.created, equals(testDate));
        expect(xcoll.items, isEmpty);
        expect(xcoll.canvas, isNull);
        expect(xcoll.images, isEmpty);
      });

      test('должен экспортировать все типы медиа', () {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            mediaType: MediaType.game,
            externalId: 100,
            platformId: 18,
            status: ItemStatus.completed,
            authorComment: 'Great game',
          ),
          createTestItem(
            id: 2,
            mediaType: MediaType.movie,
            externalId: 550,
            platformId: null,
            status: ItemStatus.notStarted,
          ),
          createTestItem(
            id: 3,
            mediaType: MediaType.tvShow,
            externalId: 1399,
            platformId: null,
            status: ItemStatus.inProgress,
            currentSeason: 3,
            currentEpisode: 5,
          ),
        ];

        final XcollFile xcoll = sut.createLightExport(collection, items);

        expect(xcoll.items.length, equals(3));

        // Игра
        expect(xcoll.items[0]['media_type'], equals('game'));
        expect(xcoll.items[0]['external_id'], equals(100));
        expect(xcoll.items[0]['platform_id'], equals(18));
        expect(xcoll.items[0]['status'], equals('completed'));
        expect(xcoll.items[0]['comment'], equals('Great game'));

        // Фильм
        expect(xcoll.items[1]['media_type'], equals('movie'));
        expect(xcoll.items[1]['external_id'], equals(550));
        expect(xcoll.items[1]['status'], equals('not_started'));

        // Сериал
        expect(xcoll.items[2]['media_type'], equals('tv_show'));
        expect(xcoll.items[2]['external_id'], equals(1399));
        expect(xcoll.items[2]['status'], equals('in_progress'));
        expect(xcoll.items[2]['current_season'], equals(3));
        expect(xcoll.items[2]['current_episode'], equals(5));
      });

      test('должен использовать toExport() для каждого элемента', () {
        final Collection collection = createTestCollection();
        final CollectionItem item = createTestItem(
          mediaType: MediaType.game,
          externalId: 42,
          platformId: 6,
          status: ItemStatus.completed,
          authorComment: 'Classic',
        );

        final XcollFile xcoll =
            sut.createLightExport(collection, <CollectionItem>[item]);

        // toExport() использует status.value, а не dbValue
        expect(xcoll.items[0]['status'], equals('completed'));
        // toExport() переименовывает author_comment → comment
        expect(xcoll.items[0]['comment'], equals('Classic'));
        // Internal поля НЕ включены
        expect(xcoll.items[0].containsKey('id'), isFalse);
        expect(xcoll.items[0].containsKey('collection_id'), isFalse);
        expect(xcoll.items[0].containsKey('user_comment'), isFalse);
        expect(xcoll.items[0].containsKey('added_at'), isFalse);
      });
    });

    group('createFullExport (v2 full)', () {
      late MockCanvasRepository mockCanvasRepo;
      late ExportService sutFull;

      setUp(() {
        mockCanvasRepo = MockCanvasRepository();
        sutFull = ExportService(canvasRepository: mockCanvasRepo);
      });

      test('должен создать full export без canvas данных', () async {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[];

        when(() => mockCanvasRepo.getViewport(any()))
            .thenAnswer((_) async => null);
        when(() => mockCanvasRepo.getItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);
        when(() => mockCanvasRepo.getConnections(any()))
            .thenAnswer((_) async => <CanvasConnection>[]);

        final XcollFile xcoll =
            await sutFull.createFullExport(collection, items, 1);

        expect(xcoll.version, equals(xcollFormatVersion));
        expect(xcoll.format, equals(ExportFormat.full));
        expect(xcoll.isFull, isTrue);
        expect(xcoll.canvas, isNull);
      });

      test('должен включить collection canvas', () async {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[];

        const CanvasViewport viewport = CanvasViewport(
          collectionId: 1,
          scale: 0.8,
          offsetX: -100.0,
          offsetY: -50.0,
        );

        final CanvasItem canvasItem = CanvasItem(
          id: 1,
          collectionId: 1,
          itemType: CanvasItemType.game,
          itemRefId: 100,
          x: 100.0,
          y: 200.0,
          width: 160.0,
          height: 220.0,
          zIndex: 0,
          createdAt: testDate,
        );

        final CanvasConnection connection = CanvasConnection(
          id: 1,
          collectionId: 1,
          fromItemId: 1,
          toItemId: 2,
          style: ConnectionStyle.arrow,
          createdAt: testDate,
        );

        when(() => mockCanvasRepo.getViewport(1))
            .thenAnswer((_) async => viewport);
        when(() => mockCanvasRepo.getItems(1))
            .thenAnswer((_) async => <CanvasItem>[canvasItem]);
        when(() => mockCanvasRepo.getConnections(1))
            .thenAnswer((_) async => <CanvasConnection>[connection]);

        final XcollFile xcoll =
            await sutFull.createFullExport(collection, items, 1);

        expect(xcoll.canvas, isNotNull);
        expect(xcoll.canvas!.viewport, isNotNull);
        expect(xcoll.canvas!.viewport!['scale'], equals(0.8));
        expect(xcoll.canvas!.viewport!['offsetX'], equals(-100.0));
        expect(xcoll.canvas!.items.length, equals(1));
        expect(xcoll.canvas!.items[0]['type'], equals('game'));
        expect(xcoll.canvas!.connections.length, equals(1));
        expect(xcoll.canvas!.connections[0]['style'], equals('arrow'));
      });

      test('должен включить per-item canvas', () async {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(id: 10, externalId: 100),
        ];

        // Collection canvas — пустой
        when(() => mockCanvasRepo.getViewport(any()))
            .thenAnswer((_) async => null);
        when(() => mockCanvasRepo.getItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);
        when(() => mockCanvasRepo.getConnections(any()))
            .thenAnswer((_) async => <CanvasConnection>[]);

        // Per-item canvas для item 10
        final CanvasItem perItemCanvasItem = CanvasItem(
          id: 50,
          collectionId: 1,
          collectionItemId: 10,
          itemType: CanvasItemType.text,
          x: 50.0,
          y: 75.0,
          zIndex: 0,
          data: const <String, dynamic>{'text': 'Notes'},
          createdAt: testDate,
        );

        when(() => mockCanvasRepo.getGameCanvasItems(10))
            .thenAnswer((_) async => <CanvasItem>[perItemCanvasItem]);
        when(() => mockCanvasRepo.getGameCanvasConnections(10))
            .thenAnswer((_) async => <CanvasConnection>[]);
        when(() => mockCanvasRepo.getGameCanvasViewport(10))
            .thenAnswer((_) async => null);

        final XcollFile xcoll =
            await sutFull.createFullExport(collection, items, 1);

        expect(xcoll.items[0].containsKey('_canvas'), isTrue);
        final Map<String, dynamic> perItemCanvas =
            xcoll.items[0]['_canvas'] as Map<String, dynamic>;
        final List<dynamic> canvasItems =
            perItemCanvas['items'] as List<dynamic>;
        expect(canvasItems, isNotEmpty);
        final Map<String, dynamic> firstCanvasItem =
            canvasItems[0] as Map<String, dynamic>;
        expect(firstCanvasItem['type'], equals('text'));
      });

      test('не должен включать _canvas если per-item canvas пуст', () async {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(id: 10, externalId: 100),
        ];

        when(() => mockCanvasRepo.getViewport(any()))
            .thenAnswer((_) async => null);
        when(() => mockCanvasRepo.getItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);
        when(() => mockCanvasRepo.getConnections(any()))
            .thenAnswer((_) async => <CanvasConnection>[]);
        when(() => mockCanvasRepo.getGameCanvasItems(10))
            .thenAnswer((_) async => <CanvasItem>[]);

        final XcollFile xcoll =
            await sutFull.createFullExport(collection, items, 1);

        expect(xcoll.items[0].containsKey('_canvas'), isFalse);
      });

      test('без canvasRepository должен пропустить canvas', () async {
        final ExportService sutNoCanvas = ExportService();
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[];

        final XcollFile xcoll =
            await sutNoCanvas.createFullExport(collection, items, 1);

        expect(xcoll.canvas, isNull);
        expect(xcoll.format, equals(ExportFormat.full));
      });
    });

    group('exportToJson', () {
      test('должен вернуть валидный v2 JSON', () {
        final Collection collection =
            createTestCollection(name: 'JSON Export');
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(externalId: 500, platformId: 20),
        ];

        final String json = sut.exportToJson(collection, items);

        final Map<String, dynamic> parsed =
            jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['name'], equals('JSON Export'));
        expect(parsed['version'], equals(xcollFormatVersion));
        expect(parsed['format'], equals('light'));
        expect((parsed['items'] as List<dynamic>).length, equals(1));
      });

      test('должен создать форматированный JSON с отступами', () {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[];

        final String json = sut.exportToJson(collection, items);

        expect(json, contains('\n'));
        expect(json, contains('  '));
      });

      test('должен корректно экспортировать пустую коллекцию', () {
        final Collection collection = createTestCollection(name: 'Empty');
        final List<CollectionItem> items = <CollectionItem>[];

        final String json = sut.exportToJson(collection, items);
        final XcollFile restored = XcollFile.fromJsonString(json);

        expect(restored.name, equals('Empty'));
        expect(restored.isV2, isTrue);
        expect(restored.items, isEmpty);
      });

      test('должен сохранять все данные при round-trip', () {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            externalId: 111,
            platformId: 22,
            authorComment: 'Fantastic game',
            status: ItemStatus.completed,
          ),
        ];

        final String json = sut.exportToJson(collection, items);
        final XcollFile restored = XcollFile.fromJsonString(json);

        expect(restored.items[0]['external_id'], equals(111));
        expect(restored.items[0]['platform_id'], equals(22));
        expect(restored.items[0]['comment'], equals('Fantastic game'));
        expect(restored.items[0]['status'], equals('completed'));
      });
    });

    group('exportToLegacyJson', () {
      test('должен создать v1 legacy JSON', () {
        final Collection collection =
            createTestCollection(name: 'Legacy Export');
        final List<CollectionItem> items = <CollectionGame>[
          createTestGame(igdbId: 500, platformId: 20),
        ].map((CollectionGame g) => g.toCollectionItem()).toList();

        final String json = sut.exportToLegacyJson(collection, items);

        final Map<String, dynamic> parsed =
            jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['name'], equals('Legacy Export'));
        expect(parsed['version'], equals(xcollLegacyVersion));
        expect(parsed.containsKey('games'), isTrue);
        expect(parsed.containsKey('items'), isFalse);
      });

      test('должен сохранять данные игр при round-trip', () {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionGame>[
          createTestGame(
            igdbId: 111,
            platformId: 22,
            authorComment: 'Fantastic game',
          ),
        ].map((CollectionGame g) => g.toCollectionItem()).toList();

        final String json = sut.exportToLegacyJson(collection, items);
        final XcollFile restored = XcollFile.fromJsonString(json);

        expect(restored.isV1, isTrue);
        expect(restored.legacyGames[0].igdbId, equals(111));
        expect(restored.legacyGames[0].platformId, equals(22));
        expect(restored.legacyGames[0].comment, equals('Fantastic game'));
      });
    });

    group('exportToJsonFull', () {
      late MockCanvasRepository mockCanvasRepo;
      late ExportService sutFull;

      setUp(() {
        mockCanvasRepo = MockCanvasRepository();
        sutFull = ExportService(canvasRepository: mockCanvasRepo);
      });

      test('должен вернуть v2 full JSON', () async {
        final Collection collection = createTestCollection(name: 'Full');
        final List<CollectionItem> items = <CollectionItem>[];

        when(() => mockCanvasRepo.getViewport(any()))
            .thenAnswer((_) async => null);
        when(() => mockCanvasRepo.getItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);
        when(() => mockCanvasRepo.getConnections(any()))
            .thenAnswer((_) async => <CanvasConnection>[]);

        final String json =
            await sutFull.exportToJsonFull(collection, items, 1);

        final Map<String, dynamic> parsed =
            jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['version'], equals(xcollFormatVersion));
        expect(parsed['format'], equals('full'));
        expect(parsed['name'], equals('Full'));
      });
    });

    group('images в full export', () {
      late MockCanvasRepository mockCanvasRepo;
      late MockImageCacheService mockImageCache;

      setUp(() {
        mockCanvasRepo = MockCanvasRepository();
        mockImageCache = MockImageCacheService();

        // Дефолтные моки для canvas (пустой)
        when(() => mockCanvasRepo.getViewport(any()))
            .thenAnswer((_) async => null);
        when(() => mockCanvasRepo.getItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);
        when(() => mockCanvasRepo.getConnections(any()))
            .thenAnswer((_) async => <CanvasConnection>[]);
      });

      test('должен собрать кэшированные обложки в images', () async {
        final Uint8List testBytes =
            Uint8List.fromList(<int>[137, 80, 78, 71, 13, 10, 26, 10]);
        when(() => mockImageCache.readImageBytes(
              ImageType.gameCover,
              '100',
            )).thenAnswer((_) async => testBytes);

        // Мок для per-item canvas (items существуют)
        when(() => mockCanvasRepo.getGameCanvasItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(externalId: 100),
        ];

        final XcollFile xcoll =
            await sutImages.createFullExport(collection, items, 1);

        expect(xcoll.images.containsKey('game_covers/100'), isTrue);
        expect(xcoll.images['game_covers/100'], equals(base64Encode(testBytes)));
      });

      test('должен пропустить элементы без кэшированных изображений',
          () async {
        when(() => mockImageCache.readImageBytes(any(), any()))
            .thenAnswer((_) async => null);

        when(() => mockCanvasRepo.getGameCanvasItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(externalId: 100),
        ];

        final XcollFile xcoll =
            await sutImages.createFullExport(collection, items, 1);

        expect(xcoll.images, isEmpty);
      });

      test('должен пропустить дубли externalId', () async {
        final Uint8List testBytes = Uint8List.fromList(<int>[1, 2, 3]);
        when(() => mockImageCache.readImageBytes(
              ImageType.gameCover,
              '100',
            )).thenAnswer((_) async => testBytes);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(id: 1, externalId: 100),
          createTestItem(id: 2, externalId: 100),
        ];

        // Мокаем getGameCanvasItems для per-item canvas
        when(() => mockCanvasRepo.getGameCanvasItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);

        final XcollFile xcoll =
            await sutImages.createFullExport(collection, items, 1);

        expect(xcoll.images.length, equals(1));
        // readImageBytes должен быть вызван только один раз
        verify(() => mockImageCache.readImageBytes(
              ImageType.gameCover,
              '100',
            )).called(1);
      });

      test('должен включить все типы медиа', () async {
        final Uint8List gameBytes = Uint8List.fromList(<int>[1, 2, 3]);
        final Uint8List movieBytes = Uint8List.fromList(<int>[4, 5, 6]);
        final Uint8List tvShowBytes = Uint8List.fromList(<int>[7, 8, 9]);

        when(() => mockImageCache.readImageBytes(
              ImageType.gameCover,
              '100',
            )).thenAnswer((_) async => gameBytes);
        when(() => mockImageCache.readImageBytes(
              ImageType.moviePoster,
              '200',
            )).thenAnswer((_) async => movieBytes);
        when(() => mockImageCache.readImageBytes(
              ImageType.tvShowPoster,
              '300',
            )).thenAnswer((_) async => tvShowBytes);

        // Мокаем per-item canvas
        when(() => mockCanvasRepo.getGameCanvasItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            id: 1,
            mediaType: MediaType.game,
            externalId: 100,
          ),
          createTestItem(
            id: 2,
            mediaType: MediaType.movie,
            externalId: 200,
            platformId: null,
          ),
          createTestItem(
            id: 3,
            mediaType: MediaType.tvShow,
            externalId: 300,
            platformId: null,
          ),
        ];

        final XcollFile xcoll =
            await sutImages.createFullExport(collection, items, 1);

        expect(xcoll.images.length, equals(3));
        expect(xcoll.images.containsKey('game_covers/100'), isTrue);
        expect(xcoll.images.containsKey('movie_posters/200'), isTrue);
        expect(xcoll.images.containsKey('tv_show_posters/300'), isTrue);
      });

      test('без imageCacheService должен вернуть пустой images', () async {
        when(() => mockCanvasRepo.getGameCanvasItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);

        final ExportService sutNoCache = ExportService(
          canvasRepository: mockCanvasRepo,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(externalId: 100),
        ];

        final XcollFile xcoll =
            await sutNoCache.createFullExport(collection, items, 1);

        expect(xcoll.images, isEmpty);
      });
    });

    group('v2 → XcollFile round-trip', () {
      test('light export → fromJsonString → поля сохранены', () {
        final Collection collection =
            createTestCollection(name: 'Round Trip');
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            mediaType: MediaType.game,
            externalId: 42,
            platformId: 6,
            status: ItemStatus.completed,
            authorComment: 'Best game',
          ),
          createTestItem(
            id: 2,
            mediaType: MediaType.tvShow,
            externalId: 1399,
            platformId: null,
            status: ItemStatus.inProgress,
            currentSeason: 2,
            currentEpisode: 8,
          ),
        ];

        final String json = sut.exportToJson(collection, items);
        final XcollFile restored = XcollFile.fromJsonString(json);

        expect(restored.version, equals(xcollFormatVersion));
        expect(restored.format, equals(ExportFormat.light));
        expect(restored.name, equals('Round Trip'));
        expect(restored.items.length, equals(2));

        // Восстановление через fromExport
        final CollectionItem restoredGame =
            CollectionItem.fromExport(restored.items[0]);
        expect(restoredGame.mediaType, equals(MediaType.game));
        expect(restoredGame.externalId, equals(42));
        expect(restoredGame.platformId, equals(6));
        expect(restoredGame.status, equals(ItemStatus.completed));
        expect(restoredGame.authorComment, equals('Best game'));

        final CollectionItem restoredTvShow =
            CollectionItem.fromExport(restored.items[1]);
        expect(restoredTvShow.mediaType, equals(MediaType.tvShow));
        expect(restoredTvShow.currentSeason, equals(2));
        expect(restoredTvShow.currentEpisode, equals(8));
      });
    });
  });
}
