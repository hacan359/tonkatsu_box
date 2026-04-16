// Фоновый сервис синхронизации с Kodi.
//
// Периодически опрашивает библиотеку Kodi, обновляет status/dates/comments
// для существующих items и добавляет новые в target collection.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

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
    this.timestamp,
  });

  /// Пустой результат.
  static const KodiSyncResult empty = KodiSyncResult();

  /// Сколько фильмов загружено из Kodi.
  final int fetched;

  /// Сколько существующих items обновлено.
  final int updated;

  /// Сколько новых items добавлено.
  final int added;

  /// Сколько ошибок.
  final int errors;

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
/// Периодически опрашивает VideoLibrary.GetMovies, находит изменения
/// с прошлого sync (по lastplayed > lastSyncTimestamp), обновляет
/// status/dates/comments.
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
  void start({
    required int intervalSeconds,
    required int targetCollectionId,
    required bool importRatings,
    required void Function(String timestamp) onSyncTimestamp,
    void Function(KodiSyncResult result)? onResult,
  }) {
    stop();
    _log.info('Starting Kodi sync (interval: ${intervalSeconds}s)');

    // Первый sync сразу.
    _runSync(
      targetCollectionId: targetCollectionId,
      importRatings: importRatings,
      onSyncTimestamp: onSyncTimestamp,
      onResult: onResult,
    );

    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _runSync(
        targetCollectionId: targetCollectionId,
        importRatings: importRatings,
        onSyncTimestamp: onSyncTimestamp,
        onResult: onResult,
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
  }) async {
    return _doSync(
      targetCollectionId: targetCollectionId,
      importRatings: importRatings,
    );
  }

  Future<void> _runSync({
    required int targetCollectionId,
    required bool importRatings,
    required void Function(String timestamp) onSyncTimestamp,
    void Function(KodiSyncResult result)? onResult,
  }) async {
    if (_isSyncing) return; // Skip if previous cycle still running.

    try {
      final KodiSyncResult result = await _doSync(
        targetCollectionId: targetCollectionId,
        importRatings: importRatings,
      );

      _lastResult = result;

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
  }) async {
    _isSyncing = true;

    try {
      // 1. Fetch all movies from Kodi.
      final List<KodiMovie> movies = await _fetchAllMovies();

      if (movies.isEmpty) {
        _isSyncing = false;
        return KodiSyncResult.empty;
      }

      // 2. Verify target collection exists (may have been deleted).
      final bool targetExists =
          await _db.getCollectionById(targetCollectionId) != null;

      // 3. Process all movies — LAN is fast, no need to filter.
      // Ratings, playcount, lastplayed can all change independently.
      int updated = 0;
      int added = 0;
      int errors = 0;

      for (final KodiMovie movie in movies) {
        try {
          final int? tmdbId = await _resolveTmdbId(movie);
          if (tmdbId == null) continue;

          // Check if already in ANY collection (movies may be in sub-collections).
          final CollectionItem? existing = await _db.findCollectionItem(
            collectionId: null,
            mediaType: MediaType.movie,
            externalId: tmdbId,
          );

          if (existing != null) {
            final bool ratingChanged = importRatings &&
                movie.userRating != null &&
                (existing.userRating == null || existing.userRating == 0);
            await _updateItem(existing, movie, importRatings);
            if (ratingChanged) {
              _kodiApi.addLog('sync', 'info',
                  '${movie.title}: rating → ${movie.userRating}/10');
            }
            updated++;
          } else if (targetExists) {
            // New movie — add to collection.
            final Movie? tmdbMovie = await _tmdbApi.getMovie(tmdbId);
            if (tmdbMovie != null) {
              await _db.upsertMovie(tmdbMovie);
            }

            final ItemStatus status = movie.playcount > 0
                ? ItemStatus.completed
                : ItemStatus.inProgress;

            final int? itemId = await _db.addItemToCollection(
              collectionId: targetCollectionId,
              mediaType: MediaType.movie,
              externalId: tmdbId,
              status: status,
            );

            if (itemId != null) {
              final String comment = _buildComment(movie);
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
            added++;
          }
        } on Exception catch (e) {
          _kodiApi.addLog('sync', 'error', '${movie.title}: $e');
          _log.fine('Sync error for ${movie.title}: $e');
          errors++;
        }
      }

      final String timestamp = DateTime.now().toIso8601String();

      _kodiApi.addLog('sync', 'info',
          'Done: $updated upd, $added new, $errors err '
          '(${movies.length} total)');
      _log.info('Sync complete: $updated updated, $added added, '
          '$errors errors');

      _isSyncing = false;
      return KodiSyncResult(
        fetched: movies.length,
        updated: updated,
        added: added,
        errors: errors,
        timestamp: timestamp,
      );
    } on Exception {
      _isSyncing = false;
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers (shared logic with KodiImportService)
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

  Future<void> _updateItem(
    CollectionItem existing,
    KodiMovie movie,
    bool importRatings,
  ) async {
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

    final String comment = _buildComment(movie);
    if (comment.isNotEmpty) {
      await _db.updateItemUserComment(existing.id, comment);
    }

    if (importRatings &&
        movie.userRating != null &&
        (existing.userRating == null || existing.userRating == 0)) {
      await _db.updateItemUserRating(existing.id, movie.userRating);
    }

    if (movie.lastPlayed != null) {
      await _db.updateItemActivityDates(
        existing.id,
        lastActivityAt: movie.lastPlayed,
      );
    }
  }

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
}
