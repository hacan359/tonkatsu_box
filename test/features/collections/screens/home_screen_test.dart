import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/screens/home_screen.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/widgets/hero_collection_card.dart';
import 'package:xerabora/shared/widgets/shimmer_loading.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  group('HomeScreen', () {
    late SharedPreferences prefs;
    late MockCollectionRepository mockRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      mockRepo = MockCollectionRepository();
    });

    Widget createWidget({List<Collection> collections = const <Collection>[]}) {
      // Mock repository methods
      when(() => mockRepo.getAll()).thenAnswer((_) async => collections);
      when(() => mockRepo.getStats(any())).thenAnswer(
        (_) async => const CollectionStats(
          total: 5,
          completed: 2,
          inProgress: 1,
          notStarted: 1,
          dropped: 0,
          planned: 1,
        ),
      );

      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          collectionRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: BreadcrumbScope(
            label: 'Collections',
            child: HomeScreen(),
          ),
        ),
      );
    }

    testWidgets('должен показывать заголовок Collections',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('Collections'), findsOneWidget);
    });

    testWidgets('должен показывать кнопку New Collection в AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byTooltip('New Collection'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('должен показывать shimmer при загрузке',
        (WidgetTester tester) async {
      // Completer никогда не завершается — имитируем бесконечную загрузку
      final Completer<List<Collection>> completer =
          Completer<List<Collection>>();
      when(() => mockRepo.getAll())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          collectionRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: BreadcrumbScope(
            label: 'Collections',
            child: HomeScreen(),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(ShimmerListTile), findsWidgets);
    });

    testWidgets('должен показывать пустое состояние когда нет коллекций',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('No Collections Yet'), findsOneWidget);
    });

    testWidgets('должен показывать иконку пустого состояния',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.collections_bookmark_outlined), findsOneWidget);
    });

    testWidgets('должен показывать коллекцию как HeroCollectionCard',
        (WidgetTester tester) async {
      final List<Collection> collections = <Collection>[
        Collection(
          id: 1,
          name: 'Test Collection',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(createWidget(collections: collections));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Test Collection'), findsOneWidget);
      expect(find.byType(HeroCollectionCard), findsOneWidget);
    });

    testWidgets('должен показывать секцию Imported для импортированных',
        (WidgetTester tester) async {
      final List<Collection> collections = <Collection>[
        Collection(
          id: 1,
          name: 'Own Collection',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime.now(),
        ),
        Collection(
          id: 2,
          name: 'Imported Collection',
          author: 'Other',
          type: CollectionType.imported,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(createWidget(collections: collections));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Imported ('), findsOneWidget);
    });

    testWidgets('должен показывать секцию My Collections при > 3 own',
        (WidgetTester tester) async {
      final List<Collection> collections = List<Collection>.generate(
        5,
        (int i) => Collection(
          id: i + 1,
          name: 'Collection ${i + 1}',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createWidget(collections: collections));
      await tester.pump();
      await tester.pump();

      // 3 Hero + секция с остальными 2
      expect(find.byType(HeroCollectionCard), findsNWidgets(3));
      expect(find.textContaining('My Collections (5)'), findsOneWidget);
    });
  });
}
