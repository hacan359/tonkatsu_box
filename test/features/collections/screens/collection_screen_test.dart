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
import 'package:xerabora/shared/widgets/media_poster_card.dart';

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

    testWidgets('не должен показывать header со статистикой',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await pumpScreen(tester);

      // Header удалён — нет текста со статистикой
      expect(find.textContaining('5 items'), findsNothing);
      // Нет прогресс-бара
      expect(find.byType(LinearProgressIndicator), findsNothing);
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

      testWidgets('grid mode должен показывать MediaPosterCard',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на grid
        await tester.tap(find.byIcon(Icons.grid_view));
        await pumpScreen(tester);

        expect(find.byType(MediaPosterCard), findsWidgets);
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('list mode не должен содержать MediaPosterCard',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // По умолчанию list mode
        expect(find.byType(MediaPosterCard), findsNothing);
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

    group('фильтр по типу (dropdown)', () {
      /// Открывает dropdown фильтра типа и выбирает пункт.
      Future<void> selectMediaFilter(
        WidgetTester tester,
        String itemText,
      ) async {
        // Тапаем по кнопке фильтра (содержит иконку filter_list)
        await tester.tap(find.byTooltip('Filter by type'));
        await tester.pumpAndSettle();
        // Тапаем по пункту меню
        await tester.tap(find.text(itemText).last);
        await pumpScreen(tester);
      }

      testWidgets('должен показывать dropdown с All по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Кнопка фильтра показывает "All"
        expect(find.text('All'), findsOneWidget);
      });

      testWidgets('dropdown должен содержать все типы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Открываем dropdown
        await tester.tap(find.byTooltip('Filter by type'));
        await tester.pumpAndSettle();

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

        await selectMediaFilter(tester, 'Games (1)');

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('Movies фильтр должен показывать только фильмы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await selectMediaFilter(tester, 'Movies (1)');

        expect(find.text('Zelda'), findsNothing);
        expect(find.text('Inception'), findsOneWidget);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('TV Shows фильтр должен показывать только сериалы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await selectMediaFilter(tester, 'TV Shows (1)');

        expect(find.text('Zelda'), findsNothing);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsOneWidget);
      });

      testWidgets('All должен показывать все элементы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Сначала выбираем Games
        await selectMediaFilter(tester, 'Games (1)');
        expect(find.text('Inception'), findsNothing);

        // Затем All — при открытом dropdown "All (5)" содержит checkmark
        await tester.tap(find.byTooltip('Filter by type'));
        await tester.pumpAndSettle();
        // Тапаем по "All (5)" в popup
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

        await selectMediaFilter(tester, 'Animation (2)');

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

        // Проверяем что MediaPosterCard рендерится
        expect(find.byType(MediaPosterCard), findsOneWidget);

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

        // Проверяем что MediaPosterCard рендерится
        expect(find.byType(MediaPosterCard), findsOneWidget);

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

        // Фильтр Games
        await tester.tap(find.byTooltip('Filter by type'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Games (1)').last);
        await pumpScreen(tester);

        // + поиск "Zel"
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
        await tester.tap(find.byTooltip('Filter by type'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Movies (1)').last);
        await pumpScreen(tester);

        // Должен быть 1 MediaPosterCard (Inception)
        expect(find.byType(MediaPosterCard), findsOneWidget);
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

    group('export в PopupMenu', () {
      testWidgets('должен показывать Export в трёхточечном меню',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Открываем PopupMenu (последний PopupMenuButton<String> — в AppBar actions)
        await tester.tap(find.byType(PopupMenuButton<String>).last);
        await tester.pumpAndSettle();

        expect(find.text('Export'), findsOneWidget);
      });

      testWidgets('должен показывать Rename в трёхточечном меню для editable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Открываем PopupMenu
        await tester.tap(find.byType(PopupMenuButton<String>).last);
        await tester.pumpAndSettle();

        expect(find.text('Rename'), findsOneWidget);
      });
    });

    group('фильтры при пустой коллекции', () {
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

      testWidgets('должен скрывать FilterRow при 0 элементах',
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

        // FilterRow скрыта — нет кнопки фильтра типа
        expect(find.byTooltip('Filter by type'), findsNothing);
        // Нет поля поиска
        expect(find.byType(TextField), findsNothing);
        // Нет кнопки сортировки
        expect(find.byTooltip('Sort'), findsNothing);
      });
    });

    group('sort dropdown', () {
      testWidgets('должен показывать кнопку сортировки',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.byTooltip('Sort'), findsOneWidget);
      });

      testWidgets('должен содержать все режимы сортировки',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await tester.tap(find.byTooltip('Sort'));
        await tester.pumpAndSettle();

        expect(find.text('Manual'), findsOneWidget);
        expect(find.text('Date Added'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Name'), findsOneWidget);
      });

      testWidgets('должен содержать пункт Ascending/Descending',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await tester.tap(find.byTooltip('Sort'));
        await tester.pumpAndSettle();

        // По умолчанию ascending
        expect(find.text('Ascending'), findsOneWidget);
      });

      testWidgets('должен показывать shortLabel на кнопке',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // По умолчанию addedDate → shortLabel "Date"
        expect(find.text('Date'), findsOneWidget);
      });

      testWidgets('должен показывать иконку направления сортировки',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // По умолчанию ascending — стрелка вверх
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
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

        // Переключаемся на Canvas mode через IconButton
        await tester.tap(find.byTooltip('Switch to Board'));
        await pumpScreen(tester);

        // Замок виден (collection.isEditable = true для own)
        expect(find.byTooltip('Lock board'), findsOneWidget);
        expect(find.byIcon(Icons.lock_open), findsOneWidget);
      });

      testWidgets('должен показывать замок для imported коллекции',
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

        // Переключаемся на Canvas mode через IconButton
        await tester.tap(find.byTooltip('Switch to Board'));
        await pumpScreen(tester);

        // Замок виден (imported теперь editable)
        expect(find.byTooltip('Lock board'), findsOneWidget);
      });

      testWidgets('должен переключать состояние замка',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Переключаемся на Canvas mode через IconButton
        await tester.tap(find.byTooltip('Switch to Board'));
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
