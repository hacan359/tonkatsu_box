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
