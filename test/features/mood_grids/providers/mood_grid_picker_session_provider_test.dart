import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/mood_grids/providers/mood_grid_picker_session_provider.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService mockDb;
  late ProviderContainer container;

  final List<CollectionItem> allItems = <CollectionItem>[
    createTestCollectionItem(id: 1, externalId: 100),
    createTestCollectionItem(id: 2, externalId: 200),
  ];
  final List<CollectionItem> collectionItems = <CollectionItem>[
    createTestCollectionItem(id: 1, externalId: 100),
  ];

  setUp(() {
    mockDb = MockDatabaseService();
    when(() => mockDb.getAllCollectionItemsWithData())
        .thenAnswer((_) async => allItems);
    when(() => mockDb.getCollectionItemsWithData(any()))
        .thenAnswer((_) async => collectionItems);
    container = ProviderContainer(
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
      ],
    );
    addTearDown(container.dispose);
  });

  group('MoodGridPickerSession', () {
    test('starts with no filter and an empty query', () {
      final MoodGridPickerSession session =
          container.read(moodGridPickerSessionProvider);
      expect(session.collectionId, isNull);
      expect(session.query, isEmpty);
    });

    test('keeps filter and query across reads (picker reopenings)', () {
      // Keep the autoDispose provider alive, as the grid screen does.
      final ProviderSubscription<MoodGridPickerSession> sub =
          container.listen(moodGridPickerSessionProvider, (Object? a, Object? b) {});
      addTearDown(sub.close);
      final MoodGridPickerSessionNotifier notifier =
          container.read(moodGridPickerSessionProvider.notifier);

      notifier.setCollection(5);
      notifier.setQuery('zelda');

      final MoodGridPickerSession session =
          container.read(moodGridPickerSessionProvider);
      expect(session.collectionId, 5);
      expect(session.query, 'zelda');
    });

    test('setCollection(null) resets to all collections', () {
      final ProviderSubscription<MoodGridPickerSession> sub =
          container.listen(moodGridPickerSessionProvider, (Object? a, Object? b) {});
      addTearDown(sub.close);
      final MoodGridPickerSessionNotifier notifier =
          container.read(moodGridPickerSessionProvider.notifier);

      notifier.setCollection(5);
      notifier.setCollection(null);

      expect(
        container.read(moodGridPickerSessionProvider).collectionId,
        isNull,
      );
    });

    test('itemsForCurrentFilter caches per filter value', () async {
      final ProviderSubscription<MoodGridPickerSession> sub =
          container.listen(moodGridPickerSessionProvider, (Object? a, Object? b) {});
      addTearDown(sub.close);
      final MoodGridPickerSessionNotifier notifier =
          container.read(moodGridPickerSessionProvider.notifier);

      final List<CollectionItem> first =
          await notifier.itemsForCurrentFilter();
      final List<CollectionItem> second =
          await notifier.itemsForCurrentFilter(refresh: false);

      expect(first, hasLength(2));
      expect(identical(first, second), isTrue);
      verify(() => mockDb.getAllCollectionItemsWithData()).called(1);
    });

    test('cache hit with refresh reloads in background and bumps revision',
        () async {
      final ProviderSubscription<MoodGridPickerSession> sub =
          container.listen(moodGridPickerSessionProvider, (Object? a, Object? b) {});
      addTearDown(sub.close);
      final MoodGridPickerSessionNotifier notifier =
          container.read(moodGridPickerSessionProvider.notifier);

      final List<CollectionItem> first =
          await notifier.itemsForCurrentFilter();
      // A new item lands in the DB while the grid screen stays open.
      when(() => mockDb.getAllCollectionItemsWithData()).thenAnswer(
        (_) async => <CollectionItem>[
          ...allItems,
          createTestCollectionItem(id: 9, externalId: 900),
        ],
      );

      final List<CollectionItem> second =
          await notifier.itemsForCurrentFilter();
      expect(identical(first, second), isTrue);

      // Let the unawaited background reload land.
      await Future<void>.delayed(Duration.zero);

      expect(container.read(moodGridPickerSessionProvider).revision, 1);
      final List<CollectionItem> fresh =
          await notifier.itemsForCurrentFilter(refresh: false);
      expect(fresh, hasLength(3));
      verify(() => mockDb.getAllCollectionItemsWithData()).called(2);
    });

    test('collapses the same media present in several collections', () async {
      // The two tv-show rows differ only in source nullness: a legacy NULL
      // must match the explicit default (tmdb), not survive as a duplicate.
      when(() => mockDb.getAllCollectionItemsWithData()).thenAnswer(
        (_) async => <CollectionItem>[
          createTestCollectionItem(id: 1, collectionId: 1, externalId: 100),
          createTestCollectionItem(id: 2, collectionId: 2, externalId: 100),
          createTestCollectionItem(id: 3, collectionId: 1, externalId: 200),
          createTestCollectionItem(
            id: 4,
            collectionId: 1,
            mediaType: MediaType.tvShow,
            externalId: 300,
            source: DataSource.tmdb,
          ),
          createTestCollectionItem(
            id: 5,
            collectionId: 2,
            mediaType: MediaType.tvShow,
            externalId: 300,
          ),
        ],
      );
      final ProviderSubscription<MoodGridPickerSession> sub =
          container.listen(moodGridPickerSessionProvider, (Object? a, Object? b) {});
      addTearDown(sub.close);

      final List<CollectionItem> items = await container
          .read(moodGridPickerSessionProvider.notifier)
          .itemsForCurrentFilter();

      expect(items, hasLength(3));
      expect(
        items.map((CollectionItem i) => i.externalId),
        <int>[100, 200, 300],
      );
    });

    test('itemsForCurrentFilter queries per collection filter', () async {
      final ProviderSubscription<MoodGridPickerSession> sub =
          container.listen(moodGridPickerSessionProvider, (Object? a, Object? b) {});
      addTearDown(sub.close);
      final MoodGridPickerSessionNotifier notifier =
          container.read(moodGridPickerSessionProvider.notifier);

      notifier.setCollection(5);
      final List<CollectionItem> filtered =
          await notifier.itemsForCurrentFilter();
      await notifier.itemsForCurrentFilter(refresh: false);

      expect(filtered, hasLength(1));
      verify(() => mockDb.getCollectionItemsWithData(5)).called(1);
      verifyNever(() => mockDb.getAllCollectionItemsWithData());
    });
  });
}
