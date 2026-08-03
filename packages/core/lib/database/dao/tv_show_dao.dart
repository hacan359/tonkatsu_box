import '../query_chunk.dart';
import '../sparse_upsert.dart';
import '../../models/data_source.dart';
import '../../models/tv_episode.dart';
import '../../models/tv_season.dart';
import '../../models/tv_show.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Season, episode and watched rows are keyed by `(source, show id)`.
class TvShowDao {
  /// Creates the DAO with a database accessor.
  const TvShowDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<TvShow?> getTvShowByTmdbId(
    int tmdbId, {
    DataSource source = DataSource.tmdb,
  }) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_shows_cache',
      where: 'tmdb_id = ? AND source = ?',
      whereArgs: <Object?>[tmdbId, source.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TvShow.fromDb(rows.first);
  }

  // List endpoints carry no totals/status; those columns keep the cached
  // detail-endpoint value rather than being wiped by the sparse row.
  static ({String sql, List<Object?> args}) _showUpsert(TvShow tvShow) =>
      buildPreservingUpsert(
        table: 'tv_shows_cache',
        row: tvShow.toDb(),
        conflictKey: const <String>['tmdb_id', 'source'],
        preserveWhenNull: const <String>{
          'total_seasons',
          'total_episodes',
          'status',
        },
      );

  /// Inserts or updates a show in the cache.
  Future<void> upsertTvShow(TvShow tvShow) async {
    final Database db = await _getDatabase();
    final ({String sql, List<Object?> args}) upsert = _showUpsert(tvShow);
    await db.rawInsert(upsert.sql, upsert.args);
  }

  /// Saves a list of shows in a batch.
  Future<void> upsertTvShows(List<TvShow> tvShows) async {
    if (tvShows.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final TvShow tvShow in tvShows) {
        final ({String sql, List<Object?> args}) upsert = _showUpsert(tvShow);
        batch.rawInsert(upsert.sql, upsert.args);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Returns matches across all sources for the given ids; callers
  /// disambiguate by [TvShow.source] (two rows can share a numeric id).
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

  /// Returns the show's seasons.
  Future<List<TvSeason>> getTvSeasonsByShowId(
    DataSource source,
    int showId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_seasons_cache',
      where: 'source = ? AND tmdb_show_id = ?',
      whereArgs: <Object?>[source.name, showId],
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

  /// Returns all cached episodes of a show.
  Future<List<TvEpisode>> getEpisodesByShowId(
    DataSource source,
    int showId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_episodes_cache',
      where: 'source = ? AND tmdb_show_id = ?',
      whereArgs: <Object?>[source.name, showId],
      orderBy: 'season_number ASC, episode_number ASC',
    );
    return rows.map(TvEpisode.fromDb).toList();
  }

  /// Returns cached episodes of a show's season.
  Future<List<TvEpisode>> getEpisodesByShowAndSeason(
    DataSource source,
    int showId,
    int seasonNumber,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_episodes_cache',
      where: 'source = ? AND tmdb_show_id = ? AND season_number = ?',
      whereArgs: <Object?>[source.name, showId, seasonNumber],
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
  Future<void> clearEpisodesByShow(DataSource source, int showId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'tv_episodes_cache',
      where: 'source = ? AND tmdb_show_id = ?',
      whereArgs: <Object?>[source.name, showId],
    );
  }

  /// Keyed by (seasonNumber, episodeNumber).
  Future<Map<(int, int), DateTime?>> getWatchedEpisodes(
    int collectionId,
    DataSource source,
    int showId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'watched_episodes',
      columns: <String>['season_number', 'episode_number', 'watched_at'],
      where: 'collection_id = ? AND source = ? AND show_id = ?',
      whereArgs: <Object?>[collectionId, source.name, showId],
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

  /// Collapses the per-collection split: release tracking treats a show as one
  /// subscription however many collections hold it.
  Future<Set<(int, int)>> getWatchedEpisodesForShow(
    DataSource source,
    int showId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'watched_episodes',
      columns: <String>['season_number', 'episode_number'],
      where: 'source = ? AND show_id = ?',
      whereArgs: <Object?>[source.name, showId],
      distinct: true,
    );
    return <(int, int)>{
      for (final Map<String, dynamic> row in rows)
        (row['season_number'] as int, row['episode_number'] as int),
    };
  }

  /// All watched episodes deduped by source/show/season/episode
  /// (collection-agnostic), for backup. Keeps the latest `watched_at`.
  Future<List<Map<String, Object?>>> getAllWatchedEpisodes() async {
    final Database db = await _getDatabase();
    return db.rawQuery(
      'SELECT source, show_id, season_number, episode_number, '
      'MAX(watched_at) AS watched_at FROM watched_episodes '
      'GROUP BY source, show_id, season_number, episode_number',
    );
  }

  /// Marks an episode watched with an explicit timestamp (restore path).
  Future<void> markEpisodeWatchedAt(
    int collectionId,
    DataSource source,
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
        'source': source.name,
        'show_id': showId,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
        'watched_at': watchedAtMs,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// One transaction for the whole title — an import expanding a completed
  /// series would otherwise pay a commit per episode.
  Future<void> markEpisodesWatchedAt(
    int collectionId,
    DataSource source,
    int showId,
    List<(int seasonNumber, int episodeNumber, int? watchedAtMs)> episodes,
  ) async {
    if (episodes.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final (int season, int episode, int? watchedAtMs) in episodes) {
        batch.insert(
          'watched_episodes',
          <String, dynamic>{
            'collection_id': collectionId,
            'source': source.name,
            'show_id': showId,
            'season_number': season,
            'episode_number': episode,
            'watched_at': watchedAtMs,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Marks an episode as watched.
  Future<void> markEpisodeWatched(
    int collectionId,
    DataSource source,
    int showId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.insert(
      'watched_episodes',
      <String, dynamic>{
        'collection_id': collectionId,
        'source': source.name,
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
    DataSource source,
    int showId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'watched_episodes',
      where: 'collection_id = ? AND source = ? AND show_id = ? '
          'AND season_number = ? AND episode_number = ?',
      whereArgs: <Object?>[
        collectionId,
        source.name,
        showId,
        seasonNumber,
        episodeNumber,
      ],
    );
  }

  /// Returns the watched-episode count for a show within a collection.
  Future<int> getWatchedEpisodeCount(
    int collectionId,
    DataSource source,
    int showId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM watched_episodes '
      'WHERE collection_id = ? AND source = ? AND show_id = ?',
      <Object?>[collectionId, source.name, showId],
    );
    return result.first['cnt'] as int;
  }

  /// Marks every episode of a season as watched.
  Future<void> markSeasonWatched(
    int collectionId,
    DataSource source,
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
            'source': source.name,
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
    DataSource source,
    int showId,
    int seasonNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'watched_episodes',
      where: 'collection_id = ? AND source = ? AND show_id = ? '
          'AND season_number = ?',
      whereArgs: <Object?>[collectionId, source.name, showId, seasonNumber],
    );
  }
}
