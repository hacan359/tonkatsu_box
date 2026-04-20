// Тесты для CollectionScreen (grid/list mode, фильтры, поиск, view mode persistence).

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
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/navigation/search_providers.dart';
import 'package:xerabora/shared/widgets/chevron_filter_bar.dart';
import 'package:xerabora/shared/widgets/media_poster_card.dart';

import '../../../helpers/test_helpers.dart';

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
    registerAllFallbacks();
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
    String searchQuery = '',
    CollectionStats stats = testStats,
  }) {
    return ProviderScope(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        imageCacheServiceProvider.overrideWithValue(mockCache),
        sharedPreferencesProvider.overrideWithValue(overridePrefs ?? prefs),
        collectionStatsProvider(collectionId)
            .overrideWith((Ref ref) async => stats),
        collectionsSearchQueryProvider.overrideWith((Ref ref) => searchQuery),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: CollectionScreen(collectionId: collectionId),
        ),
      ),
    );
  }

  group('CollectionScreen', () {
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

    group('grid mode (по умолчанию)', () {
      testWidgets('grid mode должен показывать MediaPosterCard',
          (WidgetTester tester) async {
        // По умолчанию grid mode (SharedPreferences пустые → default true)
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.byType(MediaPosterCard), findsWidgets);
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('table mode не должен содержать MediaPosterCard',
          (WidgetTester tester) async {
        // Задаём table mode через SharedPreferences
        final SharedPreferences tablePrefs =
            await SharedPreferences.getInstance();
        await tablePrefs.setBool(
          '${SettingsKeys.collectionViewModePrefix}1',
          false, // grid = false
        );
        await tablePrefs.setBool(
          '${SettingsKeys.collectionTableModePrefix}1',
          true, // table = true
        );

        await tester.pumpWidget(createWidget(overridePrefs: tablePrefs));
        await pumpScreen(tester);

        expect(find.byType(MediaPosterCard), findsNothing);
      });
    });

    group('фильтр по типу (chevron-сегменты)', () {
      /// Тапает на chevron-сегмент типа медиа по тексту.
      Future<void> selectMediaSegment(
        WidgetTester tester,
        String segmentText,
      ) async {
        await tester.tap(find.text(segmentText).first);
        await pumpScreen(tester);
      }

      testWidgets('Games фильтр должен показывать только игры',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await selectMediaSegment(tester, 'Games (1)');

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('Movies фильтр должен показывать только фильмы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await selectMediaSegment(tester, 'Movies (1)');

        expect(find.text('Zelda'), findsNothing);
        expect(find.text('Inception'), findsOneWidget);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('TV Shows фильтр должен показывать только сериалы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await selectMediaSegment(tester, 'TV Shows (1)');

        expect(find.text('Zelda'), findsNothing);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsOneWidget);
      });

      testWidgets('повторный тап на Games снимает фильтр и показывает всё',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Выбираем Games
        await selectMediaSegment(tester, 'Games (1)');
        expect(find.text('Inception'), findsNothing);

        // Повторный тап на Games снимает фильтр
        await selectMediaSegment(tester, 'Games (1)');

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsOneWidget);
        expect(find.text('Breaking Bad'), findsOneWidget);
      });

      testWidgets('Animation фильтр должен показывать только анимацию',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        await selectMediaSegment(tester, 'Animation (2)');

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

        expect(find.byType(MediaPosterCard), findsOneWidget);

        verify(() => mockCache.getImageUri(
              type: ImageType.moviePoster,
              imageId: '401',
              remoteUrl: any(named: 'remoteUrl'),
            )).called(greaterThan(0));
      });

      testWidgets('animation tvShow должен использовать tvShowPoster ImageType',
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

        expect(find.byType(MediaPosterCard), findsOneWidget);

        verify(() => mockCache.getImageUri(
              type: ImageType.tvShowPoster,
              imageId: '501',
              remoteUrl: any(named: 'remoteUrl'),
            )).called(greaterThan(0));
      });
    });

    group('animation items в list mode', () {
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

        verify(() => mockCache.getImageUri(
              type: ImageType.tvShowPoster,
              imageId: '501',
              remoteUrl: any(named: 'remoteUrl'),
            )).called(greaterThan(0));
      });
    });

    group('поиск по имени (через collectionsSearchQueryProvider)', () {
      testWidgets('должен фильтровать по имени',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(searchQuery: 'Zelda'));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('поиск должен быть case-insensitive',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(searchQuery: 'zelda'));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
      });

      testWidgets('пустой поиск должен показывать все элементы',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(searchQuery: ''));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsOneWidget);
        expect(find.text('Breaking Bad'), findsOneWidget);
      });

      testWidgets('должен находить по тексту в userComment (заметки)',
          (WidgetTester tester) async {
        final List<CollectionItem> itemsWithNotes = <CollectionItem>[
          testItems[0].copyWith(
            userComment: 'настоящий шедевр геймдева',
          ), // Zelda
          testItems[1], // Inception — без заметки
          testItems[2], // Breaking Bad — без заметки
        ];
        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => itemsWithNotes);

        await tester.pumpWidget(createWidget(searchQuery: 'шедевр'));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('должен находить по тексту в authorComment (рецензия)',
          (WidgetTester tester) async {
        final List<CollectionItem> itemsWithReviews = <CollectionItem>[
          testItems[0], // Zelda — без рецензии
          testItems[1].copyWith(
            authorComment: 'переоценённый проходняк',
          ), // Inception
          testItems[2], // Breaking Bad — без рецензии
        ];
        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => itemsWithReviews);

        await tester.pumpWidget(createWidget(searchQuery: 'проходняк'));
        await pumpScreen(tester);

        expect(find.text('Inception'), findsOneWidget);
        expect(find.text('Zelda'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('поиск по заметкам должен быть case-insensitive',
          (WidgetTester tester) async {
        final List<CollectionItem> itemsWithNotes = <CollectionItem>[
          testItems[0].copyWith(userComment: 'Настоящий ШЕДЕВР'),
          testItems[1],
        ];
        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => itemsWithNotes);

        await tester.pumpWidget(createWidget(searchQuery: 'шедевр'));
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsNothing);
      });
    });

    group('комбинированные фильтры', () {
      testWidgets('фильтр типа + поиск должны работать вместе',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(searchQuery: 'Zel'));
        await pumpScreen(tester);

        // Фильтр Games — тап на chevron-сегмент
        await tester.tap(find.text('Games (1)').first);
        await pumpScreen(tester);

        expect(find.text('Zelda'), findsOneWidget);
        expect(find.text('Inception'), findsNothing);
        expect(find.text('Breaking Bad'), findsNothing);
      });

      testWidgets('фильтры должны работать в grid mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Фильтр Movies — тап на chevron-сегмент
        await tester.tap(find.text('Movies (1)').first);
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

        expect(find.text('Collection not found'), findsWidgets);
      });
    });

    group('сохранение режима отображения (grid/table)', () {
      testWidgets('должен загрузить grid mode из SharedPreferences',
          (WidgetTester tester) async {
        await prefs.setBool(
          '${SettingsKeys.collectionViewModePrefix}1',
          true,
        );

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        // Grid mode загружен: GridView отображается
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('должен загрузить grid mode по умолчанию',
          (WidgetTester tester) async {
        // SharedPreferences пусты — default true (grid mode)
        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('разные коллекции сохраняют режим независимо',
          (WidgetTester tester) async {
        await prefs.setBool(
          '${SettingsKeys.collectionViewModePrefix}1',
          true,
        );

        await tester.pumpWidget(createWidget());
        await pumpScreen(tester);

        expect(find.byType(GridView), findsOneWidget);

        final bool? saved2 = prefs.getBool(
          '${SettingsKeys.collectionViewModePrefix}2',
        );
        expect(saved2, isNull);
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

      testWidgets('должен скрывать FilterBar при 0 элементах',
          (WidgetTester tester) async {
        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => const <CollectionItem>[]);

        await tester.pumpWidget(createWidget(stats: zeroStats));
        await pumpScreen(tester);

        // FilterBar скрыта — нет chevron-сегментов типов
        expect(find.byType(ChevronSegment), findsNothing);
      });
    });
  });
}
