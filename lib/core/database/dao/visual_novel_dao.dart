import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/visual_novel.dart';
import '../query_chunk.dart';

/// DAO for the `visual_novels_cache` and `vndb_tags` tables.
class VisualNovelDao {
  const VisualNovelDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<void> upsertVisualNovel(VisualNovel vn) async {
    final Database db = await _getDatabase();
    await db.insert(
      'visual_novels_cache',
      vn.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertVisualNovels(List<VisualNovel> vns) async {
    if (vns.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final VisualNovel vn in vns) {
      batch.insert(
        'visual_novels_cache',
        vn.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<VisualNovel?> getVisualNovel(int numericId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'visual_novels_cache',
      where: 'numeric_id = ?',
      whereArgs: <Object?>[numericId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VisualNovel.fromDb(rows.first);
  }

  Future<List<VisualNovel>> getVisualNovelsByNumericIds(
    List<int> numericIds,
  ) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(numericIds, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM visual_novels_cache WHERE numeric_id IN ($placeholders)',
        chunk,
      );
      return rows.map(VisualNovel.fromDb).toList();
    });
  }

  Future<List<VndbTag>> getVndbTags() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'vndb_tags',
      orderBy: 'name ASC',
    );
    return rows.map(VndbTag.fromDb).toList();
  }
}
