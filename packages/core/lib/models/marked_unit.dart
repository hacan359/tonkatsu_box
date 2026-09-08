import 'item_mark.dart';

/// A mark joined with the cached name of its unit, so the likes page can say
/// "S2 · E5 · The Rains of Castamere" without a query per title.
class MarkedUnit {
  const MarkedUnit({required this.mark, this.unitTitle});

  /// Reads a joined row: `item_marks.*` plus a `unit_title` column that is
  /// null when the episode / track cache holds nothing for this unit.
  factory MarkedUnit.fromDb(Map<String, dynamic> row) {
    final String? title = (row['unit_title'] as String?)?.trim();
    return MarkedUnit(
      mark: ItemMark.fromDb(row),
      unitTitle: (title == null || title.isEmpty) ? null : title,
    );
  }

  final ItemMark mark;

  final String? unitTitle;
}
