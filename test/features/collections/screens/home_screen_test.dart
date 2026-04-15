import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/screens/home_screen.dart';
import 'package:xerabora/features/collections/widgets/collection_card.dart';
import 'package:xerabora/features/collections/widgets/collection_list_tile.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_list_sort_mode.dart';
import 'package:xerabora/shared/models/cover_info.dart';
import 'package:xerabora/shared/widgets/shimmer_loading.dart';

import '../../../helpers/test_helpers.dart';

// ==================== Тестовые Notifier-ы ====================

class TestCollectionListViewModeNotifier
    extends CollectionListViewModeNotifier {
  TestCollectionListViewModeNotifier(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

class TestCollectionListSortNotifier extends CollectionListSortNotifier {
  TestCollectionListSortNotifier(this._mode);
  final CollectionListSortMode _mode;

  @override
  CollectionListSortMode build() => _mode;

  @override
  Future<void> setSortMode(CollectionListSortMode mode) async {
    state = mode;
  }
}

class TestCollectionListSortDescNotifier extends CollectionListSortDescNotifier {
  TestCollectionListSortDescNotifier(this._desc);
  final bool _desc;

  @override
  bool build() => _desc;

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

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

    Widget createWidget({
      List<Collection> collections = const <Collection>[],
      bool isGridView = true,
      CollectionListSortMode sortMode = CollectionListSortMode.createdDate,
      bool sortDesc = false,
    }) {
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
          collectionListViewModeProvider
              .overrideWith(() => TestCollectionListViewModeNotifier(isGridView)),
          collectionListSortProvider
              .overrideWith(() => TestCollectionListSortNotifier(sortMode)),
          collectionListSortDescProvider
              .overrideWith(() => TestCollectionListSortDescNotifier(sortDesc)),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(body: HomeScreen()),
        ),
      );
    }

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
          collectionListViewModeProvider
              .overrideWith(() => TestCollectionListViewModeNotifier(true)),
          collectionListSortProvider
              .overrideWith(() => TestCollectionListSortNotifier(
                    CollectionListSortMode.createdDate,
                  )),
          collectionListSortDescProvider
              .overrideWith(() => TestCollectionListSortDescNotifier(false)),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(body: HomeScreen()),
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

    testWidgets('должен показывать GridView по умолчанию',
        (WidgetTester tester) async {
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

    group('режим отображения grid/list', () {
      testWidgets('должен показывать GridView в grid режиме',
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

        // Явно выставляем grid mode
        await tester.pumpWidget(
          createWidget(collections: collections, isGridView: true),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(CollectionCard), findsOneWidget);
      });

      testWidgets('должен показывать ListView в list режиме',
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

        // Выставляем list mode через провайдер
        await tester.pumpWidget(
          createWidget(collections: collections, isGridView: false),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(CollectionListTile), findsOneWidget);
      });
    });

    group('сортировка', () {
      testWidgets('должен сортировать по алфавиту',
          (WidgetTester tester) async {
        final List<Collection> collections = <Collection>[
          Collection(
            id: 1,
            name: 'Zebra',
            author: 'User',
            type: CollectionType.own,
            createdAt: DateTime(2024),
          ),
          Collection(
            id: 2,
            name: 'Alpha',
            author: 'User',
            type: CollectionType.own,
            createdAt: DateTime(2025),
          ),
        ];

        // Алфавитный режим, ascending (A→Z)
        await tester.pumpWidget(
          createWidget(
            collections: collections,
            sortMode: CollectionListSortMode.alphabetical,
            sortDesc: false,
          ),
        );
        await tester.pump();
        await tester.pump();

        // Alpha должна быть первой
        final List<CollectionCard> cards = tester
            .widgetList<CollectionCard>(find.byType(CollectionCard))
            .toList();
        expect(cards[0].collection.name, 'Alpha');
        expect(cards[1].collection.name, 'Zebra');
      });

      testWidgets('sortDesc=false → новые первыми (New, Old)',
          (WidgetTester tester) async {
        final List<Collection> collections = <Collection>[
          Collection(
            id: 1,
            name: 'Old',
            author: 'User',
            type: CollectionType.own,
            createdAt: DateTime(2020),
          ),
          Collection(
            id: 2,
            name: 'New',
            author: 'User',
            type: CollectionType.own,
            createdAt: DateTime(2025),
          ),
        ];

        await tester.pumpWidget(
          createWidget(
            collections: collections,
            sortMode: CollectionListSortMode.createdDate,
            sortDesc: false,
          ),
        );
        await tester.pump();
        await tester.pump();

        final List<CollectionCard> cards = tester
            .widgetList<CollectionCard>(find.byType(CollectionCard))
            .toList();
        expect(cards[0].collection.name, 'New');
        expect(cards[1].collection.name, 'Old');
      });

      testWidgets('sortDesc=true → старые первыми (Old, New)',
          (WidgetTester tester) async {
        final List<Collection> collections = <Collection>[
          Collection(
            id: 1,
            name: 'Old',
            author: 'User',
            type: CollectionType.own,
            createdAt: DateTime(2020),
          ),
          Collection(
            id: 2,
            name: 'New',
            author: 'User',
            type: CollectionType.own,
            createdAt: DateTime(2025),
          ),
        ];

        await tester.pumpWidget(
          createWidget(
            collections: collections,
            sortMode: CollectionListSortMode.createdDate,
            sortDesc: true,
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump();

        final List<CollectionCard> cards = tester
            .widgetList<CollectionCard>(find.byType(CollectionCard))
            .toList();
        expect(cards[0].collection.name, 'Old');
        expect(cards[1].collection.name, 'New');
      });
    });
  });
}
