import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

const int _collectionId = 1;

// The page read is stored in currentEpisode, the same field manga/anime reuse.
CollectionItem _bookItem({
  ItemStatus status = ItemStatus.notStarted,
  int currentPage = 0,
  int? totalPages,
  DateTime? startedAt,
  DateTime? completedAt,
}) {
  return createTestCollectionItem(
    id: 1,
    collectionId: _collectionId,
    mediaType: MediaType.book,
    status: status,
    currentEpisode: currentPage,
    startedAt: startedAt,
    completedAt: completedAt,
    book: createTestBook(pageCount: totalPages),
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

    when(() => mockRepository.updateItemActivityDates(
          any(),
          startedAt: any(named: 'startedAt'),
          completedAt: any(named: 'completedAt'),
          lastActivityAt: any(named: 'lastActivityAt'),
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

  CollectionItem currentItem(ProviderContainer container) {
    return container
        .read(collectionItemsNotifierProvider(_collectionId))
        .valueOrNull!
        .firstWhere((CollectionItem i) => i.id == 1);
  }

  group('CollectionItemsNotifier.updateProgress book auto-status', () {
    test('notStarted → inProgress when page advanced from 0', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _bookItem(status: ItemStatus.notStarted, totalPages: 300),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 10);

      expect(currentItem(container).status, ItemStatus.inProgress);
      verify(() => mockRepository.updateItemStatus(
            1,
            ItemStatus.inProgress,
            mediaType: MediaType.book,
          )).called(1);
    });

    test('inProgress → completed when page reaches total', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _bookItem(
            status: ItemStatus.inProgress,
            currentPage: 299,
            totalPages: 300,
            startedAt: DateTime(2024),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 300);

      expect(currentItem(container).status, ItemStatus.completed);
      verify(() => mockRepository.updateItemStatus(
            1,
            ItemStatus.completed,
            mediaType: MediaType.book,
          )).called(1);
    });

    test('inProgress → notStarted when page reset to 0', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _bookItem(
            status: ItemStatus.inProgress,
            currentPage: 50,
            totalPages: 300,
            startedAt: DateTime(2024),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 0);

      expect(currentItem(container).status, ItemStatus.notStarted);
    });

    test('book without pageCount: notStarted → inProgress', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _bookItem(status: ItemStatus.notStarted),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 5);

      expect(currentItem(container).status, ItemStatus.inProgress);
    });

    test('dropped status is never overwritten', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _bookItem(
            status: ItemStatus.dropped,
            currentPage: 5,
            totalPages: 300,
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 300);

      expect(currentItem(container).status, ItemStatus.dropped);
      verifyNever(() => mockRepository.updateItemStatus(
            any(),
            any(),
            mediaType: any(named: 'mediaType'),
          ));
    });
  });
}
