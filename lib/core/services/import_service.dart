import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/repositories/canvas_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../shared/models/canvas_connection.dart';
import '../../shared/models/canvas_item.dart';
import '../../shared/models/canvas_viewport.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/tier_definition.dart';
import '../../shared/models/tier_list.dart';
import '../../shared/models/game.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/platform.dart' as model;
import '../../shared/models/tv_episode.dart';
import '../../shared/models/tv_season.dart';
import '../../shared/models/tv_show.dart';
import '../../shared/models/manga.dart';
import '../../shared/models/visual_novel.dart';
import '../api/anilist_api.dart';
import '../api/igdb_api.dart';
import '../api/tmdb_api.dart';
import '../api/vndb_api.dart';
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
    vndbApi: ref.watch(vndbApiProvider),
    aniListApi: ref.watch(aniListApiProvider),
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
    this.itemsUpdated = 0,
    this.error,
  });

  /// Успешный результат.
  const ImportResult.success(Collection col, int items, {int updated = 0})
      : success = true,
        collection = col,
        itemsImported = items,
        itemsUpdated = updated,
        error = null;

  /// Неуспешный результат.
  const ImportResult.failure(String message)
      : success = false,
        collection = null,
        itemsImported = null,
        itemsUpdated = 0,
        error = message;

  /// Отменённый импорт.
  const ImportResult.cancelled()
      : success = false,
        collection = null,
        itemsImported = null,
        itemsUpdated = 0,
        error = null;

  /// Успешность операции.
  final bool success;

  /// Импортированная коллекция.
  final Collection? collection;

  /// Количество импортированных элементов.
  final int? itemsImported;

  /// Количество обновлённых элементов (дубликаты).
  final int itemsUpdated;

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

  /// Загрузка данных визуальных новелл из VNDB.
  fetchingVisualNovels('Fetching visual novel data...'),

  /// Загрузка данных манги из AniList.
  fetchingManga('Fetching manga data...'),

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
    VndbApi? vndbApi,
    AniListApi? aniListApi,
    CanvasRepository? canvasRepository,
    ImageCacheService? imageCacheService,
  })  : _repository = repository,
        _igdbApi = igdbApi,
        _tmdbApi = tmdbApi,
        _vndbApi = vndbApi,
        _aniListApi = aniListApi,
        _database = database,
        _canvasRepository = canvasRepository,
        _imageCacheService = imageCacheService;

  final CollectionRepository _repository;
  final IgdbApi _igdbApi;
  final TmdbApi? _tmdbApi;
  final VndbApi? _vndbApi;
  final AniListApi? _aniListApi;
  final DatabaseService _database;
  final CanvasRepository? _canvasRepository;
  final ImageCacheService? _imageCacheService;

  static final Logger _log = Logger('ImportService');

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
  /// [collectionId] — если указан, импортирует в существующую коллекцию
  /// с обновлением дублей. Если null — создаёт новую коллекцию.
  /// [onProgress] — callback для отслеживания прогресса.
  ///
  /// Возвращает [ImportResult] с результатом операции.
  Future<ImportResult> importFromFile({
    int? collectionId,
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

      return importFromXcoll(
        xcoll,
        collectionId: collectionId,
        onProgress: onProgress,
      );
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  /// Импортирует коллекцию из [XcollFile].
  ///
  /// [collectionId] — если указан, импортирует в существующую коллекцию.
  Future<ImportResult> importFromXcoll(
    XcollFile xcoll, {
    int? collectionId,
    ImportProgressCallback? onProgress,
  }) async {
    return _importV2(xcoll, collectionId: collectionId, onProgress: onProgress);
  }

  // ==================== v2 Import (.xcoll / .xcollx) ====================

  /// Импорт v2 файла (.xcoll / .xcollx).
  ///
  /// [collectionId] — если указан, импортирует в существующую коллекцию.
  Future<ImportResult> _importV2(
    XcollFile xcoll, {
    int? collectionId,
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

      // Создание или получение коллекции
      final Collection collection;
      if (collectionId != null) {
        final Collection? existing =
            await _repository.getById(collectionId);
        if (existing == null) {
          return ImportResult.failure(
            'Collection with id $collectionId not found',
          );
        }
        collection = existing;
      } else {
        onProgress?.call(const ImportProgress(
          stage: ImportStage.creatingCollection,
          current: 0,
          total: 1,
        ));

        collection = await _repository.create(
          name: xcoll.name,
          author: xcoll.author,
          type: CollectionType.own,
        );

        onProgress?.call(const ImportProgress(
          stage: ImportStage.creatingCollection,
          current: 1,
          total: 1,
        ));
      }

      // Добавление элементов в коллекцию
      // Маппинг (media_type:external_id) → new collection_item_id для тир-листов
      final Map<String, int> itemIdMapping = <String, int>{};
      int addedCount = 0;
      int updatedCount = 0;
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
          status: xcoll.includesUserData ? parsed.status : ItemStatus.notStarted,
        );

        if (itemId != null) {
          addedCount++;
          final String key =
              '${parsed.mediaType.value}:${parsed.externalId}';
          itemIdMapping[key] = itemId;

          // Восстановление пользовательских данных из файла
          if (xcoll.includesUserData && _hasUserData(parsed)) {
            await _restoreUserData(itemId, parsed);
          }

          // Импорт per-item canvas (для full export)
          final Map<String, dynamic>? perItemCanvas =
              itemData['_canvas'] as Map<String, dynamic>?;
          if (perItemCanvas != null && _canvasRepository != null) {
            await _importPerItemCanvas(
                perItemCanvas, itemId, collection.id);
          }
        } else if (collectionId != null) {
          // Элемент уже существует — обновляем данные из файла
          final bool didUpdate = await _updateExistingItem(
            collectionId: collection.id,
            parsed: parsed,
            includesUserData: xcoll.includesUserData,
          );
          if (didUpdate) {
            updatedCount++;
          }
          // Для тир-листов нужен ID существующего элемента
          final CollectionItem? existing = await _repository.findItem(
            collectionId: collection.id,
            mediaType: parsed.mediaType,
            externalId: parsed.externalId,
          );
          if (existing != null) {
            final String key =
                '${parsed.mediaType.value}:${parsed.externalId}';
            itemIdMapping[key] = existing.id;
          }
        }
      }

      // Canvas, images и tier lists — только для новых коллекций.
      // При импорте в существующую коллекцию пропускаем: canvas items
      // не имеют unique constraint и будут дублироваться.
      final bool isNewCollection = collectionId == null;

      // Импорт canvas (для full export, только новая коллекция)
      if (xcoll.isFull && _canvasRepository != null && isNewCollection) {
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

      // Восстановление тир-листов (для full export, только новая коллекция)
      if (xcoll.isFull &&
          xcoll.tierLists != null &&
          xcoll.tierLists!.isNotEmpty &&
          isNewCollection) {
        await _importTierLists(
          xcoll.tierLists!,
          collection.id,
          itemIdMapping,
        );
      }

      // Завершено
      onProgress?.call(ImportProgress(
        stage: ImportStage.completed,
        current: addedCount,
        total: xcoll.items.length,
        message: 'Imported $addedCount items',
      ));

      return ImportResult.success(collection, addedCount, updated: updatedCount);
    } on IgdbApiException catch (e) {
      return ImportResult.failure(
          'Failed to fetch games from IGDB: ${e.message}');
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  // ==================== Update Existing Item ====================

  /// Обновляет существующий элемент коллекции данными из файла импорта.
  ///
  /// Обновляет authorComment и userRating если они пустые в БД,
  /// но заданы в файле. При [includesUserData] = true также обновляет
  /// статус, даты, заметки и прогресс.
  /// Возвращает true если хотя бы одно поле обновлено.
  Future<bool> _updateExistingItem({
    required int collectionId,
    required CollectionItem parsed,
    bool includesUserData = false,
  }) async {
    final CollectionItem? existing = await _repository.findItem(
      collectionId: collectionId,
      mediaType: parsed.mediaType,
      externalId: parsed.externalId,
    );
    if (existing == null) return false;

    bool didUpdate = false;

    // Обновляем authorComment если локальный пуст, а в файле есть
    if (existing.authorComment == null &&
        parsed.authorComment != null &&
        parsed.authorComment!.isNotEmpty) {
      await _database.updateItemAuthorComment(
        existing.id,
        parsed.authorComment,
      );
      didUpdate = true;
    }

    // Обновляем userRating если локальный пуст, а в файле есть
    if (existing.userRating == null && parsed.userRating != null) {
      await _database.updateItemUserRating(existing.id, parsed.userRating);
      didUpdate = true;
    }

    // Обновляем пользовательские данные если файл их содержит
    if (includesUserData && _hasUserData(parsed)) {
      await _restoreUserData(existing.id, parsed);
      didUpdate = true;
    }

    return didUpdate;
  }

  /// Проверяет, содержит ли элемент хотя бы одно пользовательское поле.
  bool _hasUserData(CollectionItem parsed) {
    return parsed.status != ItemStatus.notStarted ||
        parsed.userComment != null ||
        parsed.userRating != null ||
        parsed.startedAt != null ||
        parsed.completedAt != null ||
        parsed.lastActivityAt != null ||
        parsed.currentSeason > 0 ||
        parsed.currentEpisode > 0;
  }

  /// Восстанавливает пользовательские данные элемента из файла импорта.
  ///
  /// Вызывается при импорте файла с user_data = true.
  /// Обновляет статус, заметки, рейтинг, даты активности и прогресс.
  Future<void> _restoreUserData(int itemId, CollectionItem parsed) async {
    if (parsed.status != ItemStatus.notStarted) {
      await _database.updateItemStatus(
        itemId,
        parsed.status,
        mediaType: parsed.mediaType,
      );
    }
    if (parsed.userComment != null) {
      await _database.updateItemUserComment(itemId, parsed.userComment);
    }
    if (parsed.userRating != null) {
      await _database.updateItemUserRating(itemId, parsed.userRating);
    }
    if (parsed.startedAt != null ||
        parsed.completedAt != null ||
        parsed.lastActivityAt != null) {
      await _database.updateItemActivityDates(
        itemId,
        startedAt: parsed.startedAt,
        completedAt: parsed.completedAt,
        lastActivityAt: parsed.lastActivityAt,
      );
    }
    if (parsed.currentSeason > 0 || parsed.currentEpisode > 0) {
      await _database.updateItemProgress(
        itemId,
        currentSeason: parsed.currentSeason,
        currentEpisode: parsed.currentEpisode,
      );
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
    final List<dynamic> rawVisualNovels =
        media['visual_novels'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawMangas =
        media['mangas'] as List<dynamic>? ?? <dynamic>[];

    final int total = rawGames.length +
        rawMovies.length +
        rawTvShows.length +
        rawSeasons.length +
        rawEpisodes.length +
        rawPlatforms.length +
        rawVisualNovels.length +
        rawMangas.length;
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

    // Восстановление визуальных новелл
    if (rawVisualNovels.isNotEmpty) {
      final List<VisualNovel> visualNovels = <VisualNovel>[];
      for (final dynamic raw in rawVisualNovels) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        if (!row.containsKey('updated_at') || row['updated_at'] == null) {
          row['updated_at'] = cachedAt;
        }
        visualNovels.add(VisualNovel.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertVisualNovels(visualNovels);
    }

    // Восстановление манги
    if (rawMangas.isNotEmpty) {
      final List<Manga> mangas = <Manga>[];
      for (final dynamic raw in rawMangas) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        if (!row.containsKey('cached_at') || row['cached_at'] == null) {
          row['cached_at'] = cachedAt;
        }
        mangas.add(Manga.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertMangas(mangas);
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
    final List<Map<String, dynamic>> vnItems = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> mangaItems = <Map<String, dynamic>>[];

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
        case 'visual_novel':
          vnItems.add(item);
        case 'manga':
          mangaItems.add(item);
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

    // Загрузка визуальных новелл из VNDB
    final List<String> vnIds = vnItems
        .where((Map<String, dynamic> i) => i['external_id'] != null)
        .map((Map<String, dynamic> i) => 'v${i['external_id'] as int}')
        .toList();
    List<VisualNovel> visualNovels = <VisualNovel>[];

    if (vnIds.isNotEmpty && _vndbApi != null) {
      final VndbApi vndbApi = _vndbApi;
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingVisualNovels,
        current: 0,
        total: vnIds.length,
        message: 'Fetching ${vnIds.length} visual novels from VNDB...',
      ));

      try {
        visualNovels = await vndbApi.getVnByIds(vnIds);
      } on VndbApiException catch (e) {
        _log.warning('Failed to fetch visual novels: ${e.message}');
      }
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingVisualNovels,
        current: vnIds.length,
        total: vnIds.length,
      ));
    }

    // Загрузка манги из AniList
    final List<int> mangaIds = mangaItems
        .where((Map<String, dynamic> i) => i['external_id'] != null)
        .map((Map<String, dynamic> i) => i['external_id'] as int)
        .toList();
    List<Manga> mangas = <Manga>[];

    if (mangaIds.isNotEmpty && _aniListApi != null) {
      final AniListApi aniListApi = _aniListApi;
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingManga,
        current: 0,
        total: mangaIds.length,
        message: 'Fetching ${mangaIds.length} manga from AniList...',
      ));

      try {
        mangas = await aniListApi.getMangaByIds(mangaIds);
      } on AniListApiException catch (e) {
        _log.warning('Failed to fetch manga: ${e.message}');
      }
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingManga,
        current: mangaIds.length,
        total: mangaIds.length,
      ));
    }

    // Кэширование медиа-данных
    final int totalMedia = games.length +
        movies.length +
        tvShows.length +
        visualNovels.length +
        mangas.length;
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

    if (visualNovels.isNotEmpty) {
      await _database.upsertVisualNovels(visualNovels);
      cachedCount += visualNovels.length;
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingMedia,
        current: cachedCount,
        total: totalMedia,
      ));
    }

    if (mangas.isNotEmpty) {
      await _database.upsertMangas(mangas);
      cachedCount += mangas.length;
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
      } catch (e) {
        _log.warning('Failed to restore image from base64: $imageId', e);
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

  // ==================== Tier Lists Import ====================

  /// Восстанавливает тир-листы из экспорта.
  ///
  /// [itemIdMapping] — маппинг 'media_type:external_id' → new collection_item_id.
  Future<void> _importTierLists(
    List<Map<String, dynamic>> tierListsData,
    int collectionId,
    Map<String, int> itemIdMapping,
  ) async {
    for (final Map<String, dynamic> tlData in tierListsData) {
      final String name = tlData['name'] as String? ?? 'Imported Tier List';

      // Создаём тир-лист привязанный к коллекции
      final TierList tierList = await _database.tierListDao.createTierList(
        name,
        collectionId: collectionId,
      );

      // Восстанавливаем определения тиров
      final List<dynamic>? rawDefs =
          tlData['definitions'] as List<dynamic>?;
      if (rawDefs != null && rawDefs.isNotEmpty) {
        final List<TierDefinition> defs = rawDefs
            .map((dynamic d) =>
                TierDefinition.fromExport(d as Map<String, dynamic>))
            .toList();
        await _database.tierListDao.saveTierDefinitions(tierList.id, defs);
      }

      // Восстанавливаем записи (entries)
      final List<dynamic>? rawEntries =
          tlData['entries'] as List<dynamic>?;
      if (rawEntries == null) continue;

      for (final dynamic entryRaw in rawEntries) {
        final Map<String, dynamic> entryData =
            entryRaw as Map<String, dynamic>;

        // Разрешаем collection_item_id через external_id + media_type
        final int? externalId = entryData['external_id'] as int?;
        final String? mediaType = entryData['media_type'] as String?;

        if (externalId == null || mediaType == null) continue;

        final String key = '$mediaType:$externalId';
        final int? newItemId = itemIdMapping[key];
        if (newItemId == null) continue;

        final String tierKey = entryData['tier_key'] as String;
        final int sortOrder = entryData['sort_order'] as int? ?? 0;

        await _database.tierListDao.setItemTier(
          tierList.id,
          newItemId,
          tierKey,
          sortOrder,
        );
      }
    }
  }
}
