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

class KodiSyncResult {
  const KodiSyncResult({
    this.fetched = 0,
    this.updated = 0,
    this.added = 0,
    this.errors = 0,
    this.collectionsCreated = 0,
    this.affectedCollectionIds = const <int>{},
    this.timestamp,
  });

  static const KodiSyncResult empty = KodiSyncResult();

  final int fetched;

  /// Existing items updated (in at least one collection).
  final int updated;

  /// New items added to the main collection.
  final int added;

  final int errors;

  /// Sub-collections created from Kodi sets.
  final int collectionsCreated;

  /// Collection ids that received writes (target + sub-collections).
  final Set<int> affectedCollectionIds;

  final String? timestamp;

  bool get hasChanges => updated > 0 || added > 0;
}

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

/// Background Kodi sync. Every movie always lands in [targetCollectionId];
/// with [createSubCollections], Kodi sets also get per-set collections.
class KodiSyncService {
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

  KodiSyncResult? get lastResult => _lastResult;

  bool get isRunning => _timer != null && _timer!.isActive;

  bool get isSyncing => _isSyncing;

  /// [onTargetNotFound] is called when the target collection was deleted;
  /// the sync stops itself in that case.
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

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

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

      // Collection deleted — the sync already stopped itself in _doSync.
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

      // Collections that received writes (for UI invalidation).
      final Set<int> affectedIds = <int>{};

      // Cache of set name → sub-collection id.
      final Map<String, int> setCollectionIds = <String, int>{};

      for (final KodiMovie movie in movies) {
        try {
          final int? tmdbId = await _resolveTmdbId(movie);
          if (tmdbId == null) continue;

          final String comment = _buildComment(movie);
          final ItemStatus status = _resolveStatus(movie);

          final CollectionItem? existingInMain = await _db.findCollectionItem(
            collectionId: targetCollectionId,
            mediaType: MediaType.movie,
            externalId: tmdbId,
          );

          if (existingInMain != null) {
            // Already present — update without hitting TMDB
            await _updateItem(existingInMain, movie, comment, importRatings);
            affectedIds.add(targetCollectionId);
            updated++;
          } else {
            // New movie — fetch TMDB data once
            final Movie? tmdbMovie = await _tmdbApi.getMovie(tmdbId);
            if (tmdbMovie != null) {
              await _db.movieDao.upsertMovie(tmdbMovie);
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

          // Optional sub-collection mirroring the Kodi set
          if (createSubCollections && movie.set != null) {
            final _SubCollectionResult sub = await _getOrCreateSetCollection(
              setName: movie.set!,
              cache: setCollectionIds,
            );
            if (sub.created) collectionsCreated++;

            // TMDB data is already cached by the main-collection pass above.
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

  /// Returns `true` if the item was created, `false` if it already existed
  /// (and was updated in place).
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
    // Status is only ever upgraded, via the shared merge rule
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

    if (comment.isNotEmpty && comment != existing.userComment) {
      await _db.updateItemUserComment(existing.id, comment);
    }

    if (importRatings &&
        movie.userRating != null &&
        existing.userRating != movie.userRating) {
      await _db.updateItemUserRating(existing.id, movie.userRating);
    }

    if (movie.lastPlayed != null) {
      await _db.updateItemActivityDates(
        existing.id,
        lastActivityAt: movie.lastPlayed,
      );
    }
  }

  /// Comment built from Kodi metadata; the set name is always included.
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
