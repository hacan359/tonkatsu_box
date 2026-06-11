import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/movie.dart';
import '../query_chunk.dart';

/// DAO for the `movies_cache` and `tmdb_genres` tables.
class MovieDao {
  const MovieDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

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

  Future<void> upsertMovie(Movie movie) async {
    final Database db = await _getDatabase();
    await db.insert(
      'movies_cache',
      movie.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<List<Movie>> getMoviesByTmdbIds(List<int> tmdbIds) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(tmdbIds, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.query(
        'movies_cache',
        where: 'tmdb_id IN ($placeholders)',
        whereArgs: chunk.cast<Object?>(),
      );
      return rows.map(Movie.fromDb).toList();
    });
  }

  Future<void> clearMovies() async {
    final Database db = await _getDatabase();
    await db.delete('movies_cache');
  }

  /// Returns a genre ID → name map from the cache.
  ///
  /// [type] is `'movie'` or `'tv'`; [lang] is `'en'` or `'ru'`.
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
        (row['id'] as int).toString(): _capitalize(row['name'] as String),
    };
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
