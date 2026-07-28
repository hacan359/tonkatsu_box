/// Maximum number of ids to bind in a single `IN (...)` query.
///
/// SQLite's `SQLITE_MAX_VARIABLE_NUMBER` is 32766 on the bundled desktop
/// (sqflite_common_ffi) build but only 999 on many Android system SQLite
/// versions. 900 stays safely under that floor so large collections (e.g. a
/// big MyAnimeList import) don't blow the bound-parameter limit.
const int kInClauseChunkSize = 900;

/// Runs an id-list query in chunks so the `IN (...)` clause never exceeds the
/// SQLite bound-parameter limit, concatenating the per-chunk results.
///
/// Order is not preserved across chunks — every caller maps results into a
/// keyed map, so this is fine. Returns immediately for small / empty lists.
Future<List<T>> queryByIdsInChunks<T>(
  List<int> ids,
  Future<List<T>> Function(List<int> chunk) query, {
  int chunkSize = kInClauseChunkSize,
}) async {
  if (ids.isEmpty) return <T>[];
  if (ids.length <= chunkSize) return query(ids);

  final List<T> out = <T>[];
  for (int i = 0; i < ids.length; i += chunkSize) {
    final int end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
    out.addAll(await query(ids.sublist(i, end)));
  }
  return out;
}
