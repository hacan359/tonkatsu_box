// Провайдер деталей одного тир-листа.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/collection_dao.dart';
import '../../../core/database/dao/tier_list_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/tier_definition.dart';
import '../../../shared/models/tier_list.dart';
import '../../../shared/models/tier_list_entry.dart';

/// Состояние деталей тир-листа.
class TierListDetailState {
  /// Создаёт [TierListDetailState].
  const TierListDetailState({
    required this.tierList,
    required this.definitions,
    required this.entries,
    required this.items,
    this.isLoading = false,
  });

  /// Создаёт состояние загрузки.
  TierListDetailState.loading()
      : tierList = TierList(
          id: 0,
          name: '',
          createdAt: DateTime.now(),
        ),
        definitions = const <TierDefinition>[],
        entries = const <TierListEntry>[],
        items = const <CollectionItem>[],
        isLoading = true;

  /// Тир-лист.
  final TierList tierList;

  /// Определения тиров.
  final List<TierDefinition> definitions;

  /// Все записи (элементы, распределённые по тирам).
  final List<TierListEntry> entries;

  /// Все доступные элементы (по scope тир-листа).
  final List<CollectionItem> items;

  /// Флаг загрузки.
  final bool isLoading;

  /// ID элементов, распределённых по тирам.
  Set<int> get placedItemIds =>
      entries.map((TierListEntry e) => e.collectionItemId).toSet();

  /// Элементы без тира (Unranked).
  List<CollectionItem> get unrankedItems {
    final Set<int> placed = placedItemIds;
    return items
        .where((CollectionItem item) => !placed.contains(item.id))
        .toList();
  }

  /// Записи, сгруппированные по тирам.
  Map<String, List<TierListEntry>> get entriesByTier {
    final Map<String, List<TierListEntry>> result =
        <String, List<TierListEntry>>{};
    for (final TierDefinition def in definitions) {
      result[def.tierKey] = <TierListEntry>[];
    }
    for (final TierListEntry entry in entries) {
      result.putIfAbsent(entry.tierKey, () => <TierListEntry>[]);
      result[entry.tierKey]!.add(entry);
    }
    return result;
  }

  /// Создаёт копию с изменёнными полями.
  TierListDetailState copyWith({
    TierList? tierList,
    List<TierDefinition>? definitions,
    List<TierListEntry>? entries,
    List<CollectionItem>? items,
    bool? isLoading,
  }) {
    return TierListDetailState(
      tierList: tierList ?? this.tierList,
      definitions: definitions ?? this.definitions,
      entries: entries ?? this.entries,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Провайдер деталей тир-листа по ID.
final NotifierProviderFamily<TierListDetailNotifier, TierListDetailState, int>
    tierListDetailProvider = NotifierProvider.family<TierListDetailNotifier,
        TierListDetailState, int>(
  TierListDetailNotifier.new,
);

/// Notifier для управления одним тир-листом.
class TierListDetailNotifier
    extends FamilyNotifier<TierListDetailState, int> {
  late TierListDao _tierListDao;
  late CollectionDao _collectionDao;

  @override
  TierListDetailState build(int arg) {
    _tierListDao = ref.watch(tierListDaoProvider);
    _collectionDao = ref.watch(collectionDaoProvider);
    _load();
    return TierListDetailState.loading();
  }

  Future<void> _load() async {
    try {
      final TierList? tierList = await _tierListDao.getTierListById(arg);
      if (tierList == null) return;

      // Загружаем элементы по scope
      final List<CollectionItem> items = tierList.isGlobal
          ? await _collectionDao.getAllCollectionItemsWithData()
          : await _collectionDao.getCollectionItemsWithData(
              tierList.collectionId,
            );

      // Загружаем определения тиров
      List<TierDefinition> definitions =
          await _tierListDao.getTierDefinitions(arg);

      // Если определения пустые — создать дефолтные
      if (definitions.isEmpty) {
        await _tierListDao.saveTierDefinitions(arg, TierDefinition.defaults);
        definitions = TierDefinition.defaults;
      }

      // Загружаем записи
      final List<TierListEntry> entries =
          await _tierListDao.getTierListEntries(arg);

      state = TierListDetailState(
        tierList: tierList,
        definitions: definitions,
        entries: entries,
        items: items,
      );
    } on Exception catch (e) {
      debugPrint('TierListDetailNotifier._load() error: $e');
    }
  }

  /// Перезагружает данные.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  /// Перемещает элемент в тир.
  Future<void> moveToTier(
    int collectionItemId,
    String tierKey, {
    int? index,
  }) async {
    // Вычисляем sort_order
    final Map<String, List<TierListEntry>> byTier = state.entriesByTier;
    final List<TierListEntry> tierEntries =
        byTier[tierKey] ?? <TierListEntry>[];
    final int sortOrder = index ?? tierEntries.length;

    await _tierListDao.setItemTier(arg, collectionItemId, tierKey, sortOrder);

    // Оптимистичное обновление
    final List<TierListEntry> newEntries = state.entries
        .where((TierListEntry e) => e.collectionItemId != collectionItemId)
        .toList()
      ..add(TierListEntry(
        collectionItemId: collectionItemId,
        tierKey: tierKey,
        sortOrder: sortOrder,
      ));

    state = state.copyWith(entries: newEntries);
  }

  /// Удаляет элемент из тира (возвращает в Unranked).
  Future<void> removeFromTier(int collectionItemId) async {
    await _tierListDao.removeItemFromTier(arg, collectionItemId);

    state = state.copyWith(
      entries: state.entries
          .where((TierListEntry e) => e.collectionItemId != collectionItemId)
          .toList(),
    );
  }

  /// Переупорядочивает элементы внутри тира.
  Future<void> reorder(String tierKey, int oldIndex, int newIndex) async {
    final Map<String, List<TierListEntry>> byTier = state.entriesByTier;
    final List<TierListEntry> tierEntries =
        List<TierListEntry>.of(byTier[tierKey] ?? <TierListEntry>[]);

    if (oldIndex < 0 ||
        oldIndex >= tierEntries.length ||
        newIndex < 0 ||
        newIndex >= tierEntries.length) {
      return;
    }

    final TierListEntry moved = tierEntries.removeAt(oldIndex);
    tierEntries.insert(newIndex, moved);

    final List<int> itemIds =
        tierEntries.map((TierListEntry e) => e.collectionItemId).toList();
    await _tierListDao.reorderTierItems(arg, tierKey, itemIds);

    // Обновляем sort_order в state
    final List<TierListEntry> updatedEntries = state.entries
        .where((TierListEntry e) => e.tierKey != tierKey)
        .toList();
    for (int i = 0; i < tierEntries.length; i++) {
      updatedEntries.add(tierEntries[i].copyWith(sortOrder: i));
    }

    state = state.copyWith(entries: updatedEntries);
  }

  /// Перемещает элемент между тирами.
  Future<void> moveBetweenTiers(
    int collectionItemId,
    String fromTierKey,
    String toTierKey, {
    int? index,
  }) async {
    await removeFromTier(collectionItemId);
    await moveToTier(collectionItemId, toTierKey, index: index);
  }

  /// Обновляет определение тира (label или color).
  Future<void> updateTierDefinition(
    String tierKey, {
    String? label,
    Color? color,
  }) async {
    final List<TierDefinition> updated = state.definitions.map(
      (TierDefinition def) {
        if (def.tierKey == tierKey) {
          return def.copyWith(label: label, color: color);
        }
        return def;
      },
    ).toList();

    await _tierListDao.saveTierDefinitions(arg, updated);
    state = state.copyWith(definitions: updated);
  }

  /// Добавляет новый тир.
  Future<void> addTier(String tierKey, String label, Color color) async {
    final List<TierDefinition> updated = List<TierDefinition>.of(
      state.definitions,
    )..add(TierDefinition(
        tierKey: tierKey,
        label: label,
        color: color,
        sortOrder: state.definitions.length,
      ));

    await _tierListDao.saveTierDefinitions(arg, updated);
    state = state.copyWith(definitions: updated);
  }

  /// Удаляет тир (элементы возвращаются в Unranked).
  Future<void> removeTier(String tierKey) async {
    final List<TierDefinition> updated = state.definitions
        .where((TierDefinition d) => d.tierKey != tierKey)
        .toList();

    // Обновляем sort_order
    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(sortOrder: i);
    }

    await _tierListDao.saveTierDefinitions(arg, updated);

    // Удаляем записи из этого тира
    final List<TierListEntry> entriesInTier = state.entries
        .where((TierListEntry e) => e.tierKey == tierKey)
        .toList();
    for (final TierListEntry entry in entriesInTier) {
      await _tierListDao.removeItemFromTier(arg, entry.collectionItemId);
    }

    state = state.copyWith(
      definitions: updated,
      entries: state.entries
          .where((TierListEntry e) => e.tierKey != tierKey)
          .toList(),
    );
  }

  /// Очищает все тиры (элементы возвращаются в Unranked).
  Future<void> clearAll() async {
    await _tierListDao.clearTierListEntries(arg);
    state = state.copyWith(entries: const <TierListEntry>[]);
  }
}
