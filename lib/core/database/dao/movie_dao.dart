// DAO для работы с фильмами и TMDB-жанрами.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/movie.dart';

/// DAO для таблиц `movies_cache` и `tmdb_genres`.
class MovieDao {
  /// Создаёт DAO с функцией получения базы данных.
  const MovieDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Возвращает фильм по TMDB ID или null, если не найден.
  Future<Movie?> getMovieByTmdbId(int tmdbId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'movies_cache',
      where: 'tmdb_id = ?',
      whereArgs: <Object?>[tmdbId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Movie.fromDb(rows.first);
  }

  /// Сохраняет или обновляет фильм в кеше.
  Future<void> upsertMovie(Movie movie) async {
    final Database db = await _getDatabase();
    await db.insert(
      'movies_cache',
      movie.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет список фильмов пакетно.
  Future<void> upsertMovies(List<Movie> movies) async {
    if (movies.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Movie movie in movies) {
        batch.insert(
          'movies_cache',
          movie.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Возвращает несколько фильмов по списку TMDB ID.
  Future<List<Movie>> getMoviesByTmdbIds(List<int> tmdbIds) async {
    if (tmdbIds.isEmpty) return <Movie>[];

    final Database db = await _getDatabase();
    final String placeholders =
        List<String>.filled(tmdbIds.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.query(
      'movies_cache',
      where: 'tmdb_id IN ($placeholders)',
      whereArgs: tmdbIds.cast<Object?>(),
    );
    return rows.map(Movie.fromDb).toList();
  }

  /// Удаляет все фильмы из кеша.
  Future<void> clearMovies() async {
    final Database db = await _getDatabase();
    await db.delete('movies_cache');
  }

  /// Удаляет устаревшие фильмы из кэша.
  ///
  /// Элементы, привязанные к коллекции, не удаляются.
  /// [maxAgeSeconds] — максимальный возраст записи в секундах.
  Future<int> clearStaleMovies({int maxAgeSeconds = 86400 * 30}) async {
    final Database db = await _getDatabase();
    final int threshold =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - maxAgeSeconds;
    return db.rawDelete('''
      DELETE FROM movies_cache
      WHERE cached_at < ?
        AND tmdb_id NOT IN (
          SELECT external_id FROM collection_items
          WHERE media_type = 'movie'
        )
    ''', <Object?>[threshold]);
  }

  /// Возвращает маппинг ID → имя жанров из кэша.
  ///
  /// [type] — тип медиа: `'movie'` или `'tv'`.
  /// [lang] — язык: `'en'` или `'ru'`.
  Future<Map<String, String>> getTmdbGenreMap(
    String type, {
    String lang = 'en',
  }) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tmdb_genres',
      where: 'type = ? AND lang = ?',
      whereArgs: <Object?>[type, lang],
    );

    return <String, String>{
      for (final Map<String, dynamic> row in rows)
        (row['id'] as int).toString(): row['name'] as String,
    };
  }
}
