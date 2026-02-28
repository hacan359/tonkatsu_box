// Виджет-тесты для ItemDetailScreen (единый экран деталей).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/screens/item_detail_screen.dart';
import 'package:xerabora/features/collections/widgets/status_chip_row.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/platform.dart';
import 'package:xerabora/shared/models/tv_season.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';
import 'package:xerabora/shared/widgets/media_detail_view.dart';
import 'package:xerabora/shared/models/visual_novel.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockTmdbApi extends Mock implements TmdbApi {}

void main() {
  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

  late MockCollectionRepository mockRepo;
  late MockDatabaseService mockDb;
  late MockTmdbApi mockTmdbApi;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    mockRepo = MockCollectionRepository();
    mockDb = MockDatabaseService();
    mockTmdbApi = MockTmdbApi();

    when(() => mockDb.getTvSeasonsByShowId(any()))
        .thenAnswer((_) async => <TvSeason>[]);
    when(() => mockDb.getWatchedEpisodes(any(), any()))
        .thenAnswer((_) async => <(int, int), DateTime?>{});
    when(() => mockDb.getPlatformCount())
        .thenAnswer((_) async => 0);
    when(() => mockTmdbApi.getTvSeasons(any()))
        .thenAnswer((_) async => <TvSeason>[]);

    registerFallbackValue(ItemStatus.notStarted);
    registerFallbackValue(MediaType.game);
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
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: BreadcrumbScope(
          label: 'Test Collection',
          child: ItemDetailScreen(
            collectionId: collectionId,
            itemId: itemId,
            isEditable: isEditable,
          ),
        ),
      ),
    );
  }

  // ==================== Game ====================

  group('ItemDetailScreen — Game', () {
    CollectionItem createGameItem({
      int id = 1,
      int? collectionId = 1,
      int externalId = 100,
      int? platformId = 18,
      ItemStatus status = ItemStatus.notStarted,
      String? authorComment,
      String? userComment,
      Game? game,
      Platform? platform,
    }) {
      return CollectionItem(
        id: id,
        collectionId: collectionId,
        mediaType: MediaType.game,
        externalId: externalId,
        platformId: platformId,
        status: status,
        addedAt: testDate,
        authorComment: authorComment,
        userComment: userComment,
        game: game,
        platform: platform,
      );
    }

    testWidgets('должен отображать название игры',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Chrono Trigger');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chrono Trigger'), findsWidgets);
    });

    testWidgets('должен отображать платформу', (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(
        id: 18,
        name: 'Super Nintendo',
        abbreviation: 'SNES',
      );
      final CollectionItem item = createGameItem(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('SNES'), findsOneWidget);
    });

    testWidgets('должен отображать StatusChipRow с иконками статусов',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        game: game,
        platform: platform,
        status: ItemStatus.inProgress,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('должен отображать описание игры',
        (WidgetTester tester) async {
      const Game game = Game(
        id: 100,
        name: 'Test',
        summary: 'A group of adventurers travel through time.',
      );
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('A group of adventurers travel through time.'),
        findsOneWidget,
      );
    });

    testWidgets('должен отображать жанры', (WidgetTester tester) async {
      const Game game = Game(
        id: 100,
        name: 'Test',
        genres: <String>['RPG', 'Adventure'],
      );
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('RPG, Adventure'), findsOneWidget);
    });

    testWidgets('должен отображать год релиза', (WidgetTester tester) async {
      final Game game = Game(
        id: 100,
        name: 'Test',
        releaseDate: DateTime(1995),
      );
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('1995'), findsOneWidget);
    });

    testWidgets('должен отображать рейтинг', (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test', rating: 85.0);
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('8.5/10'), findsOneWidget);
    });

    testWidgets('должен показывать Game not found для несуществующей игры',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 999,
        isEditable: true,
        items: <CollectionItem>[],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Game not found'), findsOneWidget);
    });

    testWidgets('должен отображать SourceBadge IGDB',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SourceBadge), findsOneWidget);
      expect(find.text('IGDB'), findsOneWidget);
    });

    testWidgets('должен отображать комментарий автора',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        game: game,
        platform: platform,
        authorComment: 'Best RPG ever!',
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text("Author's Review"), findsOneWidget);
      expect(find.text('Best RPG ever!'), findsOneWidget);
    });

    group('Board toggle', () {
      testWidgets('должен показывать Board toggle кнопку если collectionId != null',
          (WidgetTester tester) async {
        const Game game = Game(id: 100, name: 'Test Game');
        const Platform platform = Platform(id: 18, name: 'SNES');
        final CollectionItem item = createGameItem(
          game: game,
          platform: platform,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Board'), findsOneWidget);
        expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
      });

      testWidgets('не должен показывать Board toggle для uncategorized',
          (WidgetTester tester) async {
        const Game game = Game(id: 100, name: 'Test Game');
        const Platform platform = Platform(id: 18, name: 'SNES');
        final CollectionItem item = createGameItem(
          collectionId: null,
          game: game,
          platform: platform,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: null,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Board'), findsNothing);
        expect(find.byIcon(Icons.dashboard_outlined), findsNothing);
      });

      testWidgets('должен начинать с detail view (не canvas)',
          (WidgetTester tester) async {
        const Game game = Game(id: 100, name: 'Test Game');
        const Platform platform = Platform(id: 18, name: 'SNES');
        final CollectionItem item = createGameItem(
          game: game,
          platform: platform,
          authorComment: 'Test author comment',
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text("Author's Review"), findsOneWidget);
        expect(find.text('Test author comment'), findsOneWidget);
      });
    });

    group('замок канваса', () {
      Future<void> pumpFrames(WidgetTester tester) async {
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      testWidgets('не должен показывать замок на detail view',
          (WidgetTester tester) async {
        const Game game = Game(id: 100, name: 'Test Game');
        const Platform platform = Platform(id: 18, name: 'SNES');
        final CollectionItem item = createGameItem(
          game: game,
          platform: platform,
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

      testWidgets('должен показывать замок на canvas view (editable)',
          (WidgetTester tester) async {
        const Game game = Game(id: 100, name: 'Test Game');
        const Platform platform = Platform(id: 18, name: 'SNES');
        final CollectionItem item = createGameItem(
          game: game,
          platform: platform,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Переключаемся на Canvas
        await tester.tap(find.byTooltip('Board'));
        await pumpFrames(tester);

        expect(find.byTooltip('Lock board'), findsOneWidget);
        expect(find.byIcon(Icons.lock_open), findsOneWidget);
      });

      testWidgets('не должен показывать замок когда isEditable = false',
          (WidgetTester tester) async {
        const Game game = Game(id: 100, name: 'Test Game');
        const Platform platform = Platform(id: 18, name: 'SNES');
        final CollectionItem item = createGameItem(
          game: game,
          platform: platform,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: false,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Переключаемся на Canvas
        await tester.tap(find.byTooltip('Board'));
        await pumpFrames(tester);

        expect(find.byTooltip('Lock board'), findsNothing);
        expect(find.byTooltip('Unlock board'), findsNothing);
      });

      testWidgets('должен переключать состояние замка',
          (WidgetTester tester) async {
        const Game game = Game(id: 100, name: 'Test Game');
        const Platform platform = Platform(id: 18, name: 'SNES');
        final CollectionItem item = createGameItem(
          game: game,
          platform: platform,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Переключаемся на Canvas
        await tester.tap(find.byTooltip('Board'));
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

      testWidgets('не должен показывать замок для uncategorized',
          (WidgetTester tester) async {
        const Game game = Game(id: 100, name: 'Test Game');
        const Platform platform = Platform(id: 18, name: 'SNES');
        final CollectionItem item = createGameItem(
          collectionId: null,
          game: game,
          platform: platform,
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
  });

  // ==================== Movie ====================

  group('ItemDetailScreen — Movie', () {
    CollectionItem createMovieItem({
      int id = 1,
      int? collectionId = 1,
      int externalId = 550,
      ItemStatus status = ItemStatus.notStarted,
      String? authorComment,
      String? userComment,
      Movie? movie,
    }) {
      return CollectionItem(
        id: id,
        collectionId: collectionId,
        mediaType: MediaType.movie,
        externalId: externalId,
        status: status,
        addedAt: testDate,
        authorComment: authorComment,
        userComment: userComment,
        movie: movie,
      );
    }

    Movie createTestMovie({
      int tmdbId = 550,
      String title = 'Test Movie',
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

    testWidgets('должен отображать название фильма',
        (WidgetTester tester) async {
      final Movie movie = createTestMovie(title: 'Inception');
      final CollectionItem item = createMovieItem(movie: movie);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Inception'), findsWidgets);
    });

    testWidgets('должен показывать Movie not found для несуществующего ID',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 999,
        isEditable: true,
        items: <CollectionItem>[],
      ));
      await tester.pumpAndSettle();

      // For empty items list, we get the default not found message
      expect(find.textContaining('not found'), findsOneWidget);
    });

    testWidgets('должен отображать "Movie" как тип медиа',
        (WidgetTester tester) async {
      final Movie movie = createTestMovie();
      final CollectionItem item = createMovieItem(movie: movie);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Movie'), findsOneWidget);
    });

    testWidgets('должен отображать SourceBadge TMDB',
        (WidgetTester tester) async {
      final Movie movie = createTestMovie();
      final CollectionItem item = createMovieItem(movie: movie);

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

    group('Info chips', () {
      testWidgets('должен отображать год выпуска',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(releaseYear: 2010);
        final CollectionItem item = createMovieItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2010'), findsOneWidget);
      });

      testWidgets('должен отображать runtime',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(runtime: 148);
        final CollectionItem item = createMovieItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2h 28m'), findsOneWidget);
      });

      testWidgets('должен отображать runtime в формате Xh когда 0 минут',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(runtime: 120);
        final CollectionItem item = createMovieItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2h'), findsOneWidget);
      });

      testWidgets('должен отображать runtime в формате Ym менее часа',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(runtime: 45);
        final CollectionItem item = createMovieItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('45m'), findsOneWidget);
      });

      testWidgets('должен отображать жанры',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(
          genres: <String>['Action', 'Sci-Fi', 'Thriller'],
        );
        final CollectionItem item = createMovieItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Action, Sci-Fi, Thriller'), findsOneWidget);
      });

      testWidgets('должен отображать рейтинг',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(rating: 8.4);
        final CollectionItem item = createMovieItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('8.4/10'), findsOneWidget);
      });
    });

    group('Статус', () {
      testWidgets('StatusChipRow использует MediaType.movie',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createMovieItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        final StatusChipRow dropdown = tester.widget<StatusChipRow>(
          find.byType(StatusChipRow),
        );
        expect(dropdown.mediaType, MediaType.movie);
      });

      testWidgets('должен показывать иконку play для inProgress',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createMovieItem(
          movie: movie,
          status: ItemStatus.inProgress,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      });
    });

    testWidgets('должен отображать описание фильма',
        (WidgetTester tester) async {
      final Movie movie = createTestMovie(
        overview: 'A thief who steals corporate secrets through dreams.',
      );
      final CollectionItem item = createMovieItem(movie: movie);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('A thief who steals corporate secrets through dreams.'),
        findsOneWidget,
      );
    });

    testWidgets('не должен показывать Board toggle для uncategorized',
        (WidgetTester tester) async {
      final Movie movie = createTestMovie();
      final CollectionItem item = createMovieItem(
        collectionId: null,
        movie: movie,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: null,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Board'), findsNothing);
      expect(find.byIcon(Icons.dashboard_outlined), findsNothing);
    });
  });

  // ==================== TvShow ====================

  group('ItemDetailScreen — TvShow', () {
    CollectionItem createTvShowItem({
      int id = 1,
      int? collectionId = 1,
      int externalId = 200,
      ItemStatus status = ItemStatus.notStarted,
      String? authorComment,
      String? userComment,
      TvShow? tvShow,
    }) {
      return CollectionItem(
        id: id,
        collectionId: collectionId,
        mediaType: MediaType.tvShow,
        externalId: externalId,
        status: status,
        addedAt: testDate,
        authorComment: authorComment,
        userComment: userComment,
        tvShow: tvShow,
      );
    }

    TvShow createTestTvShow({
      int tmdbId = 200,
      String title = 'Test Show',
      String? posterUrl,
      String? overview,
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
        posterUrl: posterUrl,
        overview: overview,
        genres: genres,
        firstAirYear: firstAirYear,
        totalSeasons: totalSeasons,
        totalEpisodes: totalEpisodes,
        rating: rating,
        status: status,
      );
    }

    testWidgets('должен отображать название сериала',
        (WidgetTester tester) async {
      final TvShow tvShow = createTestTvShow(title: 'Breaking Bad');
      final CollectionItem item = createTvShowItem(tvShow: tvShow);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Breaking Bad'), findsWidgets);
    });

    testWidgets('должен отображать тип медиа TV Show',
        (WidgetTester tester) async {
      final TvShow tvShow = createTestTvShow();
      final CollectionItem item = createTvShowItem(tvShow: tvShow);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('TV Show'), findsOneWidget);
    });

    testWidgets('должен отображать SourceBadge TMDB',
        (WidgetTester tester) async {
      final TvShow tvShow = createTestTvShow();
      final CollectionItem item = createTvShowItem(tvShow: tvShow);

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

    testWidgets('должен показывать TV Show not found',
        (WidgetTester tester) async {
      // Create a tvShow item that won't be found
      final CollectionItem item = createTvShowItem(id: 2);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 999,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('not found'), findsOneWidget);
    });

    group('Info chips', () {
      testWidgets('должен отображать год', (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(firstAirYear: 2008);
        final CollectionItem item = createTvShowItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2008'), findsOneWidget);
      });

      testWidgets('должен отображать количество сезонов',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(totalSeasons: 5);
        final CollectionItem item = createTvShowItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('5 seasons'), findsOneWidget);
      });

      testWidgets('должен отображать количество эпизодов',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(totalEpisodes: 62);
        final CollectionItem item = createTvShowItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('62 ep'), findsOneWidget);
      });

      testWidgets('должен отображать жанры', (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          genres: <String>['Drama', 'Crime', 'Thriller'],
        );
        final CollectionItem item = createTvShowItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Drama, Crime, Thriller'), findsOneWidget);
      });

      testWidgets('должен отображать рейтинг',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(rating: 8.9);
        final CollectionItem item = createTvShowItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('8.9/10'), findsOneWidget);
      });
    });

    testWidgets('должен отображать placeholder когда tvShow null',
        (WidgetTester tester) async {
      final CollectionItem item = createTvShowItem(tvShow: null);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tv_outlined), findsWidgets);
    });

    testWidgets('должен показывать MediaDetailView',
        (WidgetTester tester) async {
      final TvShow tvShow = createTestTvShow();
      final CollectionItem item = createTvShowItem(tvShow: tvShow);

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

  // ==================== Animation ====================

  group('ItemDetailScreen — Animation', () {
    CollectionItem createAnimeItem({
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

    group('заголовок', () {
      testWidgets('должен отображать название (movie source)',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(title: 'Spirited Away');
        final CollectionItem item = createAnimeItem(
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

      testWidgets('должен отображать название (tvShow source)',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(title: 'Attack on Titan');
        final CollectionItem item = createAnimeItem(
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

      testWidgets('должен показывать Animation not found',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 999,
          isEditable: true,
          items: <CollectionItem>[],
        ));
        await tester.pumpAndSettle();

        expect(find.textContaining('not found'), findsOneWidget);
      });
    });

    group('тип медиа', () {
      testWidgets('должен отображать Animated Movie для movie source',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createAnimeItem(
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

      testWidgets('должен отображать Animated Series для tvShow source',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createAnimeItem(
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
        final CollectionItem item = createAnimeItem(
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
        final CollectionItem item = createAnimeItem(
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
        final CollectionItem item = createAnimeItem(
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
    });

    group('info chips (tvShow source)', () {
      testWidgets('должен отображать год',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(firstAirYear: 2013);
        final CollectionItem item = createAnimeItem(
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
        final CollectionItem item = createAnimeItem(
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
    });

    testWidgets('должен отображать SourceBadge TMDB',
        (WidgetTester tester) async {
      final Movie movie = createTestMovie();
      final CollectionItem item = createAnimeItem(
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

    testWidgets('должен отображать StatusChipRow',
        (WidgetTester tester) async {
      final Movie movie = createTestMovie();
      final CollectionItem item = createAnimeItem(
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

    testWidgets('не должен показывать Board toggle для uncategorized',
        (WidgetTester tester) async {
      final Movie movie = createTestMovie();
      final CollectionItem item = createAnimeItem(
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

      expect(find.byTooltip('Board'), findsNothing);
      expect(find.byIcon(Icons.dashboard_outlined), findsNothing);
    });
  });

  // ==================== Visual Novel ====================

  group('ItemDetailScreen — Visual Novel', () {
    CollectionItem createVnItem({
      int id = 1,
      int? collectionId = 1,
      int externalId = 500,
      ItemStatus status = ItemStatus.notStarted,
      String? authorComment,
      String? userComment,
      VisualNovel? visualNovel,
    }) {
      return CollectionItem(
        id: id,
        collectionId: collectionId,
        mediaType: MediaType.visualNovel,
        externalId: externalId,
        status: status,
        addedAt: testDate,
        authorComment: authorComment,
        userComment: userComment,
        visualNovel: visualNovel,
      );
    }

    VisualNovel createTestVn({
      String id = 'v500',
      String title = 'Steins;Gate',
      String? altTitle,
      String? description,
      String? imageUrl,
      double? rating,
      int? voteCount,
      String? released,
      int? lengthMinutes,
      List<String>? tags,
      List<String>? developers,
    }) {
      return VisualNovel(
        id: id,
        title: title,
        altTitle: altTitle,
        description: description,
        imageUrl: imageUrl,
        rating: rating,
        voteCount: voteCount,
        released: released,
        lengthMinutes: lengthMinutes,
        tags: tags,
        developers: developers,
        externalUrl: 'https://vndb.org/$id',
      );
    }

    testWidgets('должен отображать название VN',
        (WidgetTester tester) async {
      final VisualNovel vn = createTestVn(title: 'Steins;Gate');
      final CollectionItem item = createVnItem(visualNovel: vn);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Steins;Gate'), findsWidgets);
    });

    testWidgets('должен отображать тип Visual Novel',
        (WidgetTester tester) async {
      final VisualNovel vn = createTestVn();
      final CollectionItem item = createVnItem(visualNovel: vn);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Visual Novel'), findsOneWidget);
    });

    testWidgets('должен отображать SourceBadge VNDB',
        (WidgetTester tester) async {
      final VisualNovel vn = createTestVn();
      final CollectionItem item = createVnItem(visualNovel: vn);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SourceBadge), findsOneWidget);
      expect(find.text('VNDB'), findsOneWidget);
    });

    testWidgets('должен показывать Visual Novel not found',
        (WidgetTester tester) async {
      final CollectionItem item = createVnItem(id: 2);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 999,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('not found'), findsOneWidget);
    });

    testWidgets('не должен показывать Recommendations для VN',
        (WidgetTester tester) async {
      final VisualNovel vn = createTestVn();
      final CollectionItem item = createVnItem(visualNovel: vn);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      // Recommendations и Reviews не должны отображаться для VN
      expect(find.text('Recommendations'), findsNothing);
      expect(find.text('Reviews'), findsNothing);
    });

    testWidgets('должен отображать StatusChipRow',
        (WidgetTester tester) async {
      final VisualNovel vn = createTestVn();
      final CollectionItem item = createVnItem(
        visualNovel: vn,
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

    testWidgets('должен показывать MediaDetailView',
        (WidgetTester tester) async {
      final VisualNovel vn = createTestVn();
      final CollectionItem item = createVnItem(visualNovel: vn);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(MediaDetailView), findsOneWidget);
    });

    testWidgets('должен отображать placeholder когда visualNovel null',
        (WidgetTester tester) async {
      final CollectionItem item = createVnItem(visualNovel: null);

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.menu_book), findsWidgets);
    });

    group('Info chips', () {
      testWidgets('должен отображать год выпуска',
          (WidgetTester tester) async {
        final VisualNovel vn = createTestVn(released: '2009-10-15');
        final CollectionItem item = createVnItem(visualNovel: vn);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2009'), findsOneWidget);
      });

      testWidgets('должен отображать жанры (tags)',
          (WidgetTester tester) async {
        final VisualNovel vn = createTestVn(
          tags: <String>['Sci-fi', 'Romance', 'Drama'],
        );
        final CollectionItem item = createVnItem(visualNovel: vn);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Sci-fi, Romance, Drama'), findsOneWidget);
      });

      testWidgets('должен отображать рейтинг',
          (WidgetTester tester) async {
        final VisualNovel vn = createTestVn(rating: 91.0);
        final CollectionItem item = createVnItem(visualNovel: vn);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('9.1/10'), findsOneWidget);
      });
    });
  });

  // ==================== Uncategorized Banner ====================

  group('ItemDetailScreen — Uncategorized Banner', () {
    CollectionItem createGameItem({
      int id = 1,
      int? collectionId,
      int externalId = 100,
      int? platformId = 18,
      ItemStatus status = ItemStatus.notStarted,
      Game? game,
      Platform? platform,
    }) {
      return CollectionItem(
        id: id,
        collectionId: collectionId,
        mediaType: MediaType.game,
        externalId: externalId,
        platformId: platformId,
        status: status,
        addedAt: DateTime(2024),
        game: game,
        platform: platform,
      );
    }

    CollectionItem createTvShowItem({
      int id = 1,
      int? collectionId,
      int externalId = 200,
      ItemStatus status = ItemStatus.notStarted,
      TvShow? tvShow,
    }) {
      return CollectionItem(
        id: id,
        collectionId: collectionId,
        mediaType: MediaType.tvShow,
        externalId: externalId,
        status: status,
        addedAt: DateTime(2024),
        tvShow: tvShow,
      );
    }

    Future<void> expandExtraSections(WidgetTester tester) async {
      final Finder tile = find.text('Activity & Progress');
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    testWidgets('должен показывать баннер для uncategorized игры',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        collectionId: null,
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: null,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      await expandExtraSections(tester);

      expect(
        find.text(
          'Add to a collection to unlock Board and episode tracking',
        ),
        findsOneWidget,
      );
      expect(find.text('Add to Collection'), findsOneWidget);
    });

    testWidgets('не должен показывать баннер для элемента в коллекции',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = CollectionItem(
        id: 1,
        collectionId: 1,
        mediaType: MediaType.game,
        externalId: 100,
        platformId: 18,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Add to a collection to unlock Board and episode tracking',
        ),
        findsNothing,
      );
    });

    testWidgets('должен показывать текст сезонов для uncategorized сериала',
        (WidgetTester tester) async {
      const TvShow tvShow = TvShow(
        tmdbId: 200,
        title: 'Breaking Bad',
        totalSeasons: 5,
        totalEpisodes: 62,
      );
      final CollectionItem item = createTvShowItem(
        collectionId: null,
        tvShow: tvShow,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: null,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      await expandExtraSections(tester);

      // Текст в _buildSeasonsInfo: "5 seasons • 62 ep"
      expect(find.text('5 seasons \u2022 62 ep'), findsOneWidget);
    });

    testWidgets('не должен показывать текст сезонов для uncategorized игры',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionItem item = createGameItem(
        collectionId: null,
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: null,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      // Не должно быть Row с video_library_outlined в extraSections
      // (video_library_outlined может быть в info chips, но не в extraSections)
      expect(find.text('5 seasons \u2022 62 ep'), findsNothing);
    });

    testWidgets(
        'должен показывать только сезоны если эпизодов нет',
        (WidgetTester tester) async {
      const TvShow tvShow = TvShow(
        tmdbId: 200,
        title: 'Test Show',
        totalSeasons: 3,
      );
      final CollectionItem item = createTvShowItem(
        collectionId: null,
        tvShow: tvShow,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: null,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      await expandExtraSections(tester);

      // "3 seasons" в extraSections (без разделителя и ep)
      expect(find.text('3 seasons'), findsWidgets);
    });

    testWidgets(
        'должен показывать только эпизоды если сезонов нет',
        (WidgetTester tester) async {
      const TvShow tvShow = TvShow(
        tmdbId: 200,
        title: 'Test Show',
        totalEpisodes: 24,
      );
      final CollectionItem item = createTvShowItem(
        collectionId: null,
        tvShow: tvShow,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: null,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      await expandExtraSections(tester);

      expect(find.text('24 ep'), findsWidgets);
    });

    testWidgets(
        'не должен показывать текст сезонов если seasons и episodes оба null',
        (WidgetTester tester) async {
      const TvShow tvShow = TvShow(
        tmdbId: 200,
        title: 'Test Show',
      );
      final CollectionItem item = createTvShowItem(
        collectionId: null,
        tvShow: tvShow,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: null,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      await expandExtraSections(tester);

      // SizedBox.shrink — нет текста сезонов
      expect(find.text('0 seasons'), findsNothing);
      expect(find.text('0 ep'), findsNothing);
    });

    testWidgets(
        'должен показывать баннер и текст сезонов для uncategorized анимации (tvShow source)',
        (WidgetTester tester) async {
      const TvShow tvShow = TvShow(
        tmdbId: 300,
        title: 'Attack on Titan',
        totalSeasons: 4,
        totalEpisodes: 87,
      );
      final CollectionItem item = CollectionItem(
        id: 1,
        collectionId: null,
        mediaType: MediaType.animation,
        externalId: 300,
        platformId: AnimationSource.tvShow,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        tvShow: tvShow,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: null,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      await expandExtraSections(tester);

      // Баннер
      expect(
        find.text(
          'Add to a collection to unlock Board and episode tracking',
        ),
        findsOneWidget,
      );
      // Текст сезонов
      expect(find.text('4 seasons \u2022 87 ep'), findsOneWidget);
    });

    testWidgets(
        'не должен показывать текст сезонов для uncategorized анимации (movie source)',
        (WidgetTester tester) async {
      final CollectionItem item = CollectionItem(
        id: 1,
        collectionId: null,
        mediaType: MediaType.animation,
        externalId: 400,
        platformId: AnimationSource.movie,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        movie: const Movie(tmdbId: 400, title: 'Spirited Away'),
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: null,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      // Баннер есть (uncategorized)
      await expandExtraSections(tester);
      expect(
        find.text(
          'Add to a collection to unlock Board and episode tracking',
        ),
        findsOneWidget,
      );
      // Текст сезонов НЕ показывается (movie source — нет episode tracker)
      expect(find.text('4 seasons \u2022 87 ep'), findsNothing);
    });

    testWidgets(
        'не должен показывать текст сезонов для сериала в коллекции',
        (WidgetTester tester) async {
      const TvShow tvShow = TvShow(
        tmdbId: 200,
        title: 'Breaking Bad',
        totalSeasons: 5,
        totalEpisodes: 62,
      );
      final CollectionItem item = CollectionItem(
        id: 1,
        collectionId: 1,
        mediaType: MediaType.tvShow,
        externalId: 200,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        tvShow: tvShow,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        itemId: 1,
        isEditable: true,
        items: <CollectionItem>[item],
      ));
      await tester.pumpAndSettle();

      // В коллекции показывается EpisodeTrackerSection, не текст сезонов
      expect(find.text('5 seasons \u2022 62 ep'), findsNothing);
    });
  });
}
