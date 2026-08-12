import 'package:sqflite_common/sqlite_api.dart';

import '../../models/item_status.dart';
import '../../models/media_type.dart';
import '../../utils/json_list.dart';

/// SQL aggregates for the statistics page. Schema date units: `added_at` is
/// unix seconds, `watched_at`/`liked_at` milliseconds; bucketing is local time.
class StatsDao {
  /// Creates the DAO over a lazy database handle.
  const StatsDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Per-media-type status counts of items added in [year] (or ever).
  Future<Map<MediaType, Map<ItemStatus, int>>> getTypeStatusCounts({
    int? year,
  }) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT media_type, status, COUNT(*) AS c FROM collection_items '
      '${w.where('added_at', seconds: true)} '
      'GROUP BY media_type, status',
      w.args,
    );
    final Map<MediaType, Map<ItemStatus, int>> result =
        <MediaType, Map<ItemStatus, int>>{};
    for (final Map<String, dynamic> row in rows) {
      final MediaType? type =
          MediaType.tryFromString(row['media_type'] as String);
      final ItemStatus? status =
          ItemStatus.tryFromString(row['status'] as String);
      if (type == null || status == null) continue;
      final Map<ItemStatus, int> perStatus =
          result.putIfAbsent(type, () => <ItemStatus, int>{});
      perStatus[status] = (perStatus[status] ?? 0) + (row['c'] as int? ?? 0);
    }
    return result;
  }

  /// Game status counts per platform for items added in [year] — the "live"
  /// per-platform completion breakdown.
  Future<Map<int?, Map<ItemStatus, int>>> getGamePlatformStatusCounts({
    int? year,
  }) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT platform_id, status, COUNT(*) AS c FROM collection_items '
      "${w.where('added_at', seconds: true, extra: "media_type = 'game'")} "
      'GROUP BY platform_id, status',
      w.args,
    );
    final Map<int?, Map<ItemStatus, int>> result =
        <int?, Map<ItemStatus, int>>{};
    for (final Map<String, dynamic> row in rows) {
      final ItemStatus? status =
          ItemStatus.tryFromString(row['status'] as String);
      if (status == null) continue;
      final Map<ItemStatus, int> perStatus = result.putIfAbsent(
          row['platform_id'] as int?, () => <ItemStatus, int>{});
      perStatus[status] = (perStatus[status] ?? 0) + (row['c'] as int? ?? 0);
    }
    return result;
  }

  /// Sum of rewatch counters over items added in [year].
  Future<int> getRewatchSum({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT SUM(COALESCE(rewatch_count, 0)) AS s FROM collection_items '
      '${w.where('added_at', seconds: true)}',
      w.args,
    );
    return (rows.first['s'] as int?) ?? 0;
  }

  /// Average user rating over items added in [year]; null when none is rated.
  Future<double?> getAverageRating({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT AVG(user_rating) AS a FROM collection_items '
      '${w.where('added_at', seconds: true)}',
      w.args,
    );
    return (rows.first['a'] as num?)?.toDouble();
  }

  /// Watched episode rows split into TV and anime (Kitsu tracker). All time
  /// includes undated rows; a year window can only count dated ones.
  Future<({int tv, int anime})> getEpisodeSplit({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      "SELECT SUM(CASE WHEN source = 'kitsu' THEN 1 ELSE 0 END) AS anime, "
      'COUNT(*) AS total FROM watched_episodes '
      '${w.where('watched_at', seconds: false)}',
      w.args,
    );
    final int anime = (rows.first['anime'] as int?) ?? 0;
    final int total = (rows.first['total'] as int?) ?? 0;
    return (tv: total - anime, anime: anime);
  }

  /// Listened track marks (the music tracker). All time includes undated
  /// rows; a year window can only count dated ones.
  Future<int> getListenedTrackTotal({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM listened_tracks '
      '${w.where('listened_at', seconds: false)}',
      w.args,
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Flat `current_episode` counter sums: AniList anime episodes, manga
  /// chapters, book pages. Kitsu anime are excluded — they use the tracker.
  Future<({int animeEpisodes, int mangaChapters, int bookPages})>
      getProgressCounterSums({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT media_type, SUM(current_episode) AS s FROM collection_items '
      "${w.where('added_at', seconds: true, extra: "(media_type IN ('manga', 'book') OR (media_type = 'anime' AND COALESCE(source, 'anilist') != 'kitsu'))")} "
      'GROUP BY media_type',
      w.args,
    );
    int anime = 0;
    int manga = 0;
    int book = 0;
    for (final Map<String, dynamic> row in rows) {
      final int sum = (row['s'] as int?) ?? 0;
      switch (MediaType.tryFromString(row['media_type'] as String)) {
        case MediaType.anime:
          anime = sum;
        case MediaType.manga:
          manga = sum;
        case MediaType.book:
          book = sum;
        default:
          break;
      }
    }
    return (animeEpisodes: anime, mangaChapters: manga, bookPages: book);
  }

  /// Liked units (episode/chapter marks) in [year], per media type of the
  /// owning item.
  Future<Map<MediaType, int>> getLikedUnitsByType({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT ci.media_type AS mt, COUNT(*) AS c FROM item_marks im '
      'JOIN collection_items ci ON ci.id = im.item_id '
      '${w.where('im.liked_at', seconds: false, extra: 'im.is_favorite = 1')} '
      'GROUP BY ci.media_type',
      w.args,
    );
    final Map<MediaType, int> result = <MediaType, int>{};
    for (final Map<String, dynamic> row in rows) {
      final MediaType? type = MediaType.tryFromString(row['mt'] as String);
      if (type == null) continue;
      result[type] = (result[type] ?? 0) + (row['c'] as int? ?? 0);
    }
    return result;
  }

  /// Manually entered minutes over items added in [year]. Movies are excluded
  /// — their time comes from the cached runtime, or manual entry would double.
  Future<int> getManualMinutes({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT SUM(time_spent_minutes) AS s FROM collection_items '
      "${w.where('added_at', seconds: true, extra: "media_type != 'movie'")}",
      w.args,
    );
    return (rows.first['s'] as int?) ?? 0;
  }

  /// Tracker-reported minutes for game items added in [year]. EXISTS keeps a
  /// game duplicated across collections from counting its playtime twice.
  Future<int> getTrackerMinutes({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT SUM(t.playtime_minutes) AS s FROM tracker_game_data t '
      'WHERE EXISTS (SELECT 1 FROM collection_items ci '
      "${w.where('ci.added_at', seconds: true, extra: "ci.external_id = t.game_id AND ci.media_type = 'game'")})",
      w.args,
    );
    return (rows.first['s'] as int?) ?? 0;
  }

  /// Fixed data only — watched episodes with a known runtime plus completed
  /// movies. No averaging: an episode without a cached runtime counts as 0.
  Future<int> getEstimatedMinutes({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);

    final List<Map<String, dynamic>> ep = await db.rawQuery(
      'SELECT SUM(tec.runtime) AS s '
      'FROM watched_episodes we '
      'JOIN tv_episodes_cache tec ON tec.tmdb_show_id = we.show_id '
      'AND tec.season_number = we.season_number '
      'AND tec.episode_number = we.episode_number '
      'AND tec.source = we.source AND tec.runtime > 0 '
      '${w.where('we.watched_at', seconds: false)}',
      w.args,
    );
    final int episodeMinutes = (ep.first['s'] as int?) ?? 0;

    final List<Map<String, dynamic>> mv = await db.rawQuery(
      'SELECT SUM(mc.runtime * (1 + COALESCE(ci.rewatch_count, 0))) AS s '
      'FROM collection_items ci '
      // Source-qualified: two providers can cache the same numeric id, and an
      // unqualified join would count that film's runtime twice.
      'JOIN movies_cache mc ON mc.tmdb_id = ci.external_id '
      "AND mc.source = COALESCE(ci.source, 'tmdb') "
      "${w.where('ci.added_at', seconds: true, extra: "ci.media_type = 'movie' AND ci.status = 'completed'")}",
      w.args,
    );
    final int movieMinutes = (mv.first['s'] as int?) ?? 0;
    return episodeMinutes + movieMinutes;
  }

  /// Items added per `year-month` bucket ("YYYY-MM" keys).
  Future<Map<String, int>> getAddedByMonth({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      "SELECT strftime('%Y-%m', added_at, 'unixepoch', 'localtime') AS ym, COUNT(*) AS c "
      'FROM collection_items '
      '${w.where('added_at', seconds: true)} '
      'GROUP BY ym',
      w.args,
    );
    return <String, int>{
      for (final Map<String, dynamic> row in rows)
        if (row['ym'] != null) row['ym'] as String: (row['c'] as int?) ?? 0,
    };
  }

  /// Episodes watched per `year-month` bucket ("YYYY-MM" keys).
  Future<Map<String, int>> getEpisodesByMonth({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      "SELECT strftime('%Y-%m', watched_at / 1000, 'unixepoch', 'localtime') AS ym, "
      'COUNT(*) AS c FROM watched_episodes '
      '${w.where('watched_at', seconds: false)} '
      'GROUP BY ym',
      w.args,
    );
    return <String, int>{
      for (final Map<String, dynamic> row in rows)
        if (row['ym'] != null) row['ym'] as String: (row['c'] as int?) ?? 0,
    };
  }

  /// No window functions anywhere in this DAO: they need SQLite 3.25+, which
  /// older Android devices lack. Rows arrive ordered and are capped in Dart.
  Future<Map<String, int>> getBestItemByMonth({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      "SELECT strftime('%Y-%m', added_at, 'unixepoch', 'localtime') AS ym, id "
      'FROM collection_items '
      '${w.where('added_at', seconds: true, extra: 'user_rating IS NOT NULL')} '
      'ORDER BY user_rating DESC, added_at DESC',
      w.args,
    );
    final Map<String, int> result = <String, int>{};
    for (final Map<String, dynamic> row in rows) {
      final String? ym = row['ym'] as String?;
      if (ym == null) continue;
      result.putIfAbsent(ym, () => row['id'] as int);
    }
    return result;
  }

  /// Game platform buckets: count and manual minutes per platform, joined to
  /// the platform name. Ordered by minutes, then count.
  Future<List<Map<String, dynamic>>> getGamePlatformRows({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    return db.rawQuery(
      'SELECT ci.platform_id AS platform_id, p.name AS name, '
      'p.abbreviation AS abbreviation, COUNT(*) AS games, '
      'SUM(ci.time_spent_minutes) AS manual_minutes '
      'FROM collection_items ci '
      'LEFT JOIN platforms p ON p.id = ci.platform_id '
      "${w.where('ci.added_at', seconds: true, extra: "ci.media_type = 'game'")} "
      'GROUP BY ci.platform_id '
      'ORDER BY manual_minutes DESC, games DESC',
      w.args,
    );
  }

  /// Tracker minutes per platform for game items added in [year]. Each tracker
  /// row lands on exactly one platform, so the buckets sum to the hero total.
  Future<Map<int?, int>> getTrackerMinutesByPlatform({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final String ciWindow =
        w.where('ci.added_at', seconds: true, extra: "ci.media_type = 'game'");
    final List<Object?> args = <Object?>[...w.args, ...w.args];
    // A platform-agnostic tracker row (t.platform_id NULL) falls back to one
    // deterministic library platform, never to every platform the game is on.
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT COALESCE(t.platform_id, '
      '(SELECT MIN(ci.platform_id) FROM collection_items ci '
      '$ciWindow AND ci.external_id = t.game_id)) AS platform_id, '
      'SUM(t.playtime_minutes) AS minutes '
      'FROM tracker_game_data t '
      'WHERE EXISTS (SELECT 1 FROM collection_items ci '
      '$ciWindow AND ci.external_id = t.game_id) '
      'GROUP BY platform_id',
      args,
    );
    return <int?, int>{
      for (final Map<String, dynamic> row in rows)
        row['platform_id'] as int?: (row['minutes'] as int?) ?? 0,
    };
  }

  /// The most-played game row ids per platform (top [perPlatform] each).
  /// Ordered rows, capped per group in Dart (see [getBestItemByMonth]).
  Future<Map<int?, List<int>>> getTopGamesByPlatform({
    int? year,
    int perPlatform = 3,
  }) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT platform_id, id FROM collection_items '
      "${w.where('added_at', seconds: true, extra: "media_type = 'game'")} "
      'ORDER BY time_spent_minutes DESC, user_rating DESC, added_at DESC',
      w.args,
    );
    final Map<int?, List<int>> result = <int?, List<int>>{};
    for (final Map<String, dynamic> row in rows) {
      final List<int> top =
          result.putIfAbsent(row['platform_id'] as int?, () => <int>[]);
      if (top.length < perPlatform) top.add(row['id'] as int);
    }
    return result;
  }

  /// Source subgenre tags for [mediaType] (JSON lists in anime/manga caches):
  /// contributing title count plus tag counts, biggest first, capped at [limit].
  Future<({int titles, List<(String, int)> tags})> getSourceTagCounts(
    MediaType mediaType, {
    int? year,
    int limit = 12,
  }) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final String cacheTable = _formatCacheTable(mediaType);
    // COALESCE: items saved before sources went namespaced carry a NULL
    // source but were always AniList (same remap as the hydration joins).
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT c.tags AS tags FROM collection_items ci '
      'JOIN $cacheTable c ON c.id = ci.external_id '
      "AND c.source = COALESCE(ci.source, 'anilist') "
      "${w.where('ci.added_at', seconds: true, extra: 'ci.media_type = ?')}",
      <Object?>[...w.args, mediaType.value],
    );
    final Map<String, int> counts = <String, int>{};
    int titles = 0;
    for (final Map<String, dynamic> row in rows) {
      final List<String> tags = decodeJsonStringList(row['tags']);
      if (tags.isEmpty) continue;
      titles++;
      for (final String tag in tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final List<(String, int)> sorted = counts.entries
        .map((MapEntry<String, int> e) => (e.key, e.value))
        .toList()
      ..sort(((String, int) a, (String, int) b) => b.$2.compareTo(a.$2));
    return (titles: titles, tags: sorted.take(limit).toList());
  }

  /// Status counts per source format for [mediaType] (TV/OVA/Movie for
  /// anime, manga/novel/one-shot for manga). Keys are raw source codes.
  Future<Map<String, Map<ItemStatus, int>>> getSourceFormatStatusCounts(
    MediaType mediaType, {
    int? year,
  }) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final String cacheTable = _formatCacheTable(mediaType);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT c.format AS f, ci.status AS s, COUNT(*) AS n '
      'FROM collection_items ci '
      'JOIN $cacheTable c ON c.id = ci.external_id '
      "AND c.source = COALESCE(ci.source, 'anilist') "
      "${w.where('ci.added_at', seconds: true, extra: 'ci.media_type = ? AND c.format IS NOT NULL')} "
      'GROUP BY c.format, ci.status',
      <Object?>[...w.args, mediaType.value],
    );
    final Map<String, Map<ItemStatus, int>> result =
        <String, Map<ItemStatus, int>>{};
    for (final Map<String, dynamic> row in rows) {
      final ItemStatus? status = ItemStatus.tryFromString(row['s'] as String);
      if (status == null) continue;
      final Map<ItemStatus, int> perStatus =
          result.putIfAbsent(row['f'] as String, () => <ItemStatus, int>{});
      perStatus[status] = (perStatus[status] ?? 0) + (row['n'] as int? ?? 0);
    }
    return result;
  }

  /// Top [perFormat] row ids per source format, for the format card covers.
  /// Capped per group in Dart (see [getBestItemByMonth]).
  Future<Map<String, List<int>>> getTopItemsByFormat(
    MediaType mediaType, {
    int? year,
    int perFormat = 3,
  }) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final String cacheTable = _formatCacheTable(mediaType);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT c.format AS f, ci.id AS id FROM collection_items ci '
      'JOIN $cacheTable c ON c.id = ci.external_id '
      "AND c.source = COALESCE(ci.source, 'anilist') "
      "${w.where('ci.added_at', seconds: true, extra: 'ci.media_type = ? AND c.format IS NOT NULL')} "
      'ORDER BY ci.user_rating DESC, ci.added_at DESC',
      <Object?>[...w.args, mediaType.value],
    );
    final Map<String, List<int>> result = <String, List<int>>{};
    for (final Map<String, dynamic> row in rows) {
      final List<int> top =
          result.putIfAbsent(row['f'] as String, () => <int>[]);
      if (top.length < perFormat) top.add(row['id'] as int);
    }
    return result;
  }

  static String _formatCacheTable(MediaType mediaType) => switch (mediaType) {
        MediaType.anime => 'anime_cache',
        MediaType.manga => 'manga_cache',
        _ => throw ArgumentError('No source cache for $mediaType'),
      };

  /// Row ids of every rated item added in [year] — the versus / top / crowd
  /// blocks hydrate exactly these.
  Future<List<int>> getRatedItemIds({int? year}) async {
    final Database db = await _getDatabase();
    final _Window w = _Window.year(year);
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT id FROM collection_items '
      '${w.where('added_at', seconds: true, extra: 'user_rating IS NOT NULL')}',
      w.args,
    );
    return <int>[for (final Map<String, dynamic> row in rows) row['id'] as int];
  }

  /// Items added in the local [year]/[month], as (day, type, count) tuples
  /// for the drill-down week bars.
  Future<List<(int, MediaType, int)>> getMonthAddedByDayType(
    int year,
    int month,
  ) async {
    final Database db = await _getDatabase();
    final int start = DateTime(year, month).millisecondsSinceEpoch ~/ 1000;
    final int end = DateTime(year, month + 1).millisecondsSinceEpoch ~/ 1000;
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      "SELECT CAST(strftime('%d', added_at, 'unixepoch', 'localtime') "
      'AS INTEGER) AS day, media_type, COUNT(*) AS c '
      'FROM collection_items WHERE added_at >= ? AND added_at < ? '
      'GROUP BY day, media_type',
      <Object?>[start, end],
    );
    return <(int, MediaType, int)>[
      for (final Map<String, dynamic> row in rows)
        if (MediaType.tryFromString(row['media_type'] as String) != null)
          (
            row['day'] as int,
            MediaType.tryFromString(row['media_type'] as String)!,
            (row['c'] as int?) ?? 0,
          ),
    ];
  }

  /// Years that have any added items, newest first.
  Future<List<int>> getAvailableYears() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      "SELECT DISTINCT strftime('%Y', added_at, 'unixepoch', 'localtime') AS y "
      'FROM collection_items ORDER BY y DESC',
    );
    return <int>[
      for (final Map<String, dynamic> row in rows)
        if (row['y'] != null) int.parse(row['y'] as String),
    ];
  }
}

/// Optional period bounds for one dated column. [where] renders a WHERE
/// clause (with an optional extra condition) and [args] carries the bounds.
class _Window {
  // Local-time bounds so the year window matches the localtime bucketing.
  _Window.year(int? year)
      : startSec = year == null
            ? null
            : DateTime(year).millisecondsSinceEpoch ~/ 1000,
        endSec = year == null
            ? null
            : DateTime(year + 1).millisecondsSinceEpoch ~/ 1000;

  final int? startSec;
  final int? endSec;

  /// Bind values for the last [where] call; a fresh list per call, so a query
  /// already handed to sqflite never sees a later mutation.
  List<Object?> args = const <Object?>[];

  /// Builds `WHERE …` over [column]; [seconds] selects the unit the column is
  /// stored in. Call once per query — it also fills [args].
  String where(String column, {required bool seconds, String? extra}) {
    final List<Object?> next = <Object?>[];
    final List<String> parts = <String>[];
    if (startSec != null && endSec != null) {
      final int mult = seconds ? 1 : 1000;
      parts.add('$column >= ? AND $column < ?');
      next
        ..add(startSec! * mult)
        ..add(endSec! * mult);
    }
    args = next;
    if (extra != null) parts.add(extra);
    if (parts.isEmpty) return '';
    return 'WHERE ${parts.join(' AND ')}';
  }
}
