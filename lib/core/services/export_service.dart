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
import 'image_cache_service.dart';
import 'xcoll_file.dart';

/// Провайдер для сервиса экспорта.
final Provider<ExportService> exportServiceProvider =
    Provider<ExportService>((Ref ref) {
  return ExportService(
    canvasRepository: ref.watch(canvasRepositoryProvider),
    imageCacheService: ref.watch(imageCacheServiceProvider),
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

/// Сервис для экспорта коллекций в .xcoll / .xcollx / .rcoll форматы.
class ExportService {
  /// Создаёт экземпляр [ExportService].
  ///
  /// [canvasRepository] нужен для full export (.xcollx) с canvas-данными.
  /// [imageCacheService] нужен для full export с обложками.
  ExportService({
    CanvasRepository? canvasRepository,
    ImageCacheService? imageCacheService,
  })  : _canvasRepository = canvasRepository,
        _imageCacheService = imageCacheService;

  final CanvasRepository? _canvasRepository;
  final ImageCacheService? _imageCacheService;

  // ==================== Legacy v1 (.rcoll) ====================

  /// Создаёт v1 .rcoll файл из коллекции (legacy).
  ///
  /// Фильтрует только игры (mediaType=game) для формата v1.
  XcollFile createXcollFile(
    Collection collection,
    List<CollectionItem> items,
  ) {
    final List<RcollGame> rcollGames = items
        .where((CollectionItem i) => i.mediaType == MediaType.game)
        .map((CollectionItem i) => RcollGame(
              igdbId: i.externalId,
              platformId: i.platformId ?? 0,
              comment: i.authorComment,
            ))
        .toList();

    return XcollFile(
      version: xcollLegacyVersion,
      name: collection.name,
      author: collection.author,
      created: collection.createdAt,
      legacyGames: rcollGames,
    );
  }

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
  /// Включает элементы, collection canvas, per-item canvas и images.
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
    Map<String, String> images = const <String, String>{};
    if (_imageCacheService != null) {
      images = await _collectCachedImages(items);
    }

    return XcollFile(
      version: xcollFormatVersion,
      format: ExportFormat.full,
      name: collection.name,
      author: collection.author,
      created: collection.createdAt,
      items: exportItems,
      canvas: canvas,
      images: images,
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
      final ImageType imageType = _imageTypeForMedia(item.mediaType);
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

  /// Маппинг MediaType → ImageType для обложек.
  ImageType _imageTypeForMedia(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.game:
        return ImageType.gameCover;
      case MediaType.movie:
        return ImageType.moviePoster;
      case MediaType.tvShow:
        return ImageType.tvShowPoster;
    }
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

  /// Экспортирует коллекцию в v1 .rcoll JSON строку (legacy).
  String exportToLegacyJson(
    Collection collection,
    List<CollectionItem> items,
  ) {
    final XcollFile rcoll = createXcollFile(collection, items);
    return rcoll.toJsonString();
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
      final String suggestedName = _sanitizeFileName(collection.name);

      // На Android FileType.custom не поддерживает кастомные расширения.
      final bool useAny = Platform.isAndroid;
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Collection',
        fileName: '$suggestedName.$extension',
        type: useAny ? FileType.any : FileType.custom,
        allowedExtensions: useAny ? null : <String>[extension],
      );

      if (outputPath == null) {
        return const ExportResult.cancelled();
      }

      final String finalPath = outputPath.endsWith('.$extension')
          ? outputPath
          : '$outputPath.$extension';

      final File file = File(finalPath);
      await file.writeAsString(json);

      return ExportResult.success(finalPath);
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
