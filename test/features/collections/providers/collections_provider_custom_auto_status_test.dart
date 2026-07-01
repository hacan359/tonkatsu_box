import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/custom_media.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

const int _collectionId = 1;

CollectionItem _customItem({
  int id = 1,
  ItemStatus status = ItemStatus.notStarted,
  int currentUnit = 0,
  int currentGroup = 0,
  int? unitTotal,
  int? unitGroupTotal,
  MediaType displayType = MediaType.tvShow,
  DateTime? startedAt,
  DateTime? completedAt,
}) {
  return createTestCollectionItem(
    id: id,
    collectionId: _collectionId,
    mediaType: MediaType.custom,
    status: status,
    currentEpisode: currentUnit,
    currentSeason: currentGroup,
    startedAt: startedAt,
    completedAt: completedAt,
    customMedia: CustomMedia(
      id: id,
      title: 'Custom',
      displayType: displayType,
      unitTotal: unitTotal,
      unitGroupTotal: unitGroupTotal,
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

  CollectionItem currentItem(ProviderContainer container, {int id = 1}) {
    final List<CollectionItem> items = container
        .read(collectionItemsNotifierProvider(_collectionId))
        .valueOrNull!;
    return items.firstWhere((CollectionItem i) => i.id == id);
  }

  group('CollectionItemsNotifier.updateProgress custom auto-status', () {
    test('notStarted → inProgress when the fine unit advances from 0', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _customItem(status: ItemStatus.notStarted, unitTotal: 24),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 1);

      expect(currentItem(container).status, ItemStatus.inProgress);
      verify(() => mockRepository.updateItemStatus(
            1,
            ItemStatus.inProgress,
            mediaType: MediaType.custom,
          )).called(1);
    });

    test('inProgress → completed when the fine unit reaches the total', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _customItem(
            status: ItemStatus.inProgress,
            currentUnit: 23,
            unitTotal: 24,
            startedAt: DateTime(2024),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 24);

      expect(currentItem(container).status, ItemStatus.completed);
      verify(() => mockRepository.updateItemStatus(
            1,
            ItemStatus.completed,
            mediaType: MediaType.custom,
          )).called(1);
    });

    test('does not complete without a total set, only advances to inProgress',
        () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _customItem(status: ItemStatus.notStarted),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 99);

      expect(currentItem(container).status, ItemStatus.inProgress);
    });

    test('inProgress → notStarted when progress reset to 0/0', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _customItem(
            status: ItemStatus.inProgress,
            currentUnit: 5,
            currentGroup: 1,
            unitTotal: 24,
            startedAt: DateTime(2024),
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 0, currentSeason: 0);

      expect(currentItem(container).status, ItemStatus.notStarted);
    });

    test('dropped status is never overwritten', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          _customItem(
            status: ItemStatus.dropped,
            currentUnit: 5,
            unitTotal: 24,
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 24);

      expect(currentItem(container).status, ItemStatus.dropped);
      verifyNever(() => mockRepository.updateItemStatus(
            any(),
            any(),
            mediaType: any(named: 'mediaType'),
          ));
    });

    test('a non-custom item is left to its own auto-status path', () async {
      final ProviderContainer container = createContainer(
        initialItems: <CollectionItem>[
          createTestCollectionItem(
            id: 1,
            collectionId: _collectionId,
            mediaType: MediaType.movie,
            status: ItemStatus.notStarted,
          ),
        ],
      );
      final CollectionItemsNotifier notifier = await loadNotifier(container);

      await notifier.updateProgress(1, currentEpisode: 1);

      verifyNever(() => mockRepository.updateItemStatus(
            any(),
            any(),
            mediaType: MediaType.custom,
          ));
    });
  });
}
