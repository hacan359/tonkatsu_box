// Тесты провайдера CollectionItemsNotifier — синхронизация статуса при ручном
// изменении дат активности.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

// Моки
class MockCollectionRepository extends Mock implements CollectionRepository {}

// Тестовые данные
const int testCollectionId = 1;

CollectionItem _makeItem({
  int id = 1,
  int? collectionId = testCollectionId,
  MediaType mediaType = MediaType.game,
  int externalId = 100,
  ItemStatus status = ItemStatus.notStarted,
  DateTime? startedAt,
  DateTime? completedAt,
}) {
  return CollectionItem(
    id: id,
    collectionId: collectionId,
    mediaType: mediaType,
    externalId: externalId,
    status: status,
    addedAt: DateTime(2024),
    startedAt: startedAt,
    completedAt: completedAt,
  );
}

void main() {
  late MockCollectionRepository mockRepository;
  late SharedPreferences sharedPrefs;

  setUpAll(() {
    registerFallbackValue(ItemStatus.notStarted);
    registerFallbackValue(MediaType.game);
    registerFallbackValue(DateTime(2024));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sharedPrefs = await SharedPreferences.getInstance();
    mockRepository = MockCollectionRepository();

    // Дефолтные моки
    when(() => mockRepository.updateItemActivityDates(
          any(),
          startedAt: any(named: 'startedAt'),
          completedAt: any(named: 'completedAt'),
          lastActivityAt: any(named: 'lastActivityAt'),
        )).thenAnswer((_) async {});

    when(() => mockRepository.updateItemStatus(
          any(),
          any(),
          mediaType: any(named: 'mediaType'),
        )).thenAnswer((_) async {});
  });

  /// Создаёт контейнер с замоканным репозиторием и заранее загруженными items.
  ProviderContainer createContainer({
    required List<CollectionItem> initialItems,
    int? collectionId = testCollectionId,
  }) {
    when(() => mockRepository.getItemsWithData(collectionId))
        .thenAnswer((_) async => initialItems);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepository),
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Ожидает, пока notifier загрузит данные.
  Future<void> waitForLoad(ProviderContainer container, int? collectionId) async {
    // Инициализируем провайдер (вызывает build → _loadItems)
    container.read(collectionItemsNotifierProvider(collectionId));
    // Ждём завершения асинхронной загрузки
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('CollectionItemsNotifier.updateActivityDates', () {
    group('синхронизация статуса при установке startedAt', () {
      test('should change status from notStarted to inProgress when startedAt is set', () async {
        final CollectionItem item = _makeItem(status: ItemStatus.notStarted);
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime startDate = DateTime(2024, 3, 15);

        await notifier.updateActivityDates(1, startedAt: startDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.startedAt, startDate);
        expect(items.first.status, ItemStatus.inProgress);
      });

      test('should change status from planned to inProgress when startedAt is set', () async {
        final CollectionItem item = _makeItem(status: ItemStatus.planned);
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime startDate = DateTime(2024, 3, 15);

        await notifier.updateActivityDates(1, startedAt: startDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.status, ItemStatus.inProgress);
      });

      test('should keep inProgress status when startedAt is set and already inProgress', () async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.inProgress,
          startedAt: DateTime(2024, 1, 1),
        );
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime newStartDate = DateTime(2024, 3, 15);

        await notifier.updateActivityDates(1, startedAt: newStartDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.startedAt, newStartDate);
        expect(items.first.status, ItemStatus.inProgress);
      });

      test('should keep completed status when startedAt is set', () async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.completed,
          startedAt: DateTime(2024, 1, 1),
          completedAt: DateTime(2024, 2, 1),
        );
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime newStartDate = DateTime(2024, 3, 15);

        await notifier.updateActivityDates(1, startedAt: newStartDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.startedAt, newStartDate);
        expect(items.first.status, ItemStatus.completed);
      });

      test('should keep dropped status when startedAt is set', () async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.dropped,
          startedAt: DateTime(2024, 1, 1),
        );
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime newStartDate = DateTime(2024, 3, 15);

        await notifier.updateActivityDates(1, startedAt: newStartDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.startedAt, newStartDate);
        expect(items.first.status, ItemStatus.dropped);
      });
    });

    group('синхронизация статуса при установке completedAt', () {
      test('should change status to completed when completedAt is set (was notStarted)', () async {
        final CollectionItem item = _makeItem(status: ItemStatus.notStarted);
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime completeDate = DateTime(2024, 6, 1);

        await notifier.updateActivityDates(1, completedAt: completeDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.completedAt, completeDate);
        expect(items.first.status, ItemStatus.completed);
      });

      test('should change status to completed when completedAt is set (was inProgress)', () async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.inProgress,
          startedAt: DateTime(2024, 1, 1),
        );
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime completeDate = DateTime(2024, 6, 1);

        await notifier.updateActivityDates(1, completedAt: completeDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.completedAt, completeDate);
        expect(items.first.status, ItemStatus.completed);
        // startedAt не должен измениться
        expect(items.first.startedAt, DateTime(2024, 1, 1));
      });

      test('should change status to completed when completedAt is set (was planned)', () async {
        final CollectionItem item = _makeItem(status: ItemStatus.planned);
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime completeDate = DateTime(2024, 6, 1);

        await notifier.updateActivityDates(1, completedAt: completeDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.completedAt, completeDate);
        expect(items.first.status, ItemStatus.completed);
      });

      test('should keep completed status when completedAt is updated and already completed', () async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.completed,
          startedAt: DateTime(2024, 1, 1),
          completedAt: DateTime(2024, 5, 1),
        );
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime newCompleteDate = DateTime(2024, 6, 1);

        await notifier.updateActivityDates(1, completedAt: newCompleteDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.completedAt, newCompleteDate);
        expect(items.first.status, ItemStatus.completed);
      });

      test('should change dropped to completed when completedAt is set', () async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.dropped,
          startedAt: DateTime(2024, 1, 1),
        );
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime completeDate = DateTime(2024, 6, 1);

        await notifier.updateActivityDates(1, completedAt: completeDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.completedAt, completeDate);
        expect(items.first.status, ItemStatus.completed);
      });
    });

    group('обе даты устанавливаются одновременно', () {
      test('should set status to completed when both startedAt and completedAt are set', () async {
        final CollectionItem item = _makeItem(status: ItemStatus.notStarted);
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime startDate = DateTime(2024, 1, 1);
        final DateTime completeDate = DateTime(2024, 6, 1);

        await notifier.updateActivityDates(
          1,
          startedAt: startDate,
          completedAt: completeDate,
          lastActivityAt: DateTime.now(),
        );

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.startedAt, startDate);
        expect(items.first.completedAt, completeDate);
        // completedAt имеет приоритет → статус completed
        expect(items.first.status, ItemStatus.completed);
      });
    });

    group('edge cases', () {
      test('should do nothing when items state is null', () async {
        // Не загружаем данные — state будет AsyncLoading
        when(() => mockRepository.getItemsWithData(testCollectionId))
            .thenAnswer((_) async => <CollectionItem>[]);
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            collectionRepositoryProvider.overrideWithValue(mockRepository),
            sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          ],
        );
        addTearDown(container.dispose);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);

        // Вызываем пока данные ещё не загружены (state == AsyncLoading)
        // Не должен кидать исключение
        await notifier.updateActivityDates(
          999,
          startedAt: DateTime(2024, 3, 15),
          lastActivityAt: DateTime.now(),
        );

        // Просто проверяем что не упало
        expect(true, isTrue);
      });

      test('should not change other items in the list', () async {
        final CollectionItem item1 = _makeItem(
          id: 1,
          status: ItemStatus.notStarted,
        );
        final CollectionItem item2 = _makeItem(
          id: 2,
          status: ItemStatus.notStarted,
          externalId: 200,
        );
        final ProviderContainer container = createContainer(
          initialItems: <CollectionItem>[item1, item2],
        );
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);

        await notifier.updateActivityDates(
          1,
          startedAt: DateTime(2024, 3, 15),
          lastActivityAt: DateTime.now(),
        );

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.length, 2);
        // item2 не должен измениться
        expect(items[1].status, ItemStatus.notStarted);
        expect(items[1].startedAt, isNull);
      });

      test('should only update dates (no status change) when only lastActivityAt is set', () async {
        final CollectionItem item = _makeItem(status: ItemStatus.notStarted);
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);

        await notifier.updateActivityDates(1, lastActivityAt: DateTime(2024, 3, 15));

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.status, ItemStatus.notStarted);
        expect(items.first.lastActivityAt, DateTime(2024, 3, 15));
      });

      test('should work for tvShow media type', () async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.tvShow,
          status: ItemStatus.notStarted,
        );
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);
        final DateTime startDate = DateTime(2024, 3, 15);

        await notifier.updateActivityDates(1, startedAt: startDate, lastActivityAt: DateTime.now());

        final List<CollectionItem>? items =
            container.read(collectionItemsNotifierProvider(testCollectionId)).valueOrNull;
        expect(items, isNotNull);
        expect(items!.first.status, ItemStatus.inProgress);
      });

      test('should persist status change to repository', () async {
        final CollectionItem item = _makeItem(status: ItemStatus.notStarted);
        final ProviderContainer container = createContainer(initialItems: <CollectionItem>[item]);
        await waitForLoad(container, testCollectionId);

        final CollectionItemsNotifier notifier =
            container.read(collectionItemsNotifierProvider(testCollectionId).notifier);

        await notifier.updateActivityDates(
          1,
          startedAt: DateTime(2024, 3, 15),
          lastActivityAt: DateTime.now(),
        );

        // Должен вызвать updateItemStatus для сохранения нового статуса в БД
        verify(() => mockRepository.updateItemStatus(
              1,
              ItemStatus.inProgress,
              mediaType: MediaType.game,
            )).called(1);
      });
    });
  });
}
