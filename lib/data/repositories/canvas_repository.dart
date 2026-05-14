import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../shared/models/anime.dart';
import '../../shared/models/canvas_connection.dart';
import '../../shared/models/canvas_item.dart';
import '../../shared/models/canvas_viewport.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/custom_media.dart';
import '../../shared/models/game.dart';
import '../../shared/models/manga.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/tv_show.dart';
import '../../shared/models/visual_novel.dart';

final Provider<CanvasRepository> canvasRepositoryProvider =
    Provider<CanvasRepository>((Ref ref) {
  return CanvasRepository(
    db: ref.watch(databaseServiceProvider),
  );
});

class CanvasRepository {
  CanvasRepository({required DatabaseService db}) : _db = db;

  final DatabaseService _db;

  static const double defaultCardWidth = 160;
  static const double defaultCardHeight = 220;
  static const double gridGap = 24;
  static const int gridColumns = 5;
  static const double initialCenterX = 2500.0;
  static const double initialCenterY = 2500.0;

  Future<List<CanvasItem>> getItems(int collectionId) async {
    final List<Map<String, dynamic>> rows =
        await _db.getCanvasItems(collectionId);
    return rows.map(CanvasItem.fromDb).toList();
  }

  Future<List<CanvasItem>> getItemsWithData(int collectionId) async {
    final List<CanvasItem> items = await getItems(collectionId);
    return _enrichItemsWithMediaData(items);
  }

  Future<CanvasItem> createItem(CanvasItem item) async {
    final int id = await _db.insertCanvasItem(item.toDb());
    return item.copyWith(id: id);
  }

  Future<List<CanvasItem>> createItemsBatch(List<CanvasItem> items) async {
    if (items.isEmpty) return <CanvasItem>[];

    final List<Map<String, dynamic>> dbMaps =
        items.map((CanvasItem item) => item.toDb()).toList();
    final List<int> ids = await _db.insertCanvasItemsBatch(dbMaps);

    return <CanvasItem>[
      for (int i = 0; i < items.length; i++) items[i].copyWith(id: ids[i]),
    ];
  }

  Future<void> deleteItemsBatch(List<int> ids) async {
    await _db.deleteCanvasItemsBatch(ids);
  }

  Future<void> updateItem(CanvasItem item) async {
    final Map<String, dynamic> dbData = item.toDb();
    dbData.remove('id');
    await _db.updateCanvasItem(item.id, dbData);
  }

  Future<void> updateItemPosition(
    int id, {
    required double x,
    required double y,
  }) async {
    await _db.updateCanvasItem(id, <String, dynamic>{'x': x, 'y': y});
  }

  Future<void> updateItemSize(
    int id, {
    double? width,
    double? height,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (width != null) data['width'] = width;
    if (height != null) data['height'] = height;
    if (data.isNotEmpty) {
      await _db.updateCanvasItem(id, data);
    }
  }

  Future<void> updateItemData(int id, Map<String, dynamic>? data) async {
    await _db.updateCanvasItem(id, <String, dynamic>{
      'data': data != null ? json.encode(data) : null,
    });
  }

  Future<void> updateItemZIndex(int id, int zIndex) async {
    await _db.updateCanvasItem(id, <String, dynamic>{'z_index': zIndex});
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteCanvasItem(id);
  }

  Future<void> deleteGameItem(int collectionId, int igdbId) async {
    await _db.deleteCanvasItemByRef(collectionId, 'game', igdbId);
  }

  Future<void> deleteMediaItem(
    int collectionId,
    CanvasItemType itemType,
    int refId,
  ) async {
    await _db.deleteCanvasItemByRef(collectionId, itemType.value, refId);
  }

  Future<void> deleteByCollectionItemId(
    int collectionId,
    int collectionItemId,
  ) async {
    await _db.deleteCanvasItemByCollectionItemId(
      collectionId,
      collectionItemId,
    );
  }

  Future<bool> hasCanvasItems(int collectionId) async {
    final int count = await _db.getCanvasItemCount(collectionId);
    return count > 0;
  }

  Future<CanvasViewport?> getViewport(int collectionId) async {
    final Map<String, dynamic>? row =
        await _db.getCanvasViewport(collectionId);
    if (row == null) return null;
    return CanvasViewport.fromDb(row);
  }

  Future<void> saveViewport(CanvasViewport viewport) async {
    await _db.upsertCanvasViewport(
      collectionId: viewport.collectionId,
      scale: viewport.scale,
      offsetX: viewport.offsetX,
      offsetY: viewport.offsetY,
    );
  }

  /// Hydrates `CanvasItem.game/movie/tvShow/...` from cache tables in one
  /// parallel batch. Animation items resolve to whichever of `movies_cache`
  /// or `tv_shows_cache` actually holds the referenced TMDB id — TMDB stores
  /// animated films and TV anime in different tables.
  Future<List<CanvasItem>> _enrichItemsWithMediaData(
    List<CanvasItem> items,
  ) async {
    if (items.isEmpty) return items;

    final List<int> gameIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.game && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    final List<int> animationRefIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.animation &&
            item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    final List<int> movieTmdbIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.movie && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList()
      ..addAll(animationRefIds);

    final List<int> tvShowTmdbIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.tvShow && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList()
      ..addAll(animationRefIds);

    final List<int> vnIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.visualNovel &&
            item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    final List<int> mangaIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.manga && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    final List<int> animeIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.anime && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    final List<int> customIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.custom && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    if (gameIds.isEmpty &&
        movieTmdbIds.isEmpty &&
        tvShowTmdbIds.isEmpty &&
        vnIds.isEmpty &&
        mangaIds.isEmpty &&
        animeIds.isEmpty &&
        customIds.isEmpty) {
      return items;
    }

    final List<Object> results = await Future.wait(<Future<Object>>[
      gameIds.isNotEmpty
          ? _db.getGamesByIds(gameIds)
          : Future<List<Game>>.value(<Game>[]),
      movieTmdbIds.isNotEmpty
          ? _db.getMoviesByTmdbIds(movieTmdbIds)
          : Future<List<Movie>>.value(<Movie>[]),
      tvShowTmdbIds.isNotEmpty
          ? _db.getTvShowsByTmdbIds(tvShowTmdbIds)
          : Future<List<TvShow>>.value(<TvShow>[]),
      vnIds.isNotEmpty
          ? _db.getVisualNovelsByNumericIds(vnIds)
          : Future<List<VisualNovel>>.value(<VisualNovel>[]),
      mangaIds.isNotEmpty
          ? _db.getMangaByIds(mangaIds)
          : Future<List<Manga>>.value(<Manga>[]),
      animeIds.isNotEmpty
          ? _db.animeDao.getAnimeByIds(animeIds)
          : Future<List<Anime>>.value(<Anime>[]),
      customIds.isNotEmpty
          ? _db.customMediaDao.getByIds(customIds)
          : Future<List<CustomMedia>>.value(<CustomMedia>[]),
    ]);

    final Map<int, Game> gamesMap = <int, Game>{
      for (final Game g in results[0] as List<Game>) g.id: g,
    };
    final Map<int, Movie> moviesMap = <int, Movie>{
      for (final Movie m in results[1] as List<Movie>) m.tmdbId: m,
    };
    final Map<int, TvShow> tvShowsMap = <int, TvShow>{
      for (final TvShow t in results[2] as List<TvShow>) t.tmdbId: t,
    };
    final Map<int, VisualNovel> vnMap = <int, VisualNovel>{
      for (final VisualNovel vn in results[3] as List<VisualNovel>)
        vn.numericId: vn,
    };
    final Map<int, Manga> mangaMap = <int, Manga>{
      for (final Manga m in results[4] as List<Manga>) m.id: m,
    };
    final Map<int, Anime> animeMap = <int, Anime>{
      for (final Anime a in results[5] as List<Anime>) a.id: a,
    };
    final Map<int, CustomMedia> customMap = <int, CustomMedia>{
      for (final CustomMedia c in results[6] as List<CustomMedia>) c.id: c,
    };

    return items.map((CanvasItem item) {
      if (item.itemRefId == null) return item;
      switch (item.itemType) {
        case CanvasItemType.game:
          return item.copyWith(game: gamesMap[item.itemRefId]);
        case CanvasItemType.movie:
          return item.copyWith(movie: moviesMap[item.itemRefId]);
        case CanvasItemType.tvShow:
          return item.copyWith(tvShow: tvShowsMap[item.itemRefId]);
        case CanvasItemType.animation:
          // Animation can resolve to either a movie or a TV show.
          final Movie? movie = moviesMap[item.itemRefId];
          if (movie != null) {
            return item.copyWith(movie: movie);
          }
          return item.copyWith(tvShow: tvShowsMap[item.itemRefId]);
        case CanvasItemType.visualNovel:
          return item.copyWith(visualNovel: vnMap[item.itemRefId]);
        case CanvasItemType.manga:
          return item.copyWith(manga: mangaMap[item.itemRefId]);
        case CanvasItemType.anime:
          return item.copyWith(anime: animeMap[item.itemRefId]);
        case CanvasItemType.custom:
          return item.copyWith(customMedia: customMap[item.itemRefId]);
        case CanvasItemType.text:
        case CanvasItemType.image:
        case CanvasItemType.link:
          return item;
      }
    }).toList();
  }

  Future<List<CanvasConnection>> getConnections(int collectionId) async {
    final List<Map<String, dynamic>> rows =
        await _db.getCanvasConnections(collectionId);
    return rows.map(CanvasConnection.fromDb).toList();
  }

  Future<CanvasConnection> createConnection(CanvasConnection conn) async {
    final int id = await _db.insertCanvasConnection(conn.toDb());
    return conn.copyWith(id: id);
  }

  Future<void> updateConnection(CanvasConnection conn) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'label': conn.label,
      'color': conn.color,
      'style': conn.style.value,
    };
    await _db.updateCanvasConnection(conn.id, data);
  }

  Future<void> deleteConnection(int id) async {
    await _db.deleteCanvasConnection(id);
  }

  Future<List<CanvasItem>> getGameCanvasItems(int collectionItemId) async {
    final List<Map<String, dynamic>> rows =
        await _db.getGameCanvasItems(collectionItemId);
    return rows.map(CanvasItem.fromDb).toList();
  }

  Future<List<CanvasItem>> getGameCanvasItemsWithData(
    int collectionItemId,
  ) async {
    final List<CanvasItem> items =
        await getGameCanvasItems(collectionItemId);
    return _enrichItemsWithMediaData(items);
  }

  Future<bool> hasGameCanvasItems(int collectionItemId) async {
    final int count = await _db.getGameCanvasItemCount(collectionItemId);
    return count > 0;
  }

  /// Returns a [CanvasViewport] whose `collectionId` is the
  /// `collectionItemId` — `CanvasState` was designed for collection-scoped
  /// viewports, so per-item viewports reuse the same shape with the item id
  /// substituted in.
  Future<CanvasViewport?> getGameCanvasViewport(
    int collectionItemId,
  ) async {
    final Map<String, dynamic>? row =
        await _db.getGameCanvasViewport(collectionItemId);
    if (row == null) return null;
    return CanvasViewport(
      collectionId: collectionItemId,
      scale: (row['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (row['offset_x'] as num?)?.toDouble() ?? 0.0,
      offsetY: (row['offset_y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<void> saveGameCanvasViewport(
    int collectionItemId,
    CanvasViewport viewport,
  ) async {
    await _db.upsertGameCanvasViewport(
      collectionItemId: collectionItemId,
      scale: viewport.scale,
      offsetX: viewport.offsetX,
      offsetY: viewport.offsetY,
    );
  }

  Future<List<CanvasConnection>> getGameCanvasConnections(
    int collectionItemId,
  ) async {
    final List<Map<String, dynamic>> rows =
        await _db.getGameCanvasConnections(collectionItemId);
    return rows.map(CanvasConnection.fromDb).toList();
  }

  /// Lays the canvas out as a centred grid on first open. The grid is sized
  /// to fit [gridColumns] across, centred around
  /// ([initialCenterX], [initialCenterY]) so the user lands on something
  /// instead of an empty void.
  Future<List<CanvasItem>> initializeCanvas(
    int collectionId,
    List<CollectionItem> items,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (items.isEmpty) {
      await saveViewport(CanvasViewport(collectionId: collectionId));
      return <CanvasItem>[];
    }

    final int cols =
        items.length < gridColumns ? items.length : gridColumns;
    final int rowCount = (items.length + cols - 1) ~/ cols;
    final double gridWidth = cols * (defaultCardWidth + gridGap) - gridGap;
    final double gridHeight =
        rowCount * (defaultCardHeight + gridGap) - gridGap;
    final double startX = initialCenterX - gridWidth / 2;
    final double startY = initialCenterY - gridHeight / 2;

    final List<CanvasItem> pendingItems = <CanvasItem>[];
    for (int i = 0; i < items.length; i++) {
      final int col = i % cols;
      final int row = i ~/ cols;
      final double x = startX + col * (defaultCardWidth + gridGap);
      final double y = startY + row * (defaultCardHeight + gridGap);

      final CanvasItemType canvasType =
          CanvasItemType.fromMediaType(items[i].mediaType);

      pendingItems.add(CanvasItem(
        id: 0,
        collectionId: collectionId,
        itemType: canvasType,
        itemRefId: items[i].externalId,
        x: x,
        y: y,
        width: defaultCardWidth,
        height: defaultCardHeight,
        zIndex: i,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      ));
    }

    final List<CanvasItem> created = await createItemsBatch(pendingItems);

    final List<CanvasItem> createdItems = <CanvasItem>[
      for (int i = 0; i < created.length; i++)
        created[i].copyWith(
          game: items[i].game,
          movie: items[i].movie,
          tvShow: items[i].tvShow,
          visualNovel: items[i].visualNovel,
          manga: items[i].manga,
        ),
    ];

    await saveViewport(CanvasViewport(collectionId: collectionId));

    return createdItems;
  }
}
