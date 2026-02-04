import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../shared/models/game.dart';
import '../../shared/models/platform.dart';

/// Провайдер для доступа к сервису базы данных.
final Provider<DatabaseService> databaseServiceProvider =
    Provider<DatabaseService>((Ref ref) {
  return DatabaseService();
});

/// Сервис для работы с SQLite базой данных.
///
/// Управляет инициализацией базы данных и CRUD операциями для платформ.
class DatabaseService {
  Database? _database;

  /// Возвращает экземпляр базы данных, инициализируя при необходимости.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbDir = p.join(appDir.path, 'xerabora');
    final String dbPath = p.join(dbDir, 'xerabora.db');

    // Создаём директорию, если не существует
    final Directory dir = Directory(dbDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    return databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createPlatformsTable(db);
    await _createGamesTable(db);
  }

  Future<void> _createPlatformsTable(Database db) async {
    await db.execute('''
      CREATE TABLE platforms (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        abbreviation TEXT,
        synced_at INTEGER
      )
    ''');
  }

  Future<void> _createGamesTable(Database db) async {
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        summary TEXT,
        cover_url TEXT,
        release_date INTEGER,
        rating REAL,
        rating_count INTEGER,
        genres TEXT,
        platform_ids TEXT,
        cached_at INTEGER
      )
    ''');

    // Индекс для поиска по имени
    await db.execute('''
      CREATE INDEX idx_games_name ON games(name)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createGamesTable(db);
    }
  }

  // ==================== Platforms ====================

  /// Возвращает все платформы из базы данных.
  Future<List<Platform>> getAllPlatforms() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'platforms',
      orderBy: 'name ASC',
    );
    return rows.map(Platform.fromDb).toList();
  }

  /// Возвращает платформу по ID или null, если не найдена.
  Future<Platform?> getPlatformById(int id) async {
    final Database db = await database;
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
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM platforms',
    );
    return result.first['count'] as int;
  }

  /// Сохраняет или обновляет платформу в базе данных.
  Future<void> upsertPlatform(Platform platform) async {
    final Database db = await database;
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
    final Database db = await database;
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

  /// Удаляет все платформы из базы данных.
  Future<void> clearPlatforms() async {
    final Database db = await database;
    await db.delete('platforms');
  }

  // ==================== Games ====================

  /// Возвращает игру по ID или null, если не найдена.
  Future<Game?> getGameById(int id) async {
    final Database db = await database;
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

    final Database db = await database;
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

    final Database db = await database;
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
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM games',
    );
    return result.first['count'] as int;
  }

  /// Сохраняет или обновляет игру в базе данных.
  Future<void> upsertGame(Game game) async {
    final Database db = await database;
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

    final Database db = await database;
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
    final Database db = await database;
    await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет все игры из кеша.
  Future<void> clearGames() async {
    final Database db = await database;
    await db.delete('games');
  }

  /// Удаляет устаревшие игры из кеша.
  ///
  /// [maxAgeSeconds] — максимальный возраст записи в секундах.
  Future<int> clearStaleGames({int maxAgeSeconds = 86400 * 30}) async {
    final Database db = await database;
    final int threshold =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - maxAgeSeconds;
    return db.delete(
      'games',
      where: 'cached_at < ?',
      whereArgs: <Object?>[threshold],
    );
  }

  /// Закрывает соединение с базой данных.
  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
