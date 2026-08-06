import 'package:sqflite_common/sqlite_api.dart';

import '../../models/anime.dart';
import '../../models/book.dart';
import '../../models/collected_item_info.dart';
import '../../models/collection.dart';
import '../../models/collection_item.dart';
import '../../models/cover_info.dart';
import '../../models/custom_media.dart';
import '../../models/data_source.dart';
import '../../models/game.dart';
import '../../models/item_status.dart';
import '../../models/item_status_logic.dart';
import '../../models/manga.dart';
import '../../models/media_type.dart';
import '../../models/movie.dart';
import '../../models/platform.dart';
import '../../models/tv_show.dart';
import '../../models/visual_novel.dart';
import '../query_chunk.dart';
import 'anime_dao.dart';
import 'book_dao.dart';
import 'custom_media_dao.dart';
import 'game_dao.dart';
import 'manga_dao.dart';
import 'movie_dao.dart';
import 'tv_show_dao.dart';
import 'visual_novel_dao.dart';

class CollectionDao {
  const CollectionDao(
    this._getDatabase, {
    required GameDao gameDao,
    required MovieDao movieDao,
    required TvShowDao tvShowDao,
    required VisualNovelDao visualNovelDao,
    required AnimeDao animeDao,
    required MangaDao mangaDao,
    required BookDao bookDao,
    required CustomMediaDao customMediaDao,
  })  : _gameDao = gameDao,
        _movieDao = movieDao,
        _tvShowDao = tvShowDao,
        _visualNovelDao = visualNovelDao,
        _animeDao = animeDao,
        _mangaDao = mangaDao,
        _bookDao = bookDao,
        _customMediaDao = customMediaDao;

  final Future<Database> Function() _getDatabase;
  final GameDao _gameDao;
  final MovieDao _movieDao;
  final TvShowDao _tvShowDao;
  final VisualNovelDao _visualNovelDao;
  final AnimeDao _animeDao;
  final MangaDao _mangaDao;
  final BookDao _bookDao;
  final CustomMediaDao _customMediaDao;

  Future<List<Collection>> getAllCollections() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      orderBy: 'created_at DESC',
    );
    return rows.map(Collection.fromDb).toList();
  }

  Future<List<Collection>> getCollectionsByType(CollectionType type) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      where: 'type = ?',
      whereArgs: <Object?>[type.value],
      orderBy: 'created_at DESC',
    );
    return rows.map(Collection.fromDb).toList();
  }

  Future<Collection?> getCollectionById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Collection.fromDb(rows.first);
  }

  Future<Collection?> findCollectionByName(String name) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      where: 'name = ?',
      whereArgs: <Object?>[name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Collection.fromDb(rows.first);
  }

  /// [createdAt] overrides the creation date — backup restore passes the
  /// original one so the collection keeps its history; defaults to now.
  Future<Collection> createCollection({
    required String name,
    required String author,
    CollectionType type = CollectionType.own,
    String? originalSnapshot,
    String? forkedFromAuthor,
    String? forkedFromName,
    DateTime? createdAt,
  }) async {
    final Database db = await _getDatabase();
    final int timestamp =
        (createdAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;

    final int id = await db.insert(
      'collections',
      <String, dynamic>{
        'name': name,
        'author': author,
        'type': type.value,
        'created_at': timestamp,
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
      originalSnapshot: originalSnapshot,
      forkedFromAuthor: forkedFromAuthor,
      forkedFromName: forkedFromName,
    );
  }

  /// Pass `clearHeroImage: true` / `clearDescription: true` to persist NULL —
  /// a plain `null` means "leave untouched".
  Future<void> updateCollection(
    int id, {
    String? name,
    String? heroImagePath,
    String? description,
    bool clearHeroImage = false,
    bool clearDescription = false,
  }) async {
    final Map<String, Object?> values = <String, Object?>{};
    if (name != null) values['name'] = name;
    if (heroImagePath != null) values['hero_image_path'] = heroImagePath;
    if (clearHeroImage) values['hero_image_path'] = null;
    if (description != null) values['description'] = description;
    if (clearDescription) values['description'] = null;
    if (values.isEmpty) return;

    final Database db = await _getDatabase();
    await db.update(
      'collections',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Cascades to collection_items via FK.
  Future<void> deleteCollection(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> getCollectionCount() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM collections',
    );
    return result.first['count'] as int;
  }

  /// [collectionId] == null targets uncategorized items.
  Future<List<CollectionItem>> getCollectionItems(
    int? collectionId, {
    MediaType? mediaType,
  }) async {
    final Database db = await _getDatabase();
    String where;
    final List<Object?> whereArgs = <Object?>[];
    if (collectionId != null) {
      where = 'collection_id = ?';
      whereArgs.add(collectionId);
    } else {
      where = 'collection_id IS NULL';
    }
    if (mediaType != null) {
      where += ' AND media_type = ?';
      whereArgs.add(mediaType.value);
    }
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'sort_order ASC',
    );
    return rows.map(CollectionItem.fromDb).toList();
  }

  Future<List<CollectionItem>> getCollectionItemsWithData(
    int? collectionId, {
    MediaType? mediaType,
  }) async {
    final List<CollectionItem> items = await getCollectionItems(
      collectionId,
      mediaType: mediaType,
    );
    if (items.isEmpty) return items;
    return _loadJoinedData(items);
  }

  Future<List<CollectionItem>> getAllCollectionItems({
    MediaType? mediaType,
  }) async {
    final Database db = await _getDatabase();
    String? where;
    List<Object?>? whereArgs;
    if (mediaType != null) {
      where = 'media_type = ?';
      whereArgs = <Object?>[mediaType.value];
    }
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'added_at DESC',
    );
    return rows.map(CollectionItem.fromDb).toList();
  }

  Future<List<CollectionItem>> getAllCollectionItemsWithData({
    MediaType? mediaType,
  }) async {
    final List<CollectionItem> items = await getAllCollectionItems(
      mediaType: mediaType,
    );
    if (items.isEmpty) return items;
    return _loadJoinedData(items);
  }

  /// Hydrated items for the given row ids (order not preserved, missing ids
  /// skipped) — aggregate screens load only the covers they actually show.
  Future<List<CollectionItem>> getItemsWithDataByRowIds(List<int> ids) async {
    if (ids.isEmpty) return const <CollectionItem>[];
    final Database db = await _getDatabase();
    final List<CollectionItem> items =
        await queryByIdsInChunks(ids, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.query(
        'collection_items',
        where: 'id IN ($placeholders)',
        whereArgs: chunk.cast<Object?>(),
      );
      return rows.map(CollectionItem.fromDb).toList();
    });
    if (items.isEmpty) return items;
    return _loadJoinedData(items);
  }

  Future<CollectionItem?> getCollectionItemById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CollectionItem.fromDb(rows.first);
  }

  Future<CollectionItem?> findCollectionItem({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
  }) async {
    final Database db = await _getDatabase();
    final StringBuffer where = StringBuffer();
    final List<Object?> whereArgs = <Object?>[];

    if (collectionId != null) {
      where.write('collection_id = ? AND media_type = ? AND external_id = ?');
      whereArgs.addAll(
        <Object?>[collectionId, mediaType.value, externalId],
      );
    } else {
      // Search across all collections (no collection_id filter).
      where.write('media_type = ? AND external_id = ?');
      whereArgs.addAll(<Object?>[mediaType.value, externalId]);
    }

    // For games, disambiguate by platform — unique index includes platform_id.
    if (platformId != null) {
      where.write(' AND platform_id = ?');
      whereArgs.add(platformId);
    }

    if (source != null) {
      where.write(' AND COALESCE(source, ?) = ?');
      whereArgs
        ..add(mediaType.defaultSource.name)
        ..add(source.name);
    }

    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: where.toString(),
      whereArgs: whereArgs,
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return CollectionItem.fromDb(rows.first);
  }

  /// Like [findCollectionItem] but with the joined media model hydrated, so
  /// callers get a resolved title / poster instead of an "Unknown" fallback.
  Future<CollectionItem?> findCollectionItemWithData({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
  }) async {
    final CollectionItem? item = await findCollectionItem(
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      source: source,
    );
    if (item == null) return null;
    return (await _loadJoinedData(<CollectionItem>[item])).first;
  }

  Future<List<CollectionItem>> findAllCollectionItems({
    required MediaType mediaType,
    required int externalId,
    DataSource? source,
  }) async {
    final Database db = await _getDatabase();
    final StringBuffer where =
        StringBuffer('media_type = ? AND external_id = ?');
    final List<Object?> whereArgs = <Object?>[mediaType.value, externalId];
    if (source != null) {
      where.write(' AND COALESCE(source, ?) = ?');
      whereArgs
        ..add(mediaType.defaultSource.name)
        ..add(source.name);
    }
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: where.toString(),
      whereArgs: whereArgs,
    );
    return rows.map(CollectionItem.fromDb).toList();
  }

  /// Resolves a content-based card link to hydrated items. Prefers the hinted
  /// [collectionId] when it matches, else returns hits across all collections.
  Future<List<CollectionItem>> resolveCardLink({
    required MediaType mediaType,
    required int externalId,
    DataSource? source,
    int? platformId,
    int? collectionId,
  }) async {
    final Database db = await _getDatabase();
    final StringBuffer where =
        StringBuffer('media_type = ? AND external_id = ?');
    final List<Object?> whereArgs = <Object?>[mediaType.value, externalId];

    if (mediaType.isMultiSource && source != null) {
      where.write(' AND COALESCE(source, ?) = ?');
      whereArgs.add(mediaType.defaultSource.name);
      whereArgs.add(source.name);
    }
    if (platformId != null) {
      where.write(' AND platform_id = ?');
      whereArgs.add(platformId);
    }

    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: where.toString(),
      whereArgs: whereArgs,
    );
    if (rows.isEmpty) return <CollectionItem>[];

    List<CollectionItem> items = rows.map(CollectionItem.fromDb).toList();
    if (collectionId != null) {
      final List<CollectionItem> inHinted = items
          .where((CollectionItem i) => i.collectionId == collectionId)
          .toList();
      if (inHinted.isNotEmpty) items = inHinted;
    }
    return _loadJoinedData(items);
  }

  /// [collectionId] null adds as uncategorized; returns null on UNIQUE
  /// conflict. [addedAt] overrides the added date (backup restore keeps it).
  Future<int?> addItemToCollection({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
    String? authorComment,
    ItemStatus status = ItemStatus.notStarted,
    DateTime? addedAt,
  }) async {
    final Database db = await _getDatabase();
    final int timestamp =
        (addedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;

    try {
      final int sortOrder = await getNextSortOrder(collectionId);
      final int id = await db.insert(
        'collection_items',
        <String, dynamic>{
          'collection_id': collectionId,
          'media_type': mediaType.value,
          'external_id': externalId,
          'platform_id': platformId,
          'source': source?.name,
          'status': status.value,
          'author_comment': authorComment,
          'added_at': timestamp,
          'sort_order': sortOrder,
        },
      );
      return id;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return null;
      }
      rethrow;
    }
  }

  Future<int> getNextSortOrder(int? collectionId) async {
    final Database db = await _getDatabase();
    final String where = collectionId != null
        ? 'WHERE collection_id = ?'
        : 'WHERE collection_id IS NULL';
    final List<Object?> args =
        collectionId != null ? <Object?>[collectionId] : <Object?>[];
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT MAX(sort_order) AS max_sort FROM collection_items $where',
      args,
    );
    final int maxSort = (result.first['max_sort'] as int?) ?? -1;
    return maxSort + 1;
  }

  /// Bulk insert in one transaction: fills collection_id/sort_order, defaults
  /// added_at when the row has none, skips UNIQUE conflicts; returns count.
  Future<int> addItemsBatch(
    int? collectionId,
    List<Map<String, dynamic>> rows,
  ) async {
    final List<int?> ids = await addItemsBatchReturningIds(collectionId, rows);
    return ids.whereType<int>().length;
  }

  /// Same bulk insert as [addItemsBatch], but returns new row ids aligned
  /// with [rows]; `null` marks rows skipped by the unique constraint.
  Future<List<int?>> addItemsBatchReturningIds(
    int? collectionId,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return const <int?>[];
    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int sortOrder = await getNextSortOrder(collectionId);

    final List<Object?> results =
        await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Map<String, dynamic> row in rows) {
        batch.insert(
          'collection_items',
          <String, dynamic>{
            ...row,
            'collection_id': collectionId,
            'added_at': (row['added_at'] as int?) ?? now,
            'sort_order': sortOrder++,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      return batch.commit();
    });

    return <int?>[
      for (final Object? r in results) r is int && r > 0 ? r : null,
    ];
  }

  /// Batch-updates only the given columns per `(id, columns)` entry in one
  /// transaction; empty column maps are skipped.
  Future<void> updateItemFieldsBatch(
    List<(int id, Map<String, dynamic> fields)> updates,
  ) async {
    if (updates.isEmpty) return;
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final (int id, Map<String, dynamic> fields) in updates) {
        if (fields.isEmpty) continue;
        batch.update(
          'collection_items',
          fields,
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Rewrites sort_order for the given ids in a single transaction.
  Future<void> reorderItems(
    int? collectionId,
    List<int> orderedItemIds,
  ) async {
    if (orderedItemIds.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (int i = 0; i < orderedItemIds.length; i++) {
        batch.update(
          'collection_items',
          <String, dynamic>{'sort_order': i},
          where: 'id = ?',
          whereArgs: <Object?>[orderedItemIds[i]],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Watch marks are keyed by (collection, source, show), not item id — they
  /// survive removal so re-adding the show restores its progress.
  Future<void> removeItemFromCollection(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'collection_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// The columns the watched-episodes helpers need, or null when the item
  /// row is gone.
  Future<Map<String, dynamic>?> _loadItemMeta(
    DatabaseExecutor db,
    int id,
  ) async {
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      columns: <String>[
        'collection_id',
        'media_type',
        'external_id',
        'source',
        // Tells an animated series from an animated movie; only the former
        // carries watch marks.
        'platform_id',
      ],
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Whether another tracker-backed item for the same show remains — shared
  /// watch marks must then stay put. Kitsu anime included.
  Future<bool> _hasTvSibling(
    DatabaseExecutor db,
    int collectionId,
    int externalId,
    String source,
  ) async {
    // Mirrors CollectionItem.usesEpisodeTrackerFor: only rows that can carry
    // watch marks count (not animated movies, not non-Kitsu anime).
    final List<Map<String, dynamic>> siblings = await db.query(
      'collection_items',
      columns: <String>['id'],
      where: 'collection_id = ? AND external_id = ? '
          "AND COALESCE(source, 'tmdb') = ? "
          "AND (media_type = 'tv_show' "
          "OR (media_type = 'animation' AND platform_id = ?) "
          "OR (media_type = 'anime' AND source = 'kitsu'))",
      whereArgs: <Object?>[
        collectionId,
        externalId,
        source,
        AnimationSource.tvShow,
      ],
      limit: 1,
    );
    return siblings.isNotEmpty;
  }

  Future<void> _deleteWatchedEpisodesUnlessShared(
    DatabaseExecutor db,
    int collectionId,
    int externalId,
    String source,
  ) async {
    if (await _hasTvSibling(db, collectionId, externalId, source)) return;
    await db.delete(
      'watched_episodes',
      where: 'collection_id = ? AND source = ? AND show_id = ?',
      whereArgs: <Object?>[
        collectionId,
        source,
        externalId,
      ],
    );
  }

  /// Sibling items keep the source rows (copy instead of move); moves
  /// to/from uncategorized leave the marks behind, like removal does.
  Future<void> _transferWatchedEpisodes(
    DatabaseExecutor db,
    Map<String, dynamic> movedItem,
    int? targetCollectionId,
  ) async {
    if (!CollectionItem.usesEpisodeTrackerFor(
      mediaType: MediaType.fromString(movedItem['media_type'] as String),
      source: DataSource.fromNameOr(
        movedItem['source'] as String?,
        DataSource.tmdb,
      ),
      platformId: movedItem['platform_id'] as int?,
    )) {
      return;
    }
    final int? oldCollectionId = movedItem['collection_id'] as int?;
    if (oldCollectionId == targetCollectionId) return;
    if (oldCollectionId == null || targetCollectionId == null) return;
    final int externalId = movedItem['external_id'] as int;
    final String source = (movedItem['source'] as String?) ?? 'tmdb';

    await db.rawInsert(
      'INSERT OR REPLACE INTO watched_episodes '
      '(collection_id, source, show_id, season_number, episode_number, '
      'watched_at) '
      'SELECT ?, source, show_id, season_number, episode_number, watched_at '
      'FROM watched_episodes '
      'WHERE collection_id = ? AND source = ? AND show_id = ?',
      <Object?>[
        targetCollectionId,
        oldCollectionId,
        source,
        externalId,
      ],
    );

    await _deleteWatchedEpisodesUnlessShared(
      db,
      oldCollectionId,
      externalId,
      source,
    );
  }

  /// Bumps last_activity_at; sets started_at/completed_at on their first
  /// transitions; recomputes rewatch_count on transitions into completed.
  Future<void> updateItemStatus(
    int id,
    ItemStatus status, {
    required MediaType mediaType,
  }) async {
    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final Map<String, dynamic> updateData = <String, dynamic>{
      'status': status.value,
      'last_activity_at': now,
    };

    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      columns: <String>['started_at', 'status', 'rewatch_count'],
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    final bool hasStartedAt =
        rows.isNotEmpty && rows.first['started_at'] != null;
    final String? currentStatus =
        rows.isNotEmpty ? rows.first['status'] as String? : null;

    if (status == ItemStatus.notStarted) {
      updateData['started_at'] = null;
      updateData['completed_at'] = null;
    } else if (status == ItemStatus.inProgress) {
      updateData['completed_at'] = null;
      if (!hasStartedAt) {
        updateData['started_at'] = now;
      }
    } else if (status == ItemStatus.completed) {
      updateData['completed_at'] = now;
      if (!hasStartedAt) {
        updateData['started_at'] = now;
      }
      final int? currentCount =
          rows.isNotEmpty ? rows.first['rewatch_count'] as int? : null;
      final int? newCount = computeRewatchCountForStatus(
        oldStatus: ItemStatus.fromString(currentStatus ?? ''),
        newStatus: status,
        currentCount: currentCount,
      );
      if (newCount != currentCount) {
        updateData['rewatch_count'] = newCount;
      }
    }

    await db.update(
      'collection_items',
      updateData,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Sets `rewatch_count` verbatim (manual edit / import). `null` clears the
  /// value back to "not tracked".
  Future<void> updateItemRewatchCount(int id, int? count) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'rewatch_count': count},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// The `clear*` flags erase a date: a plain `null` means "leave unchanged",
  /// mirroring [CollectionItem.copyWith]. Status is deliberately not touched.
  Future<void> updateItemActivityDates(
    int id, {
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
  }) async {
    final Database db = await _getDatabase();
    final Map<String, dynamic> data = <String, dynamic>{};
    if (clearStartedAt) {
      data['started_at'] = null;
    } else if (startedAt != null) {
      data['started_at'] = startedAt.millisecondsSinceEpoch ~/ 1000;
    }
    if (clearCompletedAt) {
      data['completed_at'] = null;
    } else if (completedAt != null) {
      data['completed_at'] = completedAt.millisecondsSinceEpoch ~/ 1000;
    }
    if (lastActivityAt != null) {
      data['last_activity_at'] =
          lastActivityAt.millisecondsSinceEpoch ~/ 1000;
    }
    if (data.isEmpty) return;
    await db.update(
      'collection_items',
      data,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> updateItemProgress(
    int id, {
    int? currentSeason,
    int? currentEpisode,
  }) async {
    final Database db = await _getDatabase();
    final Map<String, dynamic> data = <String, dynamic>{};
    if (currentSeason != null) {
      data['current_season'] = currentSeason;
    }
    if (currentEpisode != null) {
      data['current_episode'] = currentEpisode;
    }
    if (data.isEmpty) return;
    await db.update(
      'collection_items',
      data,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> updateItemAuthorComment(int id, String? comment) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'author_comment': comment},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> updateItemUserComment(int id, String? comment) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'user_comment': comment},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> updateItemTimeSpent(int id, int totalMinutes) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'time_spent_minutes': totalMinutes},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> updateItemUserRating(int id, double? rating) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'user_rating': rating},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Sets a user display name; empty/whitespace input clears the override so
  /// the UI falls back to the cached API title.
  Future<void> setItemOverrideName(int id, String? name) async {
    final Database db = await _getDatabase();
    final String? normalized =
        (name == null || name.trim().isEmpty) ? null : name.trim();
    await db.update(
      'collection_items',
      <String, dynamic>{'override_name': normalized},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> setItemFavorite(int id, {required bool isFavorite}) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Moves item to another collection (null = uncategorized), appending to its
  /// sort order; tv watch progress moves along. False on UNIQUE conflict.
  Future<bool> updateItemCollectionId(int id, int? collectionId) async {
    final Database db = await _getDatabase();
    final int newSortOrder = await getNextSortOrder(collectionId);
    return db.transaction((Transaction txn) async {
      final Map<String, dynamic>? item = await _loadItemMeta(txn, id);
      try {
        await txn.update(
          'collection_items',
          <String, dynamic>{
            'collection_id': collectionId,
            'sort_order': newSortOrder,
          },
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
      } on DatabaseException catch (e) {
        if (e.isUniqueConstraintError()) {
          return false;
        }
        rethrow;
      }
      if (item != null) {
        await _transferWatchedEpisodes(txn, item, collectionId);
      }
      return true;
    });
  }

  /// Full-row copy overriding only id/collection_id/added_at/sort_order;
  /// tag_id cleared (tags are per collection). Null on UNIQUE conflict.
  Future<int?> cloneItemToCollection(
    int itemId,
    int targetCollectionId,
  ) async {
    final Database db = await _getDatabase();

    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: 'id = ?',
      whereArgs: <Object?>[itemId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int sortOrder = await getNextSortOrder(targetCollectionId);

    final Map<String, dynamic> clone = Map<String, dynamic>.of(rows.first)
      ..remove('id')
      ..['collection_id'] = targetCollectionId
      ..['added_at'] = now
      ..['sort_order'] = sortOrder
      ..['tag_id'] = null;

    try {
      final int newId = await db.insert('collection_items', clone);
      return newId;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return null;
      }
      rethrow;
    }
  }

  /// Excludes NULL and the sentinel -1 (unknown platform).
  Future<List<int>> getUniquePlatformIds({int? collectionId}) async {
    final Database db = await _getDatabase();
    final StringBuffer sql = StringBuffer('''
      SELECT DISTINCT platform_id FROM collection_items
      WHERE media_type = 'game'
        AND platform_id IS NOT NULL
        AND platform_id != -1
    ''');
    final List<Object?> args = <Object?>[];
    if (collectionId != null) {
      sql.write(' AND collection_id = ?');
      args.add(collectionId);
    }
    sql.write(' ORDER BY platform_id');
    final List<Map<String, dynamic>> rows =
        await db.rawQuery(sql.toString(), args);
    return rows
        .map((Map<String, dynamic> row) => row['platform_id'] as int)
        .toList();
  }

  Future<int> getTotalItemCount() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT COUNT(*) as count FROM collection_items');
    return result.first['count'] as int;
  }

  Future<int> getCollectionItemCount(
    int? collectionId, {
    MediaType? mediaType,
  }) async {
    final Database db = await _getDatabase();
    String sql;
    final List<Object?> args = <Object?>[];
    if (collectionId != null) {
      sql =
          'SELECT COUNT(*) as count FROM collection_items '
          'WHERE collection_id = ?';
      args.add(collectionId);
    } else {
      sql =
          'SELECT COUNT(*) as count FROM collection_items '
          'WHERE collection_id IS NULL';
    }
    if (mediaType != null) {
      sql += ' AND media_type = ?';
      args.add(mediaType.value);
    }
    final List<Map<String, dynamic>> result = await db.rawQuery(sql, args);
    return result.first['count'] as int;
  }

  Future<Map<String, int>> getCollectionItemStats(int? collectionId) async {
    final Database db = await _getDatabase();
    final String where = collectionId != null
        ? 'WHERE collection_id = ?'
        : 'WHERE collection_id IS NULL';
    final List<Object?> args =
        collectionId != null ? <Object?>[collectionId] : <Object?>[];
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT media_type, status, COUNT(*) as count FROM collection_items '
      '$where GROUP BY media_type, status',
      args,
    );

    final Map<String, int> stats = <String, int>{
      'total': 0,
      'completed': 0,
      'inProgress': 0,
      'notStarted': 0,
      'dropped': 0,
      'planned': 0,
      'replaying': 0,
      'gameCount': 0,
      'movieCount': 0,
      'tvShowCount': 0,
      'animationCount': 0,
      'visualNovelCount': 0,
      'mangaCount': 0,
      'animeCount': 0,
      'bookCount': 0,
      'customCount': 0,
    };

    for (final Map<String, dynamic> row in result) {
      final int count = row['count'] as int;
      stats['total'] = (stats['total'] ?? 0) + count;

      final String? typeKey = switch (
          MediaType.tryFromString(row['media_type'] as String)) {
        MediaType.game => 'gameCount',
        MediaType.movie => 'movieCount',
        MediaType.tvShow => 'tvShowCount',
        MediaType.animation => 'animationCount',
        MediaType.visualNovel => 'visualNovelCount',
        MediaType.manga => 'mangaCount',
        MediaType.anime => 'animeCount',
        MediaType.book => 'bookCount',
        MediaType.custom => 'customCount',
        null => null,
      };
      if (typeKey != null) stats[typeKey] = (stats[typeKey] ?? 0) + count;

      final String? statusKey =
          switch (ItemStatus.tryFromString(row['status'] as String)) {
        ItemStatus.completed => 'completed',
        ItemStatus.inProgress => 'inProgress',
        ItemStatus.notStarted => 'notStarted',
        ItemStatus.dropped => 'dropped',
        ItemStatus.planned => 'planned',
        ItemStatus.replaying => 'replaying',
        null => null,
      };
      if (statusKey != null) {
        stats[statusKey] = (stats[statusKey] ?? 0) + count;
      }
    }

    return stats;
  }

  Future<void> clearCollectionItems(int? collectionId) async {
    final Database db = await _getDatabase();
    if (collectionId != null) {
      await db.delete(
        'collection_items',
        where: 'collection_id = ?',
        whereArgs: <Object?>[collectionId],
      );
    } else {
      await db.delete(
        'collection_items',
        where: 'collection_id IS NULL',
      );
    }
  }

  /// Maps external_id -> list of collection placements (uncategorized included).
  Future<Map<int, List<CollectedItemInfo>>> getCollectedItemInfos(
    MediaType mediaType,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT ci.id, ci.external_id, ci.source, ci.collection_id,
             ci.platform_id, c.name
      FROM collection_items ci
      LEFT JOIN collections c ON c.id = ci.collection_id
      WHERE ci.media_type = ?
      ORDER BY ci.added_at ASC
    ''', <Object?>[mediaType.value]);

    final Map<int, List<CollectedItemInfo>> result =
        <int, List<CollectedItemInfo>>{};
    for (final Map<String, dynamic> row in rows) {
      final int externalId = row['external_id'] as int;
      final CollectedItemInfo info = CollectedItemInfo(
        recordId: row['id'] as int,
        collectionId: row['collection_id'] as int?,
        collectionName: row['name'] as String?,
        platformId: row['platform_id'] as int?,
        source: DataSource.fromNameOr(
            row['source'] as String?, mediaType.defaultSource),
      );
      result.putIfAbsent(externalId, () => <CollectedItemInfo>[]).add(info);
    }
    return result;
  }

  Future<int> getUncategorizedItemCount() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM collection_items '
      'WHERE collection_id IS NULL',
    );
    return result.first['count'] as int;
  }

  /// Lightweight cover fetch — only URLs from cache tables, no full models.
  /// Ordering: completed > in_progress > others, then sort_order.
  Future<List<CoverInfo>> getCollectionCovers(
    int? collectionId, {
    int limit = 4,
  }) async {
    final Database db = await _getDatabase();

    final String whereClause = collectionId != null
        ? 'ci.collection_id = ?'
        : 'ci.collection_id IS NULL';
    final List<Object> args = <Object>[
      if (collectionId case final int id) id,
      limit,
    ];

    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT external_id, media_type, platform_id, source, thumbnail_url
      FROM (
        SELECT ci.external_id, ci.media_type, ci.platform_id, ci.source,
          ci.status, ci.sort_order,
          CASE ci.media_type
            WHEN 'game' THEN g.cover_url
            WHEN 'movie' THEN m.poster_url
            WHEN 'tv_show' THEN t.poster_url
            WHEN 'animation' THEN
              CASE WHEN ci.platform_id = 1 THEN t2.poster_url
                   ELSE m2.poster_url END
            WHEN 'visual_novel' THEN vn.image_url
            WHEN 'manga' THEN mc.cover_url
            WHEN 'anime' THEN ac.cover_url
            WHEN 'book' THEN bc.cover_url
            WHEN 'custom' THEN cm.cover_url
          END AS thumbnail_url
        FROM collection_items ci
        LEFT JOIN games g
          ON ci.media_type = 'game' AND ci.external_id = g.id
        LEFT JOIN movies_cache m
          ON ci.media_type = 'movie' AND ci.external_id = m.tmdb_id
        LEFT JOIN tv_shows_cache t
          ON ci.media_type = 'tv_show' AND ci.external_id = t.tmdb_id
          AND t.source = COALESCE(ci.source, 'tmdb')
        LEFT JOIN tv_shows_cache t2
          ON ci.media_type = 'animation' AND ci.platform_id = 1
          AND ci.external_id = t2.tmdb_id
          AND t2.source = COALESCE(ci.source, 'tmdb')
        LEFT JOIN movies_cache m2
          ON ci.media_type = 'animation' AND ci.platform_id != 1
          AND ci.external_id = m2.tmdb_id
        LEFT JOIN visual_novels_cache vn
          ON ci.media_type = 'visual_novel' AND ci.external_id = vn.numeric_id
        LEFT JOIN manga_cache mc
          ON ci.media_type = 'manga' AND ci.external_id = mc.id
          AND mc.source = COALESCE(ci.source, 'anilist')
        LEFT JOIN anime_cache ac
          ON ci.media_type = 'anime' AND ci.external_id = ac.id
          AND ac.source = COALESCE(ci.source, 'anilist')
        LEFT JOIN books_cache bc
          ON ci.media_type = 'book'
          AND ci.external_id = CAST(bc.id AS INTEGER)
          AND bc.source = ci.source
        LEFT JOIN custom_items cm
          ON ci.media_type = 'custom' AND ci.external_id = cm.id
        WHERE $whereClause
      )
      WHERE thumbnail_url IS NOT NULL
      ORDER BY
        CASE status
          WHEN 'completed' THEN 0
          WHEN 'in_progress' THEN 1
          ELSE 2
        END,
        sort_order
      LIMIT ?
    ''', args);

    return rows.map(CoverInfo.fromDb).toList();
  }

  Future<List<CollectionItem>> _loadJoinedData(
    List<CollectionItem> items,
  ) async {
    final List<int> gameIds = <int>[];
    final List<int> movieIds = <int>[];
    final List<int> tvShowIds = <int>[];
    final List<int> vnIds = <int>[];
    final List<int> animeIds = <int>[];
    final List<int> mangaIds = <int>[];
    final List<int> bookIds = <int>[];
    final List<int> customIds = <int>[];
    final Set<int> platformIds = <int>{};

    for (final CollectionItem item in items) {
      switch (item.mediaType) {
        case MediaType.game:
          gameIds.add(item.externalId);
          if (item.platformId != null) {
            platformIds.add(item.platformId!);
          }
        case MediaType.movie:
          movieIds.add(item.externalId);
        case MediaType.tvShow:
          tvShowIds.add(item.externalId);
        case MediaType.animation:
          if (item.platformId == AnimationSource.tvShow) {
            tvShowIds.add(item.externalId);
          } else {
            movieIds.add(item.externalId);
          }
        case MediaType.visualNovel:
          vnIds.add(item.externalId);
        case MediaType.anime:
          animeIds.add(item.externalId);
        case MediaType.manga:
          mangaIds.add(item.externalId);
        case MediaType.book:
          bookIds.add(item.externalId);
        case MediaType.custom:
          customIds.add(item.externalId);
      }
    }

    // Parallel — all queries are independent.
    final List<Object> results = await Future.wait(<Future<Object>>[
      gameIds.isNotEmpty
          ? _gameDao.getGamesByIds(gameIds)
          : Future<List<Game>>.value(<Game>[]),
      movieIds.isNotEmpty
          ? _movieDao.getMoviesByTmdbIds(movieIds)
          : Future<List<Movie>>.value(<Movie>[]),
      tvShowIds.isNotEmpty
          ? _tvShowDao.getTvShowsByTmdbIds(tvShowIds)
          : Future<List<TvShow>>.value(<TvShow>[]),
      vnIds.isNotEmpty
          ? _visualNovelDao.getVisualNovelsByNumericIds(vnIds)
          : Future<List<VisualNovel>>.value(<VisualNovel>[]),
      mangaIds.isNotEmpty
          ? _mangaDao.getMangaByIds(mangaIds)
          : Future<List<Manga>>.value(<Manga>[]),
      animeIds.isNotEmpty
          ? _animeDao.getAnimeByIds(animeIds)
          : Future<List<Anime>>.value(<Anime>[]),
      customIds.isNotEmpty
          ? _customMediaDao.getByIds(customIds)
          : Future<List<CustomMedia>>.value(<CustomMedia>[]),
      platformIds.isNotEmpty
          ? _gameDao.getPlatformsByIds(platformIds.toList())
          : Future<List<Platform>>.value(<Platform>[]),
      bookIds.isNotEmpty
          ? _bookDao.getBooksByIds(bookIds)
          : Future<List<Book>>.value(<Book>[]),
    ]);

    final List<Game> games = results[0] as List<Game>;
    final List<Movie> movies = results[1] as List<Movie>;
    final List<TvShow> tvShows = results[2] as List<TvShow>;
    final List<VisualNovel> visualNovels = results[3] as List<VisualNovel>;
    final List<Manga> mangas = results[4] as List<Manga>;
    final List<Anime> animes = results[5] as List<Anime>;
    final List<CustomMedia> customMediaList = results[6] as List<CustomMedia>;
    final List<Platform> platforms = results[7] as List<Platform>;
    final List<Book> books = results[8] as List<Book>;

    final Map<int, Platform> platformsMap = <int, Platform>{
      for (final Platform p in platforms) p.id: p,
    };

    // Custom games keep their platform FK on `custom_items`, so fetch the
    // platform ids the games pass above did not already cover.
    final List<int> customPlatformIds = <int>[
      for (final CustomMedia c in customMediaList)
        if (c.platformId != null && !platformsMap.containsKey(c.platformId))
          c.platformId!,
    ];
    if (customPlatformIds.isNotEmpty) {
      final List<Platform> extra =
          await _gameDao.getPlatformsByIds(customPlatformIds);
      for (final Platform p in extra) {
        platformsMap[p.id] = p;
      }
    }

    // Resolve numeric genre IDs to names where unresolved.
    final List<Movie> resolvedMovies = await _resolveGenresIfNeeded(
      movies,
      'movie',
      (Movie m) => m.genres,
      (Movie m, List<String> g) => m.copyWith(genres: g),
    );
    final List<TvShow> resolvedTvShows = await _resolveGenresIfNeeded(
      tvShows,
      'tv',
      (TvShow t) => t.genres,
      (TvShow t, List<String> g) => t.copyWith(genres: g),
    );

    final Map<int, Game> gamesMap = <int, Game>{
      for (final Game g in games) g.id: g,
    };
    final Map<int, Movie> moviesMap = <int, Movie>{
      for (final Movie m in resolvedMovies) m.tmdbId: m,
    };
    // TV shows are keyed by `(source, id)` — ids from different providers
    // can collide numerically.
    final Map<String, TvShow> tvShowsMap = <String, TvShow>{
      for (final TvShow t in resolvedTvShows) '${t.source.name}:${t.tmdbId}': t,
    };
    final Map<int, VisualNovel> vnMap = <int, VisualNovel>{
      for (final VisualNovel vn in visualNovels) vn.numericId: vn,
    };
    // Manga is keyed by `(source, id)` — AniList and MangaBaka can share a
    // numeric id, so a plain id-keyed map would collapse them.
    final Map<String, Manga> mangaMap = <String, Manga>{
      for (final Manga m in mangas) '${m.source.name}:${m.id}': m,
    };
    // Books are keyed by `(source, id)` — OpenLibrary and Fantlab can share
    // a numeric id; `book.id` is that id as a string.
    final Map<String, Book> bookMap = <String, Book>{
      for (final Book b in books) '${b.source.name}:${b.id}': b,
    };
    // Keyed by `(source, id)` — ids from different providers can collide.
    final Map<String, Anime> animeMap = <String, Anime>{
      for (final Anime a in animes) '${a.source.name}:${a.id}': a,
    };
    final Map<int, CustomMedia> customMap = <int, CustomMedia>{
      for (final CustomMedia c in customMediaList) c.id: c,
    };

    return items.map((CollectionItem item) {
      switch (item.mediaType) {
        case MediaType.game:
          return item.copyWith(
            game: gamesMap[item.externalId],
            platform: item.platformId != null
                ? platformsMap[item.platformId]
                : null,
          );
        case MediaType.movie:
          return item.copyWith(movie: moviesMap[item.externalId]);
        case MediaType.tvShow:
          return item.copyWith(
            tvShow: tvShowsMap[
                '${(item.source ?? DataSource.tmdb).name}:${item.externalId}'],
          );
        case MediaType.animation:
          if (item.platformId == AnimationSource.tvShow) {
            return item.copyWith(
              tvShow: tvShowsMap[
                  '${(item.source ?? DataSource.tmdb).name}:${item.externalId}'],
            );
          }
          return item.copyWith(movie: moviesMap[item.externalId]);
        case MediaType.visualNovel:
          return item.copyWith(visualNovel: vnMap[item.externalId]);
        case MediaType.anime:
          return item.copyWith(
            anime: animeMap[
                '${(item.source ?? DataSource.anilist).name}:${item.externalId}'],
          );
        case MediaType.manga:
          return item.copyWith(
            manga: mangaMap[
                '${(item.source ?? DataSource.anilist).name}:${item.externalId}'],
          );
        case MediaType.book:
          return item.copyWith(
            book: bookMap[
                '${(item.source ?? DataSource.openLibrary).name}:${item.externalId}'],
          );
        case MediaType.custom:
          final CustomMedia? cm = customMap[item.externalId];
          return item.copyWith(
            customMedia: cm,
            platform: cm?.platformId != null
                ? platformsMap[cm!.platformId]
                : null,
          );
      }
    }).toList();
  }

  static bool _isNumericGenre(String genre) {
    return int.tryParse(genre) != null;
  }

  /// Replaces numeric genre IDs with names via `tmdb_genres` cache.
  /// Skips work if no item has numeric IDs or the cache is empty.
  Future<List<T>> _resolveGenresIfNeeded<T>(
    List<T> items,
    String genreType,
    List<String>? Function(T item) getGenres,
    T Function(T item, List<String> genres) withGenres,
  ) async {
    if (items.isEmpty) return items;

    final bool hasUnresolved = items.any((T item) {
      final List<String>? genres = getGenres(item);
      return genres != null && genres.any(_isNumericGenre);
    });
    if (!hasUnresolved) return items;

    final Map<String, String> genreMap =
        await _movieDao.getTmdbGenreMap(genreType);
    if (genreMap.isEmpty) return items;

    return items.map((T item) {
      final List<String>? genres = getGenres(item);
      if (genres == null || genres.isEmpty) return item;
      if (!genres.any(_isNumericGenre)) return item;

      final List<String> resolved =
          genres.map((String g) => genreMap[g] ?? g).toList();
      return withGenres(item, resolved);
    }).toList();
  }

  /// Result includes `null` if uncategorized items match the status.
  Future<Set<int?>> getCollectionIdsWithStatus(ItemStatus status) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT DISTINCT collection_id FROM collection_items WHERE status = ?',
      <Object?>[status.value],
    );
    return rows
        .map((Map<String, dynamic> row) => row['collection_id'] as int?)
        .toSet();
  }

  /// Finds items matching (external_id, media_type) across all collections;
  /// with [filterByPlatform], a null [platformId] matches only NULL rows.
  Future<List<({int id, int? collectionId, int? platformId})>>
      getItemIdsByExternalId(
    int externalId,
    String mediaType, {
    int? platformId,
    bool filterByPlatform = false,
  }) async {
    final Database db = await _getDatabase();
    final List<String> conditions = <String>[
      'external_id = ?',
      'media_type = ?',
    ];
    final List<Object?> args = <Object?>[externalId, mediaType];
    if (filterByPlatform) {
      if (platformId == null) {
        conditions.add('platform_id IS NULL');
      } else {
        conditions.add('platform_id = ?');
        args.add(platformId);
      }
    }
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      columns: <String>['id', 'collection_id', 'platform_id'],
      where: conditions.join(' AND '),
      whereArgs: args,
    );
    return rows
        .map((Map<String, dynamic> r) => (
              id: r['id'] as int,
              collectionId: r['collection_id'] as int?,
              platformId: r['platform_id'] as int?,
            ))
        .toList();
  }

  /// Truncates every user table in one transaction (children before parents);
  /// static reference tables seeded by MigrationV24 are preserved.
  Future<void> clearAllData() async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete('mood_grid_cells');
      await txn.delete('mood_grids');
      await txn.delete('tier_list_entries');
      await txn.delete('tier_definitions');
      await txn.delete('tier_lists');
      await txn.delete('collection_tags');
      await txn.delete('item_tags');
      await txn.delete('tags');
      await txn.delete('tracker_achievements');
      await txn.delete('tracker_game_data');
      await txn.delete('tracker_profiles');
      await txn.delete('watched_episodes');
      await txn.delete('canvas_connections');
      await txn.delete('canvas_items');
      await txn.delete('canvas_viewport');
      await txn.delete('game_canvas_viewport');
      await txn.delete('custom_items');
      await txn.delete('collection_items');
      await txn.delete('collections');
      await txn.delete('tv_episodes_cache');
      await txn.delete('tv_seasons_cache');
      await txn.delete('tv_shows_cache');
      await txn.delete('movies_cache');
      await txn.delete('games');
      await txn.delete('visual_novels_cache');
      await txn.delete('manga_cache');
      await txn.delete('anime_cache');
      await txn.delete('books_cache');
      await txn.delete('wishlist');
    });
  }
}
