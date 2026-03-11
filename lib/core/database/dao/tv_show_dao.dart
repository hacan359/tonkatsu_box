// DAO для работы с сериалами, сезонами, эпизодами и просмотренными эпизодами.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';

/// DAO для таблиц `tv_shows_cache`, `tv_seasons_cache`,
/// `tv_episodes_cache` и `watched_episodes`.
class TvShowDao {
  /// Создаёт DAO с функцией получения базы данных.
  const TvShowDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ==================== TV Shows ====================

  /// Возвращает сериал по TMDB ID или null, если не найден.
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

  /// Сохраняет или обновляет сериал в кеше.
  Future<void> upsertTvShow(TvShow tvShow) async {
    final Database db = await _getDatabase();
    await db.insert(
      'tv_shows_cache',
      tvShow.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет список сериалов пакетно.
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

  /// Возвращает несколько сериалов по списку TMDB ID.
  Future<List<TvShow>> getTvShowsByTmdbIds(List<int> tmdbIds) async {
    if (tmdbIds.isEmpty) return <TvShow>[];

    final Database db = await _getDatabase();
    final String placeholders =
        List<String>.filled(tmdbIds.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_shows_cache',
      where: 'tmdb_id IN ($placeholders)',
      whereArgs: tmdbIds.cast<Object?>(),
    );
    return rows.map(TvShow.fromDb).toList();
  }

  /// Удаляет все сериалы из кеша.
  Future<void> clearTvShows() async {
    final Database db = await _getDatabase();
    await db.delete('tv_shows_cache');
  }

  /// Удаляет устаревшие сериалы из кэша.
  ///
  /// Сериалы, привязанные к коллекции, не удаляются.
  /// [maxAgeSeconds] — максимальный возраст записи в секундах.
  Future<int> clearStaleTvShows({int maxAgeSeconds = 86400 * 30}) async {
    final Database db = await _getDatabase();
    final int threshold =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - maxAgeSeconds;
    return db.rawDelete('''
      DELETE FROM tv_shows_cache
      WHERE cached_at < ?
        AND tmdb_id NOT IN (
          SELECT external_id FROM collection_items
          WHERE media_type IN ('tv_show', 'animation')
        )
    ''', <Object?>[threshold]);
  }

  /// Удаляет устаревшие эпизоды из кэша.
  ///
  /// Эпизоды сериалов, находящихся в коллекции, не удаляются.
  /// [maxAgeSeconds] — максимальный возраст записи в секундах.
  Future<int> clearStaleEpisodes({int maxAgeSeconds = 86400 * 30}) async {
    final Database db = await _getDatabase();
    final int threshold =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - maxAgeSeconds;
    return db.rawDelete('''
      DELETE FROM tv_episodes_cache
      WHERE cached_at < ?
        AND tmdb_show_id NOT IN (
          SELECT external_id FROM collection_items
          WHERE media_type IN ('tv_show', 'animation')
        )
    ''', <Object?>[threshold]);
  }

  // ==================== TV Seasons ====================

  /// Возвращает сезоны сериала.
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

  /// Сохраняет сезоны сериала пакетно.
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

  /// Удаляет все сезоны из кеша.
  Future<void> clearTvSeasons() async {
    final Database db = await _getDatabase();
    await db.delete('tv_seasons_cache');
  }

  // ==================== TV Episodes ====================

  /// Возвращает все эпизоды сериала из кеша.
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

  /// Возвращает эпизоды сезона сериала из кеша.
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

  /// Сохраняет список эпизодов пакетно (INSERT OR REPLACE).
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

  /// Удаляет кешированные эпизоды сериала.
  Future<void> clearEpisodesByShow(int showId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'tv_episodes_cache',
      where: 'tmdb_show_id = ?',
      whereArgs: <Object?>[showId],
    );
  }

  // ==================== Watched Episodes ====================

  /// Возвращает множество просмотренных эпизодов для сериала в коллекции.
  ///
  /// Возвращает Set записей (seasonNumber, episodeNumber).
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

  /// Отмечает эпизод как просмотренный.
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

  /// Снимает отметку просмотра с эпизода.
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

  /// Возвращает количество просмотренных эпизодов для сериала в коллекции.
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

  /// Отмечает все эпизоды сезона как просмотренные.
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

  /// Снимает отметку просмотра со всех эпизодов сезона.
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
