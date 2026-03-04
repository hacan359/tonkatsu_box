// DAO для работы с играми, платформами и IGDB-жанрами.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/game.dart';
import '../../../shared/models/platform.dart';

/// DAO для таблиц `games`, `platforms` и `igdb_genres`.
class GameDao {
  /// Создаёт DAO с функцией получения базы данных.
  const GameDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ==================== Platforms ====================

  /// Возвращает все платформы из базы данных.
  Future<List<Platform>> getAllPlatforms() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'platforms',
      orderBy: 'name ASC',
    );
    return rows.map(Platform.fromDb).toList();
  }

  /// Возвращает платформу по ID или null, если не найдена.
  Future<Platform?> getPlatformById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'platforms',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Platform.fromDb(rows.first);
  }

  /// Возвращает количество платформ в базе данных.
  Future<int> getPlatformCount() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM platforms',
    );
    return result.first['count'] as int;
  }

  /// Сохраняет или обновляет платформу в базе данных.
  Future<void> upsertPlatform(Platform platform) async {
    final Database db = await _getDatabase();
    await db.insert(
      'platforms',
      platform.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет список платформ пакетно.
  ///
  /// Использует транзакцию для оптимизации производительности.
  Future<void> upsertPlatforms(List<Platform> platforms) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Platform platform in platforms) {
        batch.insert(
          'platforms',
          platform.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Возвращает платформы по списку ID.
  ///
  /// Возвращает только те платформы, которые есть в базе данных.
  Future<List<Platform>> getPlatformsByIds(List<int> ids) async {
    if (ids.isEmpty) return <Platform>[];
    final Database db = await _getDatabase();
    final String placeholders =
        List<String>.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.query(
      'platforms',
      where: 'id IN ($placeholders)',
      whereArgs: ids.cast<Object?>(),
    );
    return rows.map(Platform.fromDb).toList();
  }

  // ==================== Games ====================

  /// Возвращает игру по ID или null, если не найдена.
  Future<Game?> getGameById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'games',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Game.fromDb(rows.first);
  }

  /// Возвращает несколько игр по списку ID.
  Future<List<Game>> getGamesByIds(List<int> ids) async {
    if (ids.isEmpty) return <Game>[];

    final Database db = await _getDatabase();
    final String placeholders = List<String>.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.query(
      'games',
      where: 'id IN ($placeholders)',
      whereArgs: ids.cast<Object?>(),
    );
    return rows.map(Game.fromDb).toList();
  }

  /// Ищет игры по названию в кеше.
  ///
  /// Возвращает список игр, название которых содержит [query].
  Future<List<Game>> searchGamesInCache(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return <Game>[];

    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'games',
      where: 'name LIKE ?',
      whereArgs: <Object?>['%$query%'],
      orderBy: 'name ASC',
      limit: limit,
    );
    return rows.map(Game.fromDb).toList();
  }

  /// Возвращает количество игр в кеше.
  Future<int> getGameCount() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM games',
    );
    return result.first['count'] as int;
  }

  /// Сохраняет или обновляет игру в базе данных.
  Future<void> upsertGame(Game game) async {
    final Database db = await _getDatabase();
    await db.insert(
      'games',
      game.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет список игр пакетно.
  ///
  /// Использует транзакцию для оптимизации производительности.
  Future<void> upsertGames(List<Game> games) async {
    if (games.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Game game in games) {
        batch.insert(
          'games',
          game.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Удаляет игру по ID.
  Future<void> deleteGame(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет все игры из кеша.
  Future<void> clearGames() async {
    final Database db = await _getDatabase();
    await db.delete('games');
  }

  /// Удаляет устаревшие игры из кеша.
  ///
  /// [maxAgeSeconds] — максимальный возраст записи в секундах.
  Future<int> clearStaleGames({int maxAgeSeconds = 86400 * 30}) async {
    final Database db = await _getDatabase();
    final int threshold =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - maxAgeSeconds;
    return db.delete(
      'games',
      where: 'cached_at < ?',
      whereArgs: <Object?>[threshold],
    );
  }

  // ==================== IGDB Genres ====================

  /// Возвращает все жанры IGDB из кэша.
  Future<List<Map<String, dynamic>>> getIgdbGenres() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'igdb_genres',
      orderBy: 'name ASC',
    );
    return rows;
  }
}
