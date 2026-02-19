import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/data/repositories/wishlist_repository.dart';
import 'package:xerabora/features/wishlist/screens/wishlist_screen.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

class MockWishlistRepository extends Mock implements WishlistRepository {}

void main() {
  late MockWishlistRepository mockRepo;

  setUp(() {
    mockRepo = MockWishlistRepository();
  });

  setUpAll(() {
    registerFallbackValue(MediaType.game);
  });

  final WishlistItem item1 = WishlistItem(
    id: 1,
    text: 'Chrono Trigger',
    mediaTypeHint: MediaType.game,
    note: 'SNES RPG',
    createdAt: DateTime(2024, 6, 15),
  );

  final WishlistItem item2 = WishlistItem(
    id: 2,
    text: 'The Matrix',
    mediaTypeHint: MediaType.movie,
    createdAt: DateTime(2024, 6, 16),
  );

  final WishlistItem resolvedItem = WishlistItem(
    id: 3,
    text: 'Resolved Game',
    isResolved: true,
    createdAt: DateTime(2024, 6, 10),
    resolvedAt: DateTime(2024, 6, 20),
  );

  Widget buildScreen({List<WishlistItem> items = const <WishlistItem>[]}) {
    return ProviderScope(
      overrides: <Override>[
        wishlistRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: const BreadcrumbScope(
          label: 'Wishlist',
          child: WishlistScreen(),
        ),
      ),
    );
  }

  group('WishlistScreen', () {
    group('empty state', () {
      testWidgets('должен показывать empty state при пустом списке',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('No wishlist items yet'), findsOneWidget);
        expect(
          find.text('Tap + to add something to find later'),
          findsOneWidget,
        );
      });
    });

    group('список элементов', () {
      testWidgets('должен показывать список элементов',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1, item2]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Chrono Trigger'), findsOneWidget);
        expect(find.text('The Matrix'), findsOneWidget);
      });

      testWidgets('должен показывать заметку в subtitle',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('SNES RPG'), findsOneWidget);
      });

      testWidgets('должен показывать тип медиа как subtitle если нет заметки',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item2]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Movie'), findsOneWidget);
      });
    });

    group('resolved стиль', () {
      testWidgets('должен показывать resolved элементы с opacity',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1, resolvedItem]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Находим Opacity виджет для resolved элемента
        final Finder resolvedTileFinder = find.ancestor(
          of: find.text('Resolved Game'),
          matching: find.byType(Opacity),
        );
        expect(resolvedTileFinder, findsOneWidget);

        final Opacity opacity =
            tester.widget<Opacity>(resolvedTileFinder);
        expect(opacity.opacity, 0.5);
      });
    });

    group('FAB', () {
      testWidgets('должен показывать FAB', (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('должен открывать диалог при нажатии на FAB',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Add to Wishlist'), findsOneWidget);
      });
    });

    group('popup menu', () {
      testWidgets('должен показывать popup menu при нажатии',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(find.text('Search'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Mark resolved'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('должен показывать Unresolve для resolved элемента',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[resolvedItem]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(find.text('Unresolve'), findsOneWidget);
      });
    });

    group('фильтр resolved', () {
      testWidgets('должен скрывать resolved при toggle',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1, resolvedItem]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Оба элемента видны
        expect(find.text('Chrono Trigger'), findsOneWidget);
        expect(find.text('Resolved Game'), findsOneWidget);

        // Нажимаем кнопку hide resolved
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();

        // Resolved скрыт
        expect(find.text('Chrono Trigger'), findsOneWidget);
        expect(find.text('Resolved Game'), findsNothing);
      });
    });

    group('BreadcrumbAppBar', () {
      testWidgets('должен показывать Wishlist в хлебных крошках',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Wishlist'), findsOneWidget);
      });
    });

    group('clear resolved', () {
      testWidgets('должен показывать confirmation dialog',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[resolvedItem]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_sweep));
        await tester.pumpAndSettle();

        expect(find.text('Clear resolved'), findsOneWidget);
        expect(find.text('Delete 1 resolved item?'), findsOneWidget);
      });
    });
  });
}
