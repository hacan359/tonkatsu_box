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

/// Derived collections (entriesByTier, itemsById, unrankedItems,
/// placedItemIds) are precomputed once to avoid O(N) recomputation per
/// widget build on large tier lists.
class TierListDetailState {
  factory TierListDetailState({
    required TierList tierList,
    required List<TierDefinition> definitions,
    required List<TierListEntry> entries,
    required List<CollectionItem> items,
    bool isLoading = false,
  }) {
    final Map<int, CollectionItem> itemsById = <int, CollectionItem>{
      for (final CollectionItem item in items) item.id: item,
    };
    final Set<int> placedItemIds = <int>{
      for (final TierListEntry e in entries) e.collectionItemId,
    };
    final Map<String, List<TierListEntry>> byTier =
        <String, List<TierListEntry>>{
      for (final TierDefinition def in definitions)
        def.tierKey: <TierListEntry>[],
    };
    for (final TierListEntry entry in entries) {
      byTier.putIfAbsent(entry.tierKey, () => <TierListEntry>[]).add(entry);
    }
    final Map<String, List<TierListEntry>> entriesByTier =
        <String, List<TierListEntry>>{
      for (final MapEntry<String, List<TierListEntry>> e in byTier.entries)
        e.key: List<TierListEntry>.unmodifiable(e.value),
    };
    final List<CollectionItem> unrankedItems = <CollectionItem>[
      for (final CollectionItem item in items)
        if (!placedItemIds.contains(item.id)) item,
    ];
    return TierListDetailState._(
      tierList: tierList,
      definitions: definitions,
      entries: entries,
      items: items,
      isLoading: isLoading,
      itemsById: itemsById,
      placedItemIds: placedItemIds,
      entriesByTier: entriesByTier,
      unrankedItems: unrankedItems,
    );
  }

  const TierListDetailState._({
    required this.tierList,
    required this.definitions,
    required this.entries,
    required this.items,
    required this.isLoading,
    required this.itemsById,
    required this.placedItemIds,
    required this.entriesByTier,
    required this.unrankedItems,
  });

  factory TierListDetailState.loading() => TierListDetailState(
        tierList: TierList(
          id: 0,
          name: '',
          createdAt: DateTime.now(),
        ),
        definitions: const <TierDefinition>[],
        entries: const <TierListEntry>[],
        items: const <CollectionItem>[],
        isLoading: true,
      );

  final TierList tierList;
  final List<TierDefinition> definitions;
  final List<TierListEntry> entries;
  final List<CollectionItem> items;
  final bool isLoading;
  final Map<int, CollectionItem> itemsById;
  final Set<int> placedItemIds;
  final Map<String, List<TierListEntry>> entriesByTier;
  final List<CollectionItem> unrankedItems;

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

final NotifierProviderFamily<TierListDetailNotifier, TierListDetailState, int>
    tierListDetailProvider = NotifierProvider.family<TierListDetailNotifier,
        TierListDetailState, int>(
  TierListDetailNotifier.new,
);

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

      final List<CollectionItem> items = tierList.isGlobal
          ? await _collectionDao.getAllCollectionItemsWithData()
          : await _collectionDao.getCollectionItemsWithData(
              tierList.collectionId,
            );

      List<TierDefinition> definitions =
          await _tierListDao.getTierDefinitions(arg);
      if (definitions.isEmpty) {
        await _tierListDao.saveTierDefinitions(arg, TierDefinition.defaults);
        definitions = TierDefinition.defaults;
      }

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

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  Future<void> moveToTier(
    int collectionItemId,
    String tierKey, {
    int? index,
  }) async {
    final Map<String, List<TierListEntry>> byTier = state.entriesByTier;
    final List<TierListEntry> tierEntries =
        byTier[tierKey] ?? <TierListEntry>[];
    final int sortOrder = index ?? tierEntries.length;

    await _tierListDao.setItemTier(arg, collectionItemId, tierKey, sortOrder);

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

  Future<void> removeFromTier(int collectionItemId) async {
    await _tierListDao.removeItemFromTier(arg, collectionItemId);

    state = state.copyWith(
      entries: state.entries
          .where((TierListEntry e) => e.collectionItemId != collectionItemId)
          .toList(),
    );
  }

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

    final List<TierListEntry> updatedEntries = state.entries
        .where((TierListEntry e) => e.tierKey != tierKey)
        .toList();
    for (int i = 0; i < tierEntries.length; i++) {
      updatedEntries.add(tierEntries[i].copyWith(sortOrder: i));
    }

    state = state.copyWith(entries: updatedEntries);
  }

  /// Single setItemTier handles DELETE+INSERT — one DB write, one state update,
  /// avoids the double rebuild a remove+add pair would cause.
  Future<void> moveBetweenTiers(
    int collectionItemId,
    String fromTierKey,
    String toTierKey, {
    int? index,
  }) async {
    await moveToTier(collectionItemId, toTierKey, index: index);
  }

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

  Future<void> removeTier(String tierKey) async {
    final List<TierDefinition> updated = state.definitions
        .where((TierDefinition d) => d.tierKey != tierKey)
        .toList();

    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(sortOrder: i);
    }

    await _tierListDao.saveTierDefinitions(arg, updated);

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

  Future<void> clearAll() async {
    await _tierListDao.clearTierListEntries(arg);
    state = state.copyWith(entries: const <TierListEntry>[]);
  }
}
