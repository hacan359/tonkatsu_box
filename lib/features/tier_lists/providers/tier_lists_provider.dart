// Провайдер списка тир-листов.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/tier_list_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/tier_list.dart';

/// Провайдер списка всех тир-листов.
final AsyncNotifierProvider<TierListsNotifier, List<TierList>>
    tierListsProvider =
    AsyncNotifierProvider<TierListsNotifier, List<TierList>>(
  TierListsNotifier.new,
);

/// Notifier для управления списком тир-листов.
class TierListsNotifier extends AsyncNotifier<List<TierList>> {
  late TierListDao _dao;

  @override
  Future<List<TierList>> build() async {
    _dao = ref.watch(tierListDaoProvider);
    return _dao.getAllTierLists();
  }

  /// Обновляет список из БД.
  Future<void> refresh() async {
    state = const AsyncLoading<List<TierList>>();
    state = await AsyncValue.guard(() => _dao.getAllTierLists());
  }

  /// Создаёт тир-лист и обновляет state.
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

  /// Переименовывает тир-лист.
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

  /// Удаляет тир-лист.
  Future<void> delete(int id) async {
    await _dao.deleteTierList(id);

    final List<TierList> current = state.valueOrNull ?? <TierList>[];
    state = AsyncData<List<TierList>>(
      current.where((TierList tl) => tl.id != id).toList(),
    );
  }
}
