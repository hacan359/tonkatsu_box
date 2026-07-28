// Upsert SQL builder for media cache tables.

/// Builds an `INSERT OR REPLACE` statement where [preserveWhenNull] columns
/// keep the cached value when the incoming one is NULL.
///
/// Rows parsed from list endpoints (search, recommendations, similars) lack
/// fields that only detail endpoints provide (episode totals, page counts);
/// a plain REPLACE would wipe those cached values. Preserved columns are
/// written as `COALESCE(?, (SELECT col ... WHERE key))` — the subquery reads
/// the old row before REPLACE deletes it. This idiom works on any SQLite,
/// unlike `ON CONFLICT DO UPDATE` (3.24+, missing on Android < 11).
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
