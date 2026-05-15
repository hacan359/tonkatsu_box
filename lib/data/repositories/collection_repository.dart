import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
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
    this.gameCount = 0,
    this.movieCount = 0,
    this.tvShowCount = 0,
    this.animationCount = 0,
    this.visualNovelCount = 0,
    this.mangaCount = 0,
    this.animeCount = 0,
    this.customCount = 0,
  });

  final int total;
  final int completed;
  final int inProgress;
  final int notStarted;
  final int dropped;
  final int planned;
  final int gameCount;
  final int movieCount;
  final int tvShowCount;
  final int animationCount;
  final int visualNovelCount;
  final int mangaCount;
  final int animeCount;
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

/// Thin orchestrator over [DatabaseService] for collections and their items.
/// A `null` collectionId everywhere means "uncategorized" — the catch-all
/// bucket for items that aren't in any user collection.
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
  }) async {
    return _db.createCollection(
      name: name,
      author: author,
      type: type,
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
  }) async {
    return _db.findCollectionItem(
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
    );
  }

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

  /// Returns `true` on success, `false` if the target collection already
  /// holds an item with the same `(mediaType, externalId, platformId)` —
  /// callers should fall back to [cloneItemToCollection] or surface a
  /// duplicate warning.
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

  Future<void> updateItemUserRating(int id, int? rating) async {
    await _db.updateItemUserRating(id, rating);
  }

  Future<void> setItemOverrideName(int id, String? name) async {
    await _db.setItemOverrideName(id, name);
  }

  Future<void> updateItemTimeSpent(int id, int totalMinutes) async {
    await _db.updateItemTimeSpent(id, totalMinutes);
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
      gameCount: raw['gameCount'] ?? 0,
      movieCount: raw['movieCount'] ?? 0,
      tvShowCount: raw['tvShowCount'] ?? 0,
      animationCount: raw['animationCount'] ?? 0,
      visualNovelCount: raw['visualNovelCount'] ?? 0,
      mangaCount: raw['mangaCount'] ?? 0,
      animeCount: raw['animeCount'] ?? 0,
      customCount: raw['customCount'] ?? 0,
    );
  }

  Future<int> getUncategorizedCount() async {
    return _db.getUncategorizedItemCount();
  }
}
