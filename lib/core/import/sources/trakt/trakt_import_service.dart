import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../data/repositories/wishlist_repository.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/item_status_logic.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/movie.dart';
import '../../../../shared/models/tv_show.dart';
import '../../../../shared/models/universal_import_result.dart';
import '../../../../shared/models/wishlist_tag.dart';
import '../../../api/tmdb_api.dart';
import '../../../database/database_service.dart';
import '../../../services/import_service.dart';
import '../../import_columns.dart';
import '../../import_source.dart';
import '../../import_writer.dart';

class TraktZipInfo {
  const TraktZipInfo({
    required this.isValid,
    this.username = '',
    this.watchedMovieCount = 0,
    this.watchedShowCount = 0,
    this.ratedMovieCount = 0,
    this.ratedShowCount = 0,
    this.watchlistCount = 0,
    this.error,
  });

  const TraktZipInfo.invalid(String message)
      : isValid = false,
        username = '',
        watchedMovieCount = 0,
        watchedShowCount = 0,
        ratedMovieCount = 0,
        ratedShowCount = 0,
        watchlistCount = 0,
        error = message;

  final bool isValid;
  final String username;
  final int watchedMovieCount;
  final int watchedShowCount;
  final int ratedMovieCount;
  final int ratedShowCount;
  final int watchlistCount;
  final String? error;

  int get totalItems =>
      watchedMovieCount +
      watchedShowCount +
      ratedMovieCount +
      ratedShowCount +
      watchlistCount;
}

class TraktImportOptions extends ImportOptions {
  const TraktImportOptions({
    required this.zipPath,
    super.collectionId,
    this.importWatched = true,
    this.importRatings = true,
    this.importWatchlist = true,
  });

  final String zipPath;

  final bool importWatched;
  final bool importRatings;
  final bool importWatchlist;
}

class _TraktMovie {
  const _TraktMovie({
    required this.title,
    required this.tmdbId,
    required this.year,
    this.lastWatchedAt,
  });

  final String title;
  final int? tmdbId;
  final int year;
  final DateTime? lastWatchedAt;
}

class _TraktShow {
  const _TraktShow({
    required this.title,
    required this.tmdbId,
    this.lastWatchedAt,
    this.seasons = const <_TraktSeason>[],
  });

  final String title;
  final int? tmdbId;
  final DateTime? lastWatchedAt;
  final List<_TraktSeason> seasons;
}

class _TraktSeason {
  const _TraktSeason({
    required this.number,
    this.episodes = const <_TraktEpisode>[],
  });

  final int number;
  final List<_TraktEpisode> episodes;
}

class _TraktEpisode {
  const _TraktEpisode({
    required this.number,
    this.lastWatchedAt,
  });

  final int number;
  final DateTime? lastWatchedAt;
}

class _TraktRating {
  const _TraktRating({
    required this.title,
    required this.tmdbId,
    required this.rating,
    required this.type,
  });

  final String title;
  final int? tmdbId;
  final int rating;
  final String type; // 'movie' | 'show'
}

class _TraktWatchlistEntry {
  const _TraktWatchlistEntry({
    required this.title,
    required this.tmdbId,
    required this.type,
  });

  final String title;
  final int? tmdbId;
  final String type; // 'movie' | 'show'
}

final Provider<TraktImportService> traktImportServiceProvider =
    Provider<TraktImportService>((Ref ref) {
  return TraktImportService(
    tmdbApi: ref.watch(tmdbApiProvider),
    repository: ref.watch(collectionRepositoryProvider),
    database: ref.watch(databaseServiceProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

/// Imports a Trakt.tv ZIP export onto the shared import layer.
///
/// Parses the archive, fetches each title's TMDB data once, then writes every
/// section (watched, ratings, watchlist) through [ImportWriter] in batches.
/// Watched episodes are marked directly (no collection-item analogue), and
/// titles without TMDB data fall back to the text wishlist.
class TraktImportService implements ImportSource {
  TraktImportService({
    required TmdbApi tmdbApi,
    required CollectionRepository repository,
    required DatabaseService database,
    required WishlistRepository wishlistRepository,
  })  : _tmdbApi = tmdbApi,
        _database = database,
        _writer = ImportWriter(
          collections: repository,
          wishlist: wishlistRepository,
        );

  // ignore: unused_field
  static final Logger _log = Logger('TraktImportService');

  final TmdbApi _tmdbApi;
  final DatabaseService _database;
  final ImportWriter _writer;

  @override
  String get displayName => 'Trakt';

  Future<TraktZipInfo> validateZip(String zipPath) async {
    try {
      final ({Map<String, String> files, String username}) archive =
          _readArchive(zipPath);
      if (archive.files.isEmpty) {
        return const TraktZipInfo.invalid('No JSON files found in archive');
      }

      final Map<String, String> files = archive.files;
      final String username = archive.username;

      int watchedMovieCount = 0;
      int watchedShowCount = 0;
      int ratedMovieCount = 0;
      int ratedShowCount = 0;
      int watchlistCount = 0;

      final String? watchedMovies = _getFile(
          files, 'watched/watched-movies.json', 'watched-movies.json');
      if (watchedMovies != null) {
        final List<dynamic> list =
            jsonDecode(watchedMovies) as List<dynamic>;
        watchedMovieCount = list.length;
      }

      final String? watchedShows = _getFile(
          files, 'watched/watched-shows.json', 'watched-shows.json');
      if (watchedShows != null) {
        final List<dynamic> list =
            jsonDecode(watchedShows) as List<dynamic>;
        watchedShowCount = list.length;
      }

      final String? ratingsMovies = _getFile(
          files, 'ratings/ratings-movies.json', 'ratings-movies.json');
      if (ratingsMovies != null) {
        final List<dynamic> list =
            jsonDecode(ratingsMovies) as List<dynamic>;
        ratedMovieCount = list.length;
      }

      final String? ratingsShows = _getFile(
          files, 'ratings/ratings-shows.json', 'ratings-shows.json');
      if (ratingsShows != null) {
        final List<dynamic> list =
            jsonDecode(ratingsShows) as List<dynamic>;
        ratedShowCount = list.length;
      }

      final String? watchlist = _getFile(
          files, 'lists/watchlist.json', 'lists-watchlist.json');
      if (watchlist != null) {
        final List<dynamic> list =
            jsonDecode(watchlist) as List<dynamic>;
        watchlistCount = list.length;
      }

      final int total = watchedMovieCount +
          watchedShowCount +
          ratedMovieCount +
          ratedShowCount +
          watchlistCount;

      return TraktZipInfo(
        isValid: total > 0,
        username: username,
        watchedMovieCount: watchedMovieCount,
        watchedShowCount: watchedShowCount,
        ratedMovieCount: ratedMovieCount,
        ratedShowCount: ratedShowCount,
        watchlistCount: watchlistCount,
      );
    } on ArchiveException {
      return const TraktZipInfo.invalid('Invalid ZIP archive');
    } on FormatException {
      return const TraktZipInfo.invalid('Invalid JSON in archive');
    } on FileSystemException {
      return const TraktZipInfo.invalid('Cannot read file');
    } on Exception catch (e) {
      return TraktZipInfo.invalid('Error: $e');
    }
  }

  @override
  Future<UniversalImportResult> import(
    covariant TraktImportOptions options, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(const ImportProgress(
        stage: ImportStage.reading,
        current: 0,
        total: 1,
        message: 'Reading ZIP archive...',
      ));

      final ({Map<String, String> files, String username}) archive =
          _readArchive(options.zipPath);
      if (archive.files.isEmpty) {
        return const UniversalImportResult.failure(
          sourceName: 'Trakt',
          error: 'No data found in archive',
        );
      }

      final Map<String, String> files = archive.files;
      final String username = archive.username;

      final List<_TraktMovie> watchedMovies = options.importWatched
          ? _parseWatchedMovies(_getFile(
              files, 'watched/watched-movies.json', 'watched-movies.json'))
          : <_TraktMovie>[];

      final List<_TraktShow> watchedShows = options.importWatched
          ? _parseWatchedShows(_getFile(
              files, 'watched/watched-shows.json', 'watched-shows.json'))
          : <_TraktShow>[];

      final List<_TraktRating> movieRatings = options.importRatings
          ? _parseRatings(
              _getFile(
                  files, 'ratings/ratings-movies.json', 'ratings-movies.json'),
              'movie')
          : <_TraktRating>[];

      final List<_TraktRating> showRatings = options.importRatings
          ? _parseRatings(
              _getFile(
                  files, 'ratings/ratings-shows.json', 'ratings-shows.json'),
              'show')
          : <_TraktRating>[];

      final List<_TraktWatchlistEntry> watchlistEntries =
          options.importWatchlist
              ? _parseWatchlist(_getFile(
                  files, 'lists/watchlist.json', 'lists-watchlist.json'))
              : <_TraktWatchlistEntry>[];

      // Dedup TMDB IDs across all sections to fetch each from TMDB once.
      final Set<int> movieTmdbIds = <int>{};
      final Set<int> showTmdbIds = <int>{};

      for (final _TraktMovie m in watchedMovies) {
        if (m.tmdbId != null) movieTmdbIds.add(m.tmdbId!);
      }
      for (final _TraktShow s in watchedShows) {
        if (s.tmdbId != null) showTmdbIds.add(s.tmdbId!);
      }
      for (final _TraktRating r in movieRatings) {
        if (r.tmdbId != null) movieTmdbIds.add(r.tmdbId!);
      }
      for (final _TraktRating r in showRatings) {
        if (r.tmdbId != null) showTmdbIds.add(r.tmdbId!);
      }
      for (final _TraktWatchlistEntry e in watchlistEntries) {
        if (e.tmdbId != null) {
          if (e.type == 'movie') {
            movieTmdbIds.add(e.tmdbId!);
          } else {
            showTmdbIds.add(e.tmdbId!);
          }
        }
      }

      final Map<int, Movie> fetchedMovies = <int, Movie>{};
      final Map<int, TvShow> fetchedShows = <int, TvShow>{};
      final Map<int, bool> movieIsAnimation = <int, bool>{};
      final Map<int, bool> showIsAnimation = <int, bool>{};

      final int totalToFetch = movieTmdbIds.length + showTmdbIds.length;
      int fetchProgress = 0;

      for (final int tmdbId in movieTmdbIds) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingMovies,
          current: fetchProgress,
          total: totalToFetch,
          message: 'Fetching movie $tmdbId...',
        ));

        try {
          final Movie? movie = await _tmdbApi.getMovie(tmdbId);
          if (movie != null) {
            fetchedMovies[tmdbId] = movie;
            await _database.movieDao.upsertMovie(movie);
            movieIsAnimation[tmdbId] = _isAnimationByGenres(movie.genres);
          }
        } on Exception {
          // Partial failure: skip this item, continue with the rest.
        }
        fetchProgress++;
      }

      for (final int tmdbId in showTmdbIds) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingTvShows,
          current: fetchProgress,
          total: totalToFetch,
          message: 'Fetching TV show $tmdbId...',
        ));

        try {
          final TvShow? tvShow = await _tmdbApi.getTvShow(tmdbId);
          if (tvShow != null) {
            fetchedShows[tmdbId] = tvShow;
            await _database.tvShowDao.upsertTvShow(tvShow);
            showIsAnimation[tmdbId] = _isAnimationByGenres(tvShow.genres);
          }
        } on Exception {
          // Partial failure: skip this item, continue with the rest.
        }
        fetchProgress++;
      }

      onProgress?.call(const ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 0,
        total: 1,
        message: 'Preparing collection...',
      ));

      // Resolve the collection only after the data loaded, so a failed fetch
      // never leaves an empty collection behind.
      final Collection? collection = await _writer.resolveCollection(
        collectionId: options.collectionId,
        newCollectionName: 'Trakt: $username',
        author: username,
      );
      if (collection == null) {
        return const UniversalImportResult.failure(
          sourceName: 'Trakt',
          error: 'Collection not found',
        );
      }
      final int collectionId = collection.id;

      final Map<MediaType, int> importedByType = <MediaType, int>{};
      final Map<MediaType, int> updatedByType = <MediaType, int>{};
      final List<WishlistCandidate> wishlistFallback = <WishlistCandidate>[];
      int skipped = 0;

      void accumulate(ImportWriteResult write) {
        write.importedByType.forEach((MediaType k, int v) {
          importedByType[k] = (importedByType[k] ?? 0) + v;
        });
        write.updatedByType.forEach((MediaType k, int v) {
          updatedByType[k] = (updatedByType[k] ?? 0) + v;
        });
        skipped += write.skipped;
      }

      // Pass 1 — watched movies and shows become completed/in-progress items.
      final List<ImportCandidate> watchedCandidates = <ImportCandidate>[];
      for (final _TraktMovie m in watchedMovies) {
        if (m.tmdbId == null) {
          skipped++;
          continue;
        }
        if (!fetchedMovies.containsKey(m.tmdbId)) {
          wishlistFallback.add(
              WishlistCandidate(text: m.title, mediaType: MediaType.movie));
          skipped++;
          continue;
        }
        final bool isAnim = movieIsAnimation[m.tmdbId] ?? false;
        watchedCandidates.add(_watchedCandidate(
          mediaType: isAnim ? MediaType.animation : MediaType.movie,
          externalId: m.tmdbId!,
          platformId: isAnim ? AnimationSource.movie : null,
          status: ItemStatus.completed,
          completedAt: m.lastWatchedAt,
          label: m.title,
        ));
      }
      for (final _TraktShow s in watchedShows) {
        if (s.tmdbId == null) {
          skipped++;
          continue;
        }
        if (!fetchedShows.containsKey(s.tmdbId)) {
          wishlistFallback.add(
              WishlistCandidate(text: s.title, mediaType: MediaType.tvShow));
          skipped++;
          continue;
        }
        final bool isAnim = showIsAnimation[s.tmdbId] ?? false;
        final ItemStatus status = _resolveShowStatus(s);
        watchedCandidates.add(_watchedCandidate(
          mediaType: isAnim ? MediaType.animation : MediaType.tvShow,
          externalId: s.tmdbId!,
          platformId: isAnim ? AnimationSource.tvShow : null,
          status: status,
          completedAt:
              status == ItemStatus.completed ? s.lastWatchedAt : null,
          label: s.title,
        ));
      }
      accumulate(await _writer.writeItems(
        collectionId: collectionId,
        candidates: watchedCandidates,
        onItem: (int processed, int total, int imported, int updated,
            String? label) {
          onProgress?.call(ImportProgress(
            stage: ImportStage.addingItems,
            current: processed,
            total: total,
            currentItem: label,
            imported: imported,
            updated: updated,
          ));
        },
      ));

      // Watched episodes are marked directly — there is no collection-item
      // analogue for an individual episode.
      if (options.importWatched && watchedShows.isNotEmpty) {
        for (final _TraktShow traktShow in watchedShows) {
          if (traktShow.tmdbId == null) continue;
          for (final _TraktSeason season in traktShow.seasons) {
            for (final _TraktEpisode episode in season.episodes) {
              await _database.tvShowDao.markEpisodeWatched(
                collectionId,
                traktShow.tmdbId!,
                season.number,
                episode.number,
              );
            }
          }
        }
      }

      // Pass 2 — ratings. Only titles whose TMDB data was fetched can be added
      // or matched; an existing user rating is never overwritten.
      if (options.importRatings) {
        final List<ImportCandidate> ratingCandidates = <ImportCandidate>[];
        for (final _TraktRating r in <_TraktRating>[
          ...movieRatings,
          ...showRatings,
        ]) {
          if (r.tmdbId == null) continue;
          final bool isMovie = r.type == 'movie';
          final bool hasData = isMovie
              ? fetchedMovies.containsKey(r.tmdbId)
              : fetchedShows.containsKey(r.tmdbId);
          if (!hasData) continue;
          final ({MediaType mediaType, int? platformId}) resolved =
              _resolveMediaType(
            isMovie: isMovie,
            movieIsAnimation: movieIsAnimation,
            showIsAnimation: showIsAnimation,
            tmdbId: r.tmdbId!,
          );
          ratingCandidates.add(_ratingCandidate(
            mediaType: resolved.mediaType,
            externalId: r.tmdbId!,
            platformId: resolved.platformId,
            rating: r.rating,
            label: r.title,
          ));
        }
        accumulate(await _writer.writeItems(
          collectionId: collectionId,
          candidates: ratingCandidates,
        ));
      }

      // Pass 3 — watchlist. Entries with TMDB data become planned items; the
      // rest fall back to the text wishlist.
      if (options.importWatchlist) {
        final List<ImportCandidate> watchlistCandidates = <ImportCandidate>[];
        for (final _TraktWatchlistEntry e in watchlistEntries) {
          final bool isMovie = e.type == 'movie';
          final bool hasData = e.tmdbId != null &&
              (isMovie
                  ? fetchedMovies.containsKey(e.tmdbId)
                  : fetchedShows.containsKey(e.tmdbId));
          if (hasData) {
            final ({MediaType mediaType, int? platformId}) resolved =
                _resolveMediaType(
              isMovie: isMovie,
              movieIsAnimation: movieIsAnimation,
              showIsAnimation: showIsAnimation,
              tmdbId: e.tmdbId!,
            );
            watchlistCandidates.add(_watchlistCandidate(
              mediaType: resolved.mediaType,
              externalId: e.tmdbId!,
              platformId: resolved.platformId,
              label: e.title,
            ));
          } else {
            wishlistFallback.add(WishlistCandidate(
              text: e.title,
              mediaType: isMovie ? MediaType.movie : MediaType.tvShow,
            ));
          }
        }
        accumulate(await _writer.writeItems(
          collectionId: collectionId,
          candidates: watchlistCandidates,
        ));
      }

      final Map<MediaType, int> wishlistedByType = await _writer.writeWishlist(
        entries: wishlistFallback,
        tag: buildImportTag('Trakt'),
      );

      onProgress?.call(const ImportProgress(
        stage: ImportStage.completed,
        current: 1,
        total: 1,
      ));

      return UniversalImportResult(
        sourceName: 'Trakt',
        success: true,
        collection: collection,
        importedByType: importedByType,
        updatedByType: updatedByType,
        wishlistedByType: wishlistedByType,
        skipped: skipped,
      );
    } on Exception catch (e) {
      return UniversalImportResult.failure(
        sourceName: 'Trakt',
        error: 'Import failed: $e',
      );
    }
  }

  /// Watched item: completed/in-progress status with the watch date. Re-sync
  /// merges the external status without downgrading the local one and stamps
  /// the completion date only when the local one is empty.
  ImportCandidate _watchedCandidate({
    required MediaType mediaType,
    required int externalId,
    required int? platformId,
    required ItemStatus status,
    required DateTime? completedAt,
    required String label,
  }) {
    final int? epoch = epochSeconds(completedAt);
    return ImportCandidate(
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      label: label,
      insertRow: <String, dynamic>{
        'media_type': mediaType.value,
        'external_id': externalId,
        'platform_id': platformId,
        'status': status.value,
        'completed_at': ?epoch,
        'last_activity_at': ?epoch,
      },
      changedFields: (CollectionItem existing) {
        final Map<String, dynamic> fields = <String, dynamic>{};
        final ItemStatus? merged = mergeExternalStatus(
          currentStatus: existing.status,
          externalStatus: status,
        );
        if (merged != null) {
          fields.addAll(statusDateColumns(merged, existing));
        }
        if (completedAt != null && existing.completedAt == null) {
          fields['completed_at'] = epochSeconds(completedAt);
        }
        return fields;
      },
    );
  }

  /// Rating item: a new not-started item carrying the rating, or — when the
  /// item already exists — the rating only if the user has not set one.
  ImportCandidate _ratingCandidate({
    required MediaType mediaType,
    required int externalId,
    required int? platformId,
    required int rating,
    required String label,
  }) {
    final double value = rating.clamp(1, 10).toDouble();
    return ImportCandidate(
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      label: label,
      insertRow: <String, dynamic>{
        'media_type': mediaType.value,
        'external_id': externalId,
        'platform_id': platformId,
        'status': ItemStatus.notStarted.value,
        'user_rating': value,
      },
      changedFields: (CollectionItem existing) => existing.userRating == null
          ? <String, dynamic>{'user_rating': value}
          : <String, dynamic>{},
    );
  }

  /// Watchlist item: a new planned item. An existing item is left untouched so
  /// a watched/rated title is never downgraded to planned.
  ImportCandidate _watchlistCandidate({
    required MediaType mediaType,
    required int externalId,
    required int? platformId,
    required String label,
  }) {
    return ImportCandidate(
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      label: label,
      insertRow: <String, dynamic>{
        'media_type': mediaType.value,
        'external_id': externalId,
        'platform_id': platformId,
        'status': ItemStatus.planned.value,
      },
      changedFields: (CollectionItem existing) => <String, dynamic>{},
    );
  }

  /// Reads JSON files and username in a single pass.
  ({Map<String, String> files, String username}) _readArchive(String zipPath) {
    final List<int> bytes = File(zipPath).readAsBytesSync();
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    final Map<String, String> files = <String, String>{};
    String username = 'Unknown';

    // Format autodetect: new format has JSON at root (depth 1); old format
    // nests them under username/ (depth >= 2). Decide from the first JSON.
    bool? isFlat;
    for (final ArchiveFile file in archive) {
      if (!file.isFile || !file.name.endsWith('.json')) continue;
      final List<String> parts = file.name.split('/');

      isFlat ??= parts.length == 1;

      final String content = utf8.decode(file.content as List<int>);

      if (isFlat) {
        files[file.name] = content;
      } else {
        if (username == 'Unknown' &&
            parts.isNotEmpty &&
            parts[0].isNotEmpty) {
          username = parts[0];
        }
        if (parts.length >= 2) {
          final String relativePath = parts.sublist(1).join('/');
          files[relativePath] = content;
        }
      }
    }

    // New format: username comes from user-profile.json instead of folder name.
    if ((isFlat ?? false) && files.containsKey('user-profile.json')) {
      try {
        final Map<String, dynamic> profile =
            jsonDecode(files['user-profile.json']!) as Map<String, dynamic>;
        username = (profile['username'] as String?) ?? username;
      } on FormatException {
        // Invalid JSON — keep 'Unknown'.
      }
    }

    return (files: files, username: username);
  }

  /// Tries both old (nested) and new (flat) key layouts.
  String? _getFile(Map<String, String> files, String oldKey, String newKey) {
    return files[oldKey] ?? files[newKey];
  }

  List<_TraktMovie> _parseWatchedMovies(String? json) {
    if (json == null || json.isEmpty) return <_TraktMovie>[];

    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    final List<_TraktMovie> result = <_TraktMovie>[];

    for (final dynamic item in list) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final Map<String, dynamic>? movieData =
          data['movie'] as Map<String, dynamic>?;
      if (movieData == null) continue;

      final Map<String, dynamic>? ids =
          movieData['ids'] as Map<String, dynamic>?;
      final int? tmdbId = ids?['tmdb'] as int?;

      DateTime? lastWatchedAt;
      final String? lastWatched = data['last_watched_at'] as String?;
      if (lastWatched != null) {
        lastWatchedAt = DateTime.tryParse(lastWatched);
      }

      result.add(_TraktMovie(
        title: movieData['title'] as String? ?? 'Unknown',
        tmdbId: tmdbId,
        year: movieData['year'] as int? ?? 0,
        lastWatchedAt: lastWatchedAt,
      ));
    }

    return result;
  }

  List<_TraktShow> _parseWatchedShows(String? json) {
    if (json == null || json.isEmpty) return <_TraktShow>[];

    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    final List<_TraktShow> result = <_TraktShow>[];

    for (final dynamic item in list) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final Map<String, dynamic>? showData =
          data['show'] as Map<String, dynamic>?;
      if (showData == null) continue;

      final Map<String, dynamic>? ids =
          showData['ids'] as Map<String, dynamic>?;
      final int? tmdbId = ids?['tmdb'] as int?;

      DateTime? lastWatchedAt;
      final String? lastWatched = data['last_watched_at'] as String?;
      if (lastWatched != null) {
        lastWatchedAt = DateTime.tryParse(lastWatched);
      }

      final List<_TraktSeason> seasons = <_TraktSeason>[];
      final List<dynamic>? seasonsData =
          data['seasons'] as List<dynamic>?;
      if (seasonsData != null) {
        for (final dynamic seasonItem in seasonsData) {
          final Map<String, dynamic> seasonData =
              seasonItem as Map<String, dynamic>;
          final int seasonNumber = seasonData['number'] as int? ?? 0;

          final List<_TraktEpisode> episodes = <_TraktEpisode>[];
          final List<dynamic>? episodesData =
              seasonData['episodes'] as List<dynamic>?;
          if (episodesData != null) {
            for (final dynamic epItem in episodesData) {
              final Map<String, dynamic> epData =
                  epItem as Map<String, dynamic>;

              DateTime? epWatchedAt;
              final String? epWatched =
                  epData['last_watched_at'] as String?;
              if (epWatched != null) {
                epWatchedAt = DateTime.tryParse(epWatched);
              }

              episodes.add(_TraktEpisode(
                number: epData['number'] as int? ?? 0,
                lastWatchedAt: epWatchedAt,
              ));
            }
          }

          seasons.add(_TraktSeason(
            number: seasonNumber,
            episodes: episodes,
          ));
        }
      }

      result.add(_TraktShow(
        title: showData['title'] as String? ?? 'Unknown',
        tmdbId: tmdbId,
        lastWatchedAt: lastWatchedAt,
        seasons: seasons,
      ));
    }

    return result;
  }

  List<_TraktRating> _parseRatings(String? json, String type) {
    if (json == null || json.isEmpty) return <_TraktRating>[];

    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    final List<_TraktRating> result = <_TraktRating>[];

    final String mediaKey = type == 'movie' ? 'movie' : 'show';

    for (final dynamic item in list) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final Map<String, dynamic>? mediaData =
          data[mediaKey] as Map<String, dynamic>?;
      if (mediaData == null) continue;

      final Map<String, dynamic>? ids =
          mediaData['ids'] as Map<String, dynamic>?;
      final int? tmdbId = ids?['tmdb'] as int?;
      final int rating = (data['rating'] as int? ?? 0).clamp(1, 10);

      result.add(_TraktRating(
        title: mediaData['title'] as String? ?? 'Unknown',
        tmdbId: tmdbId,
        rating: rating,
        type: type,
      ));
    }

    return result;
  }

  List<_TraktWatchlistEntry> _parseWatchlist(String? json) {
    if (json == null || json.isEmpty) return <_TraktWatchlistEntry>[];

    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    final List<_TraktWatchlistEntry> result = <_TraktWatchlistEntry>[];

    for (final dynamic item in list) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final String type = data['type'] as String? ?? 'movie';
      final String mediaKey = type == 'movie' ? 'movie' : 'show';

      final Map<String, dynamic>? mediaData =
          data[mediaKey] as Map<String, dynamic>?;
      if (mediaData == null) continue;

      final Map<String, dynamic>? ids =
          mediaData['ids'] as Map<String, dynamic>?;
      final int? tmdbId = ids?['tmdb'] as int?;

      result.add(_TraktWatchlistEntry(
        title: mediaData['title'] as String? ?? 'Unknown',
        tmdbId: tmdbId,
        type: type,
      ));
    }

    return result;
  }

  static bool _isAnimationByGenres(List<String>? genres) {
    if (genres == null || genres.isEmpty) return false;
    return genres.any(
      (String g) => g.toLowerCase() == 'animation' || g == '16',
    );
  }

  static ({MediaType mediaType, int? platformId}) _resolveMediaType({
    required bool isMovie,
    required Map<int, bool> movieIsAnimation,
    required Map<int, bool> showIsAnimation,
    required int tmdbId,
  }) {
    final bool isAnim = isMovie
        ? (movieIsAnimation[tmdbId] ?? false)
        : (showIsAnimation[tmdbId] ?? false);

    if (isAnim) {
      return (
        mediaType: MediaType.animation,
        platformId: isMovie ? AnimationSource.movie : AnimationSource.tvShow,
      );
    }
    return (
      mediaType: isMovie ? MediaType.movie : MediaType.tvShow,
      platformId: null,
    );
  }

  ItemStatus _resolveShowStatus(_TraktShow show) {
    if (show.seasons.isEmpty) {
      // No episode data but show appears in watched list → treat as completed.
      return ItemStatus.completed;
    }

    bool hasAnyEpisode = false;
    for (final _TraktSeason season in show.seasons) {
      if (season.episodes.isNotEmpty) {
        hasAnyEpisode = true;
        break;
      }
    }

    if (!hasAnyEpisode) return ItemStatus.completed;

    // Some episodes watched → inProgress. Cannot detect "completed" reliably
    // since Trakt export doesn't include total episode count for the show.
    return ItemStatus.inProgress;
  }
}
