import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/widgets/collection_tile.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/collection.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

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

  Widget createTestWidget({
    required Collection collection,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    required CollectionStats stats,
  }) {
    return ProviderScope(
      overrides: <Override>[
        collectionStatsProvider(collection.id)
            .overrideWith((Ref ref) async => stats),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: CollectionTile(
            collection: collection,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ),
    );
  }

  group('CollectionTile', () {
    testWidgets('должен отображать название коллекции', (WidgetTester tester) async {
      final Collection collection = createTestCollection(name: 'My Games');
      const CollectionStats stats = CollectionStats(
        total: 10,
        completed: 5,
        inProgress: 3,
        notStarted: 2,
        dropped: 0,
        planned: 0,
      );

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Games'), findsOneWidget);
    });

    testWidgets('должен отображать иконку папки для own коллекции',
        (WidgetTester tester) async {
      final Collection collection = createTestCollection(type: CollectionType.own);
      const CollectionStats stats = CollectionStats.empty;

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('должен отображать иконку folder для imported коллекции',
        (WidgetTester tester) async {
      final Collection collection = createTestCollection(type: CollectionType.imported);
      const CollectionStats stats = CollectionStats.empty;

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('должен отображать иконку folder для fork коллекции',
        (WidgetTester tester) async {
      final Collection collection = createTestCollection(type: CollectionType.fork);
      const CollectionStats stats = CollectionStats.empty;

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('должен отображать статистику', (WidgetTester tester) async {
      final Collection collection = createTestCollection();
      const CollectionStats stats = CollectionStats(
        total: 10,
        completed: 5,
        inProgress: 3,
        notStarted: 2,
        dropped: 0,
        planned: 0,
      );

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('10 items'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });

    testWidgets('должен отображать "item" в единственном числе',
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

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 item'), findsOneWidget);
    });

    testWidgets('должен показывать процент для imported коллекции',
        (WidgetTester tester) async {
      final Collection collection = createTestCollection(type: CollectionType.imported);
      const CollectionStats stats = CollectionStats(
        total: 10,
        completed: 5,
        inProgress: 5,
        notStarted: 0,
        dropped: 0,
        planned: 0,
      );

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('10 items'), findsOneWidget);
      expect(find.textContaining('completed'), findsOneWidget);
    });

    testWidgets('должен вызывать onTap при нажатии', (WidgetTester tester) async {
      bool tapped = false;
      final Collection collection = createTestCollection();
      const CollectionStats stats = CollectionStats.empty;

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
        onTap: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('должен вызывать onLongPress при долгом нажатии',
        (WidgetTester tester) async {
      bool longPressed = false;
      final Collection collection = createTestCollection();
      const CollectionStats stats = CollectionStats.empty;

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
        onLongPress: () => longPressed = true,
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
    });

    testWidgets('должен отображать стрелку навигации',
        (WidgetTester tester) async {
      final Collection collection = createTestCollection();
      const CollectionStats stats = CollectionStats.empty;

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('должен показывать прогресс-бар для own коллекции с играми',
        (WidgetTester tester) async {
      final Collection collection = createTestCollection(type: CollectionType.own);
      const CollectionStats stats = CollectionStats(
        total: 10,
        completed: 5,
        inProgress: 5,
        notStarted: 0,
        dropped: 0,
        planned: 0,
      );

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('не должен показывать прогресс-бар для пустой коллекции',
        (WidgetTester tester) async {
      final Collection collection = createTestCollection();
      const CollectionStats stats = CollectionStats.empty;

      await tester.pumpWidget(createTestWidget(
        collection: collection,
        stats: stats,
      ));
      await tester.pumpAndSettle();

      // Один индикатор может быть от загрузки, но не от прогресса коллекции
      // Пустая коллекция (total=0) не должна показывать прогресс-бар
      final Finder progressBars = find.byType(LinearProgressIndicator);
      // Проверяем что нет прогресс-бара с определённым value (для прогресса коллекции)
      final Iterable<LinearProgressIndicator> widgets = tester
          .widgetList<LinearProgressIndicator>(progressBars)
          .where((LinearProgressIndicator w) => w.value != null && w.value! > 0);
      expect(widgets.isEmpty, isTrue);
    });
  });

  group('CollectionSectionHeader', () {
    testWidgets('должен отображать заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollectionSectionHeader(
              title: 'My Collections',
            ),
          ),
        ),
      );

      expect(find.text('My Collections'), findsOneWidget);
    });

    testWidgets('должен отображать счётчик если передан',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollectionSectionHeader(
              title: 'Imported',
              count: 5,
            ),
          ),
        ),
      );

      expect(find.text('Imported'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('не должен отображать счётчик если count = null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollectionSectionHeader(
              title: 'Section',
              count: null,
            ),
          ),
        ),
      );

      expect(find.text('Section'), findsOneWidget);
      // Проверяем что нет контейнера со счётчиком
      expect(find.text('0'), findsNothing);
    });
  });
}
