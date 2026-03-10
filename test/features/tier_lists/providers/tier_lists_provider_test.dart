import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/tier_lists/providers/tier_lists_provider.dart';
import 'package:xerabora/shared/models/tier_list.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockTierListDao mockDao;

  setUpAll(() {
    registerAllFallbacks();
  });

  setUp(() {
    mockDao = MockTierListDao();
  });

  ProviderContainer createContainer({
    List<Override> extraOverrides = const <Override>[],
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        tierListDaoProvider.overrideWithValue(mockDao),
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pump([int times = 5]) async {
    for (int i = 0; i < times; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  final TierList tierList1 = createTestTierList(id: 1, name: 'S-Tier List');
  final TierList tierList2 = createTestTierList(id: 2, name: 'Game Rankings');
  final TierList tierList3 = createTestTierList(
    id: 3,
    name: 'Collection Tier',
    collectionId: 10,
  );

  group('TierListsNotifier', () {
    group('build', () {
      test('should load all tier lists from dao', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1, tierList2]);

        final ProviderContainer container = createContainer();
        container.read(tierListsProvider);
        await pump();

        final AsyncValue<List<TierList>> state =
            container.read(tierListsProvider);
        expect(state.valueOrNull, <TierList>[tierList1, tierList2]);
      });

      test('should return empty list when no tier lists exist', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[]);

        final ProviderContainer container = createContainer();
        container.read(tierListsProvider);
        await pump();

        final AsyncValue<List<TierList>> state =
            container.read(tierListsProvider);
        expect(state.valueOrNull, <TierList>[]);
      });

      test('should set error state when dao throws', () async {
        when(() => mockDao.getAllTierLists())
            .thenThrow(Exception('DB error'));

        final ProviderContainer container = createContainer();
        container.read(tierListsProvider);
        await pump();

        final AsyncValue<List<TierList>> state =
            container.read(tierListsProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('refresh', () {
      test('should reload tier lists from dao', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1]);

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        // Change what dao returns
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1, tierList2]);

        await container.read(tierListsProvider.notifier).refresh();
        await pump();

        final AsyncValue<List<TierList>> state =
            container.read(tierListsProvider);
        expect(state.valueOrNull, <TierList>[tierList1, tierList2]);
      });

      test('should set error state when refresh fails', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1]);

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        when(() => mockDao.getAllTierLists())
            .thenThrow(Exception('refresh error'));

        await container.read(tierListsProvider.notifier).refresh();
        await pump();

        final AsyncValue<List<TierList>> state =
            container.read(tierListsProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('create', () {
      test('should create tier list and prepend to state', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1]);
        when(() => mockDao.createTierList(any(), collectionId: any(named: 'collectionId')))
            .thenAnswer((_) async => tierList2);

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        final TierList result = await container
            .read(tierListsProvider.notifier)
            .create('Game Rankings');

        expect(result, tierList2);

        final AsyncValue<List<TierList>> state =
            container.read(tierListsProvider);
        expect(state.valueOrNull, <TierList>[tierList2, tierList1]);
      });

      test('should pass collectionId to dao when provided', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[]);
        when(() => mockDao.createTierList(any(), collectionId: any(named: 'collectionId')))
            .thenAnswer((_) async => tierList3);

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        await container
            .read(tierListsProvider.notifier)
            .create('Collection Tier', collectionId: 10);

        verify(
          () => mockDao.createTierList('Collection Tier', collectionId: 10),
        ).called(1);
      });

      test('should use empty list when state has no value', () async {
        // Simulate state where valueOrNull is null by using a dao that
        // returns a value for build, then we test create after an error state
        when(() => mockDao.getAllTierLists())
            .thenThrow(Exception('initial error'));
        when(() => mockDao.createTierList(any(), collectionId: any(named: 'collectionId')))
            .thenAnswer((_) async => tierList1);

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        // State is error, so valueOrNull is null
        expect(container.read(tierListsProvider).hasError, isTrue);

        final TierList result = await container
            .read(tierListsProvider.notifier)
            .create('S-Tier List');

        expect(result, tierList1);

        final AsyncValue<List<TierList>> state =
            container.read(tierListsProvider);
        expect(state.valueOrNull, <TierList>[tierList1]);
      });

      test('should create without collectionId by default', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[]);
        when(() => mockDao.createTierList(any(), collectionId: any(named: 'collectionId')))
            .thenAnswer((_) async => tierList1);

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        await container
            .read(tierListsProvider.notifier)
            .create('S-Tier List');

        verify(
          () => mockDao.createTierList('S-Tier List', collectionId: null),
        ).called(1);
      });
    });

    group('rename', () {
      test('should rename tier list and update state', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1, tierList2]);
        when(() => mockDao.renameTierList(any(), any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        await container.read(tierListsProvider.notifier).rename(1, 'New Name');

        final List<TierList>? tierLists =
            container.read(tierListsProvider).valueOrNull;
        expect(tierLists, isNotNull);
        expect(tierLists![0].name, 'New Name');
        expect(tierLists[1].name, 'Game Rankings');
      });

      test('should call dao with correct parameters', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1]);
        when(() => mockDao.renameTierList(any(), any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        await container
            .read(tierListsProvider.notifier)
            .rename(1, 'Updated');

        verify(() => mockDao.renameTierList(1, 'Updated')).called(1);
      });

      test('should not modify other tier lists when renaming', () async {
        when(() => mockDao.getAllTierLists()).thenAnswer(
          (_) async => <TierList>[tierList1, tierList2, tierList3],
        );
        when(() => mockDao.renameTierList(any(), any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        await container
            .read(tierListsProvider.notifier)
            .rename(2, 'Renamed');

        final List<TierList>? tierLists =
            container.read(tierListsProvider).valueOrNull;
        expect(tierLists, hasLength(3));
        expect(tierLists![0].name, 'S-Tier List');
        expect(tierLists[1].name, 'Renamed');
        expect(tierLists[2].name, 'Collection Tier');
      });

      test('should use empty list when state has no value', () async {
        when(() => mockDao.getAllTierLists())
            .thenThrow(Exception('error'));
        when(() => mockDao.renameTierList(any(), any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        expect(container.read(tierListsProvider).hasError, isTrue);

        await container
            .read(tierListsProvider.notifier)
            .rename(999, 'Whatever');

        final AsyncValue<List<TierList>> state =
            container.read(tierListsProvider);
        expect(state.valueOrNull, <TierList>[]);
      });
    });

    group('delete', () {
      test('should delete tier list and remove from state', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1, tierList2]);
        when(() => mockDao.deleteTierList(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        await container.read(tierListsProvider.notifier).delete(1);

        final List<TierList>? tierLists =
            container.read(tierListsProvider).valueOrNull;
        expect(tierLists, <TierList>[tierList2]);
      });

      test('should call dao with correct id', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1]);
        when(() => mockDao.deleteTierList(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        await container.read(tierListsProvider.notifier).delete(1);

        verify(() => mockDao.deleteTierList(1)).called(1);
      });

      test('should result in empty list when deleting last item', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1]);
        when(() => mockDao.deleteTierList(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        await container.read(tierListsProvider.notifier).delete(1);

        final List<TierList>? tierLists =
            container.read(tierListsProvider).valueOrNull;
        expect(tierLists, <TierList>[]);
      });

      test('should not remove anything when id not found', () async {
        when(() => mockDao.getAllTierLists())
            .thenAnswer((_) async => <TierList>[tierList1, tierList2]);
        when(() => mockDao.deleteTierList(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        await container.read(tierListsProvider.notifier).delete(999);

        final List<TierList>? tierLists =
            container.read(tierListsProvider).valueOrNull;
        expect(tierLists, <TierList>[tierList1, tierList2]);
      });

      test('should use empty list when state has no value', () async {
        when(() => mockDao.getAllTierLists())
            .thenThrow(Exception('error'));
        when(() => mockDao.deleteTierList(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.listen(tierListsProvider, (Object? _, Object? _) {});
        await pump();

        expect(container.read(tierListsProvider).hasError, isTrue);

        await container.read(tierListsProvider.notifier).delete(1);

        final AsyncValue<List<TierList>> state =
            container.read(tierListsProvider);
        expect(state.valueOrNull, <TierList>[]);
      });
    });
  });
}
