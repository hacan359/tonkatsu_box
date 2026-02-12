import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/canvas_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../shared/models/canvas_connection.dart';
import '../../shared/models/canvas_item.dart';
import '../../shared/models/canvas_viewport.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/game.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/tv_show.dart';
import '../api/igdb_api.dart';
import '../api/tmdb_api.dart';
import '../database/database_service.dart';
import 'image_cache_service.dart';
import 'xcoll_file.dart';

/// Провайдер для сервиса импорта.
final Provider<ImportService> importServiceProvider =
    Provider<ImportService>((Ref ref) {
  return ImportService(
    repository: ref.watch(collectionRepositoryProvider),
    igdbApi: ref.watch(igdbApiProvider),
    tmdbApi: ref.watch(tmdbApiProvider),
    database: ref.watch(databaseServiceProvider),
    canvasRepository: ref.watch(canvasRepositoryProvider),
    imageCacheService: ref.watch(imageCacheServiceProvider),
  );
});

/// Результат импорта.
class ImportResult {
  /// Создаёт экземпляр [ImportResult].
  const ImportResult({
    required this.success,
    this.collection,
    this.itemsImported,
    this.error,
  });

  /// Успешный результат.
  const ImportResult.success(Collection col, int items)
      : success = true,
        collection = col,
        itemsImported = items,
        error = null;

  /// Неуспешный результат.
  const ImportResult.failure(String message)
      : success = false,
        collection = null,
        itemsImported = null,
        error = message;

  /// Отменённый импорт.
  const ImportResult.cancelled()
      : success = false,
        collection = null,
        itemsImported = null,
        error = null;

  /// Успешность операции.
  final bool success;

  /// Импортированная коллекция.
  final Collection? collection;

  /// Количество импортированных элементов.
  final int? itemsImported;

  /// Сообщение об ошибке.
  final String? error;

  /// Возвращает true, если импорт был отменён.
  bool get isCancelled => !success && error == null;
}

/// Callback для отслеживания прогресса импорта.
typedef ImportProgressCallback = void Function(ImportProgress progress);

/// Состояние прогресса импорта.
class ImportProgress {
  /// Создаёт экземпляр [ImportProgress].
  const ImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.message,
  });

  /// Текущий этап.
  final ImportStage stage;

  /// Текущий прогресс.
  final int current;

  /// Общее количество.
  final int total;

  /// Сообщение о статусе.
  final String? message;

  /// Возвращает процент выполнения (0.0-1.0).
  double get progress => total > 0 ? current / total : 0;
}

/// Этапы импорта.
enum ImportStage {
  /// Чтение файла.
  reading('Reading file...'),

  /// Загрузка данных игр из IGDB.
  fetchingGames('Fetching game data...'),

  /// Загрузка данных фильмов из TMDB.
  fetchingMovies('Fetching movie data...'),

  /// Загрузка данных сериалов из TMDB.
  fetchingTvShows('Fetching TV show data...'),

  /// Кэширование игр (v1).
  cachingGames('Caching games...'),

  /// Кэширование медиа-данных (v2).
  cachingMedia('Caching media...'),

  /// Создание коллекции.
  creatingCollection('Creating collection...'),

  /// Добавление игр (v1).
  addingGames('Adding games...'),

  /// Добавление элементов (v2).
  addingItems('Adding items...'),

  /// Импорт canvas (v2 full).
  importingCanvas('Importing canvas...'),

  /// Восстановление изображений из экспорта (v2 full).
  importingImages('Restoring images...'),

  /// Завершено.
  completed('Import completed');

  const ImportStage(this.description);

  /// Описание этапа.
  final String description;
}

/// Сервис для импорта коллекций из .xcoll / .xcollx / .rcoll файлов.
class ImportService {
  /// Создаёт экземпляр [ImportService].
  ImportService({
    required CollectionRepository repository,
    required IgdbApi igdbApi,
    required DatabaseService database,
    TmdbApi? tmdbApi,
    CanvasRepository? canvasRepository,
    ImageCacheService? imageCacheService,
  })  : _repository = repository,
        _igdbApi = igdbApi,
        _tmdbApi = tmdbApi,
        _database = database,
        _canvasRepository = canvasRepository,
        _imageCacheService = imageCacheService;

  final CollectionRepository _repository;
  final IgdbApi _igdbApi;
  final TmdbApi? _tmdbApi;
  final DatabaseService _database;
  final CanvasRepository? _canvasRepository;
  final ImageCacheService? _imageCacheService;

  /// Допустимые расширения для импорта коллекций.
  static const List<String> _allowedExtensions = <String>[
    'xcoll',
    'xcollx',
    'rcoll',
    'json',
  ];

  /// Открывает диалог выбора файла и парсит.
  ///
  /// Возвращает [XcollFile] или null если отменено.
  /// Throws [FormatException] если файл невалидный.
  Future<XcollFile?> pickAndParseFile() async {
    // На Android FileType.custom не фильтрует кастомные расширения.
    final bool useAny = Platform.isAndroid;
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Collection',
      type: useAny ? FileType.any : FileType.custom,
      allowedExtensions: useAny ? null : _allowedExtensions,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final String? filePath = result.files.first.path;
    if (filePath == null) {
      throw const FormatException('Could not read file path');
    }

    // На Android проверяем расширение вручную.
    if (useAny) {
      final String ext = filePath.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        throw FormatException(
          'Unsupported file type: .$ext. '
          'Expected: ${_allowedExtensions.join(', ')}',
        );
      }
    }

    return parseFile(File(filePath));
  }

  /// Парсит файл коллекции.
  ///
  /// Throws [FormatException] если файл невалидный.
  Future<XcollFile> parseFile(File file) async {
    if (!await file.exists()) {
      throw const FormatException('File does not exist');
    }

    final String content = await file.readAsString();
    return XcollFile.fromJsonString(content);
  }

  /// Импортирует коллекцию из файла.
  ///
  /// [onProgress] — callback для отслеживания прогресса.
  ///
  /// Возвращает [ImportResult] с результатом операции.
  Future<ImportResult> importFromFile({
    ImportProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(const ImportProgress(
        stage: ImportStage.reading,
        current: 0,
        total: 1,
      ));

      final XcollFile? xcoll = await pickAndParseFile();
      if (xcoll == null) {
        return const ImportResult.cancelled();
      }

      return importFromXcoll(xcoll, onProgress: onProgress);
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  /// Импортирует коллекцию из [XcollFile].
  ///
  /// Автоматически определяет версию (v1/v2) и вызывает
  /// соответствующий пайплайн.
  Future<ImportResult> importFromXcoll(
    XcollFile xcoll, {
    ImportProgressCallback? onProgress,
  }) async {
    if (xcoll.isV1) {
      return _importV1(xcoll, onProgress: onProgress);
    }
    return _importV2(xcoll, onProgress: onProgress);
  }

  // ==================== v1 Legacy Import (.rcoll) ====================

  /// Импорт v1 файла (legacy .rcoll).
  Future<ImportResult> _importV1(
    XcollFile xcoll, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      final List<int> gameIds = xcoll.gameIds;

      // Загрузка данных игр из IGDB
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingGames,
        current: 0,
        total: gameIds.length,
        message: 'Fetching ${gameIds.length} games from IGDB...',
      ));

      List<Game> games = <Game>[];
      if (gameIds.isNotEmpty) {
        try {
          games = await _igdbApi.getGamesByIds(gameIds);
        } on IgdbApiException catch (e) {
          return ImportResult.failure(
              'Failed to fetch games from IGDB: ${e.message}');
        }
      }

      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingGames,
        current: games.length,
        total: gameIds.length,
        message: 'Fetched ${games.length} games',
      ));

      // Кэширование игр
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingGames,
        current: 0,
        total: games.length,
      ));

      for (int i = 0; i < games.length; i++) {
        await _database.upsertGame(games[i]);
        onProgress?.call(ImportProgress(
          stage: ImportStage.cachingGames,
          current: i + 1,
          total: games.length,
        ));
      }

      // Создание коллекции
      onProgress?.call(const ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 0,
        total: 1,
      ));

      final Collection collection = await _repository.create(
        name: xcoll.name,
        author: xcoll.author,
        type: CollectionType.imported,
      );

      onProgress?.call(const ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 1,
        total: 1,
      ));

      // Добавление игр в коллекцию
      int addedCount = 0;
      for (int i = 0; i < xcoll.legacyGames.length; i++) {
        final RcollGame rcollGame = xcoll.legacyGames[i];

        onProgress?.call(ImportProgress(
          stage: ImportStage.addingGames,
          current: i,
          total: xcoll.legacyGames.length,
        ));

        final int? gameId = await _repository.addItem(
          collectionId: collection.id,
          mediaType: MediaType.game,
          externalId: rcollGame.igdbId,
          platformId: rcollGame.platformId,
          authorComment: rcollGame.comment,
        );

        if (gameId != null) {
          addedCount++;
        }
      }

      // Завершено
      onProgress?.call(ImportProgress(
        stage: ImportStage.completed,
        current: addedCount,
        total: xcoll.legacyGames.length,
        message: 'Imported $addedCount games',
      ));

      return ImportResult.success(collection, addedCount);
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  // ==================== v2 Import (.xcoll / .xcollx) ====================

  /// Импорт v2 файла (.xcoll / .xcollx).
  Future<ImportResult> _importV2(
    XcollFile xcoll, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      // Группируем элементы по типу медиа
      final List<Map<String, dynamic>> gameItems = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> movieItems = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> tvShowItems = <Map<String, dynamic>>[];

      for (final Map<String, dynamic> item in xcoll.items) {
        final String mediaType = item['media_type'] as String;
        switch (mediaType) {
          case 'game':
            gameItems.add(item);
          case 'movie':
            movieItems.add(item);
          case 'tv_show':
            tvShowItems.add(item);
        }
      }

      // Загрузка игр из IGDB
      final List<int> gameIds =
          gameItems.map((Map<String, dynamic> i) => i['external_id'] as int).toList();

      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingGames,
        current: 0,
        total: gameIds.length,
        message: 'Fetching ${gameIds.length} games from IGDB...',
      ));

      List<Game> games = <Game>[];
      if (gameIds.isNotEmpty) {
        try {
          games = await _igdbApi.getGamesByIds(gameIds);
        } on IgdbApiException catch (e) {
          return ImportResult.failure(
              'Failed to fetch games from IGDB: ${e.message}');
        }
      }

      // Загрузка фильмов из TMDB
      final List<int> movieIds =
          movieItems.map((Map<String, dynamic> i) => i['external_id'] as int).toList();
      final List<Movie> movies = <Movie>[];

      if (movieIds.isNotEmpty && _tmdbApi != null) {
        final TmdbApi tmdbApi = _tmdbApi;
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingMovies,
          current: 0,
          total: movieIds.length,
          message: 'Fetching ${movieIds.length} movies from TMDB...',
        ));

        for (int i = 0; i < movieIds.length; i++) {
          try {
            final Movie? movie = await tmdbApi.getMovie(movieIds[i]);
            if (movie != null) {
              movies.add(movie);
            }
          } on TmdbApiException {
            // Пропускаем недоступные фильмы
          }
          onProgress?.call(ImportProgress(
            stage: ImportStage.fetchingMovies,
            current: i + 1,
            total: movieIds.length,
          ));
        }
      }

      // Загрузка сериалов из TMDB
      final List<int> tvShowIds =
          tvShowItems.map((Map<String, dynamic> i) => i['external_id'] as int).toList();
      final List<TvShow> tvShows = <TvShow>[];

      if (tvShowIds.isNotEmpty && _tmdbApi != null) {
        final TmdbApi tmdbApi = _tmdbApi;
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingTvShows,
          current: 0,
          total: tvShowIds.length,
          message: 'Fetching ${tvShowIds.length} TV shows from TMDB...',
        ));

        for (int i = 0; i < tvShowIds.length; i++) {
          try {
            final TvShow? tvShow = await tmdbApi.getTvShow(tvShowIds[i]);
            if (tvShow != null) {
              tvShows.add(tvShow);
            }
          } on TmdbApiException {
            // Пропускаем недоступные сериалы
          }
          onProgress?.call(ImportProgress(
            stage: ImportStage.fetchingTvShows,
            current: i + 1,
            total: tvShowIds.length,
          ));
        }
      }

      // Кэширование медиа-данных
      final int totalMedia = games.length + movies.length + tvShows.length;
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingMedia,
        current: 0,
        total: totalMedia,
      ));

      int cachedCount = 0;
      for (final Game game in games) {
        await _database.upsertGame(game);
        cachedCount++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.cachingMedia,
          current: cachedCount,
          total: totalMedia,
        ));
      }

      if (movies.isNotEmpty) {
        await _database.upsertMovies(movies);
        cachedCount += movies.length;
        onProgress?.call(ImportProgress(
          stage: ImportStage.cachingMedia,
          current: cachedCount,
          total: totalMedia,
        ));
      }

      if (tvShows.isNotEmpty) {
        await _database.upsertTvShows(tvShows);
        cachedCount += tvShows.length;
        onProgress?.call(ImportProgress(
          stage: ImportStage.cachingMedia,
          current: cachedCount,
          total: totalMedia,
        ));
      }

      // Создание коллекции
      onProgress?.call(const ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 0,
        total: 1,
      ));

      final Collection collection = await _repository.create(
        name: xcoll.name,
        author: xcoll.author,
        type: CollectionType.imported,
      );

      onProgress?.call(const ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 1,
        total: 1,
      ));

      // Добавление элементов в коллекцию
      int addedCount = 0;
      for (int i = 0; i < xcoll.items.length; i++) {
        final Map<String, dynamic> itemData = xcoll.items[i];

        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: i,
          total: xcoll.items.length,
        ));

        final CollectionItem parsed = CollectionItem.fromExport(itemData);

        final int? itemId = await _repository.addItem(
          collectionId: collection.id,
          mediaType: parsed.mediaType,
          externalId: parsed.externalId,
          platformId: parsed.platformId,
          authorComment: parsed.authorComment,
          status: parsed.status,
        );

        if (itemId != null) {
          addedCount++;

          // Импорт per-item canvas (для full export)
          final Map<String, dynamic>? perItemCanvas =
              itemData['_canvas'] as Map<String, dynamic>?;
          if (perItemCanvas != null && _canvasRepository != null) {
            await _importPerItemCanvas(
                perItemCanvas, itemId, collection.id);
          }
        }
      }

      // Импорт canvas (для full export)
      if (xcoll.isFull && _canvasRepository != null) {
        onProgress?.call(const ImportProgress(
          stage: ImportStage.importingCanvas,
          current: 0,
          total: 1,
          message: 'Importing canvas...',
        ));

        await _importCanvas(xcoll, collection.id);

        onProgress?.call(const ImportProgress(
          stage: ImportStage.importingCanvas,
          current: 1,
          total: 1,
        ));
      }

      // Восстановление изображений (для full export)
      if (xcoll.isFull &&
          xcoll.images.isNotEmpty &&
          _imageCacheService != null) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.importingImages,
          current: 0,
          total: xcoll.images.length,
          message: 'Restoring cover images...',
        ));

        await _restoreImages(xcoll.images, onProgress: onProgress);
      }

      // Завершено
      onProgress?.call(ImportProgress(
        stage: ImportStage.completed,
        current: addedCount,
        total: xcoll.items.length,
        message: 'Imported $addedCount items',
      ));

      return ImportResult.success(collection, addedCount);
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  // ==================== Image Restore ====================

  /// Восстанавливает base64-изображения обложек в локальный кэш.
  ///
  /// Ключи имеют формат '{ImageType.folder}/{imageId}'.
  Future<int> _restoreImages(
    Map<String, String> images, {
    ImportProgressCallback? onProgress,
  }) async {
    final ImageCacheService cache = _imageCacheService!;
    int restored = 0;
    int current = 0;

    for (final MapEntry<String, String> entry in images.entries) {
      current++;
      onProgress?.call(ImportProgress(
        stage: ImportStage.importingImages,
        current: current,
        total: images.length,
        message: 'Restoring image $current of ${images.length}',
      ));

      final List<String> parts = entry.key.split('/');
      if (parts.length != 2) continue;

      final String folder = parts[0];
      final String imageId = parts[1];

      final ImageType? imageType = _imageTypeFromFolder(folder);
      if (imageType == null) continue;

      try {
        final Uint8List bytes = base64Decode(entry.value);
        final bool success =
            await cache.saveImageBytes(imageType, imageId, bytes);
        if (success) restored++;
      } catch (_) {
        // Пропускаем невалидный base64
      }
    }

    return restored;
  }

  /// Возвращает [ImageType] по имени папки кэша.
  ImageType? _imageTypeFromFolder(String folder) {
    for (final ImageType type in ImageType.values) {
      if (type.folder == folder) {
        return type;
      }
    }
    return null;
  }

  // ==================== Canvas Import ====================

  /// Импортирует canvas из XcollFile в коллекцию.
  ///
  /// Создаёт canvas items и connections с ID-ремаппингом.
  Future<void> _importCanvas(XcollFile xcoll, int collectionId) async {
    final CanvasRepository repo = _canvasRepository!;

    if (xcoll.canvas == null) return;

    final ExportCanvas canvas = xcoll.canvas!;

    // Импорт viewport
    if (canvas.viewport != null) {
      final CanvasViewport viewport = CanvasViewport.fromExport(
        canvas.viewport!,
        collectionId: collectionId,
      );
      await repo.saveViewport(viewport);
    }

    // Импорт canvas items с ID-ремаппингом
    final Map<int, int> idRemap = <int, int>{};

    for (final Map<String, dynamic> itemData in canvas.items) {
      final int exportId = itemData['id'] as int? ?? 0;

      final CanvasItem item = CanvasItem.fromExport(
        itemData,
        collectionId: collectionId,
      ).copyWith(id: 0); // Сброс ID для автоинкремента

      final CanvasItem created = await repo.createItem(item);
      if (exportId != 0) {
        idRemap[exportId] = created.id;
      }
    }

    // Импорт connections с ремаппингом ID
    for (final Map<String, dynamic> connData in canvas.connections) {
      final int exportFromId = connData['from_item_id'] as int;
      final int exportToId = connData['to_item_id'] as int;

      final int? newFromId = idRemap[exportFromId];
      final int? newToId = idRemap[exportToId];

      // Пропускаем connection если не можем сделать ремаппинг
      if (newFromId == null || newToId == null) continue;

      final CanvasConnection conn = CanvasConnection.fromExport(
        connData,
        collectionId: collectionId,
      ).copyWith(
        id: 0,
        fromItemId: newFromId,
        toItemId: newToId,
      );

      await repo.createConnection(conn);
    }
  }

  /// Импортирует per-item canvas для элемента коллекции.
  ///
  /// Аналогичен [_importCanvas], но сохраняет данные с привязкой
  /// к конкретному элементу коллекции (collectionItemId).
  Future<void> _importPerItemCanvas(
    Map<String, dynamic> canvasData,
    int collectionItemId,
    int collectionId,
  ) async {
    final CanvasRepository repo = _canvasRepository!;
    final ExportCanvas canvas = ExportCanvas.fromJson(canvasData);

    // Viewport (для game canvas collectionId = collectionItemId)
    if (canvas.viewport != null) {
      final CanvasViewport viewport = CanvasViewport.fromExport(
        canvas.viewport!,
        collectionId: collectionItemId,
      );
      await repo.saveGameCanvasViewport(collectionItemId, viewport);
    }

    // Canvas items с ID-ремаппингом
    final Map<int, int> idRemap = <int, int>{};

    for (final Map<String, dynamic> itemData in canvas.items) {
      final int exportId = itemData['id'] as int? ?? 0;

      final CanvasItem item = CanvasItem.fromExport(
        itemData,
        collectionId: collectionId,
      ).copyWith(id: 0, collectionItemId: collectionItemId);

      final CanvasItem created = await repo.createItem(item);
      if (exportId != 0) {
        idRemap[exportId] = created.id;
      }
    }

    // Connections с ремаппингом ID
    for (final Map<String, dynamic> connData in canvas.connections) {
      final int exportFromId = connData['from_item_id'] as int;
      final int exportToId = connData['to_item_id'] as int;

      final int? newFromId = idRemap[exportFromId];
      final int? newToId = idRemap[exportToId];

      // Пропускаем connection если не можем сделать ремаппинг
      if (newFromId == null || newToId == null) continue;

      final CanvasConnection conn = CanvasConnection.fromExport(
        connData,
        collectionId: collectionId,
      ).copyWith(
        id: 0,
        collectionItemId: collectionItemId,
        fromItemId: newFromId,
        toItemId: newToId,
      );

      await repo.createConnection(conn);
    }
  }
}
