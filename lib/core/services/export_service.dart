import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/repositories/canvas_repository.dart';
import '../../shared/models/canvas_connection.dart';
import '../../shared/models/canvas_item.dart';
import '../../shared/models/canvas_viewport.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/data_source.dart';
import '../../shared/models/item_mark.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/tracker_game_data.dart';
import '../../shared/models/platform.dart' as model;
import '../../shared/models/tv_episode.dart';
import '../../shared/models/tv_season.dart';
import '../../shared/models/tier_definition.dart';
import '../../shared/models/tag.dart';
import '../../shared/models/tier_list.dart';
import '../../shared/models/tier_list_entry.dart';
import '../database/dao/tracker_dao.dart';
import '../database/database_service.dart';
import 'collection_hero_service.dart';
import 'image_cache_service.dart';
import 'xcoll_file.dart';

final Provider<ExportService> exportServiceProvider =
    Provider<ExportService>((Ref ref) {
  return ExportService(
    canvasRepository: ref.watch(canvasRepositoryProvider),
    imageCacheService: ref.watch(imageCacheServiceProvider),
    database: ref.watch(databaseServiceProvider),
    trackerDao: ref.watch(trackerDaoProvider),
    heroService: ref.watch(collectionHeroServiceProvider),
  );
});

class ExportResult {
  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
  });

  const ExportResult.success(String path)
      : success = true,
        filePath = path,
        error = null;

  const ExportResult.failure(String message)
      : success = false,
        filePath = null,
        error = message;

  const ExportResult.cancelled()
      : success = false,
        filePath = null,
        error = null;

  final bool success;

  final String? filePath;

  final String? error;

  /// Cancelled = not successful but with no error message.
  bool get isCancelled => !success && error == null;
}

/// Exports collections to the .xcoll / .xcollx formats.
class ExportService {
  /// [canvasRepository], [imageCacheService] and [database] are only needed
  /// for full export (.xcollx): canvas data, covers and season data.
  ExportService({
    CanvasRepository? canvasRepository,
    ImageCacheService? imageCacheService,
    DatabaseService? database,
    TrackerDao? trackerDao,
    CollectionHeroService? heroService,
  })  : _canvasRepository = canvasRepository,
        _imageCacheService = imageCacheService,
        _database = database,
        _trackerDao = trackerDao,
        _heroService = heroService;

  static final Logger _log = Logger('ExportService');

  final CanvasRepository? _canvasRepository;
  final ImageCacheService? _imageCacheService;
  final DatabaseService? _database;
  final TrackerDao? _trackerDao;
  final CollectionHeroService? _heroService;

  /// Creates a v2 light export (.xcoll).
  XcollFile createLightExport(
    Collection collection,
    List<CollectionItem> items, {
    bool includeUserData = false,
  }) {
    final List<Map<String, dynamic>> exportItems = items
        .map((CollectionItem i) =>
            i.toExport(includeUserData: includeUserData))
        .toList();

    return XcollFile(
      version: xcollFormatVersion,
      format: ExportFormat.light,
      name: collection.name,
      author: collection.author,
      created: collection.createdAt,
      description: collection.description,
      includesUserData: includeUserData,
      items: exportItems,
    );
  }

  /// Creates a v2 full export (.xcollx): items, collection canvas, per-item
  /// canvas, images and full media data (Game/Movie/TvShow) for offline
  /// import. Requires [canvasRepository] for the canvas data.
  Future<XcollFile> createFullExport(
    Collection collection,
    List<CollectionItem> items,
    int collectionId, {
    bool includeUserData = false,
  }) async {
    final List<Map<String, dynamic>> exportItems = items
        .map((CollectionItem i) =>
            i.toExport(includeUserData: includeUserData))
        .toList();

    // Collection-level canvas
    ExportCanvas? canvas;
    if (_canvasRepository != null) {
      canvas = await _buildCollectionCanvas(collectionId);
    }

    // Per-item canvas
    if (_canvasRepository != null) {
      await _attachPerItemCanvas(items, exportItems);
    }

    // Collect cached cover images
    Map<String, String> images = <String, String>{};
    if (_imageCacheService != null) {
      images = await _collectCachedImages(items);
    }

    // Collect canvas images (from collection and per-item canvases)
    if (_imageCacheService != null && _canvasRepository != null) {
      final Map<String, String> canvasImages =
          await _collectCanvasImages(collectionId, items);
      images.addAll(canvasImages);
    }

    // Collect hero image (if set)
    await _collectHeroImage(collection, images);

    // Per-item marks (likes/notes) and watch progress — user data only
    if (includeUserData) {
      await _attachItemMarks(items, exportItems);
      await _attachWatchedEpisodes(collectionId, items, exportItems);
    }

    // Collect full media data for offline import (includes tv_seasons)
    final Map<String, dynamic> media = await _collectMediaData(items);

    // Collect tier list data
    List<Map<String, dynamic>>? tierLists;
    if (_database != null) {
      tierLists = await _collectTierListData(collectionId);
    }

    // Collect tag data and enrich items with tag names for import resolution
    List<Map<String, dynamic>>? tags;
    if (_database != null) {
      final _TagExportResult tagResult =
          await _collectTagData(items);
      tags = tagResult.tags;
      for (int i = 0; i < items.length; i++) {
        final List<String> tagNames = tagResult.itemTagNames[i];
        if (tagNames.isNotEmpty) {
          exportItems[i]['tag_names'] = tagNames;
          // Single-tag key kept so older app versions still restore one tag.
          exportItems[i]['tag_name'] = tagNames.first;
        }
      }
    }

    // Collect tracker data (RA progress) for games — only with user data
    List<Map<String, dynamic>>? trackerData;
    if (includeUserData && _trackerDao != null) {
      trackerData = await _collectTrackerData(items);
    }

    return XcollFile(
      version: xcollFormatVersion,
      format: ExportFormat.full,
      name: collection.name,
      author: collection.author,
      created: collection.createdAt,
      description: collection.description,
      includesUserData: includeUserData,
      items: exportItems,
      canvas: canvas,
      images: images,
      media: media,
      tierLists: tierLists,
      tags: tags,
      trackerData: trackerData,
    );
  }

  /// Embeds the collection hero image into the `images` section under the
  /// key `collection_hero/{id}.{ext}` (base64).
  Future<void> _collectHeroImage(
    Collection collection,
    Map<String, String> images,
  ) async {
    final String? fileName = collection.heroImagePath;
    if (fileName == null || _heroService == null) return;
    final String? absPath = _heroService.resolve(fileName);
    if (absPath == null) return;
    final File file = File(absPath);
    if (!file.existsSync()) return;
    try {
      final List<int> bytes = await file.readAsBytes();
      final String ext = _heroExtension(fileName);
      images['collection_hero/${collection.id}.$ext'] = base64Encode(bytes);
    } on FileSystemException catch (e) {
      _log.warning('Failed to read hero image: ${e.message}', e);
    }
  }

  static String _heroExtension(String fileName) {
    final int dot = fileName.lastIndexOf('.');
    if (dot == -1) return 'png';
    return fileName.substring(dot + 1).toLowerCase();
  }

  Future<ExportCanvas?> _buildCollectionCanvas(int collectionId) async {
    final CanvasRepository repo = _canvasRepository!;
    final CanvasViewport? viewport = await repo.getViewport(collectionId);
    final List<CanvasItem> canvasItems = await repo.getItems(collectionId);
    final List<CanvasConnection> connections =
        await repo.getConnections(collectionId);

    if (viewport == null && canvasItems.isEmpty && connections.isEmpty) {
      return null;
    }

    return ExportCanvas(
      viewport: viewport?.toExport(),
      items: canvasItems
          .map((CanvasItem ci) => ci.toExport())
          .toList(),
      connections: connections
          .map((CanvasConnection cc) => cc.toExport())
          .toList(),
    );
  }

  Future<void> _attachPerItemCanvas(
    List<CollectionItem> items,
    List<Map<String, dynamic>> exportItems,
  ) async {
    final CanvasRepository repo = _canvasRepository!;
    for (int i = 0; i < items.length; i++) {
      final int collectionItemId = items[i].id;
      if (collectionItemId == 0) continue;

      final List<CanvasItem> gameCanvasItems =
          await repo.getGameCanvasItems(collectionItemId);

      if (gameCanvasItems.isEmpty) continue;

      final List<CanvasConnection> gameConnections =
          await repo.getGameCanvasConnections(collectionItemId);
      final CanvasViewport? gameViewport =
          await repo.getGameCanvasViewport(collectionItemId);

      final ExportCanvas perItemCanvas = ExportCanvas(
        viewport: gameViewport?.toExport(),
        items: gameCanvasItems
            .map((CanvasItem ci) => ci.toExport())
            .toList(),
        connections: gameConnections
            .map((CanvasConnection cc) => cc.toExport())
            .toList(),
      );

      exportItems[i]['_canvas'] = perItemCanvas.toJson();
    }
  }

  /// Attaches per-item marks (likes/notes) under the `_marks` key. Requires a
  /// database; no-op when unavailable. Only invoked for user-data exports.
  /// Fetches the exported items' marks in one query and groups by item to
  /// avoid an N+1.
  Future<void> _attachItemMarks(
    List<CollectionItem> items,
    List<Map<String, dynamic>> exportItems,
  ) async {
    final DatabaseService? db = _database;
    if (db == null) return;
    final List<ItemMark> allMarks = await db.itemMarkDao.getMarksForItems(
      <int>[for (final CollectionItem item in items) item.id],
    );
    if (allMarks.isEmpty) return;

    final Map<int, List<ItemMark>> byItem = <int, List<ItemMark>>{};
    for (final ItemMark m in allMarks) {
      (byItem[m.itemId] ??= <ItemMark>[]).add(m);
    }

    for (int i = 0; i < items.length; i++) {
      final List<ItemMark>? marks = byItem[items[i].id];
      if (marks == null || marks.isEmpty) continue;
      exportItems[i]['_marks'] =
          marks.map((ItemMark m) => m.toExport()).toList();
    }
  }

  /// Watch marks live in `watched_episodes`, not on the item — nest them
  /// under `_watched_episodes` so progress survives export/import.
  Future<void> _attachWatchedEpisodes(
    int collectionId,
    List<CollectionItem> items,
    List<Map<String, dynamic>> exportItems,
  ) async {
    final DatabaseService? db = _database;
    if (db == null) return;
    for (int i = 0; i < items.length; i++) {
      final CollectionItem item = items[i];
      if (!item.mediaType.isTvBacked) continue;
      // Resolve the source exactly like import will: parsed items carry no
      // joined show, so their dataSource collapses to the raw column.
      final DataSource source = item.source ?? DataSource.tmdb;
      final Map<(int, int), DateTime?> watched = await db.tvShowDao
          .getWatchedEpisodes(collectionId, source, item.externalId);
      if (watched.isEmpty) continue;
      exportItems[i]['_watched_episodes'] = <Map<String, dynamic>>[
        for (final MapEntry<(int, int), DateTime?> e in watched.entries)
          <String, dynamic>{
            'season': e.key.$1,
            'episode': e.key.$2,
            'watched_at': e.value != null
                ? e.value!.millisecondsSinceEpoch ~/ 1000
                : null,
          },
      ];
    }
  }

  /// Collects covers already present in the local cache (nothing is
  /// downloaded). Key is '{ImageType.folder}/{externalId}', value is base64.
  Future<Map<String, String>> _collectCachedImages(
    List<CollectionItem> items,
  ) async {
    final ImageCacheService cache = _imageCacheService!;
    final Map<String, String> images = <String, String>{};

    for (final CollectionItem item in items) {
      final ImageType imageType = item.imageType;
      final String imageId = item.coverImageId;
      final String key = '${imageType.folder}/$imageId';

      // Skip duplicates — the same externalId can appear more than once.
      if (images.containsKey(key)) continue;

      final Uint8List? bytes =
          await cache.readImageBytes(imageType, imageId);
      if (bytes != null) {
        images[key] = base64Encode(bytes);
      }
    }

    return images;
  }

  /// Collects cached canvas images: for [CanvasItemType.image] items with a
  /// URL, reads cached data by imageId = FNV-1a hash of the URL.
  Future<Map<String, String>> _collectCanvasImages(
    int collectionId,
    List<CollectionItem> items,
  ) async {
    final ImageCacheService cache = _imageCacheService!;
    final CanvasRepository repo = _canvasRepository!;
    final Map<String, String> images = <String, String>{};

    // Collection-level canvas items
    final List<CanvasItem> allCanvasItems =
        await repo.getItems(collectionId);

    // Per-item canvas items
    for (final CollectionItem item in items) {
      if (item.id == 0) continue;
      final List<CanvasItem> perItemItems =
          await repo.getGameCanvasItems(item.id);
      allCanvasItems.addAll(perItemItems);
    }

    // Collect images from image-type canvas items
    for (final CanvasItem canvasItem in allCanvasItems) {
      if (canvasItem.itemType != CanvasItemType.image) continue;

      final String? url = canvasItem.data?['url'] as String?;
      if (url == null || url.isEmpty) continue;

      final String imageId = _urlToImageId(url);
      final String key = '${ImageType.canvasImage.folder}/$imageId';

      if (images.containsKey(key)) continue;

      final Uint8List? bytes =
          await cache.readImageBytes(ImageType.canvasImage, imageId);
      if (bytes != null) {
        images[key] = base64Encode(bytes);
      }
    }

    return images;
  }

  /// FNV-1a 32-bit hash of the URL, used as imageId.
  /// Deterministic and platform-independent.
  static String _urlToImageId(String url) {
    int hash = 0x811c9dc5;
    for (int i = 0; i < url.length; i++) {
      hash ^= url.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Collects full Game/Movie/TvShow/TvSeason/TvEpisode data so that import
  /// can run offline without hitting the IGDB/TMDB APIs. Seasons and episodes
  /// come from the DB cache for every tvShow and animation-tvShow.
  Future<Map<String, dynamic>> _collectMediaData(
    List<CollectionItem> items,
  ) async {
    final Map<int, Map<String, dynamic>> games = <int, Map<String, dynamic>>{};
    final Map<int, Map<String, dynamic>> movies =
        <int, Map<String, dynamic>>{};
    // Keyed by `source:externalId` — show ids from different providers can
    // share a numeric id, like manga.
    final Map<String, Map<String, dynamic>> tvShows =
        <String, Map<String, dynamic>>{};
    final Map<int, Map<String, dynamic>> vns = <int, Map<String, dynamic>>{};
    // Keyed by `source:externalId` — AniList and MangaBaka can share a numeric
    // id, so an int key would drop one of them from the export.
    final Map<String, Map<String, dynamic>> mangas =
        <String, Map<String, dynamic>>{};
    // Keyed by `source:externalId` — OpenLibrary and Fantlab can share a
    // numeric id, like manga.
    final Map<String, Map<String, dynamic>> books =
        <String, Map<String, dynamic>>{};
    // Keyed by `source:externalId` — ids from different providers can collide.
    final Map<String, Map<String, dynamic>> animes =
        <String, Map<String, dynamic>>{};
    final Map<int, Map<String, dynamic>> customItems =
        <int, Map<String, dynamic>>{};
    final Set<(DataSource, int)> tvShowKeys = <(DataSource, int)>{};
    final Set<int> platformIds = <int>{};

    for (final CollectionItem item in items) {
      switch (item.mediaType) {
        case MediaType.game:
          if (item.game != null && !games.containsKey(item.externalId)) {
            final Map<String, dynamic> data = item.game!.toDb();
            data.remove('cached_at');
            games[item.externalId] = data;
            if (item.game!.platformIds != null) {
              platformIds.addAll(item.game!.platformIds!);
            }
          }
        case MediaType.movie:
          if (item.movie != null && !movies.containsKey(item.externalId)) {
            final Map<String, dynamic> data = item.movie!.toDb();
            data.remove('cached_at');
            movies[item.externalId] = data;
          }
        case MediaType.tvShow:
          final String tvKey =
              '${(item.source ?? DataSource.tmdb).name}:${item.externalId}';
          if (item.tvShow != null && !tvShows.containsKey(tvKey)) {
            final Map<String, dynamic> data = item.tvShow!.toDb();
            data.remove('cached_at');
            tvShows[tvKey] = data;
          }
          tvShowKeys.add((item.source ?? DataSource.tmdb, item.externalId));
        case MediaType.animation:
          if (item.platformId == AnimationSource.tvShow) {
            final String animKey =
                '${(item.source ?? DataSource.tmdb).name}:${item.externalId}';
            if (item.tvShow != null && !tvShows.containsKey(animKey)) {
              final Map<String, dynamic> data = item.tvShow!.toDb();
              data.remove('cached_at');
              tvShows[animKey] = data;
            }
            tvShowKeys.add((item.source ?? DataSource.tmdb, item.externalId));
          } else {
            if (item.movie != null && !movies.containsKey(item.externalId)) {
              final Map<String, dynamic> data = item.movie!.toDb();
              data.remove('cached_at');
              movies[item.externalId] = data;
            }
          }
        case MediaType.visualNovel:
          if (item.visualNovel != null &&
              !vns.containsKey(item.externalId)) {
            vns[item.externalId] = item.visualNovel!.toExport();
          }
        case MediaType.manga:
          final String mangaKey =
              '${(item.manga?.source ?? DataSource.anilist).name}:'
              '${item.externalId}';
          if (item.manga != null && !mangas.containsKey(mangaKey)) {
            mangas[mangaKey] = item.manga!.toExport();
          }
        case MediaType.book:
          final String bookKey =
              '${(item.book?.source ?? DataSource.openLibrary).name}:'
              '${item.externalId}';
          if (item.book != null && !books.containsKey(bookKey)) {
            books[bookKey] = item.book!.toExport();
          }
        case MediaType.anime:
          final String animeKey =
              '${(item.anime?.source ?? DataSource.anilist).name}:'
              '${item.externalId}';
          if (item.anime != null && !animes.containsKey(animeKey)) {
            animes[animeKey] = item.anime!.toExport();
          }
        case MediaType.custom:
          if (item.customMedia != null &&
              !customItems.containsKey(item.externalId)) {
            customItems[item.externalId] = item.customMedia!.toExport();
            // Custom games reference a platform from the catalog; export it
            // too so the target resolves the platform after import.
            final int? customPlatformId = item.customMedia!.platformId;
            if (customPlatformId != null) {
              platformIds.add(customPlatformId);
            }
          }
      }
    }

    // Seasons and episodes from the DB cache, fetched in parallel per showId.
    final List<Map<String, dynamic>> allSeasons = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> allEpisodes = <Map<String, dynamic>>[];
    if (_database != null && tvShowKeys.isNotEmpty) {
      for (final (DataSource source, int showId) in tvShowKeys) {
        final List<Object> results = await Future.wait(<Future<Object>>[
          _database.tvShowDao.getTvSeasonsByShowId(source, showId),
          _database.tvShowDao.getEpisodesByShowId(source, showId),
        ]);
        final List<TvSeason> seasons = results[0] as List<TvSeason>;
        final List<TvEpisode> episodes = results[1] as List<TvEpisode>;
        for (final TvSeason season in seasons) {
          allSeasons.add(season.toDb());
        }
        for (final TvEpisode episode in episodes) {
          final Map<String, dynamic> data = episode.toDb();
          data.remove('cached_at');
          allEpisodes.add(data);
        }
      }
    }

    final List<Map<String, dynamic>> allPlatforms = <Map<String, dynamic>>[];
    if (_database != null && platformIds.isNotEmpty) {
      final List<model.Platform> platforms =
          await _database.gameDao.getPlatformsByIds(platformIds.toList());
      for (final model.Platform platform in platforms) {
        allPlatforms.add(platform.toDb());
      }
    }

    if (games.isEmpty &&
        movies.isEmpty &&
        tvShows.isEmpty &&
        vns.isEmpty &&
        mangas.isEmpty &&
        books.isEmpty &&
        animes.isEmpty &&
        allSeasons.isEmpty &&
        allEpisodes.isEmpty &&
        allPlatforms.isEmpty) {
      return const <String, dynamic>{};
    }

    return <String, dynamic>{
      if (games.isNotEmpty) 'games': games.values.toList(),
      if (movies.isNotEmpty) 'movies': movies.values.toList(),
      if (tvShows.isNotEmpty) 'tv_shows': tvShows.values.toList(),
      if (allSeasons.isNotEmpty) 'tv_seasons': allSeasons,
      if (allEpisodes.isNotEmpty) 'tv_episodes': allEpisodes,
      if (allPlatforms.isNotEmpty) 'platforms': allPlatforms,
      if (vns.isNotEmpty) 'visual_novels': vns.values.toList(),
      if (mangas.isNotEmpty) 'mangas': mangas.values.toList(),
      if (books.isNotEmpty) 'books': books.values.toList(),
      if (animes.isNotEmpty) 'animes': animes.values.toList(),
      if (customItems.isNotEmpty)
        'custom_items': customItems.values.toList(),
    };
  }

  /// Exports a collection to a v2 light JSON string.
  /// For full export use [exportToJsonFull] (async).
  String exportToJson(
    Collection collection,
    List<CollectionItem> items,
  ) {
    final XcollFile xcoll = createLightExport(collection, items);
    return xcoll.toJsonString();
  }

  Future<String> exportToJsonFull(
    Collection collection,
    List<CollectionItem> items,
    int collectionId,
  ) async {
    final XcollFile xcoll =
        await createFullExport(collection, items, collectionId);
    return xcoll.toJsonString();
  }

  /// [format] selects the export mode:
  /// [ExportFormat.light] → `.xcoll` (metadata + item IDs),
  /// [ExportFormat.full] → `.xcollx` (+ canvas + images).
  Future<ExportResult> exportToFile(
    Collection collection,
    List<CollectionItem> items, {
    ExportFormat format = ExportFormat.light,
    bool includeUserData = false,
  }) async {
    try {
      final XcollFile xcoll;
      final String extension;

      if (format == ExportFormat.full) {
        xcoll = await createFullExport(
          collection,
          items,
          collection.id,
          includeUserData: includeUserData,
        );
        extension = 'xcollx';
      } else {
        xcoll = createLightExport(
          collection,
          items,
          includeUserData: includeUserData,
        );
        // Light export is synchronous and DB-free; attach marks here where a
        // database is available. xcoll.items is the same list built above.
        if (includeUserData) {
          await _attachItemMarks(items, xcoll.items);
        }
        extension = 'xcoll';
      }

      final String json = xcoll.toJsonString();
      final Uint8List jsonBytes = Uint8List.fromList(utf8.encode(json));
      final String suggestedName = _sanitizeFileName(collection.name);

      // On Android FileType.custom doesn't support custom extensions.
      final bool useAny = Platform.isAndroid || Platform.isIOS;
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Collection',
        fileName: '$suggestedName.$extension',
        type: useAny ? FileType.any : FileType.custom,
        allowedExtensions: useAny ? null : <String>[extension],
        bytes: jsonBytes,
      );

      if (outputPath == null) {
        return const ExportResult.cancelled();
      }

      // On Android/iOS file_picker writes the bytes via SAF;
      // on desktop the file must be written manually.
      if (!Platform.isAndroid && !Platform.isIOS) {
        final String finalPath = outputPath.endsWith('.$extension')
            ? outputPath
            : '$outputPath.$extension';

        final File file = File(finalPath);
        await file.writeAsString(json);

        return ExportResult.success(finalPath);
      }

      return ExportResult.success(outputPath);
    } on FileSystemException catch (e) {
      return ExportResult.failure('Failed to save file: ${e.message}');
    } catch (e) {
      _log.warning('Export failed', e);
      return ExportResult.failure('Export failed: $e');
    }
  }

  /// Collects tier lists bound to the collection. Entries are enriched with
  /// `external_id` and `media_type` so import can resolve them, since
  /// `collection_item_id` changes on import.
  Future<List<Map<String, dynamic>>?> _collectTierListData(
    int collectionId,
  ) async {
    final DatabaseService db = _database!;
    final List<TierList> lists =
        await db.tierListDao.getTierListsByCollection(collectionId);
    if (lists.isEmpty) return null;

    // Collection items for the id → (external_id, media_type) mapping.
    final List<CollectionItem> items =
        await db.collectionDao.getCollectionItems(collectionId);
    final Map<int, CollectionItem> itemsById = <int, CollectionItem>{
      for (final CollectionItem item in items) item.id: item,
    };

    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final TierList tl in lists) {
      final List<TierDefinition> defs =
          await db.tierListDao.getTierDefinitions(tl.id);
      final List<TierListEntry> entries =
          await db.tierListDao.getTierListEntries(tl.id);

      final List<Map<String, dynamic>> exportedEntries =
          <Map<String, dynamic>>[];
      for (final TierListEntry entry in entries) {
        final CollectionItem? item = itemsById[entry.collectionItemId];
        if (item == null) continue;
        final Map<String, dynamic> entryData = entry.toExport();
        entryData['external_id'] = item.externalId;
        entryData['media_type'] = item.mediaType.value;
        if (item.platformId != null) {
          entryData['platform_id'] = item.platformId;
        }
        // Without it, two same-id titles from different providers resolve to
        // one item on import and only one keeps its tier placement.
        if (item.source != null) {
          entryData['source'] = item.source!.name;
        }
        exportedEntries.add(entryData);
      }

      result.add(<String, dynamic>{
        'name': tl.name,
        'definitions':
            defs.map((TierDefinition d) => d.toExport()).toList(),
        'entries': exportedEntries,
      });
    }
    return result;
  }

  /// Collects the global tags used by [items] plus an item index → tag
  /// names mapping (display order).
  Future<_TagExportResult> _collectTagData(
    List<CollectionItem> items,
  ) async {
    final DatabaseService db = _database!;
    final List<Tag> allTags = await db.globalTagDao.getAll();
    final Map<int, List<int>> links = await db.globalTagDao
        .getTagIdsForItems(items.map((CollectionItem i) => i.id).toList());

    if (allTags.isEmpty || links.isEmpty) {
      return _TagExportResult(
        tags: null,
        itemTagNames: List<List<String>>.generate(
          items.length,
          (_) => const <String>[],
        ),
      );
    }

    final Set<int> usedIds = <int>{
      for (final List<int> ids in links.values) ...ids,
    };
    final List<Tag> usedTags =
        allTags.where((Tag t) => usedIds.contains(t.id)).toList();

    // tag_names keeps the item's display order — that's how the manual
    // per-item order survives export/import.
    final Map<int, String> nameById = <int, String>{
      for (final Tag tag in usedTags) tag.id: tag.name,
    };
    final List<List<String>> itemTagNames = items.map((CollectionItem item) {
      final List<int>? ids = links[item.id];
      if (ids == null || ids.isEmpty) return const <String>[];
      return <String>[
        for (final int id in ids)
          if (nameById[id] case final String name) name,
      ];
    }).toList();

    return _TagExportResult(
      tags: usedTags.map((Tag tag) => tag.toExport()).toList(),
      itemTagNames: itemTagNames,
    );
  }

  /// Collects tracker_game_data for the collection's games (single batch
  /// query).
  Future<List<Map<String, dynamic>>?> _collectTrackerData(
    List<CollectionItem> items,
  ) async {
    final List<int> gameIds = items
        .where((CollectionItem i) => i.mediaType == MediaType.game)
        .map((CollectionItem i) => i.externalId)
        .toList();
    if (gameIds.isEmpty) return null;
    final List<TrackerGameData> dataList =
        await _trackerDao!.getGameDataForGameIds(gameIds);
    if (dataList.isEmpty) return null;
    return dataList.map((TrackerGameData d) => d.toDb()).toList();
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .trim();
  }
}

class _TagExportResult {
  _TagExportResult({required this.tags, required this.itemTagNames});

  /// Tag export data; null when no item in the collection is tagged.
  final List<Map<String, dynamic>>? tags;

  /// Tag names per item (by index, display order); empty when untagged.
  final List<List<String>> itemTagNames;
}
