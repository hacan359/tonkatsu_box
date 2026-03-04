// Тесты автоматического обновления статуса манги при изменении прогресса чтения.

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

import '../../../helpers/test_helpers.dart';

const int _collectionId = 1;

CollectionItem _mangaItem({
  int id = 1,
  ItemStatus status = ItemStatus.notStarted,
  int currentChapter = 0,
  int currentVolume = 0,
  int? totalChapters,
  int? totalVolumes,
  DateTime? startedAt,
  DateTime? completedAt,
}) {
  return createTestCollectionItem(
    id: id,
    collectionId: _collectionId,
    mediaType: MediaType.manga,
    status: status,
    currentEpisode: currentChapter,
    currentSeason: currentVolume,
    startedAt: startedAt,
    completedAt: completedAt,
    manga: createTestManga(
      chapters: totalChapters,
      volumes: totalVolumes,
    ),
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

    when(() => mockRepository.updateItemProgress(
          any(),
          currentSeason: any(named: 'currentSeason'),
          currentEpisode: any(named: 'currentEpisode'),
        )).thenAnswer((_) async {});

    when(() => mockRepository.updateItemStatus(
          any(),
          any(),
          mediaType: any(named: 'mediaType'),
        )).thenAnswer((_) async {});
  });

  ProviderContainer createContainer({
    required List<CollectionItem> initialItems,
  }) {
    when(() => mockRepository.getItemsWithData(_collectionId))
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

  Future<CollectionItemsNotifier> loadNotifier(
    ProviderContainer container,
  ) async {
    container.read(collectionItemsNotifierProvider(_collectionId));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return container
        .read(collectionItemsNotifierProvider(_collectionId).notifier);
  }

  CollectionItem currentItem(ProviderContainer container, {int id = 1}) {
    final List<CollectionItem> items = container
        .read(collectionItemsNotifierProvider(_collectionId))
        .valueOrNull!;
    return items.firstWhere((CollectionItem i) => i.id == id);
  }

  group('CollectionItemsNotifier.updateProgress manga auto-status', () {
    test('notStarted → inProgress when chapter incremented from 0', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(status: ItemStatus.notStarted, totalChapters: 100),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 1);

      expect(currentItem(container).status, ItemStatus.inProgress);
      verify(() => mockRepository.updateItemStatus(
            1,
            ItemStatus.inProgress,
            mediaType: MediaType.manga,
          )).called(1);
    });

    test('planned → inProgress when volume incremented from 0', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(status: ItemStatus.planned, totalChapters: 100),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentSeason: 1);

      expect(currentItem(container).status, ItemStatus.inProgress);
    });

    test('inProgress → completed when chapters reach total', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(
            status: ItemStatus.inProgress,
            currentChapter: 99,
            totalChapters: 100,
            startedAt: DateTime(2024),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 100);

      expect(currentItem(container).status, ItemStatus.completed);
      verify(() => mockRepository.updateItemStatus(
            1,
            ItemStatus.completed,
            mediaType: MediaType.manga,
          )).called(1);
    });

    test('notStarted → completed when chapters set to total at once', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(status: ItemStatus.notStarted, totalChapters: 10),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 10);

      expect(currentItem(container).status, ItemStatus.completed);
    });

    test('inProgress → notStarted when progress reset to 0/0', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(
            status: ItemStatus.inProgress,
            currentChapter: 5,
            currentVolume: 2,
            totalChapters: 100,
            startedAt: DateTime(2024),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 0, currentSeason: 0);

      expect(currentItem(container).status, ItemStatus.notStarted);
      verify(() => mockRepository.updateItemStatus(
            1,
            ItemStatus.notStarted,
            mediaType: MediaType.manga,
          )).called(1);
    });

    test('completed → notStarted when progress reset to 0/0', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(
            status: ItemStatus.completed,
            currentChapter: 100,
            totalChapters: 100,
            startedAt: DateTime(2024),
            completedAt: DateTime(2024, 6),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 0, currentSeason: 0);

      expect(currentItem(container).status, ItemStatus.notStarted);
    });

    test('completed → inProgress when chapters decreased below total', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(
            status: ItemStatus.completed,
            currentChapter: 100,
            totalChapters: 100,
            startedAt: DateTime(2024),
            completedAt: DateTime(2024, 6),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 50);

      expect(currentItem(container).status, ItemStatus.inProgress);
      verify(() => mockRepository.updateItemStatus(
            1,
            ItemStatus.inProgress,
            mediaType: MediaType.manga,
          )).called(1);
    });

    test('dropped status is never overwritten', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(
            status: ItemStatus.dropped,
            currentChapter: 5,
            totalChapters: 100,
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 100);

      expect(currentItem(container).status, ItemStatus.dropped);
      verifyNever(() => mockRepository.updateItemStatus(
            any(),
            any(),
            mediaType: any(named: 'mediaType'),
          ));
    });

    test('no status change for non-manga items', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          createTestCollectionItem(
            id: 1,
            collectionId: _collectionId,
            mediaType: MediaType.tvShow,
            status: ItemStatus.notStarted,
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 1);

      expect(currentItem(container).status, ItemStatus.notStarted);
      verifyNever(() => mockRepository.updateItemStatus(
            any(),
            any(),
            mediaType: any(named: 'mediaType'),
          ));
    });

    test('no status change when already inProgress and chapter incremented', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(
            status: ItemStatus.inProgress,
            currentChapter: 5,
            totalChapters: 100,
            startedAt: DateTime(2024),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 6);

      // Status remains inProgress — no updateStatus call needed
      expect(currentItem(container).status, ItemStatus.inProgress);
      verifyNever(() => mockRepository.updateItemStatus(
            any(),
            any(),
            mediaType: any(named: 'mediaType'),
          ));
    });

    test('manga without totalChapters: notStarted → inProgress', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(status: ItemStatus.notStarted),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 1);

      expect(currentItem(container).status, ItemStatus.inProgress);
    });

    test('markCompleted triggers completed via auto-status', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _mangaItem(
            status: ItemStatus.inProgress,
            currentChapter: 5,
            totalChapters: 50,
            totalVolumes: 10,
            startedAt: DateTime(2024),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      // Simulates _markCompleted: sets chapters/volumes to total
      await notifier.updateProgress(
        1,
        currentEpisode: 50,
        currentSeason: 10,
      );

      expect(currentItem(container).status, ItemStatus.completed);
      verify(() => mockRepository.updateItemStatus(
            1,
            ItemStatus.completed,
            mediaType: MediaType.manga,
          )).called(1);
    });
  });
}
