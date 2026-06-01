import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/data/repositories/wishlist_repository.dart';
import 'package:tonkatsu_box/features/wishlist/screens/wishlist_screen.dart';
import 'package:tonkatsu_box/shared/widgets/mini_markdown_text.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockWishlistRepository mockRepo;

  setUp(() {
    mockRepo = MockWishlistRepository();
  });

  setUpAll(() {
    registerAllFallbacks();
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
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        theme: ThemeData.dark(),
        home: const Scaffold(body: WishlistScreen()),
      ),
    );
  }

  group('WishlistScreen', () {
    group('empty state', () {
      testWidgets('should show empty state when empty списке',
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
      testWidgets('should show список элементов',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1, item2]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Chrono Trigger'), findsOneWidget);
        expect(find.text('The Matrix'), findsOneWidget);
      });

      testWidgets('should show заметку через MiniMarkdownText',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byType(MiniMarkdownText), findsOneWidget);
        expect(find.text('SNES RPG'), findsOneWidget);
      });

      testWidgets('should show тип медиа как subtitle если нет заметки',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item2]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Movie'), findsOneWidget);
      });
    });

    group('resolved стиль', () {
      testWidgets('should show resolved элементы с opacity',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1, resolvedItem]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

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

    group('context menu', () {
      testWidgets('should show context menu при long press',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Chrono Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Search'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Mark resolved'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('should show Unresolve для resolved элемента',
          (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[resolvedItem]);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Resolved Game'));
        await tester.pumpAndSettle();

        expect(find.text('Unresolve'), findsOneWidget);
      });
    });
  });
}
