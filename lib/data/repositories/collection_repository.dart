import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/data_source.dart';
import '../../shared/models/media_type.dart';

final Provider<CollectionRepository> collectionRepositoryProvider =
    Provider<CollectionRepository>((Ref ref) {
  return CollectionRepository(
    db: ref.watch(databaseServiceProvider),
  );
});

class CollectionStats {
  const CollectionStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.notStarted,
    required this.dropped,
    required this.planned,
    this.replaying = 0,
    this.gameCount = 0,
    this.movieCount = 0,
    this.tvShowCount = 0,
    this.animationCount = 0,
    this.visualNovelCount = 0,
    this.mangaCount = 0,
    this.animeCount = 0,
    this.bookCount = 0,
    this.customCount = 0,
  });

  final int total;
  final int completed;
  final int inProgress;
  final int notStarted;
  final int dropped;
  final int planned;
  final int replaying;
  final int gameCount;
  final int movieCount;
  final int tvShowCount;
  final int animationCount;
  final int visualNovelCount;
  final int mangaCount;
  final int animeCount;
  final int bookCount;
  final int customCount;

  double get completionPercent {
    if (total == 0) return 0;
    return (completed / total) * 100;
  }

  String get completionPercentFormatted =>
      '${completionPercent.toStringAsFixed(0)}%';

  static const CollectionStats empty = CollectionStats(
    total: 0,
    completed: 0,
    inProgress: 0,
    notStarted: 0,
    dropped: 0,
    planned: 0,
  );
}

/// Thin orchestrator over [DatabaseService] for collections and their items;
/// a `null` collectionId everywhere means "uncategorized".
class CollectionRepository {
  CollectionRepository({required DatabaseService db}) : _db = db;

  final DatabaseService _db;

  Future<List<Collection>> getAll() async {
    return _db.getAllCollections();
  }

  Future<List<Collection>> getByType(CollectionType type) async {
    return _db.getCollectionsByType(type);
  }

  Future<Collection?> getById(int id) async {
    return _db.getCollectionById(id);
  }

  Future<Collection> create({
    required String name,
    required String author,
    CollectionType type = CollectionType.own,
    DateTime? createdAt,
  }) async {
    return _db.createCollection(
      name: name,
      author: author,
      type: type,
      createdAt: createdAt,
    );
  }

  Future<void> updateName(int id, String name) async {
    await _db.updateCollection(id, name: name);
  }

  Future<void> updatePersonalization(
    int id, {
    String? name,
    String? heroImagePath,
    String? description,
    bool clearHeroImage = false,
    bool clearDescription = false,
  }) async {
    await _db.updateCollection(
      id,
      name: name,
      heroImagePath: heroImagePath,
      description: description,
      clearHeroImage: clearHeroImage,
      clearDescription: clearDescription,
    );
  }

  Future<void> delete(int id) async {
    await _db.deleteCollection(id);
  }

  Future<int> getCount() async {
    return _db.getCollectionCount();
  }

  Future<List<CollectionItem>> getItems(
    int? collectionId, {
    MediaType? mediaType,
  }) async {
    return _db.getCollectionItems(collectionId, mediaType: mediaType);
  }

  Future<List<CollectionItem>> getItemsWithData(
    int? collectionId, {
    MediaType? mediaType,
  }) async {
    return _db.getCollectionItemsWithData(collectionId, mediaType: mediaType);
  }

  Future<List<CollectionItem>> getAllItemsWithData({
    MediaType? mediaType,
  }) async {
    return _db.getAllCollectionItemsWithData(mediaType: mediaType);
  }

  Future<CollectionItem?> findItem({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
  }) async {
    return _db.findCollectionItem(
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      source: source,
    );
  }

  Future<int?> addItem({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
    String? authorComment,
    ItemStatus status = ItemStatus.notStarted,
    DateTime? addedAt,
  }) async {
    return _db.addItemToCollection(
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      source: source,
      authorComment: authorComment,
      status: status,
      addedAt: addedAt,
    );
  }

  /// Bulk-inserts items in one transaction (used by imports); returns rows
  /// actually inserted — unique-constraint collisions are ignored.
  Future<int> addItemsBatch(
    int? collectionId,
    List<Map<String, dynamic>> rows,
  ) {
    return _db.collectionDao.addItemsBatch(collectionId, rows);
  }

  /// Same bulk insert as [addItemsBatch], but returns the new row id for
  /// each input row (aligned with [rows], `null` for ignored duplicates).
  Future<List<int?>> addItemsBatchReturningIds(
    int? collectionId,
    List<Map<String, dynamic>> rows,
  ) {
    return _db.collectionDao.addItemsBatchReturningIds(collectionId, rows);
  }

  /// Batch-updates selected columns of existing items in one transaction.
  /// Delegates to `CollectionDao`.
  Future<void> updateItemFieldsBatch(
    List<(int id, Map<String, dynamic> fields)> updates,
  ) {
    return _db.collectionDao.updateItemFieldsBatch(updates);
  }

  /// True on success, false when the target already holds the same
  /// (mediaType, externalId, platformId) — callers fall back to clone/warn.
  Future<bool> moveItemToCollection(int itemId, int? targetCollectionId) async {
    return _db.updateItemCollectionId(itemId, targetCollectionId);
  }

  /// Deep-copies an item into another collection. Returns the new id, or
  /// `null` if the target already holds the same logical item.
  Future<int?> cloneItemToCollection(
    int itemId,
    int targetCollectionId,
  ) async {
    return _db.cloneItemToCollection(itemId, targetCollectionId);
  }

  Future<void> removeItem(int id) async {
    await _db.removeItemFromCollection(id);
  }

  Future<void> updateItemStatus(
    int id,
    ItemStatus status, {
    required MediaType mediaType,
  }) async {
    await _db.updateItemStatus(id, status, mediaType: mediaType);
  }

  Future<void> updateItemRewatchCount(int id, int? count) async {
    await _db.updateItemRewatchCount(id, count);
  }

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

  Future<void> updateItemAuthorComment(int id, String? comment) async {
    await _db.updateItemAuthorComment(id, comment);
  }

  Future<void> updateItemUserComment(int id, String? comment) async {
    await _db.updateItemUserComment(id, comment);
  }

  Future<void> updateItemUserRating(int id, double? rating) async {
    await _db.updateItemUserRating(id, rating);
  }

  Future<void> setItemOverrideName(int id, String? name) async {
    await _db.setItemOverrideName(id, name);
  }

  Future<void> updateItemTimeSpent(int id, int totalMinutes) async {
    await _db.updateItemTimeSpent(id, totalMinutes);
  }

  Future<void> setItemFavorite(int id, {required bool isFavorite}) async {
    await _db.setItemFavorite(id, isFavorite: isFavorite);
  }

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
      replaying: raw['replaying'] ?? 0,
      gameCount: raw['gameCount'] ?? 0,
      movieCount: raw['movieCount'] ?? 0,
      tvShowCount: raw['tvShowCount'] ?? 0,
      animationCount: raw['animationCount'] ?? 0,
      visualNovelCount: raw['visualNovelCount'] ?? 0,
      mangaCount: raw['mangaCount'] ?? 0,
      animeCount: raw['animeCount'] ?? 0,
      bookCount: raw['bookCount'] ?? 0,
      customCount: raw['customCount'] ?? 0,
    );
  }

  Future<int> getUncategorizedCount() async {
    return _db.getUncategorizedItemCount();
  }
}
