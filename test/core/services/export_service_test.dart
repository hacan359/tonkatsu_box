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
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';

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
    Game? game,
    Movie? movie,
    TvShow? tvShow,
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
      game: game,
      movie: movie,
      tvShow: tvShow,
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

    group('createLightExport (v2 light)', () {
      test('должен создать XcollFile v2 из пустой коллекции', () {
        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[];

        final XcollFile xcoll = sut.createLightExport(collection, items);

        expect(xcoll.version, equals(xcollFormatVersion));
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
        expect(xcoll.items[0]['comment'], equals('Great game'));

        // Фильм
        expect(xcoll.items[1]['media_type'], equals('movie'));
        expect(xcoll.items[1]['external_id'], equals(550));

        // Сериал
        expect(xcoll.items[2]['media_type'], equals('tv_show'));
        expect(xcoll.items[2]['external_id'], equals(1399));
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
        expect(restored.version, equals(xcollFormatVersion));
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

      test('должен использовать tvShowPoster для animation с tvShow platformId',
          () async {
        final Uint8List tvBytes = Uint8List.fromList(<int>[7, 8, 9]);
        when(() => mockImageCache.readImageBytes(
              ImageType.tvShowPoster,
              '500',
            )).thenAnswer((_) async => tvBytes);

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
            mediaType: MediaType.animation,
            externalId: 500,
            platformId: 1, // AnimationSource.tvShow
          ),
        ];

        final XcollFile xcoll =
            await sutImages.createFullExport(collection, items, 1);

        expect(xcoll.images.containsKey('tv_show_posters/500'), isTrue);
        expect(
          xcoll.images['tv_show_posters/500'],
          equals(base64Encode(tvBytes)),
        );
      });

      test('должен использовать moviePoster для animation с movie platformId',
          () async {
        final Uint8List movieBytes = Uint8List.fromList(<int>[1, 2, 3]);
        when(() => mockImageCache.readImageBytes(
              ImageType.moviePoster,
              '600',
            )).thenAnswer((_) async => movieBytes);

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
            mediaType: MediaType.animation,
            externalId: 600,
            platformId: 0, // AnimationSource.movie
          ),
        ];

        final XcollFile xcoll =
            await sutImages.createFullExport(collection, items, 1);

        expect(xcoll.images.containsKey('movie_posters/600'), isTrue);
      });
    });

    group('canvas images в full export', () {
      late MockCanvasRepository mockCanvasRepo;
      late MockImageCacheService mockImageCache;

      setUp(() {
        mockCanvasRepo = MockCanvasRepository();
        mockImageCache = MockImageCacheService();

        when(() => mockCanvasRepo.getViewport(any()))
            .thenAnswer((_) async => null);
        when(() => mockCanvasRepo.getConnections(any()))
            .thenAnswer((_) async => <CanvasConnection>[]);
        when(() => mockCanvasRepo.getGameCanvasItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);
      });

      test('должен собрать canvas images из collection canvas', () async {
        final Uint8List canvasBytes = Uint8List.fromList(<int>[10, 20, 30]);
        const String testUrl = 'https://example.com/image.png';

        // FNV-1a hash of testUrl
        int hash = 0x811c9dc5;
        for (int i = 0; i < testUrl.length; i++) {
          hash ^= testUrl.codeUnitAt(i);
          hash = (hash * 0x01000193) & 0xFFFFFFFF;
        }
        final String expectedImageId =
            hash.toRadixString(16).padLeft(8, '0');

        final CanvasItem imageCanvasItem = CanvasItem(
          id: 1,
          collectionId: 1,
          itemType: CanvasItemType.image,
          x: 100.0,
          y: 200.0,
          data: const <String, dynamic>{'url': testUrl},
          createdAt: testDate,
        );

        when(() => mockCanvasRepo.getItems(1))
            .thenAnswer((_) async => <CanvasItem>[imageCanvasItem]);
        when(() => mockImageCache.readImageBytes(
              ImageType.canvasImage,
              expectedImageId,
            )).thenAnswer((_) async => canvasBytes);
        // Cover images — нет элементов
        when(() => mockImageCache.readImageBytes(
              ImageType.gameCover,
              any(),
            )).thenAnswer((_) async => null);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();

        final XcollFile xcoll = await sutImages.createFullExport(
          collection,
          <CollectionItem>[],
          1,
        );

        final String expectedKey = 'canvas_images/$expectedImageId';
        expect(xcoll.images.containsKey(expectedKey), isTrue);
        expect(
          xcoll.images[expectedKey],
          equals(base64Encode(canvasBytes)),
        );
      });

      test('должен собрать canvas images из per-item canvas', () async {
        final Uint8List canvasBytes = Uint8List.fromList(<int>[40, 50, 60]);
        const String testUrl = 'https://example.com/per-item.png';

        int hash = 0x811c9dc5;
        for (int i = 0; i < testUrl.length; i++) {
          hash ^= testUrl.codeUnitAt(i);
          hash = (hash * 0x01000193) & 0xFFFFFFFF;
        }
        final String expectedImageId =
            hash.toRadixString(16).padLeft(8, '0');

        final CanvasItem perItemImageCanvasItem = CanvasItem(
          id: 2,
          collectionId: 1,
          collectionItemId: 10,
          itemType: CanvasItemType.image,
          x: 50.0,
          y: 75.0,
          data: const <String, dynamic>{'url': testUrl},
          createdAt: testDate,
        );

        // Collection canvas — пустой
        when(() => mockCanvasRepo.getItems(1))
            .thenAnswer((_) async => <CanvasItem>[]);

        // Per-item canvas с image
        when(() => mockCanvasRepo.getGameCanvasItems(10))
            .thenAnswer((_) async => <CanvasItem>[perItemImageCanvasItem]);
        when(() => mockCanvasRepo.getGameCanvasConnections(10))
            .thenAnswer((_) async => <CanvasConnection>[]);
        when(() => mockCanvasRepo.getGameCanvasViewport(10))
            .thenAnswer((_) async => null);

        when(() => mockImageCache.readImageBytes(
              ImageType.canvasImage,
              expectedImageId,
            )).thenAnswer((_) async => canvasBytes);
        when(() => mockImageCache.readImageBytes(
              ImageType.gameCover,
              '100',
            )).thenAnswer((_) async => null);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(id: 10, externalId: 100),
        ];

        final XcollFile xcoll =
            await sutImages.createFullExport(collection, items, 1);

        final String expectedKey = 'canvas_images/$expectedImageId';
        expect(xcoll.images.containsKey(expectedKey), isTrue);
      });

      test('должен пропустить не-image canvas items', () async {
        final CanvasItem textCanvasItem = CanvasItem(
          id: 1,
          collectionId: 1,
          itemType: CanvasItemType.text,
          x: 100.0,
          y: 200.0,
          data: const <String, dynamic>{'text': 'Hello'},
          createdAt: testDate,
        );

        when(() => mockCanvasRepo.getItems(1))
            .thenAnswer((_) async => <CanvasItem>[textCanvasItem]);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();

        final XcollFile xcoll = await sutImages.createFullExport(
          collection,
          <CollectionItem>[],
          1,
        );

        // Никаких canvas_images ключей
        final bool hasCanvasImages = xcoll.images.keys
            .any((String k) => k.startsWith('canvas_images/'));
        expect(hasCanvasImages, isFalse);
      });

      test('должен пропустить image canvas item без URL', () async {
        final CanvasItem imageNoUrl = CanvasItem(
          id: 1,
          collectionId: 1,
          itemType: CanvasItemType.image,
          x: 100.0,
          y: 200.0,
          data: const <String, dynamic>{'base64': 'abc123'},
          createdAt: testDate,
        );

        when(() => mockCanvasRepo.getItems(1))
            .thenAnswer((_) async => <CanvasItem>[imageNoUrl]);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();

        final XcollFile xcoll = await sutImages.createFullExport(
          collection,
          <CollectionItem>[],
          1,
        );

        final bool hasCanvasImages = xcoll.images.keys
            .any((String k) => k.startsWith('canvas_images/'));
        expect(hasCanvasImages, isFalse);
      });

      test('должен дедуплицировать одинаковые URL', () async {
        final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
        const String url = 'https://example.com/same.png';

        int hash = 0x811c9dc5;
        for (int i = 0; i < url.length; i++) {
          hash ^= url.codeUnitAt(i);
          hash = (hash * 0x01000193) & 0xFFFFFFFF;
        }
        final String imageId = hash.toRadixString(16).padLeft(8, '0');

        final CanvasItem img1 = CanvasItem(
          id: 1,
          collectionId: 1,
          itemType: CanvasItemType.image,
          x: 0,
          y: 0,
          data: const <String, dynamic>{'url': url},
          createdAt: testDate,
        );
        final CanvasItem img2 = CanvasItem(
          id: 2,
          collectionId: 1,
          itemType: CanvasItemType.image,
          x: 100,
          y: 0,
          data: const <String, dynamic>{'url': url},
          createdAt: testDate,
        );

        when(() => mockCanvasRepo.getItems(1))
            .thenAnswer((_) async => <CanvasItem>[img1, img2]);
        when(() => mockImageCache.readImageBytes(
              ImageType.canvasImage,
              imageId,
            )).thenAnswer((_) async => bytes);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();

        final XcollFile xcoll = await sutImages.createFullExport(
          collection,
          <CollectionItem>[],
          1,
        );

        // Только один ключ canvas_images
        final int canvasImageCount = xcoll.images.keys
            .where((String k) => k.startsWith('canvas_images/'))
            .length;
        expect(canvasImageCount, equals(1));

        // readImageBytes вызван только 1 раз
        verify(() => mockImageCache.readImageBytes(
              ImageType.canvasImage,
              imageId,
            )).called(1);
      });

      test('должен объединить cover images и canvas images', () async {
        final Uint8List coverBytes = Uint8List.fromList(<int>[1, 2, 3]);
        final Uint8List canvasBytes = Uint8List.fromList(<int>[4, 5, 6]);
        const String canvasUrl = 'https://example.com/canvas.png';

        int hash = 0x811c9dc5;
        for (int i = 0; i < canvasUrl.length; i++) {
          hash ^= canvasUrl.codeUnitAt(i);
          hash = (hash * 0x01000193) & 0xFFFFFFFF;
        }
        final String canvasImageId =
            hash.toRadixString(16).padLeft(8, '0');

        final CanvasItem imageCanvasItem = CanvasItem(
          id: 1,
          collectionId: 1,
          itemType: CanvasItemType.image,
          x: 0,
          y: 0,
          data: const <String, dynamic>{'url': canvasUrl},
          createdAt: testDate,
        );

        when(() => mockCanvasRepo.getItems(1))
            .thenAnswer((_) async => <CanvasItem>[imageCanvasItem]);
        when(() => mockCanvasRepo.getGameCanvasItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);

        when(() => mockImageCache.readImageBytes(
              ImageType.gameCover,
              '100',
            )).thenAnswer((_) async => coverBytes);
        when(() => mockImageCache.readImageBytes(
              ImageType.canvasImage,
              canvasImageId,
            )).thenAnswer((_) async => canvasBytes);

        final ExportService sutImages = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(id: 10, externalId: 100),
        ];

        final XcollFile xcoll =
            await sutImages.createFullExport(collection, items, 1);

        // Обложка
        expect(xcoll.images.containsKey('game_covers/100'), isTrue);
        // Canvas image
        expect(
          xcoll.images.containsKey('canvas_images/$canvasImageId'),
          isTrue,
        );
        expect(xcoll.images.length, equals(2));
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
        expect(restoredGame.status, equals(ItemStatus.notStarted));
        expect(restoredGame.authorComment, equals('Best game'));

        final CollectionItem restoredTvShow =
            CollectionItem.fromExport(restored.items[1]);
        expect(restoredTvShow.mediaType, equals(MediaType.tvShow));
        expect(restoredTvShow.currentSeason, equals(0));
        expect(restoredTvShow.currentEpisode, equals(0));
      });
    });

    // ==================== media в full export ====================

    group('media в full export', () {
      late MockCanvasRepository mockCanvasRepo;
      late MockImageCacheService mockImageCache;

      setUp(() {
        mockCanvasRepo = MockCanvasRepository();
        mockImageCache = MockImageCacheService();

        // Стандартные моки для canvas
        when(() => mockCanvasRepo.getViewport(any()))
            .thenAnswer((_) async => null);
        when(() => mockCanvasRepo.getItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);
        when(() => mockCanvasRepo.getConnections(any()))
            .thenAnswer((_) async => <CanvasConnection>[]);
        when(() => mockCanvasRepo.getGameCanvasItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);

        // Стандартные моки для images
        when(() => mockImageCache.readImageBytes(any(), any()))
            .thenAnswer((_) async => null);
      });

      test('должен включить game данные через toDb()', () async {
        final ExportService sutMedia = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        const Game testGame = Game(
          id: 42,
          name: 'Test Game',
          summary: 'A test game',
          genres: <String>['Action', 'RPG'],
          rating: 85.5,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            id: 1,
            mediaType: MediaType.game,
            externalId: 42,
            game: testGame,
          ),
        ];

        final XcollFile xcoll =
            await sutMedia.createFullExport(collection, items, 1);

        expect(xcoll.media, isNotEmpty);
        final List<dynamic> games =
            xcoll.media['games'] as List<dynamic>;
        expect(games.length, equals(1));
        final Map<String, dynamic> gameData =
            games[0] as Map<String, dynamic>;
        expect(gameData['id'], equals(42));
        expect(gameData['name'], equals('Test Game'));
        expect(gameData['genres'], equals('Action|RPG'));
        expect(gameData.containsKey('cached_at'), isFalse);
      });

      test('должен включить movie данные через toDb()', () async {
        final ExportService sutMedia = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        const Movie testMovie = Movie(
          tmdbId: 550,
          title: 'Fight Club',
          overview: 'An insomniac office worker...',
          rating: 8.4,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            id: 1,
            mediaType: MediaType.movie,
            externalId: 550,
            platformId: null,
            movie: testMovie,
          ),
        ];

        final XcollFile xcoll =
            await sutMedia.createFullExport(collection, items, 1);

        expect(xcoll.media, isNotEmpty);
        final List<dynamic> movies =
            xcoll.media['movies'] as List<dynamic>;
        expect(movies.length, equals(1));
        final Map<String, dynamic> movieData =
            movies[0] as Map<String, dynamic>;
        expect(movieData['tmdb_id'], equals(550));
        expect(movieData['title'], equals('Fight Club'));
        expect(movieData.containsKey('cached_at'), isFalse);
      });

      test('должен включить tv_show данные через toDb()', () async {
        final ExportService sutMedia = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        const TvShow testTvShow = TvShow(
          tmdbId: 1399,
          title: 'Game of Thrones',
          totalSeasons: 8,
          totalEpisodes: 73,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            id: 1,
            mediaType: MediaType.tvShow,
            externalId: 1399,
            platformId: null,
            tvShow: testTvShow,
          ),
        ];

        final XcollFile xcoll =
            await sutMedia.createFullExport(collection, items, 1);

        expect(xcoll.media, isNotEmpty);
        final List<dynamic> tvShows =
            xcoll.media['tv_shows'] as List<dynamic>;
        expect(tvShows.length, equals(1));
        final Map<String, dynamic> tvData =
            tvShows[0] as Map<String, dynamic>;
        expect(tvData['tmdb_id'], equals(1399));
        expect(tvData['title'], equals('Game of Thrones'));
        expect(tvData.containsKey('cached_at'), isFalse);
      });

      test('должен дедуплицировать по externalId', () async {
        final ExportService sutMedia = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        const Game testGame = Game(id: 42, name: 'Same Game');

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            id: 1,
            mediaType: MediaType.game,
            externalId: 42,
            game: testGame,
          ),
          createTestItem(
            id: 2,
            mediaType: MediaType.game,
            externalId: 42,
            game: testGame,
          ),
        ];

        final XcollFile xcoll =
            await sutMedia.createFullExport(collection, items, 1);

        final List<dynamic> games =
            xcoll.media['games'] as List<dynamic>;
        expect(games.length, equals(1));
      });

      test('должен поместить animation tvShow в tv_shows', () async {
        final ExportService sutMedia = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        const TvShow animTvShow = TvShow(
          tmdbId: 999,
          title: 'Animated Series',
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            id: 1,
            mediaType: MediaType.animation,
            externalId: 999,
            platformId: AnimationSource.tvShow,
            tvShow: animTvShow,
          ),
        ];

        final XcollFile xcoll =
            await sutMedia.createFullExport(collection, items, 1);

        expect(xcoll.media.containsKey('games'), isFalse);
        expect(xcoll.media.containsKey('movies'), isFalse);
        final List<dynamic> tvShows =
            xcoll.media['tv_shows'] as List<dynamic>;
        expect(tvShows.length, equals(1));
        final Map<String, dynamic> data =
            tvShows[0] as Map<String, dynamic>;
        expect(data['tmdb_id'], equals(999));
      });

      test('должен поместить animation movie в movies', () async {
        final ExportService sutMedia = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        const Movie animMovie = Movie(
          tmdbId: 888,
          title: 'Animated Movie',
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            id: 1,
            mediaType: MediaType.animation,
            externalId: 888,
            platformId: AnimationSource.movie,
            movie: animMovie,
          ),
        ];

        final XcollFile xcoll =
            await sutMedia.createFullExport(collection, items, 1);

        expect(xcoll.media.containsKey('games'), isFalse);
        expect(xcoll.media.containsKey('tv_shows'), isFalse);
        final List<dynamic> movies =
            xcoll.media['movies'] as List<dynamic>;
        expect(movies.length, equals(1));
        final Map<String, dynamic> data =
            movies[0] as Map<String, dynamic>;
        expect(data['tmdb_id'], equals(888));
      });

      test('должен пропустить элементы без joined данных', () async {
        final ExportService sutMedia = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            id: 1,
            mediaType: MediaType.game,
            externalId: 42,
            // game: null — нет joined данных
          ),
        ];

        final XcollFile xcoll =
            await sutMedia.createFullExport(collection, items, 1);

        expect(xcoll.media, isEmpty);
      });

      test('должен вернуть пустой media при пустых items', () async {
        final ExportService sutMedia = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[];

        final XcollFile xcoll =
            await sutMedia.createFullExport(collection, items, 1);

        expect(xcoll.media, isEmpty);
      });

      test('должен собрать смешанные типы медиа', () async {
        final ExportService sutMedia = ExportService(
          canvasRepository: mockCanvasRepo,
          imageCacheService: mockImageCache,
        );

        const Game testGame = Game(id: 42, name: 'Game');
        const Movie testMovie = Movie(tmdbId: 550, title: 'Movie');
        const TvShow testTvShow = TvShow(tmdbId: 1399, title: 'TV');

        final Collection collection = createTestCollection();
        final List<CollectionItem> items = <CollectionItem>[
          createTestItem(
            id: 1,
            mediaType: MediaType.game,
            externalId: 42,
            game: testGame,
          ),
          createTestItem(
            id: 2,
            mediaType: MediaType.movie,
            externalId: 550,
            platformId: null,
            movie: testMovie,
          ),
          createTestItem(
            id: 3,
            mediaType: MediaType.tvShow,
            externalId: 1399,
            platformId: null,
            tvShow: testTvShow,
          ),
        ];

        final XcollFile xcoll =
            await sutMedia.createFullExport(collection, items, 1);

        expect(xcoll.media, isNotEmpty);
        expect((xcoll.media['games'] as List<dynamic>).length, equals(1));
        expect((xcoll.media['movies'] as List<dynamic>).length, equals(1));
        expect(
            (xcoll.media['tv_shows'] as List<dynamic>).length, equals(1));
      });
    });
  });
}
