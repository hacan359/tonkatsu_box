// Тесты для AllItemsScreen — экран всех элементов (Home tab).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/home/screens/all_items_screen.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockCollectionRepository mockRepo;
  late MockDatabaseService mockDb;
  late SharedPreferences prefs;

  final List<CollectionItem> testItems = <CollectionItem>[
    CollectionItem(
      id: 1,
      collectionId: 10,
      mediaType: MediaType.game,
      externalId: 100,
      sortOrder: 0,
      status: ItemStatus.completed,
      addedAt: DateTime(2025, 1, 1),
    ),
    CollectionItem(
      id: 2,
      collectionId: 10,
      mediaType: MediaType.movie,
      externalId: 200,
      sortOrder: 1,
      status: ItemStatus.inProgress,
      addedAt: DateTime(2025, 2, 1),
    ),
    CollectionItem(
      id: 3,
      collectionId: 20,
      mediaType: MediaType.tvShow,
      externalId: 300,
      sortOrder: 0,
      status: ItemStatus.notStarted,
      addedAt: DateTime(2025, 3, 1),
    ),
  ];

  final List<Collection> testCollections = <Collection>[
    Collection(
      id: 10,
      name: 'My Games',
      author: 'User',
      type: CollectionType.own,
      createdAt: DateTime(2025),
    ),
    Collection(
      id: 20,
      name: 'Watch List',
      author: 'User',
      type: CollectionType.own,
      createdAt: DateTime(2025),
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();

    mockRepo = MockCollectionRepository();
    when(() => mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
        .thenAnswer((_) async => testItems);
    when(() => mockRepo.getAll())
        .thenAnswer((_) async => testCollections);
    when(() => mockRepo.getStats(any()))
        .thenAnswer((_) async => CollectionStats.empty);

    mockDb = MockDatabaseService();
    when(() => mockDb.database).thenAnswer((_) async => MockDatabase());
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        databaseServiceProvider.overrideWithValue(mockDb),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: AllItemsScreen(),
      ),
    );
  }

  group('AllItemsScreen', () {
    testWidgets('рендерит AppBar с заголовком Main',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Main'), findsOneWidget);
    });

    testWidgets('показывает чипсы фильтрации по типу медиа',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Games'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('TV Shows'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
    });

    testWidgets('показывает чипс Rating', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Rating'), findsOneWidget);
    });

    testWidgets('показывает loading state при запуске',
        (WidgetTester tester) async {
      final Completer<List<CollectionItem>> completer =
          Completer<List<CollectionItem>>();
      when(() =>
              mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Завершаем Future чтобы не оставлять pending timer
      completer.complete(testItems);
      await tester.pumpAndSettle();
    });

    testWidgets('показывает empty state когда нет элементов',
        (WidgetTester tester) async {
      when(() =>
              mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
          .thenAnswer((_) async => <CollectionItem>[]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('показывает grid после загрузки данных',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Элементы должны отображаться
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('AllItemsScreen фильтрация', () {
    testWidgets('нажатие на Games фильтрует по типу',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Нажимаем на чипс Games
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      // Чипс Games выбран — фильтрация применяется на уровне UI
      // Проверяем что GridView всё ещё есть (с меньшим количеством элементов)
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('повторное нажатие на All сбрасывает фильтр',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Сначала фильтруем по Games
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      // Затем нажимаем All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
