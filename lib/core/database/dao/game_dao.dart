import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/game.dart';
import '../../../shared/models/platform.dart';
import '../query_chunk.dart';

class GameDao {
  const GameDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<List<Platform>> getAllPlatforms() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'platforms',
      orderBy: 'name ASC',
    );
    return rows.map(Platform.fromDb).toList();
  }

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

  Future<int> getPlatformCount() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM platforms',
    );
    return result.first['count'] as int;
  }

  Future<void> upsertPlatform(Platform platform) async {
    final Database db = await _getDatabase();
    await db.insert(
      'platforms',
      platform.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batched in a single transaction for performance.
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

  /// Chunked to stay under SQLite's variable limit for large id lists.
  Future<List<Platform>> getPlatformsByIds(List<int> ids) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(ids, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.query(
        'platforms',
        where: 'id IN ($placeholders)',
        whereArgs: chunk.cast<Object?>(),
      );
      return rows.map(Platform.fromDb).toList();
    });
  }

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

  /// Chunked to stay under SQLite's variable limit for large id lists.
  Future<List<Game>> getGamesByIds(List<int> ids) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(ids, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.query(
        'games',
        where: 'id IN ($placeholders)',
        whereArgs: chunk.cast<Object?>(),
      );
      return rows.map(Game.fromDb).toList();
    });
  }

  /// Substring match on name (case-insensitive LIKE).
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

  Future<int> getGameCount() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM games',
    );
    return result.first['count'] as int;
  }

  Future<void> upsertGame(Game game) async {
    final Database db = await _getDatabase();
    await db.insert(
      'games',
      game.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batched in a single transaction for performance.
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

  Future<void> deleteGame(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> clearGames() async {
    final Database db = await _getDatabase();
    await db.delete('games');
  }

  Future<List<Map<String, dynamic>>> getIgdbGenres() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'igdb_genres',
      orderBy: 'name ASC',
    );
    return rows;
  }
}
