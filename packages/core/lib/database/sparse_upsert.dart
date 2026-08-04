/// [preserveWhenNull] columns keep their cached value via
/// `COALESCE(?, (SELECT ...))` — works on any SQLite, unlike `ON CONFLICT` 3.24+.
({String sql, List<Object?> args}) buildPreservingUpsert({
  required String table,
  required Map<String, Object?> row,
  required List<String> conflictKey,
  required Set<String> preserveWhenNull,
}) {
  final String keyFilter =
      conflictKey.map((String k) => '$k = ?').join(' AND ');
  final List<String> values = <String>[];
  final List<Object?> args = <Object?>[];
  for (final MapEntry<String, Object?> entry in row.entries) {
    if (preserveWhenNull.contains(entry.key)) {
      values.add(
        'COALESCE(?, (SELECT ${entry.key} FROM $table WHERE $keyFilter))',
      );
      args
        ..add(entry.value)
        ..addAll(conflictKey.map((String k) => row[k]));
    } else {
      values.add('?');
      args.add(entry.value);
    }
  }
  final String sql = 'INSERT OR REPLACE INTO $table '
      '(${row.keys.join(', ')}) VALUES (${values.join(', ')})';
  return (sql: sql, args: args);
}
