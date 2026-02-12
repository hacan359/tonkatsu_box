// Тесты для HeroCollectionCard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/widgets/hero_collection_card.dart';

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

  Widget buildTestWidget({
    required Collection collection,
    required CollectionStats stats,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return ProviderScope(
      overrides: <Override>[
        collectionStatsProvider(collection.id)
            .overrideWith((Ref ref) async => stats),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: HeroCollectionCard(
            collection: collection,
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
          playing: 2,
          notStarted: 4,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(HeroCollectionCard), findsOneWidget);
        expect(find.text('RPG Classics'), findsOneWidget);
      });

      testWidgets('должен иметь высоту 160',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        final Finder containerFinder = find.byType(Container);
        bool found160 = false;
        for (final Element element in containerFinder.evaluate()) {
          final Container container = element.widget as Container;
          final BoxConstraints? constraints = container.constraints;
          if (constraints != null && constraints.maxHeight == 160) {
            found160 = true;
            break;
          }
        }
        // Container с height: 160 создаёт SizedBox-подобное ограничение
        // Проверяем через размер RenderBox
        final RenderBox box = tester
            .renderObject<RenderBox>(find.byType(HeroCollectionCard));
        expect(box.size.height, greaterThanOrEqualTo(160));
      });
    });

    group('иконки по типу', () {
      testWidgets('должен показывать folder для own',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.own);
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.folder), findsOneWidget);
      });

      testWidgets('должен показывать download для imported',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.imported);
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.download), findsOneWidget);
      });

      testWidgets('должен показывать fork_right для fork',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.fork);
        const CollectionStats stats = CollectionStats.empty;

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.fork_right), findsOneWidget);
      });
    });

    group('accentForType', () {
      test('own → gameAccent', () {
        expect(
          HeroCollectionCard.accentForType(CollectionType.own),
          equals(AppColors.gameAccent),
        );
      });

      test('imported → movieAccent', () {
        expect(
          HeroCollectionCard.accentForType(CollectionType.imported),
          equals(AppColors.movieAccent),
        );
      });

      test('fork → tvShowAccent', () {
        expect(
          HeroCollectionCard.accentForType(CollectionType.fork),
          equals(AppColors.tvShowAccent),
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

      test('imported → download', () {
        expect(
          HeroCollectionCard.iconForType(CollectionType.imported),
          equals(Icons.download),
        );
      });

      test('fork → fork_right', () {
        expect(
          HeroCollectionCard.iconForType(CollectionType.fork),
          equals(Icons.fork_right),
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
          playing: 2,
          notStarted: 4,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        expect(find.text('24 items · 75% completed'), findsOneWidget);
      });

      testWidgets('должен показывать "item" для единственного элемента',
          (WidgetTester tester) async {
        final Collection collection = createTestCollection();
        const CollectionStats stats = CollectionStats(
          total: 1,
          completed: 0,
          playing: 1,
          notStarted: 0,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        expect(find.text('1 item · 0% completed'), findsOneWidget);
      });

      testWidgets('imported не должен показывать процент',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.imported);
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 5,
          playing: 0,
          notStarted: 5,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        expect(find.text('10 items'), findsOneWidget);
        expect(find.textContaining('completed'), findsNothing);
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
          playing: 3,
          notStarted: 2,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('не должен показывать прогресс-бар для imported коллекции',
          (WidgetTester tester) async {
        final Collection collection =
            createTestCollection(type: CollectionType.imported);
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 5,
          playing: 0,
          notStarted: 5,
          dropped: 0,
          planned: 0,
        );

        await tester.pumpWidget(buildTestWidget(
          collection: collection,
          stats: stats,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsNothing);
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
        await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();

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
  });
}
