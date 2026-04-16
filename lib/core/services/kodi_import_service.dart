// Сервис импорта библиотеки Kodi → TMDB фильмы.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/kodi_movie.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/universal_import_result.dart';
import '../api/kodi_api.dart';
import '../api/tmdb_api.dart';
import '../database/database_service.dart';

// ---------------------------------------------------------------------------
// Публичные модели
// ---------------------------------------------------------------------------

/// Этап импорта Kodi.
enum KodiImportStage {
  /// Загрузка библиотеки из Kodi.
  fetchingLibrary,

  /// Матчинг и импорт фильмов.
  matchingMovies,

  /// Импорт завершён.
  completed,
}

/// Прогресс импорта Kodi.
class KodiImportProgress {
  /// Создаёт [KodiImportProgress].
  const KodiImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.currentName,
    this.importedCount = 0,
    this.updatedCount = 0,
    this.unmatchedCount = 0,
    this.collectionsCreated = 0,
  });

  /// Текущий этап.
  final KodiImportStage stage;

  /// Текущий прогресс.
  final int current;

  /// Общее количество.
  final int total;

  /// Название текущего обрабатываемого фильма.
  final String? currentName;

  /// Количество импортированных.
  final int importedCount;

  /// Количество обновлённых (дубликаты).
  final int updatedCount;

  /// Количество не сматченных с TMDB.
  final int unmatchedCount;

  /// Количество созданных подколлекций (из sets).
  final int collectionsCreated;

  /// Прогресс в долях (0.0 – 1.0).
  double get progress => total > 0 ? current / total : 0;
}

/// Результат импорта Kodi.
class KodiImportResult {
  /// Создаёт [KodiImportResult].
  const KodiImportResult({
    required this.imported,
    required this.updated,
    required this.unmatched,
    required this.total,
    required this.collectionId,
    this.collectionsCreated = 0,
    this.errors = const <String>[],
  });

  /// Количество импортированных.
  final int imported;

  /// Количество обновлённых.
  final int updated;

  /// Количество не сматченных с TMDB.
  final int unmatched;

  /// Общее количество фильмов в библиотеке Kodi.
  final int total;

  /// ID основной коллекции.
  final int collectionId;

  /// Количество созданных подколлекций (из sets).
  final int collectionsCreated;

  /// Ошибки по отдельным фильмам.
  final List<String> errors;
}

// ---------------------------------------------------------------------------
// Провайдер
// ---------------------------------------------------------------------------

/// Провайдер для [KodiImportService].
final Provider<KodiImportService> kodiImportServiceProvider =
    Provider<KodiImportService>((Ref ref) {
  return KodiImportService(
    kodiApi: ref.watch(kodiApiProvider),
    tmdbApi: ref.watch(tmdbApiProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Сервис
// ---------------------------------------------------------------------------

/// Сервис импорта библиотеки Kodi в коллекцию фильмов.
///
/// Загружает все фильмы из Kodi, матчит по TMDB, создаёт items
/// в целевой коллекции. Опционально создаёт подколлекции из Kodi sets.
class KodiImportService {
  /// Создаёт [KodiImportService].
  KodiImportService({
    required KodiApi kodiApi,
    required TmdbApi tmdbApi,
    required DatabaseService database,
  })  : _kodiApi = kodiApi,
        _tmdbApi = tmdbApi,
        _db = database;

  static final Logger _log = Logger('KodiImportService');

  final KodiApi _kodiApi;
  final TmdbApi _tmdbApi;
  final DatabaseService _db;

  /// Импортирует библиотеку фильмов из Kodi.
  ///
  /// [collectionId] — ID существующей коллекции (если выбрана).
  /// [createCollection] — callback для создания новой коллекции.
  /// [createSubCollections] — создавать подколлекции из Kodi sets.
  /// [importRatings] — копировать userrating из Kodi.
  /// [onProgress] — callback прогресса.
  Future<KodiImportResult> importLibrary({
    int? collectionId,
    Future<int> Function()? createCollection,
    required bool createSubCollections,
    required bool importRatings,
    required void Function(KodiImportProgress) onProgress,
  }) async {
    if (collectionId == null && createCollection == null) {
      throw ArgumentError(
        'Either collectionId or createCollection must be provided',
      );
    }

    // 1. Загрузить все фильмы из Kodi (с пагинацией).
    onProgress(const KodiImportProgress(
      stage: KodiImportStage.fetchingLibrary,
      current: 0,
      total: 0,
    ));

    final List<KodiMovie> movies = await _fetchAllMovies();

    if (movies.isEmpty) {
      throw const KodiApiException('No movies found in Kodi library');
    }

    _log.info('Fetched ${movies.length} movies from Kodi');

    // 2. Создание коллекции (если нужно) — только после успешной загрузки.
    final int targetCollectionId =
        collectionId ?? await createCollection!();

    // 3. Обработка каждого фильма.
    onProgress(KodiImportProgress(
      stage: KodiImportStage.matchingMovies,
      current: 0,
      total: movies.length,
    ));

    int imported = 0;
    int updated = 0;
    int unmatched = 0;
    int collectionsCreated = 0;
    final List<String> errors = <String>[];

    // Кэш set → collectionId для подколлекций.
    final Map<String, int> setCollectionIds = <String, int>{};

    for (int i = 0; i < movies.length; i++) {
      final KodiMovie movie = movies[i];

      onProgress(KodiImportProgress(
        stage: KodiImportStage.matchingMovies,
        current: i + 1,
        total: movies.length,
        currentName: movie.title,
        importedCount: imported,
        updatedCount: updated,
        unmatchedCount: unmatched,
        collectionsCreated: collectionsCreated,
      ));

      try {
        // Матчинг с TMDB.
        final int? tmdbId = await _resolveTmdbId(movie);

        if (tmdbId == null) {
          unmatched++;
          _kodiApi.addLog('import', 'warn',
              'Unmatched: ${movie.title} (${movie.year})');
          continue;
        }

        // Подтянуть полные данные из TMDB и закэшировать.
        final Movie? tmdbMovie = await _tmdbApi.getMovie(tmdbId);
        if (tmdbMovie != null) {
          await _db.upsertMovie(tmdbMovie);
        }

        // Определить целевую коллекцию (основная или sub-collection из set).
        final int itemCollectionId;
        if (createSubCollections && movie.set != null) {
          itemCollectionId = await _getOrCreateSetCollection(
            setName: movie.set!,
            cache: setCollectionIds,
            onCreated: () => collectionsCreated++,
          );
        } else {
          itemCollectionId = targetCollectionId;
        }

        // Проверка дубликата.
        final CollectionItem? existing = await _db.findCollectionItem(
          collectionId: itemCollectionId,
          mediaType: MediaType.movie,
          externalId: tmdbId,
        );

        if (existing != null) {
          await _updateExistingItem(existing, movie, importRatings);
          _kodiApi.addLog('import', 'info',
              'Updated: ${movie.title} (rating=${movie.userRating}, '
              'playcount=${movie.playcount})');
          updated++;
          continue;
        }

        // Определить статус.
        final ItemStatus status = _resolveStatus(movie);

        // Добавить в коллекцию.
        final int? itemId = await _db.addItemToCollection(
          collectionId: itemCollectionId,
          mediaType: MediaType.movie,
          externalId: tmdbId,
          status: status,
        );

        // Мета в комментарий + даты.
        if (itemId != null) {
          final String comment = _buildComment(movie);
          if (comment.isNotEmpty) {
            await _db.updateItemUserComment(itemId, comment);
          }

          if (importRatings && movie.userRating != null) {
            await _db.updateItemUserRating(itemId, movie.userRating);
            _kodiApi.addLog('import', 'info',
                '  Rating set: ${movie.userRating}/10');
          }

          if (movie.lastPlayed != null) {
            await _db.updateItemActivityDates(
              itemId,
              lastActivityAt: movie.lastPlayed,
            );
          }
        }

        _kodiApi.addLog('import', 'info',
            'Added: ${movie.title} → $status '
            '(collection=$itemCollectionId)');

        imported++;
      } on Exception catch (e) {
        errors.add('${movie.title}: $e');
        _log.warning('Error importing ${movie.title}', e);
      }
    }

    _log.info('Kodi import complete: $imported imported, '
        '$updated updated, $unmatched unmatched, '
        '$collectionsCreated sub-collections');

    onProgress(KodiImportProgress(
      stage: KodiImportStage.completed,
      current: movies.length,
      total: movies.length,
      importedCount: imported,
      updatedCount: updated,
      unmatchedCount: unmatched,
      collectionsCreated: collectionsCreated,
    ));

    return KodiImportResult(
      imported: imported,
      updated: updated,
      unmatched: unmatched,
      total: movies.length,
      collectionId: targetCollectionId,
      collectionsCreated: collectionsCreated,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Загружает все фильмы из Kodi с пагинацией.
  Future<List<KodiMovie>> _fetchAllMovies() async {
    final List<KodiMovie> all = <KodiMovie>[];
    int start = 0;
    const int pageSize = 200;

    while (true) {
      final List<KodiMovie> page = await _kodiApi.getMovies(
        start: start,
        end: start + pageSize,
      );
      all.addAll(page);
      if (page.length < pageSize) break;
      start += pageSize;
    }

    return all;
  }

  /// Определяет TMDB ID по uniqueIds Kodi-фильма.
  Future<int?> _resolveTmdbId(KodiMovie movie) async {
    // 1. Прямой TMDB ID.
    if (movie.uniqueIds.tmdbId != null) return movie.uniqueIds.tmdbId;

    // 2. Через IMDB ID.
    if (movie.uniqueIds.imdbId != null) {
      try {
        final TmdbFindResult result =
            await _tmdbApi.findByImdbId(movie.uniqueIds.imdbId!);
        if (result.movies.isNotEmpty) return result.movies.first.tmdbId;
      } on TmdbApiException catch (e) {
        _log.fine('TMDB findByImdbId failed for ${movie.title}: $e');
      }
    }

    return null;
  }

  /// Определяет статус элемента из Kodi-данных.
  ItemStatus _resolveStatus(KodiMovie movie) {
    if (movie.playcount > 0) return ItemStatus.completed;
    if (movie.lastPlayed != null) return ItemStatus.inProgress;
    return ItemStatus.planned;
  }

  /// Строит комментарий из метаданных Kodi.
  String _buildComment(KodiMovie movie) {
    final List<String> parts = <String>[];

    if (movie.playcount > 1) {
      parts.add('Watched ${movie.playcount} times');
    }
    if (movie.lastPlayed != null) {
      final String date = movie.lastPlayed!.toIso8601String().split('T').first;
      parts.add('Last played: $date');
    }
    if (movie.dateAdded != null) {
      final String date = movie.dateAdded!.toIso8601String().split('T').first;
      parts.add('Added to Kodi: $date');
    }
    return parts.join('\n');
  }

  /// Обновляет существующий элемент коллекции данными из Kodi.
  Future<void> _updateExistingItem(
    CollectionItem existing,
    KodiMovie movie,
    bool importRatings,
  ) async {
    // Повышаем статус.
    final ItemStatus externalStatus = _resolveStatus(movie);
    final ItemStatus? newStatus = mergeExternalStatus(
      currentStatus: existing.status,
      externalStatus: externalStatus,
    );
    if (newStatus != null) {
      await _db.updateItemStatus(
        existing.id,
        newStatus,
        mediaType: MediaType.movie,
      );
    }

    // Обновляем комментарий.
    final String comment = _buildComment(movie);
    if (comment.isNotEmpty) {
      await _db.updateItemUserComment(existing.id, comment);
    }

    // Обновляем рейтинг.
    if (importRatings &&
        movie.userRating != null &&
        (existing.userRating == null || existing.userRating == 0)) {
      await _db.updateItemUserRating(existing.id, movie.userRating);
    }

    // Обновляем даты.
    if (movie.lastPlayed != null) {
      await _db.updateItemActivityDates(
        existing.id,
        lastActivityAt: movie.lastPlayed,
      );
    }
  }

  /// Получает или создаёт коллекцию для Kodi movie set.
  Future<int> _getOrCreateSetCollection({
    required String setName,
    required Map<String, int> cache,
    required void Function() onCreated,
  }) async {
    final int? cached = cache[setName];
    if (cached != null) return cached;

    final String collectionName = '$setName (kodi)';

    // Ищем существующую коллекцию с таким именем.
    final Collection? existing =
        await _db.findCollectionByName(collectionName);
    if (existing != null) {
      cache[setName] = existing.id;
      return existing.id;
    }

    // Создаём новую.
    final Collection created = await _db.createCollection(
      name: collectionName,
      author: 'Kodi',
    );
    cache[setName] = created.id;
    onCreated();
    _log.info('Created sub-collection: $collectionName');
    return created.id;
  }
}

// ---------------------------------------------------------------------------
// Extension: toUniversal()
// ---------------------------------------------------------------------------

/// Конвертация [KodiImportResult] в [UniversalImportResult].
extension KodiImportResultToUniversal on KodiImportResult {
  /// Преобразует в универсальный результат.
  UniversalImportResult toUniversal({Collection? collection}) {
    final Map<MediaType, int> importedByType = <MediaType, int>{};
    final Map<MediaType, int> updatedByType = <MediaType, int>{};

    if (imported > 0) {
      importedByType[MediaType.movie] = imported;
    }
    if (updated > 0) {
      updatedByType[MediaType.movie] = updated;
    }

    return UniversalImportResult(
      sourceName: 'Kodi',
      success: true,
      collection: collection,
      collectionId: collectionId,
      importedByType: importedByType,
      updatedByType: updatedByType,
      skipped: unmatched,
      errors: errors,
    );
  }
}
