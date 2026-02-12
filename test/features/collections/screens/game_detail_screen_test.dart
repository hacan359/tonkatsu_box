import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/screens/game_detail_screen.dart';
import 'package:xerabora/shared/models/collection_game.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/platform.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

  late MockCollectionRepository mockRepo;

  CollectionGame createTestCollectionGame({
    int id = 1,
    int collectionId = 1,
    int igdbId = 100,
    int platformId = 18,
    GameStatus status = GameStatus.notStarted,
    String? authorComment,
    String? userComment,
    Game? game,
    Platform? platform,
  }) {
    return CollectionGame(
      id: id,
      collectionId: collectionId,
      igdbId: igdbId,
      platformId: platformId,
      status: status,
      addedAt: testDate,
      authorComment: authorComment,
      userComment: userComment,
      game: game,
      platform: platform,
    );
  }

  Game createTestGame({
    int id = 100,
    String name = 'Test Game',
    String? summary,
    String? coverUrl,
    List<String>? genres,
    int? releaseYear,
    double? rating,
  }) {
    return Game(
      id: id,
      name: name,
      summary: summary,
      coverUrl: coverUrl,
      genres: genres,
      releaseDate: releaseYear != null ? DateTime(releaseYear) : null,
      rating: rating,
    );
  }

  setUp(() {
    mockRepo = MockCollectionRepository();
  });

  Widget createTestWidget({
    required int collectionId,
    required int gameId,
    required bool isEditable,
    required List<CollectionGame> games,
  }) {
    when(() => mockRepo.getGamesWithData(collectionId))
        .thenAnswer((_) async => games);

    return ProviderScope(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: GameDetailScreen(
          collectionId: collectionId,
          gameId: gameId,
          isEditable: isEditable,
        ),
      ),
    );
  }

  group('GameDetailScreen', () {
    testWidgets('должен отображать название игры', (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Chrono Trigger');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
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
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.text('SNES'), findsOneWidget);
    });

    testWidgets('должен отображать статус dropdown', (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
        status: GameStatus.playing,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Status'), findsOneWidget);
      expect(find.textContaining('Playing'), findsOneWidget);
    });

    testWidgets('должен отображать описание игры inline в header',
        (WidgetTester tester) async {
      final Game game = createTestGame(
        summary: 'A group of adventurers travel through time.',
      );
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('A group of adventurers travel through time.'),
        findsOneWidget,
      );
    });

    testWidgets('должен отображать комментарий автора', (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
        authorComment: 'Best RPG ever!',
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.text("Author's Comment"), findsOneWidget);
      expect(find.text('Best RPG ever!'), findsOneWidget);
    });

    testWidgets('должен отображать личные заметки', (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
        userComment: 'Finished on 2024-01-15',
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      // Скролл вниз мимо ActivityDatesSection
      await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('My Notes'), findsOneWidget);
      expect(find.text('Finished on 2024-01-15'), findsOneWidget);
    });

    testWidgets('должен показывать кнопку Edit для комментария автора если editable',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      // Скролл вниз мимо ActivityDatesSection
      await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Должно быть 2 кнопки Edit: для комментария автора и личных заметок
      expect(find.text('Edit'), findsNWidgets(2));
    });

    testWidgets('не должен показывать кнопку Edit для комментария автора если not editable',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: false,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      // Скролл вниз мимо ActivityDatesSection
      await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Должна быть только 1 кнопка Edit: для личных заметок
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('должен отображать жанры', (WidgetTester tester) async {
      final Game game = createTestGame(
        genres: <String>['RPG', 'Adventure'],
      );
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.text('RPG, Adventure'), findsOneWidget);
    });

    testWidgets('должен отображать год релиза', (WidgetTester tester) async {
      final Game game = createTestGame(releaseYear: 1995);
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.text('1995'), findsOneWidget);
    });

    testWidgets('должен отображать рейтинг', (WidgetTester tester) async {
      final Game game = createTestGame(rating: 85.0);
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.text('8.5/10'), findsOneWidget);
    });

    testWidgets('должен показывать placeholder когда нет комментария автора',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
        authorComment: null,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No comment yet. Tap Edit to add one.'), findsOneWidget);
    });

    testWidgets('должен показывать сообщение для readonly когда нет комментария',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
        authorComment: null,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: false,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No comment from the author.'), findsOneWidget);
    });

    testWidgets('должен показывать Game not found для несуществующей игры',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 999, // Несуществующий ID
        isEditable: true,
        games: <CollectionGame>[],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Game not found'), findsOneWidget);
    });

    testWidgets('должен открывать диалог редактирования при нажатии Edit',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      // Нажимаем первую кнопку Edit (для Author's Comment)
      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();

      // Проверяем что открылся диалог
      expect(find.text("Edit Author's Comment"), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('должен закрывать диалог при нажатии Cancel',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      // Открываем диалог
      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();

      // Нажимаем Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Проверяем что диалог закрылся
      expect(find.text("Edit Author's Comment"), findsNothing);
    });

    testWidgets('должен отображать SourceBadge IGDB',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SourceBadge), findsOneWidget);
      expect(find.text('IGDB'), findsOneWidget);
    });

    testWidgets('должен отображать TabBar с двумя вкладками',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Canvas'), findsOneWidget);
    });

    testWidgets('должен отображать иконки вкладок',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
    });

    testWidgets('должен начинать с вкладки Details',
        (WidgetTester tester) async {
      const Game game = Game(id: 100, name: 'Test Game');
      const Platform platform = Platform(id: 18, name: 'SNES');
      final CollectionGame collectionGame = createTestCollectionGame(
        game: game,
        platform: platform,
        authorComment: 'Test author comment',
      );

      await tester.pumpWidget(createTestWidget(
        collectionId: 1,
        gameId: 1,
        isEditable: true,
        games: <CollectionGame>[collectionGame],
      ));
      await tester.pumpAndSettle();

      // Содержимое вкладки Details должно быть видимым по умолчанию
      expect(find.text("Author's Comment"), findsOneWidget);
      expect(find.text('Test author comment'), findsOneWidget);
    });
  });
}
