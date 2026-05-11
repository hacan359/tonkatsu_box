// Тесты moveItemToTop / moveItemToBottom в CollectionItemsNotifier.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/data/repositories/game_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/collection_sort_mode.dart';

import '../../../helpers/test_helpers.dart';

const int _collectionId = 1;

void main() {
  late MockCollectionRepository mockRepository;
  late MockDatabaseService mockDb;
  late MockGameRepository mockGameRepo;
  late SharedPreferences sharedPrefs;

  setUpAll(registerAllFallbacks);

  setUp(() async {
    // Активируем ручную сортировку — иначе applySortMode переставит items.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'collection_sort_$_collectionId': CollectionSortMode.manual.value,
    });
    sharedPrefs = await SharedPreferences.getInstance();
    mockRepository = MockCollectionRepository();
    mockDb = MockDatabaseService();
    mockGameRepo = MockGameRepository();

    when(() => mockDb.reorderItems(any(), any()))
        .thenAnswer((_) async {});
  });

  ProviderContainer createContainer(List<CollectionItem> initialItems) {
    when(() => mockRepository.getItemsWithData(_collectionId))
        .thenAnswer((_) async => initialItems);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepository),
        databaseServiceProvider.overrideWithValue(mockDb),
        gameRepositoryProvider.overrideWithValue(mockGameRepo),
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<CollectionItemsNotifier> loadNotifier(
    ProviderContainer container,
  ) async {
    container.read(collectionItemsNotifierProvider(_collectionId));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return container
        .read(collectionItemsNotifierProvider(_collectionId).notifier);
  }

  List<int> currentOrder(ProviderContainer container) {
    return container
        .read(collectionItemsNotifierProvider(_collectionId))
        .valueOrNull!
        .map((CollectionItem i) => i.id)
        .toList();
  }

  List<CollectionItem> threeItems() => <CollectionItem>[
        createTestCollectionItem(id: 10, sortOrder: 0),
        createTestCollectionItem(id: 20, sortOrder: 1),
        createTestCollectionItem(id: 30, sortOrder: 2),
      ];

  group('CollectionItemsNotifier.moveItemToTop', () {
    test('moves middle item to index 0 and persists new order', () async {
      final ProviderContainer container = createContainer(threeItems());
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.moveItemToTop(20);

      expect(currentOrder(container), <int>[20, 10, 30]);
      verify(() => mockDb.reorderItems(_collectionId, <int>[20, 10, 30]))
          .called(1);
    });

    test('moves last item to index 0', () async {
      final ProviderContainer container = createContainer(threeItems());
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.moveItemToTop(30);

      expect(currentOrder(container), <int>[30, 10, 20]);
    });

    test('is no-op when item already first', () async {
      final ProviderContainer container = createContainer(threeItems());
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.moveItemToTop(10);

      expect(currentOrder(container), <int>[10, 20, 30]);
      verifyNever(() => mockDb.reorderItems(any(), any()));
    });

    test('is no-op when item id not found', () async {
      final ProviderContainer container = createContainer(threeItems());
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.moveItemToTop(999);

      expect(currentOrder(container), <int>[10, 20, 30]);
      verifyNever(() => mockDb.reorderItems(any(), any()));
    });
  });

  group('CollectionItemsNotifier.moveItemToBottom', () {
    test('moves first item to last index and persists new order', () async {
      final ProviderContainer container = createContainer(threeItems());
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.moveItemToBottom(10);

      expect(currentOrder(container), <int>[20, 30, 10]);
      verify(() => mockDb.reorderItems(_collectionId, <int>[20, 30, 10]))
          .called(1);
    });

    test('moves middle item to last index', () async {
      final ProviderContainer container = createContainer(threeItems());
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.moveItemToBottom(20);

      expect(currentOrder(container), <int>[10, 30, 20]);
    });

    test('is no-op when item already last', () async {
      final ProviderContainer container = createContainer(threeItems());
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.moveItemToBottom(30);

      expect(currentOrder(container), <int>[10, 20, 30]);
      verifyNever(() => mockDb.reorderItems(any(), any()));
    });

    test('is no-op when item id not found', () async {
      final ProviderContainer container = createContainer(threeItems());
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.moveItemToBottom(999);

      expect(currentOrder(container), <int>[10, 20, 30]);
      verifyNever(() => mockDb.reorderItems(any(), any()));
    });
  });
}
