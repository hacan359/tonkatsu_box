import '../query_chunk.dart';
import '../../models/data_source.dart';
import '../../models/movie.dart';
import '../sparse_upsert.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// DAO for the `movies_cache` and `tmdb_genres` tables.
class MovieDao {
  const MovieDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<Movie?> getMovieByTmdbId(
    int tmdbId, {
    DataSource source = DataSource.tmdb,
  }) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'movies_cache',
      where: 'tmdb_id = ? AND source = ?',
      whereArgs: <Object?>[tmdbId, source.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Movie.fromDb(rows.first);
  }

  Future<void> upsertMovie(Movie movie) async {
    final Database db = await _getDatabase();
    final ({String sql, List<Object?> args}) upsert = _movieUpsert(movie);
    await db.rawInsert(upsert.sql, upsert.args);
  }

  Future<void> upsertMovies(List<Movie> movies) async {
    if (movies.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Movie movie in movies) {
        final ({String sql, List<Object?> args}) upsert = _movieUpsert(movie);
        batch.rawInsert(upsert.sql, upsert.args);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Search hits carry no runtime and no overview, so a later list refresh must
  /// not blank what a detail fetch already cached.
  ({String sql, List<Object?> args}) _movieUpsert(Movie movie) {
    return buildPreservingUpsert(
      table: 'movies_cache',
      row: movie.toDb(),
      conflictKey: <String>['tmdb_id', 'source'],
      preserveWhenNull: <String>{'runtime', 'overview', 'backdrop_url'},
    );
  }

  /// Returns hits from every source; callers disambiguate by [Movie.source].
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

  /// [type] is `movie` or `tv`; [lang] is `en` or `ru`.
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
