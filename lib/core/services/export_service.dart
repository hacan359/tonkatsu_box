import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/canvas_repository.dart';
import '../../shared/models/canvas_connection.dart';
import '../../shared/models/canvas_item.dart';
import '../../shared/models/canvas_viewport.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/platform.dart' as model;
import '../../shared/models/tv_episode.dart';
import '../../shared/models/tv_season.dart';
import '../database/database_service.dart';
import 'image_cache_service.dart';
import 'xcoll_file.dart';

/// Провайдер для сервиса экспорта.
final Provider<ExportService> exportServiceProvider =
    Provider<ExportService>((Ref ref) {
  return ExportService(
    canvasRepository: ref.watch(canvasRepositoryProvider),
    imageCacheService: ref.watch(imageCacheServiceProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

/// Результат экспорта.
class ExportResult {
  /// Создаёт экземпляр [ExportResult].
  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
  });

  /// Успешный результат.
  const ExportResult.success(String path)
      : success = true,
        filePath = path,
        error = null;

  /// Неуспешный результат.
  const ExportResult.failure(String message)
      : success = false,
        filePath = null,
        error = message;

  /// Отменённый экспорт.
  const ExportResult.cancelled()
      : success = false,
        filePath = null,
        error = null;

  /// Успешность операции.
  final bool success;

  /// Путь к сохранённому файлу.
  final String? filePath;

  /// Сообщение об ошибке.
  final String? error;

  /// Возвращает true, если экспорт был отменён.
  bool get isCancelled => !success && error == null;
}

/// Сервис для экспорта коллекций в .xcoll / .xcollx форматы.
class ExportService {
  /// Создаёт экземпляр [ExportService].
  ///
  /// [canvasRepository] нужен для full export (.xcollx) с canvas-данными.
  /// [imageCacheService] нужен для full export с обложками.
  /// [database] нужен для full export с данными сезонов.
  ExportService({
    CanvasRepository? canvasRepository,
    ImageCacheService? imageCacheService,
    DatabaseService? database,
  })  : _canvasRepository = canvasRepository,
        _imageCacheService = imageCacheService,
        _database = database;

  final CanvasRepository? _canvasRepository;
  final ImageCacheService? _imageCacheService;
  final DatabaseService? _database;

  // ==================== v2 Light (.xcoll) ====================

  /// Создаёт v2 light export (.xcoll).
  ///
  /// Включает все элементы коллекции (игры, фильмы, сериалы)
  /// через [CollectionItem.toExport].
  XcollFile createLightExport(
    Collection collection,
    List<CollectionItem> items,
  ) {
    final List<Map<String, dynamic>> exportItems =
        items.map((CollectionItem i) => i.toExport()).toList();

    return XcollFile(
      version: xcollFormatVersion,
      format: ExportFormat.light,
      name: collection.name,
      author: collection.author,
      created: collection.createdAt,
      items: exportItems,
    );
  }

  // ==================== v2 Full (.xcollx) ====================

  /// Создаёт v2 full export (.xcollx).
  ///
  /// Включает элементы, collection canvas, per-item canvas, images
  /// и полные медиа-данные (Game/Movie/TvShow) для офлайн-импорта.
  /// Требует [canvasRepository] для получения canvas-данных.
  Future<XcollFile> createFullExport(
    Collection collection,
    List<CollectionItem> items,
    int collectionId,
  ) async {
    final List<Map<String, dynamic>> exportItems =
        items.map((CollectionItem i) => i.toExport()).toList();

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

    // Collect full media data for offline import (includes tv_seasons)
    final Map<String, dynamic> media = await _collectMediaData(items);

    return XcollFile(
      version: xcollFormatVersion,
      format: ExportFormat.full,
      name: collection.name,
      author: collection.author,
      created: collection.createdAt,
      items: exportItems,
      canvas: canvas,
      images: images,
      media: media,
    );
  }

  /// Собирает canvas-данные коллекции (viewport, items, connections).
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

  /// Добавляет per-item canvas (_canvas) в соответствующие export items.
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

  // ==================== Cover Images ====================

  /// Собирает кэшированные обложки для всех элементов коллекции.
  ///
  /// Только те изображения, которые уже есть в локальном кэше.
  /// Ключ — '{ImageType.folder}/{externalId}', значение — base64.
  Future<Map<String, String>> _collectCachedImages(
    List<CollectionItem> items,
  ) async {
    final ImageCacheService cache = _imageCacheService!;
    final Map<String, String> images = <String, String>{};

    for (final CollectionItem item in items) {
      final ImageType imageType = item.imageType;
      final String imageId = item.externalId.toString();
      final String key = '${imageType.folder}/$imageId';

      // Пропускаем дубли (один externalId может встретиться несколько раз)
      if (images.containsKey(key)) continue;

      final Uint8List? bytes =
          await cache.readImageBytes(imageType, imageId);
      if (bytes != null) {
        images[key] = base64Encode(bytes);
      }
    }

    return images;
  }

  // ==================== Canvas Images ====================

  /// Собирает кэшированные изображения с канваса.
  ///
  /// Для canvas items типа [CanvasItemType.image] с URL,
  /// читает кэшированные данные по imageId = FNV-1a hash URL.
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

  /// Вычисляет FNV-1a 32-bit хэш URL для imageId.
  ///
  /// Детерминированный хэш, не зависит от платформы.
  static String _urlToImageId(String url) {
    int hash = 0x811c9dc5;
    for (int i = 0; i < url.length; i++) {
      hash ^= url.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  // ==================== Media Data ====================

  /// Собирает полные данные Game/Movie/TvShow/TvSeason/TvEpisode из элементов.
  ///
  /// Используется для офлайн-импорта: при наличии этих данных
  /// импорт не требует обращения к IGDB/TMDB API.
  /// Сезоны и эпизоды загружаются из кэша БД для всех tvShow и animation-tvShow.
  Future<Map<String, dynamic>> _collectMediaData(
    List<CollectionItem> items,
  ) async {
    final Map<int, Map<String, dynamic>> games = <int, Map<String, dynamic>>{};
    final Map<int, Map<String, dynamic>> movies =
        <int, Map<String, dynamic>>{};
    final Map<int, Map<String, dynamic>> tvShows =
        <int, Map<String, dynamic>>{};
    final Set<int> tvShowIds = <int>{};
    final Set<int> platformIds = <int>{};

    for (final CollectionItem item in items) {
      switch (item.mediaType) {
        case MediaType.game:
          if (item.game != null && !games.containsKey(item.externalId)) {
            final Map<String, dynamic> data = item.game!.toDb();
            data.remove('cached_at');
            games[item.externalId] = data;
            // Собираем platformIds для экспорта
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
          if (item.tvShow != null && !tvShows.containsKey(item.externalId)) {
            final Map<String, dynamic> data = item.tvShow!.toDb();
            data.remove('cached_at');
            tvShows[item.externalId] = data;
          }
          tvShowIds.add(item.externalId);
        case MediaType.animation:
          if (item.platformId == AnimationSource.tvShow) {
            if (item.tvShow != null && !tvShows.containsKey(item.externalId)) {
              final Map<String, dynamic> data = item.tvShow!.toDb();
              data.remove('cached_at');
              tvShows[item.externalId] = data;
            }
            tvShowIds.add(item.externalId);
          } else {
            if (item.movie != null && !movies.containsKey(item.externalId)) {
              final Map<String, dynamic> data = item.movie!.toDb();
              data.remove('cached_at');
              movies[item.externalId] = data;
            }
          }
      }
    }

    // Собираем сезоны и эпизоды из кэша БД (параллельно для каждого showId)
    final List<Map<String, dynamic>> allSeasons = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> allEpisodes = <Map<String, dynamic>>[];
    if (_database != null && tvShowIds.isNotEmpty) {
      for (final int showId in tvShowIds) {
        final List<Object> results = await Future.wait(<Future<Object>>[
          _database.getTvSeasonsByShowId(showId),
          _database.getEpisodesByShowId(showId),
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

    // Собираем платформы из кэша БД
    final List<Map<String, dynamic>> allPlatforms = <Map<String, dynamic>>[];
    if (_database != null && platformIds.isNotEmpty) {
      final List<model.Platform> platforms =
          await _database.getPlatformsByIds(platformIds.toList());
      for (final model.Platform platform in platforms) {
        allPlatforms.add(platform.toDb());
      }
    }

    if (games.isEmpty &&
        movies.isEmpty &&
        tvShows.isEmpty &&
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
    };
  }

  // ==================== Export API ====================

  /// Экспортирует коллекцию в v2 light JSON строку.
  ///
  /// Для full export используйте [exportToJsonFull] (async).
  String exportToJson(
    Collection collection,
    List<CollectionItem> items,
  ) {
    final XcollFile xcoll = createLightExport(collection, items);
    return xcoll.toJsonString();
  }

  /// Экспортирует коллекцию в JSON строку (async, для full export).
  Future<String> exportToJsonFull(
    Collection collection,
    List<CollectionItem> items,
    int collectionId,
  ) async {
    final XcollFile xcoll =
        await createFullExport(collection, items, collectionId);
    return xcoll.toJsonString();
  }

  /// Экспортирует коллекцию в файл.
  ///
  /// [format] определяет режим экспорта:
  /// - [ExportFormat.light] → `.xcoll` (метаданные + ID элементов)
  /// - [ExportFormat.full] → `.xcollx` (+ canvas + images)
  ///
  /// Открывает диалог выбора места сохранения.
  /// Возвращает [ExportResult] с результатом операции.
  Future<ExportResult> exportToFile(
    Collection collection,
    List<CollectionItem> items, {
    ExportFormat format = ExportFormat.light,
  }) async {
    try {
      final XcollFile xcoll;
      final String extension;

      if (format == ExportFormat.full) {
        xcoll = await createFullExport(collection, items, collection.id);
        extension = 'xcollx';
      } else {
        xcoll = createLightExport(collection, items);
        extension = 'xcoll';
      }

      final String json = xcoll.toJsonString();
      final Uint8List jsonBytes = Uint8List.fromList(utf8.encode(json));
      final String suggestedName = _sanitizeFileName(collection.name);

      // На Android FileType.custom не поддерживает кастомные расширения.
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

      // На Android/iOS file_picker записывает bytes через SAF.
      // На десктопе нужно записать файл самостоятельно.
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
      return ExportResult.failure('Export failed: $e');
    }
  }

  /// Очищает название файла от недопустимых символов.
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .trim();
  }
}
