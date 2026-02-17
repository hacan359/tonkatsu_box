// Тесты провайдеров All Items (Home tab).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/home/providers/all_items_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/collection_sort_mode.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockDatabase extends Mock implements Database {}

/// Вспомогательная функция: прокачать event queue для async fire-and-forget.
Future<void> _pump([int times = 5]) async {
  for (int i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

CollectionItem _makeItem({
  required int id,
  String name = 'Item',
  DateTime? addedAt,
  int? userRating,
  ItemStatus status = ItemStatus.notStarted,
  int collectionId = 1,
}) {
  return CollectionItem(
    id: id,
    collectionId: collectionId,
    mediaType: MediaType.game,
    externalId: id * 100,
    sortOrder: id,
    status: status,
    addedAt: addedAt ?? DateTime(2026, 1, id),
    userRating: userRating,
    game: Game(id: id * 100, name: name),
  );
}

void main() {
  late MockCollectionRepository mockRepo;
  late MockDatabaseService mockDb;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();

    mockRepo = MockCollectionRepository();
    when(() => mockRepo.getAllItemsWithData())
        .thenAnswer((_) async => <CollectionItem>[]);
    when(() => mockRepo.getAll())
        .thenAnswer((_) async => <Collection>[]);
    when(() => mockRepo.getStats(any()))
        .thenAnswer((_) async => CollectionStats.empty);

    mockDb = MockDatabaseService();
    when(() => mockDb.database).thenAnswer((_) async => MockDatabase());
  });

  ProviderContainer createContainer({
    List<Override> extraOverrides = const <Override>[],
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        databaseServiceProvider.overrideWithValue(mockDb),
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // ==================== AllItemsSortNotifier ====================

  group('AllItemsSortNotifier', () {
    test('по умолчанию возвращает addedDate', () {
      final ProviderContainer container = createContainer();

      final CollectionSortMode mode =
          container.read(allItemsSortProvider);

      expect(mode, CollectionSortMode.addedDate);
    });

    test('загружает сохранённый режим из SharedPreferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'all_items_sort_mode': 'name',
      });
      prefs = await SharedPreferences.getInstance();

      final ProviderContainer container = createContainer();
      container.read(allItemsSortProvider);
      await _pump();

      expect(
          container.read(allItemsSortProvider), CollectionSortMode.name);
    });

    test('загружает rating из SharedPreferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'all_items_sort_mode': 'rating',
      });
      prefs = await SharedPreferences.getInstance();

      final ProviderContainer container = createContainer();
      container.read(allItemsSortProvider);
      await _pump();

      expect(container.read(allItemsSortProvider),
          CollectionSortMode.rating);
    });

    test('невалидное значение в prefs возвращает addedDate', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'all_items_sort_mode': 'invalid_value',
      });
      prefs = await SharedPreferences.getInstance();

      final ProviderContainer container = createContainer();
      container.read(allItemsSortProvider);
      await _pump();

      expect(container.read(allItemsSortProvider),
          CollectionSortMode.addedDate);
    });

    test('setSortMode обновляет состояние', () async {
      final ProviderContainer container = createContainer();

      await container
          .read(allItemsSortProvider.notifier)
          .setSortMode(CollectionSortMode.rating);

      expect(container.read(allItemsSortProvider),
          CollectionSortMode.rating);
    });

    test('setSortMode сохраняет в SharedPreferences', () async {
      final ProviderContainer container = createContainer();

      await container
          .read(allItemsSortProvider.notifier)
          .setSortMode(CollectionSortMode.name);

      expect(prefs.getString('all_items_sort_mode'), 'name');
    });

    test('setSortMode сохраняет каждый режим корректно', () async {
      final ProviderContainer container = createContainer();
      final AllItemsSortNotifier notifier =
          container.read(allItemsSortProvider.notifier);

      for (final CollectionSortMode mode in CollectionSortMode.values) {
        await notifier.setSortMode(mode);
        expect(container.read(allItemsSortProvider), mode);
        expect(prefs.getString('all_items_sort_mode'), mode.value);
      }
    });
  });

  // ==================== AllItemsSortDescNotifier ====================

  group('AllItemsSortDescNotifier', () {
    test('по умолчанию возвращает false', () {
      final ProviderContainer container = createContainer();

      expect(container.read(allItemsSortDescProvider), false);
    });

    test('загружает true из SharedPreferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'all_items_sort_desc': true,
      });
      prefs = await SharedPreferences.getInstance();

      final ProviderContainer container = createContainer();
      container.read(allItemsSortDescProvider);
      await _pump();

      expect(container.read(allItemsSortDescProvider), true);
    });

    test('toggle переключает с false на true', () async {
      final ProviderContainer container = createContainer();

      await container.read(allItemsSortDescProvider.notifier).toggle();

      expect(container.read(allItemsSortDescProvider), true);
    });

    test('toggle переключает с true на false', () async {
      final ProviderContainer container = createContainer();

      await container.read(allItemsSortDescProvider.notifier).toggle();
      await container.read(allItemsSortDescProvider.notifier).toggle();

      expect(container.read(allItemsSortDescProvider), false);
    });

    test('toggle сохраняет значение в SharedPreferences', () async {
      final ProviderContainer container = createContainer();

      await container.read(allItemsSortDescProvider.notifier).toggle();

      expect(prefs.getBool('all_items_sort_desc'), true);
    });
  });

  // ==================== AllItemsNotifier ====================

  group('AllItemsNotifier', () {
    test('начинает с AsyncLoading', () {
      final ProviderContainer container = createContainer();

      final AsyncValue<List<CollectionItem>> state =
          container.read(allItemsNotifierProvider);

      expect(state, isA<AsyncLoading<List<CollectionItem>>>());
    });

    test('загружает элементы и возвращает AsyncData', () async {
      final List<CollectionItem> items = <CollectionItem>[
        _makeItem(id: 1, addedAt: DateTime(2026, 1, 1)),
        _makeItem(id: 2, addedAt: DateTime(2026, 1, 5)),
        _makeItem(id: 3, addedAt: DateTime(2026, 1, 3)),
      ];
      when(() => mockRepo.getAllItemsWithData())
          .thenAnswer((_) async => items);

      final ProviderContainer container = createContainer();
      container.read(allItemsNotifierProvider);
      await _pump();

      final AsyncValue<List<CollectionItem>> state =
          container.read(allItemsNotifierProvider);
      expect(state, isA<AsyncData<List<CollectionItem>>>());
      expect(state.valueOrNull?.length, 3);
    });

    test('сортирует по addedDate (новейшие первыми) по умолчанию',
        () async {
      final List<CollectionItem> items = <CollectionItem>[
        _makeItem(id: 1, addedAt: DateTime(2026, 1, 1)),
        _makeItem(id: 2, addedAt: DateTime(2026, 1, 15)),
        _makeItem(id: 3, addedAt: DateTime(2026, 1, 10)),
      ];
      when(() => mockRepo.getAllItemsWithData())
          .thenAnswer((_) async => items);

      final ProviderContainer container = createContainer();
      container.read(allItemsNotifierProvider);
      await _pump();

      final List<CollectionItem>? sorted =
          container.read(allItemsNotifierProvider).valueOrNull;
      expect(sorted, isNotNull);
      expect(sorted!.map((CollectionItem i) => i.id).toList(),
          <int>[2, 3, 1]);
    });

    test('manual подменяется на addedDate', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'all_items_sort_mode': 'manual',
      });
      prefs = await SharedPreferences.getInstance();

      final List<CollectionItem> items = <CollectionItem>[
        _makeItem(id: 1, addedAt: DateTime(2026, 1, 1)),
        _makeItem(id: 2, addedAt: DateTime(2026, 1, 15)),
      ];
      when(() => mockRepo.getAllItemsWithData())
          .thenAnswer((_) async => items);

      final ProviderContainer container = createContainer();
      // listen() создаёт подписку — провайдер перестраивается при
      // изменении allItemsSortProvider (после _loadFromPrefs).
      container.listen(allItemsNotifierProvider, (_, _) {});
      await _pump(10);

      final List<CollectionItem>? sorted =
          container.read(allItemsNotifierProvider).valueOrNull;
      expect(sorted, isNotNull);
      // addedDate: новейшие первыми
      expect(sorted!.first.id, 2);
    });

    test('возвращает пустой список если элементов нет', () async {
      when(() => mockRepo.getAllItemsWithData())
          .thenAnswer((_) async => <CollectionItem>[]);

      final ProviderContainer container = createContainer();
      container.read(allItemsNotifierProvider);
      await _pump();

      final AsyncValue<List<CollectionItem>> state =
          container.read(allItemsNotifierProvider);
      expect(state, isA<AsyncData<List<CollectionItem>>>());
      expect(state.valueOrNull, isEmpty);
    });

    test('обрабатывает ошибку из репозитория', () async {
      when(() => mockRepo.getAllItemsWithData())
          .thenThrow(Exception('DB error'));

      final ProviderContainer container = createContainer();
      container.read(allItemsNotifierProvider);
      await _pump();

      final AsyncValue<List<CollectionItem>> state =
          container.read(allItemsNotifierProvider);
      expect(state, isA<AsyncError<List<CollectionItem>>>());
    });

    test('refresh перезагружает элементы', () async {
      int callCount = 0;
      when(() => mockRepo.getAllItemsWithData()).thenAnswer((_) async {
        callCount++;
        return <CollectionItem>[
          _makeItem(id: callCount),
        ];
      });

      final ProviderContainer container = createContainer();
      container.read(allItemsNotifierProvider);
      await _pump();

      // Первая загрузка
      expect(
        container.read(allItemsNotifierProvider).valueOrNull?.first.id,
        1,
      );

      // Refresh
      await container.read(allItemsNotifierProvider.notifier).refresh();

      expect(
        container.read(allItemsNotifierProvider).valueOrNull?.first.id,
        2,
      );
    });

    test('пересортирует при смене режима сортировки', () async {
      final List<CollectionItem> items = <CollectionItem>[
        _makeItem(id: 1, name: 'Zelda', addedAt: DateTime(2026, 1, 1)),
        _makeItem(id: 2, name: 'Ape', addedAt: DateTime(2026, 1, 15)),
      ];
      when(() => mockRepo.getAllItemsWithData())
          .thenAnswer((_) async => items);

      final ProviderContainer container = createContainer();
      container.listen(allItemsNotifierProvider, (_, _) {});
      await _pump();

      // По умолчанию addedDate: id=2 первый (новейший)
      expect(
        container.read(allItemsNotifierProvider).valueOrNull?.first.id,
        2,
      );

      // Переключаем на name
      await container
          .read(allItemsSortProvider.notifier)
          .setSortMode(CollectionSortMode.name);
      await _pump();

      // По имени A-Z: Ape (id=2) первый
      expect(
        container
            .read(allItemsNotifierProvider)
            .valueOrNull
            ?.first
            .itemName,
        'Ape',
      );
    });

    test('учитывает isDescending при сортировке', () async {
      final List<CollectionItem> items = <CollectionItem>[
        _makeItem(id: 1, name: 'Ape', addedAt: DateTime(2026, 1, 1)),
        _makeItem(id: 2, name: 'Zelda', addedAt: DateTime(2026, 1, 15)),
      ];
      when(() => mockRepo.getAllItemsWithData())
          .thenAnswer((_) async => items);

      final ProviderContainer container = createContainer();

      // Включаем сортировку по имени
      await container
          .read(allItemsSortProvider.notifier)
          .setSortMode(CollectionSortMode.name);
      container.listen(allItemsNotifierProvider, (_, _) {});
      await _pump();

      // A-Z: Ape первый
      expect(
        container.read(allItemsNotifierProvider).valueOrNull?.first.id,
        1,
      );

      // Toggle desc → Z-A
      await container.read(allItemsSortDescProvider.notifier).toggle();
      await _pump();

      expect(
        container.read(allItemsNotifierProvider).valueOrNull?.first.id,
        2,
      );
    });
  });

  // ==================== collectionNamesProvider ====================

  group('collectionNamesProvider', () {
    test('строит карту id→name из списка коллекций', () async {
      final List<Collection> collections = <Collection>[
        Collection(
          id: 1,
          name: 'Games',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026),
        ),
        Collection(
          id: 2,
          name: 'Movies',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026),
        ),
      ];
      when(() => mockRepo.getAll()).thenAnswer((_) async => collections);

      final ProviderContainer container = createContainer();
      container.read(collectionsProvider);
      await _pump();

      final Map<int, String> names =
          container.read(collectionNamesProvider);
      expect(names.length, 2);
      expect(names[1], 'Games');
      expect(names[2], 'Movies');
    });

    test('возвращает пустую карту когда нет коллекций', () async {
      when(() => mockRepo.getAll())
          .thenAnswer((_) async => <Collection>[]);

      final ProviderContainer container = createContainer();
      container.read(collectionsProvider);
      await _pump();

      final Map<int, String> names =
          container.read(collectionNamesProvider);
      expect(names, isEmpty);
    });

    test('возвращает пустую карту при AsyncLoading', () {
      final ProviderContainer container = createContainer();

      // Без pump — collectionsProvider в состоянии loading
      final Map<int, String> names =
          container.read(collectionNamesProvider);
      expect(names, isEmpty);
    });

    test('возвращает пустую карту при AsyncError', () async {
      when(() => mockRepo.getAll())
          .thenThrow(Exception('Network error'));

      final ProviderContainer container = createContainer();
      container.read(collectionsProvider);
      await _pump();

      final Map<int, String> names =
          container.read(collectionNamesProvider);
      expect(names, isEmpty);
    });
  });
}
