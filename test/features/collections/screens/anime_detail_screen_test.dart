// Виджет-тесты для AnimeDetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/screens/anime_detail_screen.dart';
import 'package:xerabora/features/collections/widgets/status_chip_row.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_season.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/widgets/media_detail_view.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockTmdbApi extends Mock implements TmdbApi {}

void main() {
  final DateTime testDate = DateTime(2024, 6, 10, 12, 0, 0);

  late MockCollectionRepository mockRepo;
  late MockDatabaseService mockDb;
  late MockTmdbApi mockTmdbApi;

  CollectionItem createTestItem({
    int id = 1,
    int? collectionId = 1,
    int externalId = 550,
    int? platformId = AnimationSource.movie,
    ItemStatus status = ItemStatus.notStarted,
    String? authorComment,
    String? userComment,
    Movie? movie,
    TvShow? tvShow,
  }) {
    return CollectionItem(
      id: id,
      collectionId: collectionId,
      mediaType: MediaType.animation,
      externalId: externalId,
      platformId: platformId,
      status: status,
      addedAt: testDate,
      authorComment: authorComment,
      userComment: userComment,
      movie: movie,
      tvShow: tvShow,
    );
  }

  Movie createTestMovie({
    int tmdbId = 550,
    String title = 'Test Anime Movie',
    String? overview,
    String? posterUrl,
    List<String>? genres,
    int? releaseYear,
    double? rating,
    int? runtime,
  }) {
    return Movie(
      tmdbId: tmdbId,
      title: title,
      overview: overview,
      posterUrl: posterUrl,
      genres: genres,
      releaseYear: releaseYear,
      rating: rating,
      runtime: runtime,
    );
  }

  TvShow createTestTvShow({
    int tmdbId = 200,
    String title = 'Test Anime Series',
    String? overview,
    String? posterUrl,
    List<String>? genres,
    int? firstAirYear,
    int? totalSeasons,
    int? totalEpisodes,
    double? rating,
    String? status,
  }) {
    return TvShow(
      tmdbId: tmdbId,
      title: title,
      overview: overview,
      posterUrl: posterUrl,
      genres: genres,
      firstAirYear: firstAirYear,
      totalSeasons: totalSeasons,
      totalEpisodes: totalEpisodes,
      rating: rating,
      status: status,
    );
  }

  setUp(() {
    mockRepo = MockCollectionRepository();
    mockDb = MockDatabaseService();
    mockTmdbApi = MockTmdbApi();

    when(() => mockDb.getTvSeasonsByShowId(any()))
        .thenAnswer((_) async => <TvSeason>[]);
    when(() => mockDb.getWatchedEpisodes(any(), any()))
        .thenAnswer((_) async => <(int, int), DateTime?>{});
    when(() => mockTmdbApi.getTvSeasons(any()))
        .thenAnswer((_) async => <TvSeason>[]);

    registerFallbackValue(ItemStatus.notStarted);
    registerFallbackValue(MediaType.animation);
  });

  Widget createTestWidget({
    required int? collectionId,
    required int itemId,
    required bool isEditable,
    required List<CollectionItem> items,
  }) {
    when(() => mockRepo.getItemsWithData(
          collectionId,
          mediaType: any(named: 'mediaType'),
        )).thenAnswer((_) async => items);

    return ProviderScope(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        databaseServiceProvider.overrideWithValue(mockDb),
        tmdbApiProvider.overrideWithValue(mockTmdbApi),
      ],
      child: MaterialApp(
        home: AnimeDetailScreen(
          collectionId: collectionId,
          collectionName: 'Test Collection',
          itemId: itemId,
          isEditable: isEditable,
        ),
      ),
    );
  }

  group('AnimeDetailScreen', () {
    group('заголовок и AppBar', () {
      testWidgets('должен отображать название анимации (movie source)',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(title: 'Spirited Away');
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Spirited Away'), findsWidgets);
      });

      testWidgets('должен отображать название анимации (tvShow source)',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(title: 'Attack on Titan');
        final CollectionItem item = createTestItem(
          tvShow: tvShow,
          platformId: AnimationSource.tvShow,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Attack on Titan'), findsWidgets);
      });

      testWidgets('должен показывать "Animation not found" для несуществующего ID',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 999,
          isEditable: true,
          items: <CollectionItem>[],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Animation not found'), findsOneWidget);
      });
    });

    group('тип медиа', () {
      testWidgets('должен отображать "Animated Movie" для movie source',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Animated Movie'), findsOneWidget);
      });

      testWidgets('должен отображать "Animated Series" для tvShow source',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestItem(
          tvShow: tvShow,
          platformId: AnimationSource.tvShow,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Animated Series'), findsOneWidget);
      });
    });

    group('info chips (movie source)', () {
      testWidgets('должен отображать год выпуска',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(releaseYear: 2001);
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2001'), findsOneWidget);
      });

      testWidgets('должен отображать runtime',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(runtime: 125);
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2h 5m'), findsOneWidget);
      });

      testWidgets('должен отображать рейтинг',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(rating: 8.6);
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('8.6/10'), findsOneWidget);
      });

      testWidgets('должен отображать жанры',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(
          genres: <String>['Animation', 'Adventure'],
        );
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Animation, Adventure'), findsOneWidget);
      });
    });

    group('info chips (tvShow source)', () {
      testWidgets('должен отображать год выхода',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(firstAirYear: 2013);
        final CollectionItem item = createTestItem(
          tvShow: tvShow,
          platformId: AnimationSource.tvShow,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2013'), findsOneWidget);
      });

      testWidgets('должен отображать количество сезонов',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(totalSeasons: 4);
        final CollectionItem item = createTestItem(
          tvShow: tvShow,
          platformId: AnimationSource.tvShow,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('4 seasons'), findsOneWidget);
      });

      testWidgets('должен отображать рейтинг',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(rating: 8.7);
        final CollectionItem item = createTestItem(
          tvShow: tvShow,
          platformId: AnimationSource.tvShow,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('8.7/10'), findsOneWidget);
      });
    });

    group('статус', () {
      testWidgets('должен отображать StatusChipRow',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
          status: ItemStatus.inProgress,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(StatusChipRow), findsOneWidget);
      });
    });

    group('описание', () {
      testWidgets('должен отображать описание фильма',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(
          overview: 'A young girl enters a spirit world.',
        );
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('A young girl enters a spirit world.'),
          findsOneWidget,
        );
      });
    });

    group('комментарий автора', () {
      testWidgets('должен отображать комментарий автора',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
          authorComment: 'Masterpiece of Miyazaki',
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text("Author's Review"), findsOneWidget);
        expect(find.text('Masterpiece of Miyazaki'), findsOneWidget);
      });

      testWidgets('должен показывать placeholder когда нет комментария (editable)',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('No review yet. Tap Edit to add one.'),
          findsOneWidget,
        );
      });

      testWidgets('должен показывать сообщение для readonly',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: false,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('No review from the author.'), findsOneWidget);
      });

      testWidgets('должен показывать кнопку Edit если editable',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Скролл вниз
        await tester.drag(
          find.byType(Scrollable).at(1),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        // 2 кнопки Edit: Author's Review и My Notes
        expect(find.text('Edit'), findsNWidgets(2));
      });

      testWidgets('не должен показывать кнопку Edit для Author Review если not editable',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: false,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Скролл вниз
        await tester.drag(
          find.byType(Scrollable).at(1),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        // Только 1 кнопка Edit: My Notes
        expect(find.text('Edit'), findsOneWidget);
      });
    });

    group('личные заметки', () {
      testWidgets('должен отображать личные заметки',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
          userComment: 'Watched with family',
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Скролл вниз
        await tester.drag(
          find.byType(Scrollable).at(1),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Notes'), findsOneWidget);
        expect(find.text('Watched with family'), findsOneWidget);
      });
    });

    group('SourceBadge', () {
      testWidgets('должен отображать TMDB',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(SourceBadge), findsOneWidget);
        expect(find.text('TMDB'), findsOneWidget);
      });
    });

    group('TabBar', () {
      testWidgets('должен отображать TabBar с двумя вкладками',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(Tab), findsNWidgets(2));
        expect(find.text('Details'), findsOneWidget);
        expect(find.text('Board'), findsOneWidget);
      });

      testWidgets('должен отображать иконки вкладок',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
      });

      testWidgets('должен начинать с вкладки Details',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(MediaDetailView), findsOneWidget);
      });
    });

    group('uncategorized (collectionId == null)', () {
      testWidgets('не должен показывать вкладку Board',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          collectionId: null,
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: null,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(Tab), findsOneWidget);
        expect(find.text('Details'), findsOneWidget);
        expect(find.text('Board'), findsNothing);
      });

      testWidgets('не должен показывать иконку Board',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          collectionId: null,
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: null,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.dashboard_outlined), findsNothing);
      });

      testWidgets('не должен показывать замок',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          collectionId: null,
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: null,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Lock board'), findsNothing);
        expect(find.byTooltip('Unlock board'), findsNothing);
      });
    });

    group('замок канваса', () {
      Future<void> pumpFrames(WidgetTester tester) async {
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      testWidgets('не должен показывать замок на вкладке Details',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Lock board'), findsNothing);
        expect(find.byTooltip('Unlock board'), findsNothing);
      });

      testWidgets('должен показывать замок на вкладке Canvas (editable)',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Board'));
        await pumpFrames(tester);

        expect(find.byTooltip('Lock board'), findsOneWidget);
        expect(find.byIcon(Icons.lock_open), findsOneWidget);
      });

      testWidgets('не должен показывать замок когда isEditable = false',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: false,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Board'));
        await pumpFrames(tester);

        expect(find.byTooltip('Lock board'), findsNothing);
        expect(find.byTooltip('Unlock board'), findsNothing);
      });

      testWidgets('должен переключать состояние замка',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          platformId: AnimationSource.movie,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Board'));
        await pumpFrames(tester);

        // Блокируем
        await tester.tap(find.byTooltip('Lock board'));
        await pumpFrames(tester);

        expect(find.byIcon(Icons.lock), findsOneWidget);
        expect(find.byTooltip('Unlock board'), findsOneWidget);

        // Разблокируем
        await tester.tap(find.byTooltip('Unlock board'));
        await pumpFrames(tester);

        expect(find.byIcon(Icons.lock_open), findsOneWidget);
        expect(find.byTooltip('Lock board'), findsOneWidget);
      });
    });
  });
}
