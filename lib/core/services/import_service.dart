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
import '../../shared/models/platform.dart' as model;
import '../../shared/models/tv_episode.dart';
import '../../shared/models/tv_season.dart';
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

  /// Кэширование медиа-данных.
  cachingMedia('Caching media...'),

  /// Создание коллекции.
  creatingCollection('Creating collection...'),

  /// Добавление элементов.
  addingItems('Adding items...'),

  /// Импорт board (v2 full).
  importingCanvas('Importing board...'),

  /// Восстановление медиа-данных из экспорта (v2 full).
  restoringMedia('Restoring media data...'),

  /// Восстановление изображений из экспорта (v2 full).
  importingImages('Restoring images...'),

  /// Завершено.
  completed('Import completed');

  const ImportStage(this.description);

  /// Описание этапа.
  final String description;
}

/// Сервис для импорта коллекций из .xcoll / .xcollx файлов.
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
  Future<ImportResult> importFromXcoll(
    XcollFile xcoll, {
    ImportProgressCallback? onProgress,
  }) async {
    return _importV2(xcoll, onProgress: onProgress);
  }

  // ==================== v2 Import (.xcoll / .xcollx) ====================

  /// Импорт v2 файла (.xcoll / .xcollx).
  Future<ImportResult> _importV2(
    XcollFile xcoll, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      final bool hasEmbeddedMedia = xcoll.media.isNotEmpty;

      if (hasEmbeddedMedia) {
        // Восстановление медиа-данных из встроенных данных (офлайн)
        await _restoreEmbeddedMedia(xcoll.media, onProgress: onProgress);
      } else {
        // Загрузка медиа-данных из API (онлайн)
        await _fetchMediaFromApi(xcoll.items, onProgress: onProgress);
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
        type: CollectionType.own,
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
          message: 'Importing board...',
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
    } on IgdbApiException catch (e) {
      return ImportResult.failure(
          'Failed to fetch games from IGDB: ${e.message}');
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  // ==================== Media Restore (Embedded) ====================

  /// Восстанавливает медиа-данные из встроенной секции media (офлайн).
  ///
  /// Парсит Game/Movie/TvShow/TvSeason/TvEpisode из `media['games']`,
  /// `media['movies']`, `media['tv_shows']`, `media['tv_seasons']`,
  /// `media['tv_episodes']` через `fromDb()` и сохраняет в локальный кэш.
  Future<void> _restoreEmbeddedMedia(
    Map<String, dynamic> media, {
    ImportProgressCallback? onProgress,
  }) async {
    final List<dynamic> rawGames =
        media['games'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawMovies =
        media['movies'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawTvShows =
        media['tv_shows'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawSeasons =
        media['tv_seasons'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawEpisodes =
        media['tv_episodes'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawPlatforms =
        media['platforms'] as List<dynamic>? ?? <dynamic>[];

    final int total = rawGames.length +
        rawMovies.length +
        rawTvShows.length +
        rawSeasons.length +
        rawEpisodes.length +
        rawPlatforms.length;
    final int cachedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int current = 0;

    onProgress?.call(ImportProgress(
      stage: ImportStage.restoringMedia,
      current: 0,
      total: total,
      message: 'Restoring $total media entries...',
    ));

    // Восстановление игр
    if (rawGames.isNotEmpty) {
      final List<Game> games = <Game>[];
      for (final dynamic raw in rawGames) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        // Устанавливаем cached_at, если отсутствует
        if (!row.containsKey('cached_at') || row['cached_at'] == null) {
          row['cached_at'] = cachedAt;
        }
        games.add(Game.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertGames(games);
    }

    // Восстановление фильмов
    if (rawMovies.isNotEmpty) {
      final List<Movie> movies = <Movie>[];
      for (final dynamic raw in rawMovies) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        if (!row.containsKey('cached_at') || row['cached_at'] == null) {
          row['cached_at'] = cachedAt;
        }
        movies.add(Movie.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertMovies(movies);
    }

    // Восстановление сериалов
    if (rawTvShows.isNotEmpty) {
      final List<TvShow> tvShows = <TvShow>[];
      for (final dynamic raw in rawTvShows) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        if (!row.containsKey('cached_at') || row['cached_at'] == null) {
          row['cached_at'] = cachedAt;
        }
        tvShows.add(TvShow.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertTvShows(tvShows);
    }

    // Восстановление сезонов
    if (rawSeasons.isNotEmpty) {
      final List<TvSeason> seasons = <TvSeason>[];
      for (final dynamic raw in rawSeasons) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        seasons.add(TvSeason.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertTvSeasons(seasons);
    }

    // Восстановление эпизодов
    if (rawEpisodes.isNotEmpty) {
      final List<TvEpisode> episodes = <TvEpisode>[];
      for (final dynamic raw in rawEpisodes) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        if (!row.containsKey('cached_at') || row['cached_at'] == null) {
          row['cached_at'] = cachedAt;
        }
        episodes.add(TvEpisode.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertEpisodes(episodes);
    }

    // Восстановление платформ
    if (rawPlatforms.isNotEmpty) {
      final List<model.Platform> platforms = <model.Platform>[];
      for (final dynamic raw in rawPlatforms) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        platforms.add(model.Platform.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertPlatforms(platforms);
    }
  }

  // ==================== Media Fetch (API) ====================

  /// Загружает медиа-данные из API (IGDB/TMDB) и кэширует в БД.
  ///
  /// Используется при импорте файлов без встроенных медиа-данных
  /// (light export или старые full export без секции media).
  Future<void> _fetchMediaFromApi(
    List<Map<String, dynamic>> items, {
    ImportProgressCallback? onProgress,
  }) async {
    // Группируем элементы по типу медиа
    final List<Map<String, dynamic>> gameItems = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> movieItems = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> tvShowItems = <Map<String, dynamic>>[];

    for (final Map<String, dynamic> item in items) {
      final String mediaType = item['media_type'] as String;
      switch (mediaType) {
        case 'game':
          gameItems.add(item);
        case 'movie':
          movieItems.add(item);
        case 'tv_show':
          tvShowItems.add(item);
        case 'animation':
          final int? platformId = item['platform_id'] as int?;
          if (platformId == AnimationSource.tvShow) {
            tvShowItems.add(item);
          } else {
            movieItems.add(item);
          }
      }
    }

    // Загрузка игр из IGDB
    final List<int> gameIds = gameItems
        .map((Map<String, dynamic> i) => i['external_id'] as int)
        .toList();

    onProgress?.call(ImportProgress(
      stage: ImportStage.fetchingGames,
      current: 0,
      total: gameIds.length,
      message: 'Fetching ${gameIds.length} games from IGDB...',
    ));

    List<Game> games = <Game>[];
    if (gameIds.isNotEmpty) {
      games = await _igdbApi.getGamesByIds(gameIds);
    }

    // Загрузка фильмов из TMDB
    final List<int> movieIds = movieItems
        .map((Map<String, dynamic> i) => i['external_id'] as int)
        .toList();
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
    final List<int> tvShowIds = tvShowItems
        .map((Map<String, dynamic> i) => i['external_id'] as int)
        .toList();
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
