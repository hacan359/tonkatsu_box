// Тесты для CollectionScreen (grid/list mode, canvas lock, view mode persistence).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/screens/collection_screen.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/widgets/poster_card.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockImageCacheService extends Mock implements ImageCacheService {}

void main() {
  final DateTime testDate = DateTime(2024, 1, 15);
  late MockCollectionRepository mockRepo;
  late MockImageCacheService mockCache;
  late SharedPreferences prefs;

  final Collection testCollection = Collection(
    id: 1,
    name: 'Test Collection',
    author: 'Test Author',
    type: CollectionType.own,
    createdAt: testDate,
  );

  const CollectionStats testStats = CollectionStats(
    total: 5,
    completed: 2,
    inProgress: 2,
    notStarted: 1,
    dropped: 0,
    planned: 0,
    gameCount: 1,
    movieCount: 1,
    tvShowCount: 1,
    animationCount: 2,
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
      mediaType: MediaType.movie,
      externalId: 201,
      status: ItemStatus.inProgress,
      addedAt: testDate,
      movie: const Movie(
        tmdbId: 201,
        title: 'Inception',
        posterUrl: 'https://example.com/inception.jpg',
        rating: 8.8,
        releaseYear: 2010,
      ),
    ),
    CollectionItem(
      id: 3,
      collectionId: 1,
      mediaType: MediaType.tvShow,
      externalId: 301,
      status: ItemStatus.notStarted,
      addedAt: testDate,
      tvShow: const TvShow(
        tmdbId: 301,
        title: 'Breaking Bad',
        posterUrl: 'https://example.com/bb.jpg',
        rating: 9.5,
        firstAirYear: 2008,
      ),
    ),
    CollectionItem(
      id: 4,
      collectionId: 1,
      mediaType: MediaType.animation,
      externalId: 401,
      platformId: AnimationSource.movie,
      status: ItemStatus.completed,
      addedAt: testDate,
      movie: const Movie(
        tmdbId: 401,
        title: 'Spirited Away',
        posterUrl: 'https://example.com/spirited.jpg',
        rating: 8.6,
        releaseYear: 2001,
      ),
    ),
    CollectionItem(
      id: 5,
      collectionId: 1,
      mediaType: MediaType.animation,
      externalId: 501,
      platformId: AnimationSource.tvShow,
      status: ItemStatus.inProgress,
      addedAt: testDate,
      tvShow: const TvShow(
        tmdbId: 501,
        title: 'Attack on Titan',
        posterUrl: 'https://example.com/aot.jpg',
        rating: 8.9,
        firstAirYear: 2013,
      ),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(ImageType.platformLogo);
    registerFallbackValue(MediaType.game);
    registerFallbackValue(ItemStatus.notStarted);
  });

  setUp(() async {
    mockRepo = MockCollectionRepository();
    mockCache = MockImageCacheService();

    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();

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

  Widget createWidget({
    int collectionId = 1,
    SharedPreferences? overridePrefs,
  }) {
    return ProviderScope(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        imageCacheServiceProvider.overrideWithValue(mockCache),
        sharedPreferencesProvider.overrideWithValue(overridePrefs ?? prefs),
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

      expect(find.textContaining('5 items'), findsOneWidget);
    });

    testWidgets('должен показывать элементы коллекции',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await pumpScreen(tester);

      expect(find.text('Zelda'), findsOneWidget);
      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsOneWidget);
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

    group('фильтр по типу', () {
      testWidgets('должен показывать чипы фильтра',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.text('All (5)'), findsOneWidget);
        expect(find.text('Games (1)'), findsOneWidget);
        expect(find.text('Movies (1)'), findsOneWidget);
        expect(find.text('TV Shows (1)'), findsOneWidget);
        expect(find.text('Animation (2)'), findsOneWidget);
      });

      testWidgets('Games фильтр должен показывать только игры',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await tester.tap(find.text('Games (1)'));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('Movies фильтр должен показывать только фильмы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await tester.tap(find.text('Movies (1)'));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsNothing);
        expect(find.text('Inception'), findsOneWidget);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('TV Shows фильтр должен показывать только сериалы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await tester.tap(find.text('TV Shows (1)'));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsNothing);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsOneWidget);
      });

      testWidgets('All должен показывать все элементы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Сначала выбираем Games
        await tester.tap(find.text('Games (1)'));
        await pumpScreen(tester);
        expect(find.text('Inception'), findsNothing);

        // Затем All
        await tester.tap(find.text('All (5)'));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsOneWidget);
        expect(find.text('Breaking Bad'), findsOneWidget);
      });

      testWidgets('Animation фильтр должен показывать только анимацию',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await tester.tap(find.text('Animation (2)'));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsNothing);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
        expect(find.text('Spirited Away'), findsOneWidget);
        expect(find.text('Attack on Titan'), findsOneWidget);
      });
    });

    group('animation items в grid mode', () {
      testWidgets('animation movie должен использовать moviePoster ImageType',
          (WidgetTester tester) async {
        // Элементы: только animation movie
        final List<CollectionItem> animMovieItems = <CollectionItem>[
          CollectionItem(
            id: 4,
            collectionId: 1,
            mediaType: MediaType.animation,
            externalId: 401,
            platformId: AnimationSource.movie,
            status: ItemStatus.completed,
            addedAt: testDate,
            movie: const Movie(
              tmdbId: 401,
              title: 'Spirited Away',
              posterUrl: 'https://example.com/spirited.jpg',
              rating: 8.6,
              releaseYear: 2001,
            ),
          ),
        ];

        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => animMovieItems);

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на grid
        await tester.tap(find.byIcon(Icons.grid_view));
        await pumpScreen(tester);

        // Проверяем что PosterCard рендерится
        expect(find.byType(PosterCard), findsOneWidget);

        // Проверяем что getImageUri вызван с moviePoster
        verify(() => mockCache.getImageUri(
              type: ImageType.moviePoster,
              imageId: '401',
              remoteUrl: any(named: 'remoteUrl'),
            )).called(greaterThan(0));
      });

      testWidgets('animation tvShow должен использовать tvShowPoster ImageType',
          (WidgetTester tester) async {
        // Элементы: только animation tvShow
        final List<CollectionItem> animTvItems = <CollectionItem>[
          CollectionItem(
            id: 5,
            collectionId: 1,
            mediaType: MediaType.animation,
            externalId: 501,
            platformId: AnimationSource.tvShow,
            status: ItemStatus.inProgress,
            addedAt: testDate,
            tvShow: const TvShow(
              tmdbId: 501,
              title: 'Attack on Titan',
              posterUrl: 'https://example.com/aot.jpg',
              rating: 8.9,
              firstAirYear: 2013,
            ),
          ),
        ];

        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => animTvItems);

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на grid
        await tester.tap(find.byIcon(Icons.grid_view));
        await pumpScreen(tester);

        // Проверяем что PosterCard рендерится
        expect(find.byType(PosterCard), findsOneWidget);

        // Проверяем что getImageUri вызван с tvShowPoster
        verify(() => mockCache.getImageUri(
              type: ImageType.tvShowPoster,
              imageId: '501',
              remoteUrl: any(named: 'remoteUrl'),
            )).called(greaterThan(0));
      });
    });

    group('animation items в list mode (default)', () {
      testWidgets(
          'animation movie в list mode должен использовать moviePoster ImageType',
          (WidgetTester tester) async {
        final List<CollectionItem> animMovieItems = <CollectionItem>[
          CollectionItem(
            id: 4,
            collectionId: 1,
            mediaType: MediaType.animation,
            externalId: 401,
            platformId: AnimationSource.movie,
            status: ItemStatus.completed,
            addedAt: testDate,
            movie: const Movie(
              tmdbId: 401,
              title: 'Spirited Away',
              posterUrl: 'https://example.com/spirited.jpg',
              rating: 8.6,
              releaseYear: 2001,
            ),
          ),
        ];

        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => animMovieItems);

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // List mode — по умолчанию, не переключаемся на grid
        // Проверяем что getImageUri вызван с moviePoster
        verify(() => mockCache.getImageUri(
              type: ImageType.moviePoster,
              imageId: '401',
              remoteUrl: any(named: 'remoteUrl'),
            )).called(greaterThan(0));
      });

      testWidgets(
          'animation tvShow в list mode должен использовать tvShowPoster ImageType',
          (WidgetTester tester) async {
        final List<CollectionItem> animTvItems = <CollectionItem>[
          CollectionItem(
            id: 5,
            collectionId: 1,
            mediaType: MediaType.animation,
            externalId: 501,
            platformId: AnimationSource.tvShow,
            status: ItemStatus.inProgress,
            addedAt: testDate,
            tvShow: const TvShow(
              tmdbId: 501,
              title: 'Attack on Titan',
              posterUrl: 'https://example.com/aot.jpg',
              rating: 8.9,
              firstAirYear: 2013,
            ),
          ),
        ];

        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => animTvItems);

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // List mode — по умолчанию
        // Проверяем что getImageUri вызван с tvShowPoster (не moviePoster!)
        verify(() => mockCache.getImageUri(
              type: ImageType.tvShowPoster,
              imageId: '501',
              remoteUrl: any(named: 'remoteUrl'),
            )).called(greaterThan(0));
      });
    });

    group('поиск по имени', () {
      testWidgets('должен показывать поле поиска',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('должен фильтровать по имени',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await tester.enterText(find.byType(TextField), 'Zelda');
        await pumpScreen(tester);

        // Zelda: 2 вхождения (TextField + карточка)
        expect(find.text('Zelda'), findsNWidgets(2));
        // Остальные элементы отфильтрованы
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('поиск должен быть case-insensitive',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await tester.enterText(find.byType(TextField), 'zelda');
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
      });

      testWidgets('кнопка очистки должна сбрасывать поиск',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Вводим текст
        await tester.enterText(find.byType(TextField), 'Zelda');
        await pumpScreen(tester);
        expect(find.text('Inception'), findsNothing);

        // Очищаем
        await tester.tap(find.byIcon(Icons.close));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsOneWidget);
        expect(find.text('Breaking Bad'), findsOneWidget);
      });
    });

    group('комбинированные фильтры', () {
      testWidgets('фильтр типа + поиск должны работать вместе',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Фильтр Games + поиск "Zel"
        await tester.tap(find.text('Games (1)'));
        await pumpScreen(tester);
        await tester.enterText(find.byType(TextField), 'Zel');
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('фильтры должны работать в grid mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на grid
        await tester.tap(find.byIcon(Icons.grid_view));
        await pumpScreen(tester);

        // Фильтр Movies
        await tester.tap(find.text('Movies (1)'));
        await pumpScreen(tester);

        // Должен быть 1 PosterCard (Inception)
        expect(find.byType(PosterCard), findsOneWidget);
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
        when(() => mockRepo.getItemsWithData(
              99,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => const <CollectionItem>[]);
        when(() => mockRepo.getStats(99))
            .thenAnswer((_) async => const CollectionStats(
                  total: 0,
                  completed: 0,
                  inProgress: 0,
                  notStarted: 0,
                  dropped: 0,
                  planned: 0,
                ));

        await tester.pumpWidget(createWidget(collectionId: 99));
        await pumpScreen(tester);

        expect(find.text('Collection not found'), findsOneWidget);
      });
    });

    group('Add Items кнопка', () {
      testWidgets('должен показывать кнопку Add Items в AppBar для editable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.byTooltip('Add Items'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('сохранение режима отображения (grid/list)', () {
      testWidgets('должен загрузить grid mode из SharedPreferences',
          (WidgetTester tester) async {
        // Сохраняем grid mode = true для коллекции 1
        await prefs.setBool(
          '${SettingsKeys.collectionViewModePrefix}1',
          true,
        );

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Grid mode загружен: иконка view_list (обратное переключение)
        expect(find.byIcon(Icons.view_list), findsOneWidget);
        expect(find.byIcon(Icons.grid_view), findsNothing);
      });

      testWidgets('должен загрузить list mode по умолчанию',
          (WidgetTester tester) async {
        // SharedPreferences пусты — default false (list mode)
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // List mode по умолчанию: иконка grid_view
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
      });

      testWidgets('должен сохранять grid mode в SharedPreferences при toggle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на grid
        await tester.tap(find.byIcon(Icons.grid_view));
        await pumpScreen(tester);

        // Проверяем сохранение в SharedPreferences
        final bool? saved = prefs.getBool(
          '${SettingsKeys.collectionViewModePrefix}1',
        );
        expect(saved, isTrue);
      });

      testWidgets('должен сохранять list mode при обратном toggle',
          (WidgetTester tester) async {
        // Начинаем с grid mode
        await prefs.setBool(
          '${SettingsKeys.collectionViewModePrefix}1',
          true,
        );

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся обратно на list
        await tester.tap(find.byIcon(Icons.view_list));
        await pumpScreen(tester);

        // Проверяем сохранение в SharedPreferences
        final bool? saved = prefs.getBool(
          '${SettingsKeys.collectionViewModePrefix}1',
        );
        expect(saved, isFalse);
      });

      testWidgets('разные коллекции сохраняют режим независимо',
          (WidgetTester tester) async {
        // Коллекция 1 — grid, коллекция 2 — list (по умолчанию)
        await prefs.setBool(
          '${SettingsKeys.collectionViewModePrefix}1',
          true,
        );

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Коллекция 1 в grid mode
        expect(find.byIcon(Icons.view_list), findsOneWidget);

        // Проверяем что для коллекции 2 ключ не установлен
        final bool? saved2 = prefs.getBool(
          '${SettingsKeys.collectionViewModePrefix}2',
        );
        expect(saved2, isNull);
      });
    });

    group('export кнопка', () {
      testWidgets('должен показывать кнопку Export в AppBar',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.byTooltip('Export'), findsOneWidget);
        expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);
      });
    });

    group('filter chips с нулевыми каунтами', () {
      const CollectionStats zeroStats = CollectionStats(
        total: 0,
        completed: 0,
        inProgress: 0,
        notStarted: 0,
        dropped: 0,
        planned: 0,
        gameCount: 0,
        movieCount: 0,
        tvShowCount: 0,
        animationCount: 0,
      );

      testWidgets('должен показывать label без каунта при 0 элементах',
          (WidgetTester tester) async {
        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => const <CollectionItem>[]);

        await tester.pumpWidget(ProviderScope(
          overrides: <Override>[
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            imageCacheServiceProvider.overrideWithValue(mockCache),
            sharedPreferencesProvider.overrideWithValue(prefs),
            collectionStatsProvider(1)
                .overrideWith((Ref ref) async => zeroStats),
          ],
          child: const MaterialApp(
            home: CollectionScreen(collectionId: 1),
          ),
        ));
        await pumpScreen(tester);

        // Без каунта — не "All (0)", а просто "All"
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Games'), findsOneWidget);
        expect(find.text('Movies'), findsOneWidget);
        expect(find.text('TV Shows'), findsOneWidget);
        expect(find.text('Animation'), findsOneWidget);
      });
    });

    group('замок канваса', () {
      testWidgets('не должен показывать замок в List mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // В list mode замок не виден
        expect(find.byTooltip('Lock board'), findsNothing);
        expect(find.byTooltip('Unlock board'), findsNothing);
      });

      testWidgets('должен показывать замок при переключении на Canvas mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на Canvas mode
        await tester.tap(find.text('Board'));
        await pumpScreen(tester);

        // Замок виден (collection.isEditable = true для own)
        expect(find.byTooltip('Lock board'), findsOneWidget);
        expect(find.byIcon(Icons.lock_open), findsOneWidget);
      });

      testWidgets('не должен показывать замок для imported коллекции',
          (WidgetTester tester) async {
        final Collection importedCollection = Collection(
          id: 1,
          name: 'Imported Collection',
          author: 'Other',
          type: CollectionType.imported,
          createdAt: testDate,
        );
        when(() => mockRepo.getById(1))
            .thenAnswer((_) async => importedCollection);

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на Canvas mode
        await tester.tap(find.text('Board'));
        await pumpScreen(tester);

        // Замок не виден (imported — не editable)
        expect(find.byTooltip('Lock board'), findsNothing);
        expect(find.byTooltip('Unlock board'), findsNothing);
      });

      testWidgets('должен переключать состояние замка',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на Canvas mode
        await tester.tap(find.text('Board'));
        await pumpScreen(tester);

        // Нажимаем замок (lock_open → lock)
        await tester.tap(find.byTooltip('Lock board'));
        await pumpScreen(tester);

        expect(find.byIcon(Icons.lock), findsOneWidget);
        expect(find.byTooltip('Unlock board'), findsOneWidget);

        // Нажимаем замок (lock → lock_open)
        await tester.tap(find.byTooltip('Unlock board'));
        await pumpScreen(tester);

        expect(find.byIcon(Icons.lock_open), findsOneWidget);
        expect(find.byTooltip('Lock board'), findsOneWidget);
      });
    });
  });
}
