import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/episode_tracker_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/tier_lists/providers/tier_list_detail_provider.dart';

import '../../../helpers/test_helpers.dart';

const int testCollectionId = 1;

/// Counts family rebuilds so tests can assert tracker invalidation without
/// wiring the real tracker's DB/API dependencies.
class _ProbeEpisodeTrackerNotifier extends EpisodeTrackerNotifier {
  static int buildCount = 0;

  @override
  EpisodeTrackerState build(EpisodeTrackerArg arg) {
    buildCount++;
    return const EpisodeTrackerState();
  }
}

/// Counts family rebuilds so tests can assert tier-list invalidation without
/// wiring the real tier-list DB dependencies.
class _ProbeTierListDetailNotifier extends TierListDetailNotifier {
  static int buildCount = 0;

  @override
  TierListDetailState build(int arg) {
    buildCount++;
    return TierListDetailState.loading();
  }
}

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

  setUpAll(registerAllFallbacks);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sharedPrefs = await SharedPreferences.getInstance();
    mockRepository = MockCollectionRepository();

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

  Future<void> waitForLoad(ProviderContainer container, int? collectionId) async {
    container.read(collectionItemsNotifierProvider(collectionId));
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
        // completedAt takes priority over startedAt.
        expect(items.first.status, ItemStatus.completed);
      });
    });

    group('edge cases', () {
      test('should do nothing when items state is null', () async {
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

        // Call while state is still AsyncLoading — must not throw.
        await notifier.updateActivityDates(
          999,
          startedAt: DateTime(2024, 3, 15),
          lastActivityAt: DateTime.now(),
        );

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

        verify(() => mockRepository.updateItemStatus(
              1,
              ItemStatus.inProgress,
              mediaType: MediaType.game,
            )).called(1);
      });
    });
  });

  group('CollectionItemsNotifier.removeItem', () {
    late MockTierListDao mockTierListDao;
    late MockCalendarEntryDao mockCalendarDao;
    late MockTrackedReleaseDao mockTrackedDao;

    setUp(() {
      mockTierListDao = MockTierListDao();
      when(() => mockTierListDao.getTierListById(any()))
          .thenAnswer((_) async => null);
      mockCalendarDao = MockCalendarEntryDao();
      mockTrackedDao = MockTrackedReleaseDao();
      when(() => mockCalendarDao.deleteOrphaned()).thenAnswer((_) async {});
      when(() => mockTrackedDao.deleteOrphaned()).thenAnswer((_) async {});
    });

    ProviderContainer createTierContainer({
      required List<CollectionItem> initialItems,
      int? collectionId = testCollectionId,
    }) {
      when(() => mockRepository.getItemsWithData(collectionId))
          .thenAnswer((_) async => initialItems);
      when(() => mockRepository.removeItem(any()))
          .thenAnswer((_) async {});

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          collectionRepositoryProvider.overrideWithValue(mockRepository),
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          tierListDaoProvider.overrideWithValue(mockTierListDao),
          calendarEntryDaoProvider.overrideWithValue(mockCalendarDao),
          trackedReleaseDaoProvider.overrideWithValue(mockTrackedDao),
          tierListDetailProvider.overrideWith(_ProbeTierListDetailNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('инвалидирует tierListDetailProvider при удалении', () async {
      _ProbeTierListDetailNotifier.buildCount = 0;

      final ProviderContainer container = createTierContainer(
        initialItems: <CollectionItem>[_makeItem()],
      );
      await waitForLoad(container, testCollectionId);

      container.read(tierListDetailProvider(10));
      expect(_ProbeTierListDetailNotifier.buildCount, 1);

      when(() => mockRepository.getItemsWithData(testCollectionId))
          .thenAnswer((_) async => <CollectionItem>[]);

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      await notifier.removeItem(1, mediaType: MediaType.game);

      container.read(tierListDetailProvider(10));
      expect(_ProbeTierListDetailNotifier.buildCount, 2);
      verify(() => mockRepository.removeItem(1)).called(1);
    });
  });

  group('CollectionItemsNotifier.addItem', () {
    test('инвалидирует tierListDetailProvider при добавлении', () async {
      _ProbeTierListDetailNotifier.buildCount = 0;
      when(() => mockRepository.getItemsWithData(testCollectionId))
          .thenAnswer((_) async => <CollectionItem>[]);
      when(() => mockRepository.addItem(
            collectionId: any(named: 'collectionId'),
            mediaType: any(named: 'mediaType'),
            externalId: any(named: 'externalId'),
            platformId: any(named: 'platformId'),
            source: any(named: 'source'),
            authorComment: any(named: 'authorComment'),
          )).thenAnswer((_) async => 42);

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          collectionRepositoryProvider.overrideWithValue(mockRepository),
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          tierListDetailProvider.overrideWith(_ProbeTierListDetailNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      await waitForLoad(container, testCollectionId);

      // A tier list created from this collection: the new item must appear
      // in its unranked pool, which requires a provider reload.
      container.read(tierListDetailProvider(10));
      expect(_ProbeTierListDetailNotifier.buildCount, 1);

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      final bool added = await notifier.addItem(
        mediaType: MediaType.game,
        externalId: 100,
      );

      expect(added, isTrue);
      container.read(tierListDetailProvider(10));
      expect(_ProbeTierListDetailNotifier.buildCount, 2);
    });
  });

  group('CollectionItemsNotifier.moveItem', () {
    late MockTierListDao mockTierListDao;
    late MockGlobalTagDao mockTagDao;

    setUp(() {
      mockTierListDao = MockTierListDao();
      mockTagDao = MockGlobalTagDao();
      when(() => mockTierListDao.getTierListById(any()))
          .thenAnswer((_) async => null);
      when(() => mockTagDao.copyItemTags(any(), any()))
          .thenAnswer((_) async => 0);
    });

    ProviderContainer createMoveContainer({
      required List<CollectionItem> initialItems,
      int? collectionId = testCollectionId,
    }) {
      when(() => mockRepository.getItemsWithData(collectionId))
          .thenAnswer((_) async => initialItems);
      when(() => mockRepository.moveItemToCollection(any(), any()))
          .thenAnswer((_) async => true);

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          collectionRepositoryProvider.overrideWithValue(mockRepository),
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          tierListDaoProvider.overrideWithValue(mockTierListDao),
          globalTagDaoProvider.overrideWithValue(mockTagDao),
          episodeTrackerNotifierProvider
              .overrideWith(_ProbeEpisodeTrackerNotifier.new),
          tierListDetailProvider.overrideWith(_ProbeTierListDetailNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<int> trackerBuildsAfterMove(MediaType mediaType) async {
      _ProbeEpisodeTrackerNotifier.buildCount = 0;
      when(() => mockTierListDao.removeItemFromCollectionTierLists(
          1, testCollectionId)).thenAnswer((_) async {});

      final ProviderContainer container = createMoveContainer(
        initialItems: <CollectionItem>[_makeItem(mediaType: mediaType)],
      );
      await waitForLoad(container, testCollectionId);

      const EpisodeTrackerArg trackerArg = (
        collectionId: testCollectionId,
        showId: 500,
        source: DataSource.tmdb,
      );
      container.read(episodeTrackerNotifierProvider(trackerArg));
      expect(_ProbeEpisodeTrackerNotifier.buildCount, 1);

      when(() => mockRepository.getItemsWithData(testCollectionId))
          .thenAnswer((_) async => <CollectionItem>[]);
      await container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier)
          .moveItem(1, targetCollectionId: 99, mediaType: mediaType);

      container.read(episodeTrackerNotifierProvider(trackerArg));
      return _ProbeEpisodeTrackerNotifier.buildCount;
    }

    test('инвалидирует трекеры эпизодов при перемещении сериала', () async {
      expect(await trackerBuildsAfterMove(MediaType.tvShow), 2);
    });

    test('не трогает трекеры эпизодов при перемещении игры', () async {
      expect(await trackerBuildsAfterMove(MediaType.game), 1);
    });

    test('удаляет entries из тир-листов исходной коллекции при перемещении',
        () async {
      when(() => mockTierListDao.removeItemFromCollectionTierLists(
            1, testCollectionId))
          .thenAnswer((_) async {});

      final ProviderContainer container = createMoveContainer(
        initialItems: <CollectionItem>[_makeItem()],
      );
      await waitForLoad(container, testCollectionId);

      when(() => mockRepository.getItemsWithData(testCollectionId))
          .thenAnswer((_) async => <CollectionItem>[]);

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      await notifier.moveItem(
        1,
        targetCollectionId: 99,
        mediaType: MediaType.game,
      );

      verify(
        () => mockTierListDao.removeItemFromCollectionTierLists(
          1,
          testCollectionId,
        ),
      ).called(1);
    });

    test('инвалидирует tierListDetailProvider при перемещении', () async {
      _ProbeTierListDetailNotifier.buildCount = 0;
      when(() => mockTierListDao.removeItemFromCollectionTierLists(
            1, testCollectionId))
          .thenAnswer((_) async {});

      final ProviderContainer container = createMoveContainer(
        initialItems: <CollectionItem>[_makeItem()],
      );
      await waitForLoad(container, testCollectionId);

      // The target collection's tier list: the item was never placed in it,
      // yet it must reload so the item shows up in its unranked pool.
      container.read(tierListDetailProvider(10));
      expect(_ProbeTierListDetailNotifier.buildCount, 1);

      when(() => mockRepository.getItemsWithData(testCollectionId))
          .thenAnswer((_) async => <CollectionItem>[]);

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      await notifier.moveItem(
        1,
        targetCollectionId: 99,
        mediaType: MediaType.game,
      );

      container.read(tierListDetailProvider(10));
      expect(_ProbeTierListDetailNotifier.buildCount, 2);
    });

    test('не вызывает removeItemFromCollectionTierLists для uncategorized',
        () async {
      when(() => mockRepository.getItemsWithData(null))
          .thenAnswer(
              (_) async => <CollectionItem>[_makeItem(collectionId: null)]);
      when(() => mockRepository.moveItemToCollection(any(), any()))
          .thenAnswer((_) async => true);

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          collectionRepositoryProvider.overrideWithValue(mockRepository),
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          tierListDaoProvider.overrideWithValue(mockTierListDao),
          globalTagDaoProvider.overrideWithValue(mockTagDao),
        ],
      );
      addTearDown(container.dispose);

      container.read(collectionItemsNotifierProvider(null));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      when(() => mockRepository.getItemsWithData(null))
          .thenAnswer((_) async => <CollectionItem>[]);

      final CollectionItemsNotifier notifier =
          container.read(collectionItemsNotifierProvider(null).notifier);
      await notifier.moveItem(
        1,
        targetCollectionId: 99,
        mediaType: MediaType.game,
      );

      verifyNever(
        () => mockTierListDao.removeItemFromCollectionTierLists(any(), any()),
      );
    });
  });

  group('CollectionItemsNotifier global tags on move/clone', () {
    late MockTierListDao mockTierListDao;
    late MockGlobalTagDao mockTagDao;

    setUp(() {
      mockTierListDao = MockTierListDao();
      mockTagDao = MockGlobalTagDao();
      when(() => mockTierListDao.removeItemFromCollectionTierLists(
            any(),
            any(),
          )).thenAnswer((_) async {});
      when(() => mockTierListDao.getTierListById(any()))
          .thenAnswer((_) async => null);
      when(() => mockTagDao.copyItemTags(any(), any()))
          .thenAnswer((_) async => 0);
    });

    ProviderContainer createRemapContainer({
      required List<CollectionItem> initialItems,
      int? collectionId = testCollectionId,
    }) {
      when(() => mockRepository.getItemsWithData(collectionId))
          .thenAnswer((_) async => initialItems);
      when(() => mockRepository.moveItemToCollection(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockRepository.cloneItemToCollection(any(), any()))
          .thenAnswer((_) async => 777);
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          collectionRepositoryProvider.overrideWithValue(mockRepository),
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          tierListDaoProvider.overrideWithValue(mockTierListDao),
          globalTagDaoProvider.overrideWithValue(mockTagDao),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('moveItem never touches tags — they stay with the item', () async {
      final ProviderContainer container = createRemapContainer(
        initialItems: <CollectionItem>[_makeItem()],
      );
      await waitForLoad(container, testCollectionId);
      when(() => mockRepository.getItemsWithData(testCollectionId))
          .thenAnswer((_) async => <CollectionItem>[]);

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      await notifier.moveItem(
        1,
        targetCollectionId: 99,
        mediaType: MediaType.game,
      );

      verifyNever(() => mockTagDao.copyItemTags(any(), any()));
    });

    test('cloneItem carries the source tag links onto the copy', () async {
      when(() => mockTagDao.copyItemTags(1, 777))
          .thenAnswer((_) async => 2);

      final ProviderContainer container = createRemapContainer(
        initialItems: <CollectionItem>[_makeItem()],
      );
      await waitForLoad(container, testCollectionId);

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      final bool success = await notifier.cloneItem(
        1,
        targetCollectionId: 99,
        mediaType: MediaType.game,
      );

      expect(success, isTrue);
      verify(() => mockTagDao.copyItemTags(1, 777)).called(1);
    });

    test('cloneItem still copies links when the source has no tags',
        () async {
      final ProviderContainer container = createRemapContainer(
        initialItems: <CollectionItem>[_makeItem()],
      );
      await waitForLoad(container, testCollectionId);

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      await notifier.cloneItem(
        1,
        targetCollectionId: 99,
        mediaType: MediaType.game,
      );

      verify(() => mockTagDao.copyItemTags(1, 777)).called(1);
    });

    test('cloneItem returns false when repo reports duplicate', () async {
      final ProviderContainer container = createRemapContainer(
        initialItems: <CollectionItem>[_makeItem()],
      );
      await waitForLoad(container, testCollectionId);
      when(() => mockRepository.cloneItemToCollection(any(), any()))
          .thenAnswer((_) async => null);

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      final bool success = await notifier.cloneItem(
        1,
        targetCollectionId: 99,
        mediaType: MediaType.game,
      );

      expect(success, isFalse);
      verifyNever(() => mockTagDao.copyItemTags(any(), any()));
    });
  });

  group('CollectionItemsNotifier.setOverrideName', () {
    test('writes trimmed override and updates state in place', () async {
      final CollectionItem item = _makeItem(id: 42);
      final ProviderContainer container =
          createContainer(initialItems: <CollectionItem>[item]);
      await waitForLoad(container, testCollectionId);
      when(() => mockRepository.setItemOverrideName(any(), any()))
          .thenAnswer((_) async {});

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      await notifier.setOverrideName(42, '  FF7R  ');

      verify(() => mockRepository.setItemOverrideName(42, 'FF7R'))
          .called(1);

      final List<CollectionItem> after = container
          .read(collectionItemsNotifierProvider(testCollectionId))
          .requireValue;
      expect(after.single.overrideName, 'FF7R');
    });

    test('empty input clears the override on the row in state', () async {
      final CollectionItem item =
          _makeItem(id: 42).copyWith(overrideName: 'FF7R');
      final ProviderContainer container =
          createContainer(initialItems: <CollectionItem>[item]);
      await waitForLoad(container, testCollectionId);
      when(() => mockRepository.setItemOverrideName(any(), any()))
          .thenAnswer((_) async {});

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      await notifier.setOverrideName(42, '   ');

      verify(() => mockRepository.setItemOverrideName(42, null)).called(1);

      final List<CollectionItem> after = container
          .read(collectionItemsNotifierProvider(testCollectionId))
          .requireValue;
      expect(after.single.overrideName, isNull);
    });

    test('null input clears the override', () async {
      final CollectionItem item =
          _makeItem(id: 42).copyWith(overrideName: 'FF7R');
      final ProviderContainer container =
          createContainer(initialItems: <CollectionItem>[item]);
      await waitForLoad(container, testCollectionId);
      when(() => mockRepository.setItemOverrideName(any(), any()))
          .thenAnswer((_) async {});

      final CollectionItemsNotifier notifier = container
          .read(collectionItemsNotifierProvider(testCollectionId).notifier);
      await notifier.setOverrideName(42, null);

      verify(() => mockRepository.setItemOverrideName(42, null)).called(1);

      final List<CollectionItem> after = container
          .read(collectionItemsNotifierProvider(testCollectionId))
          .requireValue;
      expect(after.single.overrideName, isNull);
    });
  });
}
