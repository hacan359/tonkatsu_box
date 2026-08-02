
import 'package:core/database/dao/tier_list_dao.dart';
import 'package:core/models/tier_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';

final AsyncNotifierProvider<TierListsNotifier, List<TierList>>
    tierListsProvider =
    AsyncNotifierProvider<TierListsNotifier, List<TierList>>(
  TierListsNotifier.new,
);

final AsyncNotifierProviderFamily<CollectionTierListsNotifier, List<TierList>,
        int> collectionTierListsProvider =
    AsyncNotifierProvider.family<CollectionTierListsNotifier, List<TierList>,
        int>(
  CollectionTierListsNotifier.new,
);

class TierListsNotifier extends AsyncNotifier<List<TierList>> {
  late TierListDao _dao;

  @override
  Future<List<TierList>> build() async {
    _dao = ref.watch(tierListDaoProvider);
    return _dao.getAllTierLists();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<TierList>>();
    state = await AsyncValue.guard(() => _dao.getAllTierLists());
  }

  Future<TierList> create(String name, {int? collectionId}) async {
    final TierList tierList = await _dao.createTierList(
      name,
      collectionId: collectionId,
    );

    // Оптимистичное обновление: добавляем в начало
    final List<TierList> current = state.valueOrNull ?? <TierList>[];
    state = AsyncData<List<TierList>>(
      <TierList>[tierList, ...current],
    );

    return tierList;
  }

  Future<void> rename(int id, String name) async {
    await _dao.renameTierList(id, name);

    final List<TierList> current = state.valueOrNull ?? <TierList>[];
    state = AsyncData<List<TierList>>(
      current.map((TierList tl) {
        if (tl.id == id) return tl.copyWith(name: name);
        return tl;
      }).toList(),
    );
  }

  Future<void> delete(int id) async {
    await _dao.deleteTierList(id);

    final List<TierList> current = state.valueOrNull ?? <TierList>[];
    state = AsyncData<List<TierList>>(
      current.where((TierList tl) => tl.id != id).toList(),
    );
  }
}

class CollectionTierListsNotifier
    extends FamilyAsyncNotifier<List<TierList>, int> {
  late TierListDao _dao;

  @override
  Future<List<TierList>> build(int arg) async {
    _dao = ref.watch(tierListDaoProvider);
    return _dao.getTierListsByCollection(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<TierList>>();
    state = await AsyncValue.guard(
      () => _dao.getTierListsByCollection(arg),
    );
  }

  Future<TierList> create(String name) async {
    final TierList tierList = await _dao.createTierList(
      name,
      collectionId: arg,
    );

    final List<TierList> current = state.valueOrNull ?? <TierList>[];
    state = AsyncData<List<TierList>>(
      <TierList>[tierList, ...current],
    );

    ref.invalidate(tierListsProvider);

    return tierList;
  }

  Future<void> rename(int id, String name) async {
    await _dao.renameTierList(id, name);

    final List<TierList> current = state.valueOrNull ?? <TierList>[];
    state = AsyncData<List<TierList>>(
      current.map((TierList tl) {
        if (tl.id == id) return tl.copyWith(name: name);
        return tl;
      }).toList(),
    );
    ref.invalidate(tierListsProvider);
  }

  Future<void> delete(int id) async {
    await _dao.deleteTierList(id);

    final List<TierList> current = state.valueOrNull ?? <TierList>[];
    state = AsyncData<List<TierList>>(
      current.where((TierList tl) => tl.id != id).toList(),
    );
    ref.invalidate(tierListsProvider);
  }
}
