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
}
