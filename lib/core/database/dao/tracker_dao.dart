import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/tracker_achievement.dart';
import '../../../shared/models/tracker_game_data.dart';
import '../../../shared/models/tracker_profile.dart';
import '../query_chunk.dart';

/// DAO for `tracker_profiles`, `tracker_game_data`, `tracker_achievements`.
class TrackerDao {
  const TrackerDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<TrackerProfile?> getProfile(TrackerType type) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_profiles',
      where: 'tracker_type = ?',
      whereArgs: <Object?>[type.value],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TrackerProfile.fromDb(rows.first);
  }

  Future<List<TrackerProfile>> getAllProfiles() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_profiles',
      orderBy: 'created_at DESC',
    );
    return rows.map(TrackerProfile.fromDb).toList();
  }

  /// Upsert keyed by tracker_type.
  Future<TrackerProfile> upsertProfile(TrackerProfile profile) async {
    final Database db = await _getDatabase();
    final int id = await db.insert(
      'tracker_profiles',
      profile.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return profile.copyWith(id: id);
  }

  /// Deletes a tracker profile together with all of its data.
  Future<void> deleteProfile(TrackerType type) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'tracker_achievements',
        where: 'tracker_type = ?',
        whereArgs: <Object?>[type.value],
      );
      await txn.delete(
        'tracker_game_data',
        where: 'tracker_type = ?',
        whereArgs: <Object?>[type.value],
      );
      await txn.delete(
        'tracker_profiles',
        where: 'tracker_type = ?',
        whereArgs: <Object?>[type.value],
      );
    });
  }

  /// Returns the tracker row for `(tracker_type, game_id, platform_id)`.
  /// Pass `platformId = null` to look up the legacy platform-agnostic row.
  Future<TrackerGameData?> getGameData(
    TrackerType type,
    int gameId, {
    int? platformId,
  }) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_game_data',
      where: platformId == null
          ? 'tracker_type = ? AND game_id = ? AND platform_id IS NULL'
          : 'tracker_type = ? AND game_id = ? AND platform_id = ?',
      whereArgs: platformId == null
          ? <Object?>[type.value, gameId]
          : <Object?>[type.value, gameId, platformId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TrackerGameData.fromDb(rows.first);
  }

  /// Returns every tracker row tied to `(tracker_type, game_id)` regardless
  /// of platform — useful when the caller wants to aggregate across all
  /// platform variants of the same IGDB game.
  Future<List<TrackerGameData>> getGameDataForAnyPlatform(
    TrackerType type,
    int gameId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_game_data',
      where: 'tracker_type = ? AND game_id = ?',
      whereArgs: <Object?>[type.value, gameId],
    );
    return rows.map(TrackerGameData.fromDb).toList();
  }

  Future<List<TrackerGameData>> getAllGameData(TrackerType type) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_game_data',
      where: 'tracker_type = ?',
      whereArgs: <Object?>[type.value],
    );
    return rows.map(TrackerGameData.fromDb).toList();
  }

  Future<List<TrackerGameData>> getGameDataForGameIds(
    List<int> gameIds,
  ) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(gameIds, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM tracker_game_data WHERE game_id IN ($placeholders)',
        chunk,
      );
      return rows.map(TrackerGameData.fromDb).toList();
    });
  }

  /// Returns tracker data for a game from all trackers.
  Future<List<TrackerGameData>> getGameDataForGame(int gameId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_game_data',
      where: 'game_id = ?',
      whereArgs: <Object?>[gameId],
    );
    return rows.map(TrackerGameData.fromDb).toList();
  }

  /// Upsert keyed by the UNIQUE index on tracker_type + game_id.
  Future<void> upsertGameData(TrackerGameData data) async {
    final Database db = await _getDatabase();
    await db.insert(
      'tracker_game_data',
      data.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertGameDataBatch(List<TrackerGameData> items) async {
    if (items.isEmpty) return;
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final TrackerGameData data in items) {
        batch.insert(
          'tracker_game_data',
          data.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Drops tracker rows + their per-game achievements. When [platformId] is
  /// provided only that platform variant is removed; otherwise every platform
  /// variant for the IGDB game is wiped together.
  Future<void> deleteGameData(
    TrackerType type,
    int gameId, {
    int? platformId,
    bool allPlatforms = false,
  }) async {
    final Database db = await _getDatabase();

    // Locate the tracker_game_id values whose achievements should also go.
    String gameDataWhere;
    List<Object?> gameDataArgs;
    if (allPlatforms) {
      gameDataWhere = 'tracker_type = ? AND game_id = ?';
      gameDataArgs = <Object?>[type.value, gameId];
    } else if (platformId == null) {
      gameDataWhere =
          'tracker_type = ? AND game_id = ? AND platform_id IS NULL';
      gameDataArgs = <Object?>[type.value, gameId];
    } else {
      gameDataWhere =
          'tracker_type = ? AND game_id = ? AND platform_id = ?';
      gameDataArgs = <Object?>[type.value, gameId, platformId];
    }

    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_game_data',
      columns: <String>['tracker_game_id'],
      where: gameDataWhere,
      whereArgs: gameDataArgs,
    );
    final Set<String> trackerGameIds = <String>{
      for (final Map<String, dynamic> r in rows) r['tracker_game_id'] as String,
    };
    // Only drop achievements when no other tracker_game_data row still
    // references them — different platform installs can share an RA id only
    // in theory, but Steam definitely shares AppId across platforms.
    for (final String trackerGameId in trackerGameIds) {
      final List<Map<String, Object?>> countRows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM tracker_game_data '
        'WHERE tracker_type = ? AND tracker_game_id = ? '
        'AND NOT ($gameDataWhere)',
        <Object?>[type.value, trackerGameId, ...gameDataArgs],
      );
      final int remaining = (countRows.first['c'] as int?) ?? 0;
      if (remaining == 0) {
        await db.delete(
          'tracker_achievements',
          where: 'tracker_type = ? AND tracker_game_id = ?',
          whereArgs: <Object?>[type.value, trackerGameId],
        );
      }
    }

    await db.delete(
      'tracker_game_data',
      where: gameDataWhere,
      whereArgs: gameDataArgs,
    );
  }

  Future<List<TrackerAchievement>> getAchievements(
    TrackerType type,
    String trackerGameId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_achievements',
      where: 'tracker_type = ? AND tracker_game_id = ?',
      whereArgs: <Object?>[type.value, trackerGameId],
      orderBy: 'display_order ASC',
    );
    return rows.map(TrackerAchievement.fromDb).toList();
  }

  Future<bool> hasAchievements(
    TrackerType type,
    String trackerGameId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM tracker_achievements '
      'WHERE tracker_type = ? AND tracker_game_id = ?',
      <Object?>[type.value, trackerGameId],
    );
    return (rows.first['cnt'] as int) > 0;
  }

  /// Replaces all achievements for a game (delete + insert in one
  /// transaction).
  Future<void> replaceAchievements(
    TrackerType type,
    String trackerGameId,
    List<TrackerAchievement> achievements,
  ) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'tracker_achievements',
        where: 'tracker_type = ? AND tracker_game_id = ?',
        whereArgs: <Object?>[type.value, trackerGameId],
      );
      final Batch batch = txn.batch();
      for (final TrackerAchievement ach in achievements) {
        batch.insert('tracker_achievements', ach.toDb());
      }
      await batch.commit(noResult: true);
    });
  }
}
