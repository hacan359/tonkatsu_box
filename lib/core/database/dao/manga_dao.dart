// DAO for manga from AniList / MangaBaka.

import 'package:core/database/query_chunk.dart';
import 'package:core/database/sparse_upsert.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/manga.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DAO for `manga_cache`. Row identity is the pair `(id, source)`, so the same
/// numeric `id` from AniList and MangaBaka can coexist.
class MangaDao {
  const MangaDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // MangaBaka list rows may lack chapter/volume totals; those columns keep
  // the cached detail-endpoint value instead of being wiped by a sparse row.
  static ({String sql, List<Object?> args}) _mangaUpsert(Manga manga) =>
      buildPreservingUpsert(
        table: 'manga_cache',
        row: manga.toDb(),
        conflictKey: const <String>['id', 'source'],
        preserveWhenNull: const <String>{'chapters', 'volumes'},
      );

  Future<void> upsertManga(Manga manga) async {
    final Database db = await _getDatabase();
    final ({String sql, List<Object?> args}) upsert = _mangaUpsert(manga);
    await db.rawInsert(upsert.sql, upsert.args);
  }

  Future<void> upsertMangas(List<Manga> mangas) async {
    if (mangas.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final Manga manga in mangas) {
      final ({String sql, List<Object?> args}) upsert = _mangaUpsert(manga);
      batch.rawInsert(upsert.sql, upsert.args);
    }
    await batch.commit(noResult: true);
  }

  Future<Manga?> getManga(
    int id, {
    DataSource source = DataSource.anilist,
  }) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'manga_cache',
      where: 'id = ? AND source = ?',
      whereArgs: <Object?>[id, source.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Manga.fromDb(rows.first);
  }

  /// Returns matches across all sources for the given ids; callers
  /// disambiguate by [Manga.source] (two rows can share a numeric `id`).
  Future<List<Manga>> getMangaByIds(List<int> ids) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(ids, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM manga_cache WHERE id IN ($placeholders)',
        chunk,
      );
      return rows.map(Manga.fromDb).toList();
    });
  }
}
