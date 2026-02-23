import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';

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
    required this.inProgress,
    required this.notStarted,
    required this.dropped,
    required this.planned,
    this.onHold = 0,
    this.gameCount = 0,
    this.movieCount = 0,
    this.tvShowCount = 0,
    this.animationCount = 0,
  });

  /// Общее количество элементов.
  final int total;

  /// Количество завершённых.
  final int completed;

  /// Количество в процессе.
  final int inProgress;

  /// Количество не начатых.
  final int notStarted;

  /// Количество брошенных.
  final int dropped;

  /// Количество запланированных.
  final int planned;

  /// Количество на паузе.
  final int onHold;

  /// Количество игр.
  final int gameCount;

  /// Количество фильмов.
  final int movieCount;

  /// Количество сериалов.
  final int tvShowCount;

  /// Количество анимации.
  final int animationCount;

  /// Возвращает процент завершения (0-100).
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
    inProgress: 0,
    notStarted: 0,
    dropped: 0,
    planned: 0,
  );
}

/// Репозиторий для работы с коллекциями.
///
/// Управляет CRUD операциями для коллекций и элементов в них.
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

  // ==================== Collection Items ====================

  /// Возвращает все элементы коллекции.
  ///
  /// Если [collectionId] == null, возвращает uncategorized элементы.
  Future<List<CollectionItem>> getItems(
    int? collectionId, {
    MediaType? mediaType,
  }) async {
    return _db.getCollectionItems(collectionId, mediaType: mediaType);
  }

  /// Возвращает элементы коллекции с подгруженными данными.
  ///
  /// Если [collectionId] == null, возвращает uncategorized элементы.
  Future<List<CollectionItem>> getItemsWithData(
    int? collectionId, {
    MediaType? mediaType,
  }) async {
    return _db.getCollectionItemsWithData(collectionId, mediaType: mediaType);
  }

  /// Возвращает все элементы из всех коллекций с подгруженными данными.
  Future<List<CollectionItem>> getAllItemsWithData({
    MediaType? mediaType,
  }) async {
    return _db.getAllCollectionItemsWithData(mediaType: mediaType);
  }

  /// Находит элемент коллекции по типу медиа и внешнему ID.
  ///
  /// Возвращает null если элемент не найден.
  Future<CollectionItem?> findItem({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
  }) async {
    return _db.findCollectionItem(
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
    );
  }

  /// Добавляет элемент в коллекцию.
  ///
  /// Если [collectionId] == null, добавляет как uncategorized.
  Future<int?> addItem({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    String? authorComment,
    ItemStatus status = ItemStatus.notStarted,
  }) async {
    return _db.addItemToCollection(
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      authorComment: authorComment,
      status: status,
    );
  }

  /// Перемещает элемент в другую коллекцию.
  ///
  /// Возвращает true при успехе, false если элемент уже есть в целевой
  /// коллекции (дубликат).
  Future<bool> moveItemToCollection(int itemId, int? targetCollectionId) async {
    return _db.updateItemCollectionId(itemId, targetCollectionId);
  }

  /// Удаляет элемент из коллекции.
  Future<void> removeItem(int id) async {
    await _db.removeItemFromCollection(id);
  }

  /// Обновляет статус элемента.
  Future<void> updateItemStatus(
    int id,
    ItemStatus status, {
    required MediaType mediaType,
  }) async {
    await _db.updateItemStatus(id, status, mediaType: mediaType);
  }

  /// Обновляет прогресс просмотра сериала.
  Future<void> updateItemProgress(
    int id, {
    int? currentSeason,
    int? currentEpisode,
  }) async {
    await _db.updateItemProgress(
      id,
      currentSeason: currentSeason,
      currentEpisode: currentEpisode,
    );
  }

  /// Обновляет комментарий автора элемента.
  Future<void> updateItemAuthorComment(int id, String? comment) async {
    await _db.updateItemAuthorComment(id, comment);
  }

  /// Обновляет личный комментарий пользователя элемента.
  Future<void> updateItemUserComment(int id, String? comment) async {
    await _db.updateItemUserComment(id, comment);
  }

  /// Обновляет пользовательский рейтинг элемента (1-10 или null).
  Future<void> updateItemUserRating(int id, int? rating) async {
    await _db.updateItemUserRating(id, rating);
  }

  /// Обновляет даты активности элемента.
  Future<void> updateItemActivityDates(
    int id, {
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
  }) async {
    await _db.updateItemActivityDates(
      id,
      startedAt: startedAt,
      completedAt: completedAt,
      lastActivityAt: lastActivityAt,
    );
  }

  // ==================== Stats ====================

  /// Возвращает статистику коллекции.
  ///
  /// Если [collectionId] == null, возвращает статистику uncategorized.
  Future<CollectionStats> getStats(int? collectionId) async {
    final Map<String, int> raw =
        await _db.getCollectionItemStats(collectionId);
    return CollectionStats(
      total: raw['total'] ?? 0,
      completed: raw['completed'] ?? 0,
      inProgress: raw['inProgress'] ?? 0,
      notStarted: raw['notStarted'] ?? 0,
      dropped: raw['dropped'] ?? 0,
      planned: raw['planned'] ?? 0,
      onHold: raw['onHold'] ?? 0,
      gameCount: raw['gameCount'] ?? 0,
      movieCount: raw['movieCount'] ?? 0,
      tvShowCount: raw['tvShowCount'] ?? 0,
      animationCount: raw['animationCount'] ?? 0,
    );
  }

  /// Возвращает количество uncategorized элементов.
  Future<int> getUncategorizedCount() async {
    return _db.getUncategorizedItemCount();
  }

}
