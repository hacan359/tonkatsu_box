import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_game.dart';

/// Провайдер для репозитория коллекций.
final Provider<CollectionRepository> collectionRepositoryProvider =
    Provider<CollectionRepository>((Ref ref) {
  return CollectionRepository(
    db: ref.watch(databaseServiceProvider),
  );
});

/// Статистика коллекции.
class CollectionStats {
  /// Создаёт экземпляр [CollectionStats].
  const CollectionStats({
    required this.total,
    required this.completed,
    required this.playing,
    required this.notStarted,
    required this.dropped,
    required this.planned,
  });

  /// Общее количество игр.
  final int total;

  /// Количество пройденных игр.
  final int completed;

  /// Количество игр в процессе.
  final int playing;

  /// Количество не начатых игр.
  final int notStarted;

  /// Количество брошенных игр.
  final int dropped;

  /// Количество запланированных игр.
  final int planned;

  /// Возвращает процент прохождения (0-100).
  double get completionPercent {
    if (total == 0) return 0;
    return (completed / total) * 100;
  }

  /// Возвращает отформатированный процент.
  String get completionPercentFormatted =>
      '${completionPercent.toStringAsFixed(0)}%';

  /// Пустая статистика.
  static const CollectionStats empty = CollectionStats(
    total: 0,
    completed: 0,
    playing: 0,
    notStarted: 0,
    dropped: 0,
    planned: 0,
  );
}

/// Репозиторий для работы с коллекциями.
///
/// Управляет CRUD операциями для коллекций и игр в них.
class CollectionRepository {
  /// Создаёт экземпляр [CollectionRepository].
  CollectionRepository({required DatabaseService db}) : _db = db;

  final DatabaseService _db;

  // ==================== Collections ====================

  /// Возвращает все коллекции.
  Future<List<Collection>> getAll() async {
    return _db.getAllCollections();
  }

  /// Возвращает коллекции по типу.
  Future<List<Collection>> getByType(CollectionType type) async {
    return _db.getCollectionsByType(type);
  }

  /// Возвращает коллекцию по ID.
  Future<Collection?> getById(int id) async {
    return _db.getCollectionById(id);
  }

  /// Создаёт новую коллекцию.
  Future<Collection> create({
    required String name,
    required String author,
    CollectionType type = CollectionType.own,
  }) async {
    return _db.createCollection(
      name: name,
      author: author,
      type: type,
    );
  }

  /// Обновляет название коллекции.
  Future<void> updateName(int id, String name) async {
    await _db.updateCollection(id, name: name);
  }

  /// Удаляет коллекцию.
  Future<void> delete(int id) async {
    await _db.deleteCollection(id);
  }

  /// Возвращает количество коллекций.
  Future<int> getCount() async {
    return _db.getCollectionCount();
  }

  // ==================== Collection Games ====================

  /// Возвращает все игры в коллекции.
  Future<List<CollectionGame>> getGames(int collectionId) async {
    return _db.getCollectionGames(collectionId);
  }

  /// Возвращает игры в коллекции с подгруженными данными.
  Future<List<CollectionGame>> getGamesWithData(int collectionId) async {
    return _db.getCollectionGamesWithData(collectionId);
  }

  /// Добавляет игру в коллекцию.
  ///
  /// Возвращает ID записи или null при дубликате.
  Future<int?> addGame({
    required int collectionId,
    required int igdbId,
    required int platformId,
    String? authorComment,
  }) async {
    return _db.addGameToCollection(
      collectionId: collectionId,
      igdbId: igdbId,
      platformId: platformId,
      authorComment: authorComment,
    );
  }

  /// Удаляет игру из коллекции.
  Future<void> removeGame(int id) async {
    await _db.removeGameFromCollection(id);
  }

  /// Обновляет статус игры.
  Future<void> updateGameStatus(int id, GameStatus status) async {
    await _db.updateGameStatus(id, status);
  }

  /// Обновляет комментарий автора.
  Future<void> updateAuthorComment(int id, String? comment) async {
    await _db.updateAuthorComment(id, comment);
  }

  /// Обновляет личный комментарий.
  Future<void> updateUserComment(int id, String? comment) async {
    await _db.updateUserComment(id, comment);
  }

  // ==================== Stats ====================

  /// Возвращает статистику коллекции.
  Future<CollectionStats> getStats(int collectionId) async {
    final Map<String, int> raw = await _db.getCollectionStats(collectionId);
    return CollectionStats(
      total: raw['total'] ?? 0,
      completed: raw['completed'] ?? 0,
      playing: raw['playing'] ?? 0,
      notStarted: raw['notStarted'] ?? 0,
      dropped: raw['dropped'] ?? 0,
      planned: raw['planned'] ?? 0,
    );
  }

  // ==================== Fork ====================

  /// Создаёт форк коллекции.
  ///
  /// Копирует все игры и сохраняет оригинальный snapshot.
  Future<Collection> fork(int collectionId, String newAuthor) async {
    final Collection? original = await getById(collectionId);
    if (original == null) {
      throw ArgumentError('Collection not found: $collectionId');
    }

    final List<CollectionGame> games = await getGames(collectionId);

    // Сериализуем оригинальное состояние
    final String snapshot = jsonEncode(<String, dynamic>{
      'name': original.name,
      'author': original.author,
      'games': games
          .map((CollectionGame g) => <String, dynamic>{
                'igdb_id': g.igdbId,
                'platform_id': g.platformId,
                'author_comment': g.authorComment,
              })
          .toList(),
    });

    // Создаём форк
    final Collection fork = await _db.createCollection(
      name: '${original.name} (copy)',
      author: newAuthor,
      type: CollectionType.fork,
      originalSnapshot: snapshot,
      forkedFromAuthor: original.author,
      forkedFromName: original.name,
    );

    // Копируем игры
    for (final CollectionGame game in games) {
      await addGame(
        collectionId: fork.id,
        igdbId: game.igdbId,
        platformId: game.platformId,
        authorComment: game.authorComment,
      );
    }

    return fork;
  }

  /// Откатывает форк к оригинальному состоянию.
  Future<void> revertToOriginal(int collectionId) async {
    final Collection? collection = await getById(collectionId);
    if (collection == null) {
      throw ArgumentError('Collection not found: $collectionId');
    }
    if (collection.originalSnapshot == null) {
      throw StateError('Collection has no original snapshot');
    }

    final Map<String, dynamic> snapshot =
        jsonDecode(collection.originalSnapshot!) as Map<String, dynamic>;

    // Очищаем текущие игры
    await _db.clearCollectionGames(collectionId);

    // Восстанавливаем из snapshot
    final List<dynamic> gamesData = snapshot['games'] as List<dynamic>;
    for (final dynamic game in gamesData) {
      final Map<String, dynamic> gameMap = game as Map<String, dynamic>;
      await addGame(
        collectionId: collectionId,
        igdbId: gameMap['igdb_id'] as int,
        platformId: gameMap['platform_id'] as int,
        authorComment: gameMap['author_comment'] as String?,
      );
    }
  }
}
