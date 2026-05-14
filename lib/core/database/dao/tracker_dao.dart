// DAO для работы с таблицами трекеров.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/tracker_achievement.dart';
import '../../../shared/models/tracker_game_data.dart';
import '../../../shared/models/tracker_profile.dart';

/// DAO для `tracker_profiles`, `tracker_game_data`, `tracker_achievements`.
class TrackerDao {
  /// Создаёт DAO с функцией получения базы данных.
  const TrackerDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ==================== Profiles ====================

  /// Возвращает профиль трекера по типу.
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

  /// Возвращает все подключённые профили.
  Future<List<TrackerProfile>> getAllProfiles() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_profiles',
      orderBy: 'created_at DESC',
    );
    return rows.map(TrackerProfile.fromDb).toList();
  }

  /// Создаёт или обновляет профиль трекера (upsert по tracker_type).
  Future<TrackerProfile> upsertProfile(TrackerProfile profile) async {
    final Database db = await _getDatabase();
    final int id = await db.insert(
      'tracker_profiles',
      profile.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return profile.copyWith(id: id);
  }

  /// Удаляет профиль трекера и все связанные данные.
  Future<void> deleteProfile(TrackerType type) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      // Удаляем достижения по всем играм этого трекера.
      await txn.delete(
        'tracker_achievements',
        where: 'tracker_type = ?',
        whereArgs: <Object?>[type.value],
      );
      // Удаляем game data.
      await txn.delete(
        'tracker_game_data',
        where: 'tracker_type = ?',
        whereArgs: <Object?>[type.value],
      );
      // Удаляем профиль.
      await txn.delete(
        'tracker_profiles',
        where: 'tracker_type = ?',
        whereArgs: <Object?>[type.value],
      );
    });
  }

  // ==================== Game Data ====================

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

  /// Возвращает все tracker data для типа трекера.
  Future<List<TrackerGameData>> getAllGameData(TrackerType type) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_game_data',
      where: 'tracker_type = ?',
      whereArgs: <Object?>[type.value],
    );
    return rows.map(TrackerGameData.fromDb).toList();
  }

  /// Возвращает tracker data для нескольких игр (batch query).
  Future<List<TrackerGameData>> getGameDataForGameIds(
    List<int> gameIds,
  ) async {
    if (gameIds.isEmpty) return <TrackerGameData>[];
    final Database db = await _getDatabase();
    final String placeholders =
        List<String>.filled(gameIds.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT * FROM tracker_game_data WHERE game_id IN ($placeholders)',
      gameIds.map((int id) => id as Object).toList(),
    );
    return rows.map(TrackerGameData.fromDb).toList();
  }

  /// Возвращает все tracker data для игры (от всех трекеров).
  Future<List<TrackerGameData>> getGameDataForGame(int gameId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracker_game_data',
      where: 'game_id = ?',
      whereArgs: <Object?>[gameId],
    );
    return rows.map(TrackerGameData.fromDb).toList();
  }

  /// Создаёт или обновляет game data (upsert по UNIQUE index tracker_type+game_id).
  Future<void> upsertGameData(TrackerGameData data) async {
    final Database db = await _getDatabase();
    await db.insert(
      'tracker_game_data',
      data.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch upsert game data в одной транзакции.
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

  // ==================== Achievements ====================

  /// Возвращает достижения для игры.
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

  /// Проверяет есть ли закэшированные достижения для игры.
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

  /// Заменяет все достижения для игры (delete + insert в транзакции).
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
