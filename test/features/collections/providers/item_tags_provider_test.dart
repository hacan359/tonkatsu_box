import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/providers/item_tags_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockGlobalTagDao mockDao;
  late ProviderContainer container;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDao = MockGlobalTagDao();
    container = ProviderContainer(
      overrides: <Override>[
        globalTagDaoProvider.overrideWithValue(mockDao),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<Map<int, List<int>>> load() async {
    return container.read(itemTagsProvider.future);
  }

  group('ItemTagsNotifier', () {
    test('build loads the whole junction from the dao', () async {
      when(() => mockDao.getAllItemTags()).thenAnswer(
        (_) async => <int, List<int>>{
          1: <int>[10, 20],
        },
      );

      expect(await load(), <int, List<int>>{
        1: <int>[10, 20],
      });
    });

    group('setItemTags', () {
      setUp(() {
        when(() => mockDao.getAllItemTags()).thenAnswer(
          (_) async => <int, List<int>>{
            1: <int>[10, 20],
          },
        );
        when(() => mockDao.setItemTags(any(), any()))
            .thenAnswer((_) async {});
      });

      test('re-reads the item order from the dao', () async {
        await load();
        when(() => mockDao.getTagIdsByItem(1))
            .thenAnswer((_) async => <int>[20, 10, 30]);

        await container
            .read(itemTagsProvider.notifier)
            .setItemTags(1, <int>{10, 20, 30});

        verify(() => mockDao.setItemTags(1, <int>{10, 20, 30})).called(1);
        expect(container.read(itemTagsProvider).valueOrNull?[1],
            <int>[20, 10, 30]);
      });

      test('empty set removes the item entry without a dao read', () async {
        await load();

        await container
            .read(itemTagsProvider.notifier)
            .setItemTags(1, <int>{});

        expect(
          container.read(itemTagsProvider).valueOrNull,
          isNot(contains(1)),
        );
        verifyNever(() => mockDao.getTagIdsByItem(any()));
      });
    });

    test('reorderItemTags persists and reorders in memory', () async {
      when(() => mockDao.getAllItemTags()).thenAnswer(
        (_) async => <int, List<int>>{
          1: <int>[10, 20, 30],
        },
      );
      when(() => mockDao.setItemTagPositions(any(), any()))
          .thenAnswer((_) async {});
      await load();

      await container
          .read(itemTagsProvider.notifier)
          .reorderItemTags(1, <int>[30, 10, 20]);

      verify(() => mockDao.setItemTagPositions(1, <int>[30, 10, 20]))
          .called(1);
      expect(container.read(itemTagsProvider).valueOrNull?[1],
          <int>[30, 10, 20]);
    });

    test('refreshFromDb replaces state without a loading gap', () async {
      when(() => mockDao.getAllItemTags())
          .thenAnswer((_) async => <int, List<int>>{});
      await load();
      when(() => mockDao.getAllItemTags()).thenAnswer(
        (_) async => <int, List<int>>{
          2: <int>[5],
        },
      );

      await container.read(itemTagsProvider.notifier).refreshFromDb();

      expect(container.read(itemTagsProvider).valueOrNull, <int, List<int>>{
        2: <int>[5],
      });
    });

    group('bulk tag changes', () {
      setUp(() {
        when(() => mockDao.getAllItemTags()).thenAnswer(
          (_) async => <int, List<int>>{
            1: <int>[10],
            2: <int>[10, 20],
          },
        );
        when(() => mockDao.addTagsToItems(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockDao.removeTagsFromItems(any(), any()))
            .thenAnswer((_) async {});
      });

      test('addTagsToItems writes once and re-reads once', () async {
        await load();
        when(() => mockDao.getTagIdsForItems(any())).thenAnswer(
          (_) async => <int, List<int>>{
            1: <int>[10, 20],
            2: <int>[10, 20],
          },
        );

        await container
            .read(itemTagsProvider.notifier)
            .addTagsToItems(<int>[1, 2], <int>{20});

        verify(() => mockDao.addTagsToItems(<int>[1, 2], <int>{20})).called(1);
        verify(() => mockDao.getTagIdsForItems(<int>[1, 2])).called(1);
        verifyNever(() => mockDao.setItemTags(any(), any()));
        verifyNever(() => mockDao.getTagIdsByItem(any()));
      });

      test('addTagsToItems counts only links that were missing', () async {
        await load();
        when(() => mockDao.getTagIdsForItems(any())).thenAnswer(
          (_) async => <int, List<int>>{
            1: <int>[10, 20],
            2: <int>[10, 20],
          },
        );

        final int changed = await container
            .read(itemTagsProvider.notifier)
            .addTagsToItems(<int>[1, 2], <int>{20});

        // Item 2 already carried tag 20, so only item 1 gained a link.
        expect(changed, 1);
      });

      test('addTagsToItems takes the dao order, not the requested one',
          () async {
        await load();
        when(() => mockDao.getTagIdsForItems(any())).thenAnswer(
          (_) async => <int, List<int>>{
            1: <int>[30, 10],
            2: <int>[10, 20],
          },
        );

        await container
            .read(itemTagsProvider.notifier)
            .addTagsToItems(<int>[1], <int>{30});

        expect(container.read(itemTagsProvider).valueOrNull?[1], <int>[30, 10]);
      });

      test('removeTagsFromItems drops items left without tags', () async {
        await load();
        when(() => mockDao.getTagIdsForItems(any())).thenAnswer(
          (_) async => <int, List<int>>{
            2: <int>[20],
          },
        );

        final int changed = await container
            .read(itemTagsProvider.notifier)
            .removeTagsFromItems(<int>[1, 2], <int>{10});

        expect(changed, 2);
        expect(container.read(itemTagsProvider).valueOrNull, <int, List<int>>{
          2: <int>[20],
        });
      });

      test('both operations no-op on an empty selection or empty tag set',
          () async {
        await load();

        final ItemTagsNotifier notifier =
            container.read(itemTagsProvider.notifier);
        expect(await notifier.addTagsToItems(<int>[], <int>{10}), 0);
        expect(await notifier.addTagsToItems(<int>[1], <int>{}), 0);
        expect(await notifier.removeTagsFromItems(<int>[], <int>{10}), 0);
        expect(await notifier.removeTagsFromItems(<int>[1], <int>{}), 0);

        verifyNever(() => mockDao.addTagsToItems(any(), any()));
        verifyNever(() => mockDao.removeTagsFromItems(any(), any()));
      });
    });

    test('dropTagEverywhere removes the tag, keeping list order', () async {
      when(() => mockDao.getAllItemTags()).thenAnswer(
        (_) async => <int, List<int>>{
          1: <int>[20, 10, 30],
          2: <int>[10],
        },
      );
      await load();

      container.read(itemTagsProvider.notifier).dropTagEverywhere(10);

      expect(container.read(itemTagsProvider).valueOrNull, <int, List<int>>{
        1: <int>[20, 30],
      });
    });
  });
}
