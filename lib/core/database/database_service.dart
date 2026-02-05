import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../shared/models/collection.dart';
import '../../shared/models/collection_game.dart';
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
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (Database db) async {
          // Включаем foreign keys
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createPlatformsTable(db);
    await _createGamesTable(db);
    await _createCollectionsTable(db);
    await _createCollectionGamesTable(db);
  }

  Future<void> _createPlatformsTable(Database db) async {
    await db.execute('''
      CREATE TABLE platforms (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        abbreviation TEXT,
        logo_image_id TEXT,
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

  Future<void> _createCollectionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        author TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'own',
        created_at INTEGER NOT NULL,
        original_snapshot TEXT,
        forked_from_author TEXT,
        forked_from_name TEXT
      )
    ''');
  }

  Future<void> _createCollectionGamesTable(Database db) async {
    await db.execute('''
      CREATE TABLE collection_games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        igdb_id INTEGER NOT NULL,
        platform_id INTEGER NOT NULL,
        author_comment TEXT,
        user_comment TEXT,
        status TEXT DEFAULT 'not_started',
        added_at INTEGER NOT NULL,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
        UNIQUE(collection_id, igdb_id, platform_id)
      )
    ''');

    // Индексы для быстрого поиска
    await db.execute('''
      CREATE INDEX idx_collection_games_collection
      ON collection_games(collection_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_collection_games_igdb
      ON collection_games(igdb_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createGamesTable(db);
    }
    if (oldVersion < 3) {
      await _createCollectionsTable(db);
      await _createCollectionGamesTable(db);
    }
    if (oldVersion < 4) {
      // Добавляем колонку logo_image_id для хранения логотипов платформ
      await db.execute('ALTER TABLE platforms ADD COLUMN logo_image_id TEXT');
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

  // ==================== Collections ====================

  /// Возвращает все коллекции.
  Future<List<Collection>> getAllCollections() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      orderBy: 'created_at DESC',
    );
    return rows.map(Collection.fromDb).toList();
  }

  /// Возвращает коллекции по типу.
  Future<List<Collection>> getCollectionsByType(CollectionType type) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      where: 'type = ?',
      whereArgs: <Object?>[type.value],
      orderBy: 'created_at DESC',
    );
    return rows.map(Collection.fromDb).toList();
  }

  /// Возвращает коллекцию по ID или null, если не найдена.
  Future<Collection?> getCollectionById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Collection.fromDb(rows.first);
  }

  /// Создаёт новую коллекцию и возвращает её с присвоенным ID.
  Future<Collection> createCollection({
    required String name,
    required String author,
    CollectionType type = CollectionType.own,
    String? originalSnapshot,
    String? forkedFromAuthor,
    String? forkedFromName,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final int id = await db.insert(
      'collections',
      <String, dynamic>{
        'name': name,
        'author': author,
        'type': type.value,
        'created_at': now,
        'original_snapshot': originalSnapshot,
        'forked_from_author': forkedFromAuthor,
        'forked_from_name': forkedFromName,
      },
    );

    return Collection(
      id: id,
      name: name,
      author: author,
      type: type,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      originalSnapshot: originalSnapshot,
      forkedFromAuthor: forkedFromAuthor,
      forkedFromName: forkedFromName,
    );
  }

  /// Обновляет коллекцию.
  Future<void> updateCollection(int id, {String? name}) async {
    if (name == null) return;

    final Database db = await database;
    await db.update(
      'collections',
      <String, dynamic>{'name': name},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет коллекцию и все связанные игры (каскадно).
  Future<void> deleteCollection(int id) async {
    final Database db = await database;
    await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Возвращает количество коллекций.
  Future<int> getCollectionCount() async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM collections',
    );
    return result.first['count'] as int;
  }

  // ==================== Collection Games ====================

  /// Возвращает все игры в коллекции.
  Future<List<CollectionGame>> getCollectionGames(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_games',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
      orderBy: 'added_at DESC',
    );
    return rows.map(CollectionGame.fromDb).toList();
  }

  /// Возвращает игры в коллекции с подгруженными данными.
  Future<List<CollectionGame>> getCollectionGamesWithData(
    int collectionId,
  ) async {
    final List<CollectionGame> collectionGames =
        await getCollectionGames(collectionId);

    if (collectionGames.isEmpty) return collectionGames;

    // Получаем данные игр и платформ
    final List<int> gameIds =
        collectionGames.map((CollectionGame cg) => cg.igdbId).toList();
    final List<int> platformIds =
        collectionGames.map((CollectionGame cg) => cg.platformId).toSet().toList();

    final List<Game> games = await getGamesByIds(gameIds);
    final Map<int, Game> gamesMap = <int, Game>{
      for (final Game g in games) g.id: g,
    };

    // Получаем платформы
    final Database db = await database;
    final String placeholders =
        List<String>.filled(platformIds.length, '?').join(',');
    final List<Map<String, dynamic>> platformRows = await db.query(
      'platforms',
      where: 'id IN ($placeholders)',
      whereArgs: platformIds.cast<Object?>(),
    );
    final Map<int, Platform> platformsMap = <int, Platform>{
      for (final Map<String, dynamic> row in platformRows)
        row['id'] as int: Platform.fromDb(row),
    };

    // Собираем результат с подгруженными данными
    return collectionGames.map((CollectionGame cg) {
      return cg.copyWith(
        game: gamesMap[cg.igdbId],
        platform: platformsMap[cg.platformId],
      );
    }).toList();
  }

  /// Возвращает запись игры в коллекции по ID.
  Future<CollectionGame?> getCollectionGameById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_games',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CollectionGame.fromDb(rows.first);
  }

  /// Добавляет игру в коллекцию.
  ///
  /// Возвращает ID созданной записи или null при конфликте.
  Future<int?> addGameToCollection({
    required int collectionId,
    required int igdbId,
    required int platformId,
    String? authorComment,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      final int id = await db.insert(
        'collection_games',
        <String, dynamic>{
          'collection_id': collectionId,
          'igdb_id': igdbId,
          'platform_id': platformId,
          'author_comment': authorComment,
          'status': GameStatus.notStarted.value,
          'added_at': now,
        },
      );
      return id;
    } on DatabaseException catch (e) {
      // UNIQUE constraint violation — игра уже в коллекции
      if (e.isUniqueConstraintError()) {
        return null;
      }
      rethrow;
    }
  }

  /// Удаляет игру из коллекции.
  Future<void> removeGameFromCollection(int id) async {
    final Database db = await database;
    await db.delete(
      'collection_games',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет статус игры в коллекции.
  Future<void> updateGameStatus(int id, GameStatus status) async {
    final Database db = await database;
    await db.update(
      'collection_games',
      <String, dynamic>{'status': status.value},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет комментарий автора.
  Future<void> updateAuthorComment(int id, String? comment) async {
    final Database db = await database;
    await db.update(
      'collection_games',
      <String, dynamic>{'author_comment': comment},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет личный комментарий пользователя.
  Future<void> updateUserComment(int id, String? comment) async {
    final Database db = await database;
    await db.update(
      'collection_games',
      <String, dynamic>{'user_comment': comment},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Возвращает количество игр в коллекции.
  Future<int> getCollectionGameCount(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM collection_games WHERE collection_id = ?',
      <Object?>[collectionId],
    );
    return result.first['count'] as int;
  }

  /// Возвращает количество пройденных игр в коллекции.
  Future<int> getCompletedGameCount(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''SELECT COUNT(*) as count FROM collection_games
         WHERE collection_id = ? AND status = ?''',
      <Object?>[collectionId, GameStatus.completed.value],
    );
    return result.first['count'] as int;
  }

  /// Возвращает статистику по коллекции.
  Future<Map<String, int>> getCollectionStats(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''SELECT status, COUNT(*) as count FROM collection_games
         WHERE collection_id = ?
         GROUP BY status''',
      <Object?>[collectionId],
    );

    final Map<String, int> stats = <String, int>{
      'total': 0,
      'completed': 0,
      'playing': 0,
      'notStarted': 0,
      'dropped': 0,
      'planned': 0,
    };

    for (final Map<String, dynamic> row in result) {
      final String status = row['status'] as String;
      final int count = row['count'] as int;
      stats['total'] = (stats['total'] ?? 0) + count;

      switch (status) {
        case 'completed':
          stats['completed'] = count;
        case 'playing':
          stats['playing'] = count;
        case 'not_started':
          stats['notStarted'] = count;
        case 'dropped':
          stats['dropped'] = count;
        case 'planned':
          stats['planned'] = count;
      }
    }

    return stats;
  }

  /// Удаляет все игры из коллекции.
  Future<void> clearCollectionGames(int collectionId) async {
    final Database db = await database;
    await db.delete(
      'collection_games',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
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
