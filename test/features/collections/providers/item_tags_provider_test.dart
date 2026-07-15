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
