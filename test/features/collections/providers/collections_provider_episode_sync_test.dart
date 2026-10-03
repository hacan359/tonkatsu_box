import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/episode_tracker_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

const int _collectionId = 1;

class _RecordingTracker extends EpisodeTrackerNotifier {
  _RecordingTracker(
    this.markCalls,
    this.unmarkCalls, {
    this.cleared = const <(int, int), DateTime?>{},
    this.restoreCalls,
  });

  final List<DateTime?> markCalls;
  final List<void> unmarkCalls;
  final WatchedMarks cleared;
  final List<(WatchedMarks, bool)>? restoreCalls;

  // Skips the real build: no DB, no eager loads.
  @override
  EpisodeTrackerState build(EpisodeTrackerArg arg) =>
      const EpisodeTrackerState();

  @override
  Future<void> markAllWatched({DateTime? at}) async => markCalls.add(at);

  @override
  Future<WatchedMarks> unmarkAllWatched() async {
    unmarkCalls.add(null);
    return cleared;
  }

  @override
  Future<void> restoreWatched(
    WatchedMarks marks, {
    bool syncStatus = true,
  }) async =>
      restoreCalls?.add((marks, syncStatus));
}

void main() {
  late MockCollectionRepository mockRepository;
  late SharedPreferences sharedPrefs;
  late List<DateTime?> markCalls;
  late List<void> unmarkCalls;

  setUpAll(registerAllFallbacks);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sharedPrefs = await SharedPreferences.getInstance();
    mockRepository = MockCollectionRepository();
    markCalls = <DateTime?>[];
    unmarkCalls = <void>[];

    when(() => mockRepository.updateItemStatus(
          any(),
          any(),
          mediaType: any(named: 'mediaType'),
        )).thenAnswer((_) async {});
    when(() => mockRepository.updateItemActivityDates(
          any(),
          startedAt: any(named: 'startedAt'),
          completedAt: any(named: 'completedAt'),
          lastActivityAt: any(named: 'lastActivityAt'),
          clearStartedAt: any(named: 'clearStartedAt'),
          clearCompletedAt: any(named: 'clearCompletedAt'),
        )).thenAnswer((_) async {});
    when(() => mockRepository.updateItemRewatchCount(any(), any()))
        .thenAnswer((_) async {});
  });

  ProviderContainer createContainer(
    List<CollectionItem> initialItems, {
    WatchedMarks cleared = const <(int, int), DateTime?>{},
    List<(WatchedMarks, bool)>? restoreCalls,
  }) {
    when(() => mockRepository.getItemsWithData(_collectionId))
        .thenAnswer((_) async => initialItems);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepository),
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        episodeTrackerNotifierProvider.overrideWith(
          () => _RecordingTracker(
            markCalls,
            unmarkCalls,
            cleared: cleared,
            restoreCalls: restoreCalls,
          ),
        ),
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

  CollectionItem tvItem({ItemStatus status = ItemStatus.notStarted}) =>
      createTestCollectionItem(
        id: 1,
        collectionId: _collectionId,
        mediaType: MediaType.tvShow,
        externalId: 100,
        status: status,
        tvShow: createTestTvShow(),
      );

  group('CollectionItemsNotifier episode sync', () {
    group('updateStatus', () {
      test('entering completed marks every episode', () async {
        final ProviderContainer container =
            createContainer(<CollectionItem>[tvItem()]);
        final CollectionItemsNotifier notifier = await loadNotifier(container);

        await notifier.updateStatus(1, ItemStatus.completed, MediaType.tvShow);
        await Future<void>.delayed(Duration.zero);

        expect(markCalls, hasLength(1));
        expect(markCalls.single, isNotNull);
        expect(unmarkCalls, isEmpty);
      });

      for (final ItemStatus target in <ItemStatus>[
        ItemStatus.notStarted,
        ItemStatus.inProgress,
        ItemStatus.planned,
        ItemStatus.dropped,
        ItemStatus.replaying,
        ItemStatus.ignored,
      ]) {
        test('leaving completed for $target clears every episode', () async {
          final ProviderContainer container = createContainer(
              <CollectionItem>[tvItem(status: ItemStatus.completed)]);
          final CollectionItemsNotifier notifier =
              await loadNotifier(container);

          await notifier.updateStatus(1, target, MediaType.tvShow);
          await Future<void>.delayed(Duration.zero);

          expect(unmarkCalls, hasLength(1));
          expect(markCalls, isEmpty);
        });
      }

      test('a transition not touching completed leaves episodes alone',
          () async {
        final ProviderContainer container = createContainer(
            <CollectionItem>[tvItem(status: ItemStatus.inProgress)]);
        final CollectionItemsNotifier notifier = await loadNotifier(container);

        await notifier.updateStatus(1, ItemStatus.planned, MediaType.tvShow);
        await Future<void>.delayed(Duration.zero);

        expect(markCalls, isEmpty);
        expect(unmarkCalls, isEmpty);
      });

      test('the same status again is a no-op for episodes', () async {
        final ProviderContainer container = createContainer(
            <CollectionItem>[tvItem(status: ItemStatus.completed)]);
        final CollectionItemsNotifier notifier = await loadNotifier(container);

        await notifier.updateStatus(1, ItemStatus.completed, MediaType.tvShow);
        await Future<void>.delayed(Duration.zero);

        expect(markCalls, isEmpty);
        expect(unmarkCalls, isEmpty);
      });

      test('an item without an episode tracker is skipped', () async {
        final ProviderContainer container = createContainer(<CollectionItem>[
          createTestCollectionItem(
            id: 1,
            collectionId: _collectionId,
            mediaType: MediaType.game,
            game: createTestGame(),
          ),
        ]);
        final CollectionItemsNotifier notifier = await loadNotifier(container);

        await notifier.updateStatus(1, ItemStatus.completed, MediaType.game);
        await Future<void>.delayed(Duration.zero);

        expect(markCalls, isEmpty);
      });

      test('syncEpisodes: false skips the sync (tracker-originated change)',
          () async {
        final ProviderContainer container =
            createContainer(<CollectionItem>[tvItem()]);
        final CollectionItemsNotifier notifier = await loadNotifier(container);

        await notifier.updateStatus(
          1,
          ItemStatus.completed,
          MediaType.tvShow,
          syncEpisodes: false,
        );
        await Future<void>.delayed(Duration.zero);

        expect(markCalls, isEmpty);
        expect(
          container
              .read(collectionItemsNotifierProvider(_collectionId))
              .valueOrNull
              ?.single
              .status,
          ItemStatus.completed,
        );
      });
    });

    group('undo', () {
      final WatchedMarks marks = <(int, int), DateTime?>{
        (1, 1): DateTime(2023, 2, 3),
        (1, 2): null,
      };

      CollectionItem completedItem() => createTestCollectionItem(
            id: 1,
            collectionId: _collectionId,
            mediaType: MediaType.tvShow,
            externalId: 100,
            status: ItemStatus.completed,
            startedAt: DateTime(2023, 1, 1),
            completedAt: DateTime(2023, 3, 1),
            rewatchCount: 2,
            tvShow: createTestTvShow(),
          );

      test('leaving completed hands back the erased marks and the old item',
          () async {
        final ProviderContainer container =
            createContainer(<CollectionItem>[completedItem()], cleared: marks);
        final CollectionItemsNotifier notifier = await loadNotifier(container);

        final ClearedEpisodeMarks? cleared = await notifier.updateStatus(
            1, ItemStatus.inProgress, MediaType.tvShow);

        expect(cleared, isNotNull);
        expect(cleared?.marks, marks);
        expect(cleared?.before.status, ItemStatus.completed);
      });

      test('nothing to clear means nothing to undo', () async {
        final ProviderContainer container =
            createContainer(<CollectionItem>[completedItem()]);
        final CollectionItemsNotifier notifier = await loadNotifier(container);

        expect(
          await notifier.updateStatus(
              1, ItemStatus.inProgress, MediaType.tvShow),
          isNull,
        );
      });

      test('a change that does not leave completed returns null', () async {
        final ProviderContainer container =
            createContainer(<CollectionItem>[tvItem()], cleared: marks);
        final CollectionItemsNotifier notifier = await loadNotifier(container);

        expect(
          await notifier.updateStatus(1, ItemStatus.planned, MediaType.tvShow),
          isNull,
        );
      });

      test('restoreCompleted puts back status, dates, replays and marks',
          () async {
        final List<(WatchedMarks, bool)> restoreCalls =
            <(WatchedMarks, bool)>[];
        final ProviderContainer container = createContainer(
          <CollectionItem>[completedItem()],
          cleared: marks,
          restoreCalls: restoreCalls,
        );
        final CollectionItemsNotifier notifier = await loadNotifier(container);
        final ClearedEpisodeMarks? cleared = await notifier.updateStatus(
            1, ItemStatus.inProgress, MediaType.tvShow);
        markCalls.clear();
        unmarkCalls.clear();

        await notifier.restoreCompleted(cleared ?? fail('no undo offered'));

        verify(() => mockRepository.updateItemStatus(
              1,
              ItemStatus.completed,
              mediaType: MediaType.tvShow,
            )).called(1);
        verify(() => mockRepository.updateItemActivityDates(
              1,
              startedAt: DateTime(2023, 1, 1),
              completedAt: DateTime(2023, 3, 1),
              lastActivityAt: null,
              clearStartedAt: false,
              clearCompletedAt: false,
            )).called(1);
        verify(() => mockRepository.updateItemRewatchCount(1, 2)).called(1);
        // Marks come back verbatim, not re-filled by the completed sync.
        expect(markCalls, isEmpty);
        expect(unmarkCalls, isEmpty);
        expect(restoreCalls, <(WatchedMarks, bool)>[(marks, false)]);

        final CollectionItem restored = container
            .read(collectionItemsNotifierProvider(_collectionId))
            .requireValue
            .single;
        expect(restored.status, ItemStatus.completed);
        expect(restored.completedAt, DateTime(2023, 3, 1));
        expect(restored.rewatchCount, 2);
      });
    });

    group('updateActivityDates', () {
      test('a completion date marks episodes with that date', () async {
        final ProviderContainer container = createContainer(
            <CollectionItem>[tvItem(status: ItemStatus.inProgress)]);
        final CollectionItemsNotifier notifier = await loadNotifier(container);
        final DateTime finished = DateTime(2024, 3, 10);

        await notifier.updateActivityDates(1, completedAt: finished);
        await Future<void>.delayed(Duration.zero);

        expect(markCalls, <DateTime?>[finished]);
      });

      test('a start date alone does not touch episodes', () async {
        final ProviderContainer container =
            createContainer(<CollectionItem>[tvItem()]);
        final CollectionItemsNotifier notifier = await loadNotifier(container);

        await notifier.updateActivityDates(1, startedAt: DateTime(2024));
        await Future<void>.delayed(Duration.zero);

        expect(markCalls, isEmpty);
        expect(unmarkCalls, isEmpty);
      });
    });

    group('syncEpisodesToStatus', () {
      test('resolves the tracker by the item collection, show and source',
          () async {
        final ProviderContainer container =
            createContainer(<CollectionItem>[]);

        syncEpisodesToStatus(
          container.read,
          tvItem(status: ItemStatus.completed),
          ItemStatus.dropped,
        );
        await Future<void>.delayed(Duration.zero);

        expect(unmarkCalls, hasLength(1));
      });
    });
  });
}
