// Фоновый сервис синхронизации с Kodi.
//
// Периодически опрашивает библиотеку Kodi, актуализирует status/dates/
// comments для существующих items и добавляет новые. ВСЕ фильмы всегда
// попадают в основную коллекцию (targetCollectionId). Если включены
// sub-collections — фильмы из Kodi sets дополнительно дублируются
// в отдельные коллекции по имени set.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/kodi_movie.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../api/kodi_api.dart';
import '../api/tmdb_api.dart';
import '../database/database_service.dart';

/// Результат одного цикла синхронизации.
class KodiSyncResult {
  /// Создаёт [KodiSyncResult].
  const KodiSyncResult({
    this.fetched = 0,
    this.updated = 0,
    this.added = 0,
    this.errors = 0,
    this.collectionsCreated = 0,
    this.affectedCollectionIds = const <int>{},
    this.timestamp,
  });

  /// Пустой результат.
  static const KodiSyncResult empty = KodiSyncResult();

  /// Сколько фильмов загружено из Kodi.
  final int fetched;

  /// Сколько существующих items обновлено (хотя бы в одной коллекции).
  final int updated;

  /// Сколько новых items добавлено в основную коллекцию.
  final int added;

  /// Сколько ошибок.
  final int errors;

  /// Сколько sub-collections создано из sets.
  final int collectionsCreated;

  /// Все ID коллекций, в которых были изменения (target + sub-collections).
  final Set<int> affectedCollectionIds;

  /// Timestamp этого sync-цикла.
  final String? timestamp;

  /// Были ли изменения.
  bool get hasChanges => updated > 0 || added > 0;
}

/// Провайдер для [KodiSyncService].
final Provider<KodiSyncService> kodiSyncServiceProvider =
    Provider<KodiSyncService>((Ref ref) {
  final KodiSyncService service = KodiSyncService(
    kodiApi: ref.watch(kodiApiProvider),
    tmdbApi: ref.watch(tmdbApiProvider),
    database: ref.watch(databaseServiceProvider),
  );
  ref.onDispose(service.stop);
  return service;
});

/// Фоновый сервис синхронизации с Kodi.
///
/// Все фильмы всегда попадают в [targetCollectionId]. Если
/// [createSubCollections] — фильмы из Kodi sets дополнительно
/// добавляются в отдельные коллекции по имени set.
class KodiSyncService {
  /// Создаёт [KodiSyncService].
  KodiSyncService({
    required KodiApi kodiApi,
    required TmdbApi tmdbApi,
    required DatabaseService database,
  })  : _kodiApi = kodiApi,
        _tmdbApi = tmdbApi,
        _db = database;

  static final Logger _log = Logger('KodiSyncService');

  final KodiApi _kodiApi;
  final TmdbApi _tmdbApi;
  final DatabaseService _db;

  Timer? _timer;
  bool _isSyncing = false;
  KodiSyncResult? _lastResult;

  /// Последний результат sync.
  KodiSyncResult? get lastResult => _lastResult;

  /// Работает ли sync.
  bool get isRunning => _timer != null && _timer!.isActive;

  /// Идёт ли сейчас sync-цикл.
  bool get isSyncing => _isSyncing;

  /// Запускает периодический sync.
  ///
  /// [onTargetNotFound] вызывается если целевая коллекция удалена —
  /// sync автоматически останавливается.
  void start({
    required int intervalSeconds,
    required int targetCollectionId,
    required bool importRatings,
    required bool createSubCollections,
    required void Function(String timestamp) onSyncTimestamp,
    void Function(KodiSyncResult result)? onResult,
    void Function()? onTargetNotFound,
  }) {
    stop();
    _log.info('Starting Kodi sync (interval: ${intervalSeconds}s)');

    _runSync(
      targetCollectionId: targetCollectionId,
      importRatings: importRatings,
      createSubCollections: createSubCollections,
      onSyncTimestamp: onSyncTimestamp,
      onResult: onResult,
      onTargetNotFound: onTargetNotFound,
    );

    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _runSync(
        targetCollectionId: targetCollectionId,
        importRatings: importRatings,
        createSubCollections: createSubCollections,
        onSyncTimestamp: onSyncTimestamp,
        onResult: onResult,
        onTargetNotFound: onTargetNotFound,
      ),
    );
  }

  /// Останавливает sync.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Ручной запуск одного цикла sync.
  Future<KodiSyncResult> syncNow({
    required int targetCollectionId,
    required bool importRatings,
    required bool createSubCollections,
  }) async {
    return _doSync(
      targetCollectionId: targetCollectionId,
      importRatings: importRatings,
      createSubCollections: createSubCollections,
    );
  }

  Future<void> _runSync({
    required int targetCollectionId,
    required bool importRatings,
    required bool createSubCollections,
    required void Function(String timestamp) onSyncTimestamp,
    void Function(KodiSyncResult result)? onResult,
    void Function()? onTargetNotFound,
  }) async {
    if (_isSyncing) return;

    try {
      final KodiSyncResult result = await _doSync(
        targetCollectionId: targetCollectionId,
        importRatings: importRatings,
        createSubCollections: createSubCollections,
      );

      _lastResult = result;

      // Коллекция удалена — sync сам остановился в _doSync.
      if (!isRunning && result == KodiSyncResult.empty) {
        onTargetNotFound?.call();
        return;
      }

      if (result.timestamp != null) {
        onSyncTimestamp(result.timestamp!);
      }

      onResult?.call(result);
    } on Exception catch (e) {
      _log.warning('Sync cycle failed', e);
    }
  }

  Future<KodiSyncResult> _doSync({
    required int targetCollectionId,
    required bool importRatings,
    required bool createSubCollections,
  }) async {
    _isSyncing = true;

    try {
      final List<KodiMovie> movies = await _fetchAllMovies();

      if (movies.isEmpty) {
        _isSyncing = false;
        return KodiSyncResult.empty;
      }

      // Проверяем что основная коллекция ещё существует.
      final bool targetExists =
          await _db.getCollectionById(targetCollectionId) != null;
      if (!targetExists) {
        _kodiApi.addLog('sync', 'error',
            'Target collection #$targetCollectionId deleted — sync stopped');
        stop();
        _isSyncing = false;
        return KodiSyncResult.empty;
      }

      int updated = 0;
      int added = 0;
      int errors = 0;
      int collectionsCreated = 0;

      // Все коллекции, куда были записи (для UI invalidate).
      final Set<int> affectedIds = <int>{};

      // Кэш set name → sub-collection ID.
      final Map<String, int> setCollectionIds = <String, int>{};

      for (final KodiMovie movie in movies) {
        try {
          final int? tmdbId = await _resolveTmdbId(movie);
          if (tmdbId == null) continue;

          final String comment = _buildComment(movie);
          final ItemStatus status = _resolveStatus(movie);

          // Проверяем существует ли элемент в основной коллекции.
          final CollectionItem? existingInMain = await _db.findCollectionItem(
            collectionId: targetCollectionId,
            mediaType: MediaType.movie,
            externalId: tmdbId,
          );

          if (existingInMain != null) {
            // ---- Уже есть — обновляем без TMDB запроса ----
            await _updateItem(existingInMain, movie, comment, importRatings);
            affectedIds.add(targetCollectionId);
            updated++;
          } else {
            // ---- Новый фильм — один раз тянем данные из TMDB ----
            final Movie? tmdbMovie = await _tmdbApi.getMovie(tmdbId);
            if (tmdbMovie != null) {
              await _db.upsertMovie(tmdbMovie);
            }

            final int? itemId = await _db.addItemToCollection(
              collectionId: targetCollectionId,
              mediaType: MediaType.movie,
              externalId: tmdbId,
              status: status,
            );
            if (itemId != null) {
              if (comment.isNotEmpty) {
                await _db.updateItemUserComment(itemId, comment);
              }
              if (importRatings && movie.userRating != null) {
                await _db.updateItemUserRating(itemId, movie.userRating);
              }
              if (movie.lastPlayed != null) {
                await _db.updateItemActivityDates(
                  itemId,
                  lastActivityAt: movie.lastPlayed,
                );
              }
            }

            _kodiApi.addLog('sync', 'info',
                '${movie.title}: added as $status');
            affectedIds.add(targetCollectionId);
            added++;
          }

          // ---- Sub-collection из set (опционально) ----
          if (createSubCollections && movie.set != null) {
            final _SubCollectionResult sub = await _getOrCreateSetCollection(
              setName: movie.set!,
              cache: setCollectionIds,
            );
            if (sub.created) collectionsCreated++;

            // TMDB данные уже в кэше (из main ветки выше).
            await _syncItemToCollection(
              collectionId: sub.collectionId,
              tmdbId: tmdbId,
              movie: movie,
              status: status,
              comment: comment,
              importRatings: importRatings,
            );
            affectedIds.add(sub.collectionId);
          }
        } on Exception catch (e) {
          _kodiApi.addLog('sync', 'error', '${movie.title}: $e');
          _log.fine('Sync error for ${movie.title}: $e');
          errors++;
        }
      }

      final String timestamp = DateTime.now().toIso8601String();

      _kodiApi.addLog('sync', 'info',
          'Done: $updated upd, $added new, $errors err'
          '${collectionsCreated > 0 ? ', $collectionsCreated sets' : ''}'
          ' (${movies.length} total)');
      _log.info('Sync: $updated upd, $added new, $errors err, '
          '$collectionsCreated sets');

      _isSyncing = false;
      return KodiSyncResult(
        fetched: movies.length,
        updated: updated,
        added: added,
        errors: errors,
        collectionsCreated: collectionsCreated,
        affectedCollectionIds: affectedIds,
        timestamp: timestamp,
      );
    } on Exception {
      _isSyncing = false;
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Core: добавить/обновить один фильм в конкретной коллекции
  // ---------------------------------------------------------------------------

  /// Синхронизирует один фильм в одну коллекцию.
  ///
  /// Возвращает `true` если элемент был **создан** (новый),
  /// `false` если уже существовал (обновлён).
  Future<bool> _syncItemToCollection({
    required int collectionId,
    required int tmdbId,
    required KodiMovie movie,
    required ItemStatus status,
    required String comment,
    required bool importRatings,
  }) async {
    final CollectionItem? existing = await _db.findCollectionItem(
      collectionId: collectionId,
      mediaType: MediaType.movie,
      externalId: tmdbId,
    );

    if (existing != null) {
      await _updateItem(existing, movie, comment, importRatings);
      return false;
    }

    // Новый элемент.
    final int? itemId = await _db.addItemToCollection(
      collectionId: collectionId,
      mediaType: MediaType.movie,
      externalId: tmdbId,
      status: status,
    );

    if (itemId != null) {
      if (comment.isNotEmpty) {
        await _db.updateItemUserComment(itemId, comment);
      }
      if (importRatings && movie.userRating != null) {
        await _db.updateItemUserRating(itemId, movie.userRating);
      }
      if (movie.lastPlayed != null) {
        await _db.updateItemActivityDates(
          itemId,
          lastActivityAt: movie.lastPlayed,
        );
      }
    }

    _kodiApi.addLog('sync', 'info',
        '${movie.title}: added as $status (col=$collectionId)');
    return true;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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

  Future<int?> _resolveTmdbId(KodiMovie movie) async {
    if (movie.uniqueIds.tmdbId != null) return movie.uniqueIds.tmdbId;

    if (movie.uniqueIds.imdbId != null) {
      try {
        final TmdbFindResult result =
            await _tmdbApi.findByImdbId(movie.uniqueIds.imdbId!);
        if (result.movies.isNotEmpty) return result.movies.first.tmdbId;
      } on TmdbApiException catch (e) {
        _log.fine('findByImdbId failed for ${movie.title}: $e');
      }
    }

    return null;
  }

  ItemStatus _resolveStatus(KodiMovie movie) {
    if (movie.playcount > 0) return ItemStatus.completed;
    if (movie.lastPlayed != null) return ItemStatus.inProgress;
    return ItemStatus.planned;
  }

  Future<void> _updateItem(
    CollectionItem existing,
    KodiMovie movie,
    String comment,
    bool importRatings,
  ) async {
    // Статус: повышаем через общее правило.
    final ItemStatus externalStatus = movie.playcount > 0
        ? ItemStatus.completed
        : ItemStatus.inProgress;

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

    // Комментарий: обновляем только если изменился.
    if (comment.isNotEmpty && comment != existing.userComment) {
      await _db.updateItemUserComment(existing.id, comment);
    }

    // Рейтинг: обновляем только если изменился.
    if (importRatings &&
        movie.userRating != null &&
        existing.userRating != movie.userRating) {
      await _db.updateItemUserRating(existing.id, movie.userRating);
    }

    // Даты.
    if (movie.lastPlayed != null) {
      await _db.updateItemActivityDates(
        existing.id,
        lastActivityAt: movie.lastPlayed,
      );
    }
  }

  /// Комментарий из метаданных Kodi. Set name всегда включён.
  String _buildComment(KodiMovie movie) {
    final List<String> parts = <String>[];

    if (movie.set != null) {
      parts.add('Set: ${movie.set}');
    }
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

  /// Получает или создаёт sub-collection для Kodi movie set.
  Future<_SubCollectionResult> _getOrCreateSetCollection({
    required String setName,
    required Map<String, int> cache,
  }) async {
    final int? cached = cache[setName];
    if (cached != null) {
      return _SubCollectionResult(collectionId: cached, created: false);
    }

    final String collectionName = '$setName (kodi)';

    final Collection? existing =
        await _db.findCollectionByName(collectionName);
    if (existing != null) {
      cache[setName] = existing.id;
      return _SubCollectionResult(collectionId: existing.id, created: false);
    }

    final Collection created = await _db.createCollection(
      name: collectionName,
      author: 'Kodi',
    );
    cache[setName] = created.id;
    _log.info('Created sub-collection: $collectionName');
    return _SubCollectionResult(collectionId: created.id, created: true);
  }
}

class _SubCollectionResult {
  const _SubCollectionResult({
    required this.collectionId,
    required this.created,
  });

  final int collectionId;
  final bool created;
}
