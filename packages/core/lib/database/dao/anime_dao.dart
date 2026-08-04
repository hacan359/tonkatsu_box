import '../query_chunk.dart';
import '../../models/anime.dart';
import '../../models/data_source.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// DAO for `anime_cache`. Row identity is the pair `(id, source)`.
class AnimeDao {
  const AnimeDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<void> upsertAnime(Anime anime) async {
    final Database db = await _getDatabase();
    await db.insert(
      'anime_cache',
      anime.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAnimes(List<Anime> animes) async {
    if (animes.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final Anime anime in animes) {
      batch.insert(
        'anime_cache',
        anime.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Anime?> getAnime(
    int id, {
    DataSource source = DataSource.anilist,
  }) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'anime_cache',
      where: 'id = ? AND source = ?',
      whereArgs: <Object?>[id, source.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Anime.fromDb(rows.first);
  }

  /// Matches across all sources; callers disambiguate by [Anime.source].
  Future<List<Anime>> getAnimeByIds(List<int> ids) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(ids, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM anime_cache WHERE id IN ($placeholders)',
        chunk,
      );
      return rows.map(Anime.fromDb).toList();
    });
  }
}
