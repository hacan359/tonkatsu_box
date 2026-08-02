/// `SQLITE_MAX_VARIABLE_NUMBER` is 32766 on desktop but only 999 on many
/// Android system SQLite builds; 900 stays safely under that floor.
const int kInClauseChunkSize = 900;

/// Chunks an id-list query so `IN (...)` never exceeds the bound-parameter
/// limit. Order is not preserved across chunks — callers key results by id.
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
