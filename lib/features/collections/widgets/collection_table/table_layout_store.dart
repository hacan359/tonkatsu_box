import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Column layout of the collection table: visual order, widths and hidden
/// columns by field id.
class TableColumnLayout {
  const TableColumnLayout({
    required this.order,
    required this.widths,
    this.hidden = const <String>{},
  });

  factory TableColumnLayout.fromJson(Map<String, dynamic> json) {
    final List<dynamic> order = json['order'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> widths =
        json['widths'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final List<dynamic> hidden =
        json['hidden'] as List<dynamic>? ?? <dynamic>[];
    return TableColumnLayout(
      order: order.cast<String>(),
      widths: widths.map(
        (String key, dynamic value) =>
            MapEntry<String, double>(key, (value as num).toDouble()),
      ),
      hidden: hidden.cast<String>().toSet(),
    );
  }

  /// Column field ids in visual order.
  final List<String> order;

  /// Field id → column width.
  final Map<String, double> widths;

  /// Field ids of columns hidden by the user.
  final Set<String> hidden;

  String encode() => jsonEncode(<String, dynamic>{
        'order': order,
        'widths': widths,
        'hidden': hidden.toList(),
      });
}

/// Persists the table column layout per collection in [SharedPreferences].
abstract final class TableLayoutStore {
  static String _key(int collectionId) => 'collection_table_layout_$collectionId';

  static Future<TableColumnLayout?> load(int collectionId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(collectionId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return TableColumnLayout.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    }
  }

  static Future<void> save(int collectionId, TableColumnLayout layout) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(collectionId), layout.encode());
  }
}
