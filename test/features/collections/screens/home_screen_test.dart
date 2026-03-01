import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/screens/home_screen.dart';
import 'package:xerabora/features/collections/widgets/collection_card.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/cover_info.dart';
import 'package:xerabora/shared/widgets/shimmer_loading.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('HomeScreen', () {
    late SharedPreferences prefs;
    late MockCollectionRepository mockRepo;
    late MockDatabaseService mockDb;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      mockRepo = MockCollectionRepository();
      mockDb = MockDatabaseService();
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
      when(() => mockRepo.getUncategorizedCount())
          .thenAnswer((_) async => 0);

      // Mock covers
      when(() => mockDb.getCollectionCovers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => <CoverInfo>[]);

      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          collectionRepositoryProvider.overrideWithValue(mockRepo),
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
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
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
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

      expect(find.byIcon(Icons.shelves), findsOneWidget);
    });

    testWidgets('должен показывать коллекцию как CollectionCard',
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
      expect(find.byType(CollectionCard), findsOneWidget);
    });

    testWidgets('должен показывать все коллекции в едином гриде',
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

      // Все коллекции как CollectionCard в гриде
      expect(find.byType(CollectionCard), findsNWidgets(2));
      expect(find.text('Imported Collection'), findsOneWidget);
    });

    testWidgets('должен показывать все 5 коллекций как CollectionCard',
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

      // Все 5 коллекций в едином гриде (нет разделения Hero/Tile)
      expect(find.byType(CollectionCard), findsNWidgets(5));
    });

    testWidgets('должен показывать GridView', (WidgetTester tester) async {
      final List<Collection> collections = <Collection>[
        Collection(
          id: 1,
          name: 'Collection 1',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(createWidget(collections: collections));
      await tester.pump();
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
