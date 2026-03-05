// DAO для работы с коллекциями, элементами коллекций и обложками.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/cover_info.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/visual_novel.dart';
import 'game_dao.dart';
import 'manga_dao.dart';
import 'movie_dao.dart';
import 'tv_show_dao.dart';
import 'visual_novel_dao.dart';

/// DAO для таблиц `collections` и `collection_items`.
class CollectionDao {
  /// Создаёт DAO с функцией получения базы данных и зависимыми DAO.
  const CollectionDao(
    this._getDatabase, {
    required GameDao gameDao,
    required MovieDao movieDao,
    required TvShowDao tvShowDao,
    required VisualNovelDao visualNovelDao,
    required MangaDao mangaDao,
  })  : _gameDao = gameDao,
        _movieDao = movieDao,
        _tvShowDao = tvShowDao,
        _visualNovelDao = visualNovelDao,
        _mangaDao = mangaDao;

  final Future<Database> Function() _getDatabase;
  final GameDao _gameDao;
  final MovieDao _movieDao;
  final TvShowDao _tvShowDao;
  final VisualNovelDao _visualNovelDao;
  final MangaDao _mangaDao;

  // ==================== Collections ====================

  /// Возвращает все коллекции.
  Future<List<Collection>> getAllCollections() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      orderBy: 'created_at DESC',
    );
    return rows.map(Collection.fromDb).toList();
  }

  /// Возвращает коллекции по типу.
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

  /// Возвращает коллекцию по ID или null, если не найдена.
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

  /// Создаёт новую коллекцию и возвращает её с присвоенным ID.
  Future<Collection> createCollection({
    required String name,
    required String author,
    CollectionType type = CollectionType.own,
    String? originalSnapshot,
    String? forkedFromAuthor,
    String? forkedFromName,
  }) async {
    final Database db = await _getDatabase();
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

    final Database db = await _getDatabase();
    await db.update(
      'collections',
      <String, dynamic>{'name': name},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет коллекцию и все связанные игры (каскадно).
  Future<void> deleteCollection(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Возвращает количество коллекций.
  Future<int> getCollectionCount() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM collections',
    );
    return result.first['count'] as int;
  }

  // ==================== Collection Items ====================

  /// Возвращает все элементы в коллекции.
  ///
  /// Если [collectionId] == null, возвращает uncategorized элементы.
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

  /// Возвращает элементы коллекции с подгруженными данными.
  ///
  /// Если [collectionId] == null, возвращает uncategorized элементы.
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

  /// Возвращает все элементы из всех коллекций.
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

  /// Возвращает все элементы из всех коллекций с подгруженными данными.
  Future<List<CollectionItem>> getAllCollectionItemsWithData({
    MediaType? mediaType,
  }) async {
    final List<CollectionItem> items = await getAllCollectionItems(
      mediaType: mediaType,
    );
    if (items.isEmpty) return items;
    return _loadJoinedData(items);
  }

  /// Возвращает элемент коллекции по ID.
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

  /// Находит элемент коллекции по типу медиа и внешнему ID.
  ///
  /// Возвращает null если элемент не найден в указанной коллекции.
  Future<CollectionItem?> findCollectionItem({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
  }) async {
    final Database db = await _getDatabase();
    String where;
    final List<Object?> whereArgs = <Object?>[];

    if (collectionId != null) {
      where = 'collection_id = ? AND media_type = ? AND external_id = ?';
      whereArgs.addAll(
        <Object?>[collectionId, mediaType.value, externalId],
      );
    } else {
      where = 'collection_id IS NULL AND media_type = ? AND external_id = ?';
      whereArgs.addAll(<Object?>[mediaType.value, externalId]);
    }

    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return CollectionItem.fromDb(rows.first);
  }

  /// Добавляет элемент в коллекцию.
  ///
  /// Если [collectionId] == null, элемент добавляется как uncategorized.
  /// Возвращает ID созданной записи или null при конфликте.
  Future<int?> addItemToCollection({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    String? authorComment,
    ItemStatus status = ItemStatus.notStarted,
  }) async {
    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      final int sortOrder = await getNextSortOrder(collectionId);
      final int id = await db.insert(
        'collection_items',
        <String, dynamic>{
          'collection_id': collectionId,
          'media_type': mediaType.value,
          'external_id': externalId,
          'platform_id': platformId,
          'status': status.value,
          'author_comment': authorComment,
          'added_at': now,
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

  /// Возвращает следующий sort_order для коллекции.
  ///
  /// Если [collectionId] == null, возвращает sort_order для uncategorized.
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

  /// Пересортировывает элементы коллекции после drag-and-drop.
  ///
  /// Обновляет sort_order всех элементов в транзакции.
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

  /// Удаляет элемент из коллекции.
  Future<void> removeItemFromCollection(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'collection_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет статус элемента коллекции.
  ///
  /// Автоматически устанавливает даты активности:
  /// - `last_activity_at` обновляется всегда
  /// - `started_at` устанавливается при переходе в inProgress (если null)
  /// - `completed_at` устанавливается при переходе в completed
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

    // Получаем текущий элемент для проверки дат
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      columns: <String>['started_at'],
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    final bool hasStartedAt =
        rows.isNotEmpty && rows.first['started_at'] != null;

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
    }

    await db.update(
      'collection_items',
      updateData,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет даты активности элемента коллекции вручную.
  Future<void> updateItemActivityDates(
    int id, {
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
  }) async {
    final Database db = await _getDatabase();
    final Map<String, dynamic> data = <String, dynamic>{};
    if (startedAt != null) {
      data['started_at'] = startedAt.millisecondsSinceEpoch ~/ 1000;
    }
    if (completedAt != null) {
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

  /// Обновляет прогресс просмотра сериала.
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

  /// Обновляет комментарий автора элемента.
  Future<void> updateItemAuthorComment(int id, String? comment) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'author_comment': comment},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет личный комментарий пользователя элемента.
  Future<void> updateItemUserComment(int id, String? comment) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'user_comment': comment},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет пользовательский рейтинг элемента (1-10 или null).
  Future<void> updateItemUserRating(int id, int? rating) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'user_rating': rating},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет collection_id элемента (перемещает в другую коллекцию).
  ///
  /// Передайте [collectionId] = null для перемещения в uncategorized.
  /// Также обновляет sort_order для целевой коллекции.
  /// Возвращает true при успехе, false если элемент уже есть в целевой
  /// коллекции (UNIQUE constraint).
  Future<bool> updateItemCollectionId(int id, int? collectionId) async {
    final Database db = await _getDatabase();
    final int newSortOrder = await getNextSortOrder(collectionId);
    try {
      await db.update(
        'collection_items',
        <String, dynamic>{
          'collection_id': collectionId,
          'sort_order': newSortOrder,
        },
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return false;
      }
      rethrow;
    }
  }

  /// Возвращает уникальные platform_id из игр в коллекциях.
  ///
  /// Если [collectionId] указан, фильтрует по этой коллекции.
  /// Если null — возвращает платформы из всех коллекций.
  /// Исключает platform_id = NULL и platform_id = -1.
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

  /// Возвращает количество элементов в коллекции.
  ///
  /// Если [collectionId] == null, считает uncategorized элементы.
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

  /// Возвращает расширенную статистику по коллекции.
  ///
  /// Если [collectionId] == null, возвращает статистику uncategorized.
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
      'gameCount': 0,
      'movieCount': 0,
      'tvShowCount': 0,
      'animationCount': 0,
      'visualNovelCount': 0,
      'mangaCount': 0,
    };

    for (final Map<String, dynamic> row in result) {
      final String status = row['status'] as String;
      final String type = row['media_type'] as String;
      final int count = row['count'] as int;
      stats['total'] = (stats['total'] ?? 0) + count;

      // Подсчёт по типам медиа
      switch (type) {
        case 'game':
          stats['gameCount'] = (stats['gameCount'] ?? 0) + count;
        case 'movie':
          stats['movieCount'] = (stats['movieCount'] ?? 0) + count;
        case 'tv_show':
          stats['tvShowCount'] = (stats['tvShowCount'] ?? 0) + count;
        case 'animation':
          stats['animationCount'] = (stats['animationCount'] ?? 0) + count;
        case 'visual_novel':
          stats['visualNovelCount'] =
              (stats['visualNovelCount'] ?? 0) + count;
        case 'manga':
          stats['mangaCount'] = (stats['mangaCount'] ?? 0) + count;
      }

      // Подсчёт по статусам
      switch (status) {
        case 'completed':
          stats['completed'] = (stats['completed'] ?? 0) + count;
        case 'in_progress':
          stats['inProgress'] = (stats['inProgress'] ?? 0) + count;
        case 'not_started':
          stats['notStarted'] = (stats['notStarted'] ?? 0) + count;
        case 'dropped':
          stats['dropped'] = (stats['dropped'] ?? 0) + count;
        case 'planned':
          stats['planned'] = (stats['planned'] ?? 0) + count;
      }
    }

    return stats;
  }

  /// Удаляет все элементы из коллекции.
  ///
  /// Если [collectionId] == null, удаляет uncategorized элементы.
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

  // ==================== Info ====================

  /// Возвращает информацию о нахождении элементов заданного типа в коллекциях.
  ///
  /// Результат: `Map` external_id -> список записей в коллекциях.
  /// Элементы без коллекции (uncategorized) также включаются.
  Future<Map<int, List<CollectedItemInfo>>> getCollectedItemInfos(
    MediaType mediaType,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT ci.id, ci.external_id, ci.collection_id, c.name
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
      );
      result.putIfAbsent(externalId, () => <CollectedItemInfo>[]).add(info);
    }
    return result;
  }

  /// Возвращает количество uncategorized элементов.
  Future<int> getUncategorizedItemCount() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM collection_items '
      'WHERE collection_id IS NULL',
    );
    return result.first['count'] as int;
  }

  // ==================== Collection Covers ====================

  /// Возвращает первые [limit] обложек элементов коллекции.
  ///
  /// Легковесный запрос: получает только URL обложек из кэш-таблиц,
  /// без загрузки полных моделей. Приоритет: completed > in_progress > остальные.
  ///
  /// Если [collectionId] == null, возвращает обложки uncategorized элементов.
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
      SELECT external_id, media_type, platform_id, thumbnail_url
      FROM (
        SELECT ci.external_id, ci.media_type, ci.platform_id, ci.status,
          ci.sort_order,
          CASE ci.media_type
            WHEN 'game' THEN g.cover_url
            WHEN 'movie' THEN m.poster_url
            WHEN 'tv_show' THEN t.poster_url
            WHEN 'animation' THEN
              CASE WHEN ci.platform_id = 1 THEN t2.poster_url
                   ELSE m2.poster_url END
            WHEN 'visual_novel' THEN vn.image_url
            WHEN 'manga' THEN mc.cover_url
          END AS thumbnail_url
        FROM collection_items ci
        LEFT JOIN games g
          ON ci.media_type = 'game' AND ci.external_id = g.id
        LEFT JOIN movies_cache m
          ON ci.media_type = 'movie' AND ci.external_id = m.tmdb_id
        LEFT JOIN tv_shows_cache t
          ON ci.media_type = 'tv_show' AND ci.external_id = t.tmdb_id
        LEFT JOIN tv_shows_cache t2
          ON ci.media_type = 'animation' AND ci.platform_id = 1
          AND ci.external_id = t2.tmdb_id
        LEFT JOIN movies_cache m2
          ON ci.media_type = 'animation' AND ci.platform_id != 1
          AND ci.external_id = m2.tmdb_id
        LEFT JOIN visual_novels_cache vn
          ON ci.media_type = 'visual_novel' AND ci.external_id = vn.numeric_id
        LEFT JOIN manga_cache mc
          ON ci.media_type = 'manga' AND ci.external_id = mc.id
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

  // ==================== Private ====================

  /// Загружает связанные данные (Game, Movie, TvShow, Platform) для элементов.
  Future<List<CollectionItem>> _loadJoinedData(
    List<CollectionItem> items,
  ) async {
    // Собираем ID по типам
    final List<int> gameIds = <int>[];
    final List<int> movieIds = <int>[];
    final List<int> tvShowIds = <int>[];
    final List<int> vnIds = <int>[];
    final List<int> mangaIds = <int>[];
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
        case MediaType.manga:
          mangaIds.add(item.externalId);
      }
    }

    // Загружаем данные параллельно
    final List<Game> games =
        gameIds.isNotEmpty ? await _gameDao.getGamesByIds(gameIds) : <Game>[];
    final List<Movie> movies = movieIds.isNotEmpty
        ? await _movieDao.getMoviesByTmdbIds(movieIds)
        : <Movie>[];
    final List<TvShow> tvShows = tvShowIds.isNotEmpty
        ? await _tvShowDao.getTvShowsByTmdbIds(tvShowIds)
        : <TvShow>[];
    final List<VisualNovel> visualNovels = vnIds.isNotEmpty
        ? await _visualNovelDao.getVisualNovelsByNumericIds(vnIds)
        : <VisualNovel>[];
    final List<Manga> mangas = mangaIds.isNotEmpty
        ? await _mangaDao.getMangaByIds(mangaIds)
        : <Manga>[];

    // Загружаем платформы
    Map<int, Platform> platformsMap = <int, Platform>{};
    if (platformIds.isNotEmpty) {
      final List<Platform> platforms =
          await _gameDao.getPlatformsByIds(platformIds.toList());
      platformsMap = <int, Platform>{
        for (final Platform p in platforms) p.id: p,
      };
    }

    // Резолвим жанры из числовых ID в имена (если есть нерезолвленные)
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

    // Создаём карты для быстрого поиска
    final Map<int, Game> gamesMap = <int, Game>{
      for (final Game g in games) g.id: g,
    };
    final Map<int, Movie> moviesMap = <int, Movie>{
      for (final Movie m in resolvedMovies) m.tmdbId: m,
    };
    final Map<int, TvShow> tvShowsMap = <int, TvShow>{
      for (final TvShow t in resolvedTvShows) t.tmdbId: t,
    };
    final Map<int, VisualNovel> vnMap = <int, VisualNovel>{
      for (final VisualNovel vn in visualNovels) vn.numericId: vn,
    };
    final Map<int, Manga> mangaMap = <int, Manga>{
      for (final Manga m in mangas) m.id: m,
    };

    // Собираем результат
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
          return item.copyWith(tvShow: tvShowsMap[item.externalId]);
        case MediaType.animation:
          if (item.platformId == AnimationSource.tvShow) {
            return item.copyWith(tvShow: tvShowsMap[item.externalId]);
          }
          return item.copyWith(movie: moviesMap[item.externalId]);
        case MediaType.visualNovel:
          return item.copyWith(visualNovel: vnMap[item.externalId]);
        case MediaType.manga:
          return item.copyWith(manga: mangaMap[item.externalId]);
      }
    }).toList();
  }

  /// Проверяет, является ли строка числовым ID (нерезолвленный жанр).
  static bool _isNumericGenre(String genre) {
    return int.tryParse(genre) != null;
  }

  /// Резолвит числовые genre_ids в имена для списка медиа-элементов.
  ///
  /// Проверяет жанры каждого элемента: если хотя бы один жанр — числовой ID,
  /// загружает маппинг из кэша `tmdb_genres` и заменяет ID на имена.
  /// Если кэш пуст или нет нерезолвленных жанров, возвращает исходный список.
  Future<List<T>> _resolveGenresIfNeeded<T>(
    List<T> items,
    String genreType,
    List<String>? Function(T item) getGenres,
    T Function(T item, List<String> genres) withGenres,
  ) async {
    if (items.isEmpty) return items;

    // Проверяем, есть ли нерезолвленные жанры (числовые ID)
    final bool hasUnresolved = items.any((T item) {
      final List<String>? genres = getGenres(item);
      return genres != null && genres.any(_isNumericGenre);
    });
    if (!hasUnresolved) return items;

    // Загружаем маппинг из кэша
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
}
