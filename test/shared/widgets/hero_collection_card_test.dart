import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для HeroCollectionCard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/navigation/navigation_shell.dart';
import 'package:xerabora/shared/widgets/hero_collection_card.dart';

class MockImageCacheService extends Mock implements ImageCacheService {}
class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);
  late MockImageCacheService mockCacheService;
  late MockCollectionRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(ImageType.platformLogo);
    registerFallbackValue(MediaType.game);
  });

  setUp(() {
    mockCacheService = MockImageCacheService();
    mockRepo = MockCollectionRepository();

    when(() => mockCacheService.getImageUri(
          type: any(named: 'type'),
          imageId: any(named: 'imageId'),
          remoteUrl: any(named: 'remoteUrl'),
        )).thenAnswer((_) async => const ImageResult(
          uri: 'https://example.com/cover.jpg',
          isLocal: false,
          isMissing: false,
        ));
  });

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

  Widget buildTestWidget({
    required Collection collection,
    required CollectionStats stats,
    List<CollectionItem> items = const <CollectionItem>[],
    HeroCardStyle style = HeroCardStyle.backdrop,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    // Mock repository для items provider
    when(() => mockRepo.getItemsWithData(
          collection.id,
          mediaType: any(named: 'mediaType'),
        )).thenAnswer((_) async => items);
    when(() => mockRepo.getStats(collection.id))
        .thenAnswer((_) async => stats);

    return ProviderScope(
      overrides: <Override>[
        imageCacheServiceProvider.overrideWithValue(mockCacheService),
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        collectionStatsProvider(collection.id)
            .overrideWith((Ref ref) async => stats),
      ],
      child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: HeroCollectionCard(
            collection: collection,
            style: style,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ),
    );
  }

  group('HeroCollectionCard', () {
    group('рендеринг', () {
      testWidgets('должен рендериться с названием коллекции',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(name: 'RPG Classics');
        const CollectionStats stats = CollectionStats(
          total: 24,
          completed: 18,
          inProgress: 2,
          notStarted: 4,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byType(HeroCollectionCard), findsOneWidget);
        expect(find.text('RPG Classics'), findsOneWidget);
      });

      testWidgets('должен иметь высоту >= 120',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        final RenderBox box = tester
            .renderObject<RenderBox>(find.byType(HeroCollectionCard));
        expect(box.size.height, greaterThanOrEqualTo(120));
      });
    });

    group('backdrop стиль', () {
      testWidgets('должен показывать иконку типа own',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.own);
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.folder), findsOneWidget);
      });

      testWidgets('должен показывать иконку folder для imported',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.imported);
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.folder), findsOneWidget);
      });

      testWidgets('должен содержать ClipRRect для скругления',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byType(ClipRRect), findsWidgets);
      });

      testWidgets('должен содержать акцентную линию (ColoredBox)',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        // Акцентная линия — ColoredBox с цветом gameAccent
        final Finder accentLines = find.byWidgetPredicate(
          (Widget w) =>
              w is ColoredBox && w.color == AppColors.gameAccent,
        );
        expect(accentLines, findsOneWidget);
      });
    });

    group('mosaic стиль', () {
      testWidgets('должен показывать fallback иконку при пустой коллекции',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.own);
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
          style: HeroCardStyle.mosaic,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.folder), findsOneWidget);
      });

      testWidgets('должен показывать fallback иконку folder для imported',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.imported);
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
          style: HeroCardStyle.mosaic,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.folder), findsOneWidget);
      });

      testWidgets('должен показывать название коллекции',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(name: 'Mosaic Test');
        const CollectionStats stats = CollectionStats(
          total: 5,
          completed: 3,
          inProgress: 1,
          notStarted: 1,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
          style: HeroCardStyle.mosaic,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.text('Mosaic Test'), findsOneWidget);
        expect(find.text('5 items · 60% completed'), findsOneWidget);
      });
    });

    group('accentForType', () {
      test('own → gameAccent', () {
        expect(
          HeroCollectionCard.accentForType(CollectionType.own),
          equals(AppColors.gameAccent),
        );
      });

      test('imported → gameAccent', () {
        expect(
          HeroCollectionCard.accentForType(CollectionType.imported),
          equals(AppColors.gameAccent),
        );
      });

      test('fork → gameAccent', () {
        expect(
          HeroCollectionCard.accentForType(CollectionType.fork),
          equals(AppColors.gameAccent),
        );
      });
    });

    group('iconForType', () {
      test('own → folder', () {
        expect(
          HeroCollectionCard.iconForType(CollectionType.own),
          equals(Icons.folder),
        );
      });

      test('imported → folder', () {
        expect(
          HeroCollectionCard.iconForType(CollectionType.imported),
          equals(Icons.folder),
        );
      });

      test('fork → folder', () {
        expect(
          HeroCollectionCard.iconForType(CollectionType.fork),
          equals(Icons.folder),
        );
      });
    });

    group('статистика', () {
      testWidgets('должен показывать количество элементов и процент',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats(
          total: 24,
          completed: 18,
          inProgress: 2,
          notStarted: 4,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.text('24 items · 75% completed'), findsOneWidget);
      });

      testWidgets('должен показывать "item" для единственного элемента',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats(
          total: 1,
          completed: 0,
          inProgress: 1,
          notStarted: 0,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.text('1 item · 0% completed'), findsOneWidget);
      });

      testWidgets('imported должен показывать процент',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.imported);
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 5,
          inProgress: 0,
          notStarted: 5,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.text('10 items · 50% completed'), findsOneWidget);
      });
    });

    group('прогресс-бар', () {
      testWidgets('должен показывать прогресс-бар для own коллекции',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.own);
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 5,
          inProgress: 3,
          notStarted: 2,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('должен показывать прогресс-бар для imported',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.imported);
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 5,
          inProgress: 0,
          notStarted: 5,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('не должен показывать прогресс-бар при total = 0',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.own);
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsNothing);
      });
    });

    group('взаимодействие', () {
      testWidgets('должен вызывать onTap при нажатии',
          (WidgetTester tester) async {
        bool tapped = false;
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
          onTap: () => tapped = true,
        ));
        await tester.pump();
        await tester.pump();

        await tester.tap(find.byType(InkWell));
        expect(tapped, isTrue);
      });

      testWidgets('должен вызывать onLongPress при долгом нажатии',
          (WidgetTester tester) async {
        bool longPressed = false;
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
          onLongPress: () => longPressed = true,
        ));
        await tester.pump();
        await tester.pump();

        await tester.longPress(find.byType(InkWell));
        expect(longPressed, isTrue);
      });
    });

    group('градиент', () {
      testWidgets('должен содержать Container с градиентом',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.own);
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pump();
        await tester.pump();

        final Finder containers = find.byType(Container);
        bool foundGradient = false;
        for (final Element element in containers.evaluate()) {
          final Container container = element.widget as Container;
          final BoxDecoration? decoration =
              container.decoration as BoxDecoration?;
          if (decoration?.gradient is LinearGradient) {
            foundGradient = true;
            break;
          }
        }
        expect(foundGradient, isTrue);
      });
    });

    group('адаптивный стиль', () {
      Widget buildAutoWidget({
        required Collection collection,
        required CollectionStats stats,
        required double screenWidth,
      }) {
        when(() => mockRepo.getItemsWithData(
              collection.id,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => const <CollectionItem>[]);
        when(() => mockRepo.getStats(collection.id))
            .thenAnswer((_) async => stats);

        return ProviderScope(
          overrides: <Override>[
            imageCacheServiceProvider.overrideWithValue(mockCacheService),
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            collectionStatsProvider(collection.id)
                .overrideWith((Ref ref) async => stats),
          ],
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(size: Size(screenWidth, 600)),
              child: Scaffold(
                body: HeroCollectionCard(collection: collection),
              ),
            ),
          ),
        );
      }

      testWidgets('узкий экран → backdrop (ColoredBox акцентная линия)',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildAutoWidget(
          collection: collection,
          stats: stats,
          screenWidth: navigationBreakpoint - 1,
        ));
        await tester.pump();
        await tester.pump();

        // Backdrop содержит акцентную ColoredBox линию
        final Finder accentLine = find.byWidgetPredicate(
          (Widget w) => w is ColoredBox && w.color == AppColors.gameAccent,
        );
        expect(accentLine, findsOneWidget);
      });

      testWidgets('широкий экран → mosaic (нет акцентной линии)',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildAutoWidget(
          collection: collection,
          stats: stats,
          screenWidth: navigationBreakpoint,
        ));
        await tester.pump();
        await tester.pump();

        // Mosaic НЕ содержит акцентную ColoredBox линию
        final Finder accentLine = find.byWidgetPredicate(
          (Widget w) => w is ColoredBox && w.color == AppColors.gameAccent,
        );
        expect(accentLine, findsNothing);
      });
    });

    group('animation ImageType', () {
      testWidgets(
          'animation movie должен запрашивать moviePoster из кэша',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats(
          total: 1,
          completed: 1,
          inProgress: 0,
          notStarted: 0,
          dropped: 0,
          planned: 0,
        );
        final List<CollectionItem> items = <CollectionItem>[
          CollectionItem(
            id: 10,
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

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
          items: items,
        ));
        await tester.pump();
        await tester.pump();
        await tester.pump();

        verify(() => mockCacheService.getImageUri(
              type: ImageType.moviePoster,
              imageId: '401',
              remoteUrl: any(named: 'remoteUrl'),
            )).called(greaterThan(0));
      });

      testWidgets(
          'animation tvShow должен запрашивать tvShowPoster из кэша',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats(
          total: 1,
          completed: 0,
          inProgress: 1,
          notStarted: 0,
          dropped: 0,
          planned: 0,
        );
        final List<CollectionItem> items = <CollectionItem>[
          CollectionItem(
            id: 11,
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

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
          items: items,
        ));
        await tester.pump();
        await tester.pump();
        await tester.pump();

        verify(() => mockCacheService.getImageUri(
              type: ImageType.tvShowPoster,
              imageId: '501',
              remoteUrl: any(named: 'remoteUrl'),
            )).called(greaterThan(0));
      });
    });
  });
}
