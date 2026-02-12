// Тесты для CollectionScreen (grid/list mode).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/screens/collection_screen.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/widgets/poster_card.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockImageCacheService extends Mock implements ImageCacheService {}

void main() {
  final DateTime testDate = DateTime(2024, 1, 15);
  late MockCollectionRepository mockRepo;
  late MockImageCacheService mockCache;

  final Collection testCollection = Collection(
    id: 1,
    name: 'Test Collection',
    author: 'Test Author',
    type: CollectionType.own,
    createdAt: testDate,
  );

  const CollectionStats testStats = CollectionStats(
    total: 3,
    completed: 1,
    playing: 1,
    notStarted: 1,
    dropped: 0,
    planned: 0,
  );

  final List<CollectionItem> testItems = <CollectionItem>[
    CollectionItem(
      id: 1,
      collectionId: 1,
      mediaType: MediaType.game,
      externalId: 101,
      status: ItemStatus.completed,
      addedAt: testDate,
      game: const Game(
        id: 101,
        name: 'Zelda',
        coverUrl: 'https://example.com/zelda.jpg',
        rating: 95,
      ),
    ),
    CollectionItem(
      id: 2,
      collectionId: 1,
      mediaType: MediaType.game,
      externalId: 102,
      status: ItemStatus.inProgress,
      addedAt: testDate,
      game: const Game(
        id: 102,
        name: 'Mario',
        coverUrl: 'https://example.com/mario.jpg',
        rating: 85,
      ),
    ),
    CollectionItem(
      id: 3,
      collectionId: 1,
      mediaType: MediaType.game,
      externalId: 103,
      status: ItemStatus.notStarted,
      addedAt: testDate,
      game: const Game(
        id: 103,
        name: 'Metroid',
      ),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(ImageType.platformLogo);
    registerFallbackValue(MediaType.game);
    registerFallbackValue(ItemStatus.notStarted);
  });

  setUp(() {
    mockRepo = MockCollectionRepository();
    mockCache = MockImageCacheService();

    when(() => mockRepo.getById(1)).thenAnswer((_) async => testCollection);
    when(() => mockRepo.getItemsWithData(
          1,
          mediaType: any(named: 'mediaType'),
        )).thenAnswer((_) async => testItems);
    when(() => mockRepo.getStats(1)).thenAnswer((_) async => testStats);

    when(() => mockCache.getImageUri(
          type: any(named: 'type'),
          imageId: any(named: 'imageId'),
          remoteUrl: any(named: 'remoteUrl'),
        )).thenAnswer((_) async => const ImageResult(
          uri: 'https://example.com/cached.jpg',
          isLocal: false,
          isMissing: false,
        ));
  });

  /// Прокачивает виджет достаточно фреймов для загрузки данных.
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  Widget createWidget({int collectionId = 1}) {
    return ProviderScope(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        imageCacheServiceProvider.overrideWithValue(mockCache),
        collectionStatsProvider(collectionId)
            .overrideWith((Ref ref) async => testStats),
      ],
      child: MaterialApp(
        home: CollectionScreen(collectionId: collectionId),
      ),
    );
  }

  group('CollectionScreen', () {
    testWidgets('должен показывать название коллекции',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await pumpScreen(tester);

      expect(find.text('Test Collection'), findsOneWidget);
    });

    testWidgets('должен показывать статистику',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await pumpScreen(tester);

      expect(find.textContaining('3 items'), findsOneWidget);
    });

    testWidgets('должен показывать элементы коллекции',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await pumpScreen(tester);

      expect(find.text('Zelda'), findsOneWidget);
      expect(find.text('Mario'), findsOneWidget);
      expect(find.text('Metroid'), findsOneWidget);
    });

    group('grid/list toggle', () {
      testWidgets('должен показывать кнопку переключения',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // По умолчанию list mode — иконка grid_view для переключения
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
      });

      testWidgets('должен переключаться на grid при нажатии',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Нажимаем на toggle
        await tester.tap(find.byIcon(Icons.grid_view));
        await pumpScreen(tester);

        // Теперь иконка view_list (для обратного переключения)
        expect(find.byIcon(Icons.view_list), findsOneWidget);
      });

      testWidgets('grid mode должен показывать PosterCard',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на grid
        await tester.tap(find.byIcon(Icons.grid_view));
        await pumpScreen(tester);

        expect(find.byType(PosterCard), findsWidgets);
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('list mode не должен содержать PosterCard',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // По умолчанию list mode
        expect(find.byType(PosterCard), findsNothing);
      });

      testWidgets('должен переключаться обратно на list',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Grid
        await tester.tap(find.byIcon(Icons.grid_view));
        await pumpScreen(tester);
        expect(find.byType(GridView), findsOneWidget);

        // Обратно на list
        await tester.tap(find.byIcon(Icons.view_list));
        await pumpScreen(tester);
        expect(find.byType(GridView), findsNothing);
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
      });
    });

    group('пустая коллекция', () {
      testWidgets('должен показывать empty state',
          (WidgetTester tester) async {
        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => const <CollectionItem>[]);

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.text('No Items Yet'), findsOneWidget);
      });
    });

    group('collection not found', () {
      testWidgets('должен показывать сообщение об ошибке',
          (WidgetTester tester) async {
        when(() => mockRepo.getById(99)).thenAnswer((_) async => null);

        await tester.pumpWidget(createWidget(collectionId: 99));
        await pumpScreen(tester);

        expect(find.text('Collection not found'), findsOneWidget);
      });
    });

    group('FAB', () {
      testWidgets('должен показывать FAB Add Items для editable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.text('Add Items'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });
  });
}
