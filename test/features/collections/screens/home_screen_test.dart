import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/screens/home_screen.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/collection.dart';

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
          playing: 1,
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
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('должен показывать заголовок xeRAbora',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(); // Initial pump
      await tester.pump(); // Allow async to complete

      expect(find.text('xeRAbora'), findsOneWidget);
    });

    testWidgets('должен показывать кнопку настроек',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('должен показывать FAB New Collection',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('New Collection'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('должен показывать пустое состояние когда нет коллекций',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(); // Allow async to complete

      expect(find.text('No Collections Yet'), findsOneWidget);
    });

    testWidgets('должен показывать список коллекций',
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
      await tester.pump(); // Allow multiple async frames

      expect(find.text('Test Collection'), findsOneWidget);
    });

    testWidgets('должен показывать секцию My Collections',
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

      expect(find.text('My Collections'), findsOneWidget);
    });

    testWidgets('должен группировать коллекции по типу',
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

      expect(find.text('My Collections'), findsOneWidget);
      expect(find.text('Imported'), findsOneWidget);
    });

    testWidgets('кнопка поиска должна быть отключена когда API не готов',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Find search icon button
      final Finder searchButton = find.byIcon(Icons.search);
      expect(searchButton, findsOneWidget);

      // Icon button should be disabled (onPressed is null)
      final IconButton iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: searchButton,
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('кнопка поиска должна быть активна когда API готов',
        (WidgetTester tester) async {
      // Set up valid API credentials
      final int futureExpiry =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;

      SharedPreferences.setMockInitialValues(<String, Object>{
        'igdb_client_id': 'test_client_id',
        'igdb_client_secret': 'test_client_secret',
        'igdb_access_token': 'test_access_token',
        'igdb_token_expires': futureExpiry,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Find search icon button
      final Finder searchButton = find.byIcon(Icons.search);
      expect(searchButton, findsOneWidget);

      // Icon button should be enabled
      final IconButton iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: searchButton,
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.onPressed, isNotNull);
    });

    testWidgets('должен показывать иконку пустого состояния',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.collections_bookmark_outlined), findsOneWidget);
    });
  });
}
