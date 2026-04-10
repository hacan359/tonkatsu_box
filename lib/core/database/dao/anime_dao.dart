// DAO для работы с аниме из AniList.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/anime.dart';

/// DAO для таблицы `anime_cache`.
class AnimeDao {
  /// Создаёт DAO с функцией получения базы данных.
  const AnimeDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Сохраняет или обновляет аниме в кэше.
  Future<void> upsertAnime(Anime anime) async {
    final Database db = await _getDatabase();
    await db.insert(
      'anime_cache',
      anime.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет или обновляет список аниме.
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

  /// Получает аниме по AniList ID.
  Future<Anime?> getAnime(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'anime_cache',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Anime.fromDb(rows.first);
  }

  /// Получает аниме по списку ID.
  Future<List<Anime>> getAnimeByIds(List<int> ids) async {
    if (ids.isEmpty) return <Anime>[];
    final Database db = await _getDatabase();
    final String placeholders =
        List<String>.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT * FROM anime_cache WHERE id IN ($placeholders)',
      ids,
    );
    return rows.map(Anime.fromDb).toList();
  }
}
