// DAO for TV shows, seasons, episodes and watched episodes.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../query_chunk.dart';

/// DAO for the `tv_shows_cache`, `tv_seasons_cache`, `tv_episodes_cache` and
/// `watched_episodes` tables.
class TvShowDao {
  /// Creates the DAO with a database accessor.
  const TvShowDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ==================== TV Shows ====================

  /// Returns the show by TMDB id, or null if not cached.
  Future<TvShow?> getTvShowByTmdbId(int tmdbId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_shows_cache',
      where: 'tmdb_id = ?',
      whereArgs: <Object?>[tmdbId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TvShow.fromDb(rows.first);
  }

  /// Inserts or updates a show in the cache.
  Future<void> upsertTvShow(TvShow tvShow) async {
    final Database db = await _getDatabase();
    await db.insert(
      'tv_shows_cache',
      tvShow.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Saves a list of shows in a batch.
  Future<void> upsertTvShows(List<TvShow> tvShows) async {
    if (tvShows.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final TvShow tvShow in tvShows) {
        batch.insert(
          'tv_shows_cache',
          tvShow.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Returns several shows by a list of TMDB ids.
  Future<List<TvShow>> getTvShowsByTmdbIds(List<int> tmdbIds) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(tmdbIds, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.query(
        'tv_shows_cache',
        where: 'tmdb_id IN ($placeholders)',
        whereArgs: chunk.cast<Object?>(),
      );
      return rows.map(TvShow.fromDb).toList();
    });
  }

  /// Clears all shows from the cache.
  Future<void> clearTvShows() async {
    final Database db = await _getDatabase();
    await db.delete('tv_shows_cache');
  }

  // ==================== TV Seasons ====================

  /// Returns the show's seasons.
  Future<List<TvSeason>> getTvSeasonsByShowId(int tmdbShowId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_seasons_cache',
      where: 'tmdb_show_id = ?',
      whereArgs: <Object?>[tmdbShowId],
      orderBy: 'season_number ASC',
    );
    return rows.map(TvSeason.fromDb).toList();
  }

  /// Saves the show's seasons in a batch.
  Future<void> upsertTvSeasons(List<TvSeason> seasons) async {
    if (seasons.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final TvSeason season in seasons) {
        batch.insert(
          'tv_seasons_cache',
          season.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Clears all seasons from the cache.
  Future<void> clearTvSeasons() async {
    final Database db = await _getDatabase();
    await db.delete('tv_seasons_cache');
  }

  // ==================== TV Episodes ====================

  /// Returns all cached episodes of a show.
  Future<List<TvEpisode>> getEpisodesByShowId(int showId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_episodes_cache',
      where: 'tmdb_show_id = ?',
      whereArgs: <Object?>[showId],
      orderBy: 'season_number ASC, episode_number ASC',
    );
    return rows.map(TvEpisode.fromDb).toList();
  }

  /// Returns cached episodes of a show's season.
  Future<List<TvEpisode>> getEpisodesByShowAndSeason(
    int showId,
    int seasonNumber,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_episodes_cache',
      where: 'tmdb_show_id = ? AND season_number = ?',
      whereArgs: <Object?>[showId, seasonNumber],
      orderBy: 'episode_number ASC',
    );
    return rows.map(TvEpisode.fromDb).toList();
  }

  /// Saves a list of episodes in a batch (INSERT OR REPLACE).
  Future<void> upsertEpisodes(List<TvEpisode> episodes) async {
    if (episodes.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final TvEpisode episode in episodes) {
        batch.insert(
          'tv_episodes_cache',
          episode.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Clears a show's cached episodes.
  Future<void> clearEpisodesByShow(int showId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'tv_episodes_cache',
      where: 'tmdb_show_id = ?',
      whereArgs: <Object?>[showId],
    );
  }

  // ==================== Watched Episodes ====================

  /// Watched episodes of a show within a collection.
  ///
  /// Returns a set of (seasonNumber, episodeNumber) records.
  Future<Map<(int, int), DateTime?>> getWatchedEpisodes(
    int collectionId,
    int showId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'watched_episodes',
      columns: <String>['season_number', 'episode_number', 'watched_at'],
      where: 'collection_id = ? AND show_id = ?',
      whereArgs: <Object?>[collectionId, showId],
    );
    final Map<(int, int), DateTime?> result = <(int, int), DateTime?>{};
    for (final Map<String, dynamic> row in rows) {
      final int? watchedAtMs = row['watched_at'] as int?;
      result[(
        row['season_number'] as int,
        row['episode_number'] as int,
      )] = watchedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(watchedAtMs)
          : null;
    }
    return result;
  }

  /// Watched episodes for a show aggregated across all collections: an episode
  /// counts as watched if it is marked in any collection. Release tracking
  /// treats a show as a single subscription regardless of how many collections
  /// hold it, so the per-collection split in `watched_episodes` is collapsed.
  Future<Set<(int, int)>> getWatchedEpisodesForShow(int showId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'watched_episodes',
      columns: <String>['season_number', 'episode_number'],
      where: 'show_id = ?',
      whereArgs: <Object?>[showId],
      distinct: true,
    );
    return <(int, int)>{
      for (final Map<String, dynamic> row in rows)
        (row['season_number'] as int, row['episode_number'] as int),
    };
  }

  /// All watched episodes deduped by show/season/episode (collection-agnostic),
  /// for backup. Keeps the latest `watched_at`.
  Future<List<Map<String, Object?>>> getAllWatchedEpisodes() async {
    final Database db = await _getDatabase();
    return db.rawQuery(
      'SELECT show_id, season_number, episode_number, '
      'MAX(watched_at) AS watched_at FROM watched_episodes '
      'GROUP BY show_id, season_number, episode_number',
    );
  }

  /// Marks an episode watched with an explicit timestamp (restore path).
  Future<void> markEpisodeWatchedAt(
    int collectionId,
    int showId,
    int seasonNumber,
    int episodeNumber,
    int? watchedAtMs,
  ) async {
    final Database db = await _getDatabase();
    await db.insert(
      'watched_episodes',
      <String, dynamic>{
        'collection_id': collectionId,
        'show_id': showId,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
        'watched_at': watchedAtMs,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Marks an episode as watched.
  Future<void> markEpisodeWatched(
    int collectionId,
    int showId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.insert(
      'watched_episodes',
      <String, dynamic>{
        'collection_id': collectionId,
        'show_id': showId,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
        'watched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Clears the watched mark from an episode.
  Future<void> markEpisodeUnwatched(
    int collectionId,
    int showId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'watched_episodes',
      where: 'collection_id = ? AND show_id = ? '
          'AND season_number = ? AND episode_number = ?',
      whereArgs: <Object?>[collectionId, showId, seasonNumber, episodeNumber],
    );
  }

  /// Returns the watched-episode count for a show within a collection.
  Future<int> getWatchedEpisodeCount(
    int collectionId,
    int showId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM watched_episodes '
      'WHERE collection_id = ? AND show_id = ?',
      <Object?>[collectionId, showId],
    );
    return result.first['cnt'] as int;
  }

  /// Marks every episode of a season as watched.
  Future<void> markSeasonWatched(
    int collectionId,
    int showId,
    int seasonNumber,
    List<int> episodeNumbers,
  ) async {
    if (episodeNumbers.isEmpty) return;

    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final int ep in episodeNumbers) {
        batch.insert(
          'watched_episodes',
          <String, dynamic>{
            'collection_id': collectionId,
            'show_id': showId,
            'season_number': seasonNumber,
            'episode_number': ep,
            'watched_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Clears the watched mark from every episode of a season.
  Future<void> unmarkSeasonWatched(
    int collectionId,
    int showId,
    int seasonNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'watched_episodes',
      where: 'collection_id = ? AND show_id = ? AND season_number = ?',
      whereArgs: <Object?>[collectionId, showId, seasonNumber],
    );
  }
}
