import 'dart:async';

import 'package:core/models/item_mark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';

/// Key identifying a unit within an item.
typedef UnitKey = ({String unitType, int parent, int unit});

/// State holding every mark of one collection item, indexed by unit.
class ItemMarksState {
  const ItemMarksState({this.marks = const <UnitKey, ItemMark>{}});

  /// Marks keyed by their unit coordinates.
  final Map<UnitKey, ItemMark> marks;

  /// The mark for a unit, or null.
  ItemMark? markFor(String unitType, int parent, int unit) =>
      marks[(unitType: unitType, parent: parent, unit: unit)];

  /// Whether a unit is liked.
  bool isLiked(String unitType, int parent, int unit) =>
      markFor(unitType, parent, unit)?.isFavorite ?? false;

  /// The note on a unit (null when absent/empty).
  String? noteFor(String unitType, int parent, int unit) =>
      markFor(unitType, parent, unit)?.note;

  /// All marks as a flat list.
  List<ItemMark> get all => marks.values.toList();

  /// Liked count restricted to one unit type.
  int likedCountOfType(String unitType) => marks.values
      .where((ItemMark m) => m.unitType == unitType && m.isFavorite)
      .length;

  /// Commented count restricted to one unit type.
  int commentedCountOfType(String unitType) => marks.values
      .where((ItemMark m) => m.unitType == unitType && m.note != null)
      .length;
}

/// Marks provider, keyed by `collection_items.id` so it is universal across
/// media types.
final NotifierProviderFamily<ItemMarksNotifier, ItemMarksState, int>
    itemMarksProvider =
    NotifierProvider.family<ItemMarksNotifier, ItemMarksState, int>(
  ItemMarksNotifier.new,
);

/// Notifier managing a single item's marks.
class ItemMarksNotifier extends FamilyNotifier<ItemMarksState, int> {
  late DatabaseService _db;
  late int _itemId;

  @override
  ItemMarksState build(int itemId) {
    _itemId = itemId;
    _db = ref.watch(databaseServiceProvider);
    unawaited(_load());
    return const ItemMarksState();
  }

  Future<void> _load() async {
    final List<ItemMark> marks =
        await _db.itemMarkDao.getMarksForItem(_itemId);
    state = ItemMarksState(
      marks: <UnitKey, ItemMark>{
        for (final ItemMark m in marks)
          (unitType: m.unitType, parent: m.parentNumber, unit: m.unitNumber):
              m,
      },
    );
  }

  /// Toggles the like flag on a unit.
  Future<void> toggleFavorite(String unitType, int parent, int unit) async {
    await setFavorite(
      unitType,
      parent,
      unit,
      value: !state.isLiked(unitType, parent, unit),
    );
  }

  /// Sets the like flag on a unit to an explicit value.
  Future<void> setFavorite(
    String unitType,
    int parent,
    int unit, {
    required bool value,
  }) async {
    final ItemMark? merged = await _db.itemMarkDao.setFavorite(
      _itemId,
      unitType,
      parent,
      unit,
      isFavorite: value,
    );
    _apply((unitType: unitType, parent: parent, unit: unit), merged);
  }

  /// Sets the note on a unit (empty/null clears it).
  Future<void> setComment(
    String unitType,
    int parent,
    int unit,
    String? comment,
  ) async {
    final ItemMark? merged = await _db.itemMarkDao
        .setComment(_itemId, unitType, parent, unit, comment);
    _apply((unitType: unitType, parent: parent, unit: unit), merged);
  }

  /// Deletes a mark outright.
  Future<void> deleteMark(String unitType, int parent, int unit) async {
    await _db.itemMarkDao.deleteMark(_itemId, unitType, parent, unit);
    _apply((unitType: unitType, parent: parent, unit: unit), null);
  }

  /// Patches one unit in local state with the mark the DAO returned (null =
  /// row deleted), so no reload is needed after a write.
  void _apply(UnitKey key, ItemMark? mark) {
    final Map<UnitKey, ItemMark> next =
        Map<UnitKey, ItemMark>.of(state.marks);
    if (mark == null) {
      next.remove(key);
    } else {
      next[key] = mark;
    }
    state = ItemMarksState(marks: next);
  }
}
