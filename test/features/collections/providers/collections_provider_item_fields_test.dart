import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  const int collectionId = 1;
  late MockCollectionRepository repo;
  late SharedPreferences prefs;

  setUpAll(registerAllFallbacks);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    repo = MockCollectionRepository();

    when(() => repo.updateItemUserRating(any(), any()))
        .thenAnswer((_) async {});
    when(() => repo.updateItemUserComment(any(), any()))
        .thenAnswer((_) async {});
    when(() => repo.updateItemAuthorComment(any(), any()))
        .thenAnswer((_) async {});
    when(() => repo.updateItemTimeSpent(any(), any()))
        .thenAnswer((_) async {});
    when(() => repo.setItemFavorite(any(), isFavorite: any(named: 'isFavorite')))
        .thenAnswer((_) async {});
    when(() => repo.setItemOverrideName(any(), any())).thenAnswer((_) async {});
    // Card edits stamp last_activity_at through this method.
    when(() => repo.updateItemActivityDates(
          any(),
          startedAt: any(named: 'startedAt'),
          completedAt: any(named: 'completedAt'),
          lastActivityAt: any(named: 'lastActivityAt'),
        )).thenAnswer((_) async {});
    // setFavorite syncs the All Items notifier, which loads via this method.
    when(() => repo.getAllItemsWithData())
        .thenAnswer((_) async => <CollectionItem>[]);
  });

  ProviderContainer makeContainer(List<CollectionItem> items) {
    when(() => repo.getItemsWithData(collectionId))
        .thenAnswer((_) async => items);
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(repo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<CollectionItemsNotifier> loaded(List<CollectionItem> items) async {
    final ProviderContainer c = makeContainer(items);
    c.read(collectionItemsNotifierProvider(collectionId));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return c.read(collectionItemsNotifierProvider(collectionId).notifier);
  }

  CollectionItem item({double? userRating, int timeSpent = 0}) =>
      createTestCollectionItem(
        id: 7,
        mediaType: MediaType.movie,
        externalId: 550,
        userRating: userRating,
      ).copyWith(timeSpentMinutes: timeSpent);

  CollectionItem? readItem(CollectionItemsNotifier n) =>
      n.state.valueOrNull?.firstWhere((CollectionItem i) => i.id == 7);

  group('updateUserRating', () {
    test('persists and reflects a fractional rating', () async {
      final CollectionItemsNotifier n = await loaded(<CollectionItem>[item()]);

      await n.updateUserRating(7, 8.5);

      verify(() => repo.updateItemUserRating(7, 8.5)).called(1);
      expect(readItem(n)!.userRating, 8.5);
    });

    test('null clears the rating', () async {
      final CollectionItemsNotifier n =
          await loaded(<CollectionItem>[item(userRating: 9)]);

      await n.updateUserRating(7, null);

      verify(() => repo.updateItemUserRating(7, null)).called(1);
      expect(readItem(n)!.userRating, isNull);
    });
  });

  group('comments', () {
    test('updateUserComment sets and clears', () async {
      final CollectionItemsNotifier n = await loaded(<CollectionItem>[item()]);

      await n.updateUserComment(7, 'great');
      expect(readItem(n)!.userComment, 'great');
      verify(() => repo.updateItemUserComment(7, 'great')).called(1);

      await n.updateUserComment(7, null);
      expect(readItem(n)!.userComment, isNull);
    });

    test('updateAuthorComment sets and clears', () async {
      final CollectionItemsNotifier n = await loaded(<CollectionItem>[item()]);

      await n.updateAuthorComment(7, 'note');
      expect(readItem(n)!.authorComment, 'note');
      verify(() => repo.updateItemAuthorComment(7, 'note')).called(1);

      await n.updateAuthorComment(7, null);
      expect(readItem(n)!.authorComment, isNull);
    });
  });

  group('favorite', () {
    test('toggleFavorite flips false -> true, persists and reflects', () async {
      final CollectionItemsNotifier n = await loaded(<CollectionItem>[item()]);

      await n.toggleFavorite(7);

      verify(() => repo.setItemFavorite(7, isFavorite: true)).called(1);
      expect(readItem(n)!.isFavorite, isTrue);
    });

    test('toggleFavorite flips true -> false', () async {
      final CollectionItemsNotifier n = await loaded(
        <CollectionItem>[item().copyWith(isFavorite: true)],
      );

      await n.toggleFavorite(7);

      verify(() => repo.setItemFavorite(7, isFavorite: false)).called(1);
      expect(readItem(n)!.isFavorite, isFalse);
    });

    test('setFavorite persists the explicit value', () async {
      final CollectionItemsNotifier n = await loaded(<CollectionItem>[item()]);

      await n.setFavorite(7, isFavorite: true);
      verify(() => repo.setItemFavorite(7, isFavorite: true)).called(1);
      expect(readItem(n)!.isFavorite, isTrue);

      await n.setFavorite(7, isFavorite: false);
      verify(() => repo.setItemFavorite(7, isFavorite: false)).called(1);
      expect(readItem(n)!.isFavorite, isFalse);
    });
  });

  group('time spent', () {
    test('addTimeSpent accumulates onto the current value', () async {
      final CollectionItemsNotifier n =
          await loaded(<CollectionItem>[item(timeSpent: 30)]);

      await n.addTimeSpent(7, 45);

      verify(() => repo.updateItemTimeSpent(7, 75)).called(1);
      expect(readItem(n)!.timeSpentMinutes, 75);
    });

    test('setTimeSpent overwrites the total', () async {
      final CollectionItemsNotifier n =
          await loaded(<CollectionItem>[item(timeSpent: 30)]);

      await n.setTimeSpent(7, 120);

      verify(() => repo.updateItemTimeSpent(7, 120)).called(1);
      expect(readItem(n)!.timeSpentMinutes, 120);
    });
  });

  group('resort and activity stamping', () {
    // Default sort mode is lastActivity, so the list starts newest-activity
    // first: [2, 1].
    List<CollectionItem> twoByActivity() => <CollectionItem>[
          createTestCollectionItem(
            id: 1,
            mediaType: MediaType.movie,
            externalId: 1,
            addedAt: DateTime(2024),
            lastActivityAt: DateTime(2024),
          ),
          createTestCollectionItem(
            id: 2,
            mediaType: MediaType.movie,
            externalId: 2,
            addedAt: DateTime(2024, 6),
            lastActivityAt: DateTime(2024, 6),
          ),
        ];

    List<int> order(CollectionItemsNotifier n) =>
        n.state.valueOrNull!.map((CollectionItem i) => i.id).toList();

    CollectionItem byId(CollectionItemsNotifier n, int id) =>
        n.state.valueOrNull!.firstWhere((CollectionItem i) => i.id == id);

    test('rating an item stamps activity and bubbles it up in activity sort',
        () async {
      final CollectionItemsNotifier n = await loaded(twoByActivity());
      expect(order(n), <int>[2, 1]);

      await n.updateUserRating(1, 9.0);

      expect(order(n), <int>[1, 2]);
      expect(byId(n, 1).lastActivityAt!.isAfter(DateTime(2024, 6)), isTrue);
    });

    test('editing a comment counts as activity and bubbles the item up',
        () async {
      final CollectionItemsNotifier n = await loaded(twoByActivity());
      expect(order(n), <int>[2, 1]);

      await n.updateUserComment(1, 'note');

      expect(order(n), <int>[1, 2]);
      expect(byId(n, 1).lastActivityAt!.isAfter(DateTime(2024, 6)), isTrue);
    });

    test('renaming counts as activity and bubbles the item up', () async {
      final CollectionItemsNotifier n = await loaded(twoByActivity());
      expect(order(n), <int>[2, 1]);

      await n.setOverrideName(1, 'ZZZ');

      expect(order(n), <int>[1, 2]);
      expect(byId(n, 1).lastActivityAt!.isAfter(DateTime(2024, 6)), isTrue);
    });
  });
}
