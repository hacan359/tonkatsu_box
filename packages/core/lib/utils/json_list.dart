import 'dart:convert';

/// Decodes a JSON-array DB column into a string list, tolerating null and
/// malformed data — cache rows written by older builds must never throw.
List<String> decodeJsonStringList(Object? value) {
  if (value is! String || value.isEmpty) return const <String>[];
  try {
    final Object? decoded = jsonDecode(value);
    if (decoded is List<dynamic>) {
      return decoded.whereType<String>().toList();
    }
  } on FormatException {
    return const <String>[];
  }
  return const <String>[];
}

/// Like [decodeJsonStringList], but an absent or empty list reads as null so
/// "never fetched" stays distinct from a value.
List<String>? decodeJsonStringListOrNull(Object? value) {
  final List<String> list = decodeJsonStringList(value);
  return list.isEmpty ? null : list;
}

String? encodeJsonStringList(List<String>? list) =>
    list == null || list.isEmpty ? null : jsonEncode(list);

/// Trimmed, de-duplicated (case-sensitive, first wins) non-empty strings of
/// [values]; null when nothing is left.
List<String>? distinctNames(Iterable<Object?> values) {
  final Set<String> seen = <String>{};
  for (final Object? value in values) {
    if (value is! String) continue;
    final String name = value.trim();
    if (name.isNotEmpty) seen.add(name);
  }
  return seen.isEmpty ? null : seen.toList();
}

/// [distinctNames] of the `name` keys in a `[{name: ...}]` list, the shape of
/// TMDB credits, companies and networks.
List<String>? distinctEntryNames(Object? entries) {
  if (entries is! List<dynamic>) return null;
  return distinctNames(<Object?>[
    for (final dynamic e in entries)
      if (e is Map<String, dynamic>) e['name'],
  ]);
}
