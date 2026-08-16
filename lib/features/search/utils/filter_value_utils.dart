/// Coerces a multi-select filter value (a `List`, a single value, or null) to
/// `List<String>`. Returns null when nothing is selected.
List<String>? readFilterStringList(Object? value) {
  return switch (value) {
    final List<Object?> list => list.whereType<String>().toList(),
    final String single => <String>[single],
    _ => null,
  };
}
