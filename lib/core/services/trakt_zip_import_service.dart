import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/wishlist_item.dart';
import '../../shared/models/tv_show.dart';
import '../../shared/models/universal_import_result.dart';
import '../api/tmdb_api.dart';
import '../database/database_service.dart';
import 'import_service.dart';

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

class TraktImportOptions {
  const TraktImportOptions({
    required this.zipPath,
    this.collectionId,
    this.importWatched = true,
    this.importRatings = true,
    this.importWatchlist = true,
  });

  final String zipPath;

  /// null = create new collection.
  final int? collectionId;

  final bool importWatched;
  final bool importRatings;
  final bool importWatchlist;
}

class TraktImportResult {
  const TraktImportResult({
    required this.success,
    this.collection,
    this.itemsImported = 0,
    this.itemsSkipped = 0,
    this.itemsUpdated = 0,
    this.wishlistItemsAdded = 0,
    this.importedByType = const <MediaType, int>{},
    this.wishlistedByType = const <MediaType, int>{},
    this.updatedByType = const <MediaType, int>{},
    this.errors = const <String>[],
    this.error,
  });

  const TraktImportResult.success({
    required Collection this.collection,
    required this.itemsImported,
    this.itemsSkipped = 0,
    this.itemsUpdated = 0,
    this.wishlistItemsAdded = 0,
    this.importedByType = const <MediaType, int>{},
    this.wishlistedByType = const <MediaType, int>{},
    this.updatedByType = const <MediaType, int>{},
    this.errors = const <String>[],
  })  : success = true,
        error = null;

  const TraktImportResult.failure(String message)
      : success = false,
        collection = null,
        itemsImported = 0,
        itemsSkipped = 0,
        itemsUpdated = 0,
        wishlistItemsAdded = 0,
        importedByType = const <MediaType, int>{},
        wishlistedByType = const <MediaType, int>{},
        updatedByType = const <MediaType, int>{},
        errors = const <String>[],
        error = message;

  final bool success;
  final Collection? collection;
  final int itemsImported;

  /// Skipped due to missing TMDB ID or TMDB fetch error.
  final int itemsSkipped;

  /// Updated via conflict-resolution.
  final int itemsUpdated;

  final int wishlistItemsAdded;
  final Map<MediaType, int> importedByType;
  final Map<MediaType, int> wishlistedByType;
  final Map<MediaType, int> updatedByType;

  /// Per-item errors (non-fatal).
  final List<String> errors;

  /// Fatal error if import failed.
  final String? error;
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

final Provider<TraktZipImportService> traktZipImportServiceProvider =
    Provider<TraktZipImportService>((Ref ref) {
  return TraktZipImportService(
    tmdbApi: ref.watch(tmdbApiProvider),
    repository: ref.watch(collectionRepositoryProvider),
    database: ref.watch(databaseServiceProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

class TraktZipImportService {
  TraktZipImportService({
    required TmdbApi tmdbApi,
    required CollectionRepository repository,
    required DatabaseService database,
    required WishlistRepository wishlistRepository,
  })  : _tmdbApi = tmdbApi,
        _repository = repository,
        _database = database,
        _wishlistRepository = wishlistRepository;

  // ignore: unused_field
  static final Logger _log = Logger('TraktZipImportService');

  final TmdbApi _tmdbApi;
  final CollectionRepository _repository;
  final DatabaseService _database;
  final WishlistRepository _wishlistRepository;

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

  Future<TraktImportResult> importFromZip({
    required TraktImportOptions options,
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
        return const TraktImportResult.failure('No data found in archive');
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
      final List<String> errors = <String>[];

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
            await _database.upsertMovie(movie);
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
            await _database.upsertTvShow(tvShow);
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

      final int collectionId;
      final Collection collection;

      if (options.collectionId != null) {
        collectionId = options.collectionId!;
        final Collection? existing =
            await _repository.getById(collectionId);
        if (existing == null) {
          return const TraktImportResult.failure('Collection not found');
        }
        collection = existing;
      } else {
        collection = await _repository.create(
          name: 'Trakt: $username',
          author: username,
        );
        collectionId = collection.id;
      }

      int itemsImported = 0;
      int itemsSkipped = 0;
      int itemsUpdated = 0;

      final Map<MediaType, int> importedByType = <MediaType, int>{};
      final Map<MediaType, int> wishlistedByType = <MediaType, int>{};
      final Map<MediaType, int> updatedByType = <MediaType, int>{};

      final int totalItems = watchedMovies.length + watchedShows.length;
      int itemProgress = 0;

      for (final _TraktMovie traktMovie in watchedMovies) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: itemProgress,
          total: totalItems,
          message: 'Importing "${traktMovie.title}"...',
        ));

        if (traktMovie.tmdbId == null) {
          errors.add('Skipped "${traktMovie.title}" (no TMDB ID)');
          itemsSkipped++;
          itemProgress++;
          continue;
        }

        if (!fetchedMovies.containsKey(traktMovie.tmdbId)) {
          // Wishlist fallback: TMDB data unavailable → add to wishlist
          const MediaType hintType = MediaType.movie;
          final WishlistItem? existingWl =
              await _wishlistRepository.findUnresolved(traktMovie.title);
          if (existingWl == null) {
            await _wishlistRepository.add(
              text: traktMovie.title,
              mediaTypeHint: hintType,
            );
            wishlistedByType[hintType] =
                (wishlistedByType[hintType] ?? 0) + 1;
          }
          errors.add(
            'Wishlisted "${traktMovie.title}" (TMDB data not available)',
          );
          itemsSkipped++;
          itemProgress++;
          continue;
        }

        final bool isAnim = movieIsAnimation[traktMovie.tmdbId] ?? false;
        final MediaType mediaType =
            isAnim ? MediaType.animation : MediaType.movie;
        final int? platformId = isAnim ? AnimationSource.movie : null;

        final _ImportItemResult result = await _importOrUpdateItem(
          collectionId: collectionId,
          mediaType: mediaType,
          externalId: traktMovie.tmdbId!,
          platformId: platformId,
          status: ItemStatus.completed,
          completedAt: traktMovie.lastWatchedAt,
        );

        switch (result) {
          case _ImportItemResult.added:
            itemsImported++;
            importedByType[mediaType] =
                (importedByType[mediaType] ?? 0) + 1;
          case _ImportItemResult.updated:
            itemsUpdated++;
            updatedByType[mediaType] =
                (updatedByType[mediaType] ?? 0) + 1;
          case _ImportItemResult.skipped:
            itemsSkipped++;
        }

        itemProgress++;
      }

      for (final _TraktShow traktShow in watchedShows) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: itemProgress,
          total: totalItems,
          message: 'Importing "${traktShow.title}"...',
        ));

        if (traktShow.tmdbId == null) {
          errors.add('Skipped "${traktShow.title}" (no TMDB ID)');
          itemsSkipped++;
          itemProgress++;
          continue;
        }

        if (!fetchedShows.containsKey(traktShow.tmdbId)) {
          // Wishlist fallback: TMDB data unavailable → add to wishlist
          const MediaType hintType = MediaType.tvShow;
          final WishlistItem? existingWl =
              await _wishlistRepository.findUnresolved(traktShow.title);
          if (existingWl == null) {
            await _wishlistRepository.add(
              text: traktShow.title,
              mediaTypeHint: hintType,
            );
            wishlistedByType[hintType] =
                (wishlistedByType[hintType] ?? 0) + 1;
          }
          errors.add(
            'Wishlisted "${traktShow.title}" (TMDB data not available)',
          );
          itemsSkipped++;
          itemProgress++;
          continue;
        }

        final bool isAnim = showIsAnimation[traktShow.tmdbId] ?? false;
        final MediaType mediaType =
            isAnim ? MediaType.animation : MediaType.tvShow;
        final int? platformId = isAnim ? AnimationSource.tvShow : null;

        final ItemStatus showStatus = _resolveShowStatus(traktShow);

        final _ImportItemResult result = await _importOrUpdateItem(
          collectionId: collectionId,
          mediaType: mediaType,
          externalId: traktShow.tmdbId!,
          platformId: platformId,
          status: showStatus,
          completedAt: showStatus == ItemStatus.completed
              ? traktShow.lastWatchedAt
              : null,
        );

        switch (result) {
          case _ImportItemResult.added:
            itemsImported++;
            importedByType[mediaType] =
                (importedByType[mediaType] ?? 0) + 1;
          case _ImportItemResult.updated:
            itemsUpdated++;
            updatedByType[mediaType] =
                (updatedByType[mediaType] ?? 0) + 1;
          case _ImportItemResult.skipped:
            itemsSkipped++;
        }

        itemProgress++;
      }

      if (options.importWatched && watchedShows.isNotEmpty) {
        int episodeProgress = 0;
        int totalEpisodes = 0;
        for (final _TraktShow s in watchedShows) {
          for (final _TraktSeason season in s.seasons) {
            totalEpisodes += season.episodes.length;
          }
        }

        for (final _TraktShow traktShow in watchedShows) {
          if (traktShow.tmdbId == null) continue;

          for (final _TraktSeason season in traktShow.seasons) {
            for (final _TraktEpisode episode in season.episodes) {
              onProgress?.call(ImportProgress(
                stage: ImportStage.addingItems,
                current: episodeProgress,
                total: totalEpisodes,
                message: 'Importing episodes for "${traktShow.title}"...',
              ));

              await _database.markEpisodeWatched(
                collectionId,
                traktShow.tmdbId!,
                season.number,
                episode.number,
              );
              episodeProgress++;
            }
          }
        }
      }

      if (options.importRatings) {
        final List<_TraktRating> allRatings = <_TraktRating>[
          ...movieRatings,
          ...showRatings,
        ];

        for (int i = 0; i < allRatings.length; i++) {
          final _TraktRating rating = allRatings[i];

          onProgress?.call(ImportProgress(
            stage: ImportStage.addingItems,
            current: i,
            total: allRatings.length,
            message: 'Applying rating for "${rating.title}"...',
          ));

          if (rating.tmdbId == null) continue;

          final ({MediaType mediaType, int? platformId}) resolved =
              _resolveMediaType(
            isMovie: rating.type == 'movie',
            movieIsAnimation: movieIsAnimation,
            showIsAnimation: showIsAnimation,
            tmdbId: rating.tmdbId!,
          );

          final CollectionItem? existing = await _repository.findItem(
            collectionId: collectionId,
            mediaType: resolved.mediaType,
            externalId: rating.tmdbId!,
          );

          if (existing != null) {
            // Only set rating if local one is unset — never overwrite user input.
            if (existing.userRating == null) {
              await _database.updateItemUserRating(
                existing.id,
                rating.rating.clamp(1, 10),
              );
              itemsUpdated++;
              updatedByType[resolved.mediaType] =
                  (updatedByType[resolved.mediaType] ?? 0) + 1;
            }
          } else {
            // No existing item: only add if TMDB data was fetched.
            final bool hasData = rating.type == 'movie'
                ? fetchedMovies.containsKey(rating.tmdbId)
                : fetchedShows.containsKey(rating.tmdbId);

            if (hasData) {
              final int? itemId = await _repository.addItem(
                collectionId: collectionId,
                mediaType: resolved.mediaType,
                externalId: rating.tmdbId!,
                platformId: resolved.platformId,
              );
              if (itemId != null) {
                await _database.updateItemUserRating(
                  itemId,
                  rating.rating.clamp(1, 10),
                );
                itemsImported++;
                importedByType[resolved.mediaType] =
                    (importedByType[resolved.mediaType] ?? 0) + 1;
              }
            }
          }
        }
      }

      int wishlistItemsAdded = 0;

      if (options.importWatchlist && watchlistEntries.isNotEmpty) {
        for (int i = 0; i < watchlistEntries.length; i++) {
          final _TraktWatchlistEntry entry = watchlistEntries[i];

          onProgress?.call(ImportProgress(
            stage: ImportStage.addingItems,
            current: i,
            total: watchlistEntries.length,
            message: 'Adding "${entry.title}" to wishlist...',
          ));

          if (entry.tmdbId != null) {
            final ({MediaType mediaType, int? platformId}) resolved =
                _resolveMediaType(
              isMovie: entry.type == 'movie',
              movieIsAnimation: movieIsAnimation,
              showIsAnimation: showIsAnimation,
              tmdbId: entry.tmdbId!,
            );

            final CollectionItem? existing = await _repository.findItem(
              collectionId: collectionId,
              mediaType: resolved.mediaType,
              externalId: entry.tmdbId!,
            );

            if (existing == null) {
              final bool hasData = entry.type == 'movie'
                  ? fetchedMovies.containsKey(entry.tmdbId)
                  : fetchedShows.containsKey(entry.tmdbId);

              if (hasData) {
                final int? itemId = await _repository.addItem(
                  collectionId: collectionId,
                  mediaType: resolved.mediaType,
                  externalId: entry.tmdbId!,
                  platformId: resolved.platformId,
                  status: ItemStatus.planned,
                );
                if (itemId != null) {
                  itemsImported++;
                  importedByType[resolved.mediaType] =
                      (importedByType[resolved.mediaType] ?? 0) + 1;
                  continue;
                }
              }
            } else {
              continue;
            }
          }

          // Fallback: add to text Wishlist with title-based dedup.
          final MediaType hint = entry.type == 'movie'
              ? MediaType.movie
              : MediaType.tvShow;

          final WishlistItem? existingWishlist =
              await _wishlistRepository.findUnresolved(entry.title);
          if (existingWishlist == null) {
            await _wishlistRepository.add(
              text: entry.title,
              mediaTypeHint: hint,
            );
            wishlistItemsAdded++;
          }
        }
      }

      onProgress?.call(const ImportProgress(
        stage: ImportStage.completed,
        current: 1,
        total: 1,
      ));

      // Total wishlist = watched fallback + watchlist section
      final int totalWishlistAdded = wishlistItemsAdded +
          wishlistedByType.values.fold<int>(0, (int s, int v) => s + v);

      return TraktImportResult.success(
        collection: collection,
        itemsImported: itemsImported,
        itemsSkipped: itemsSkipped,
        itemsUpdated: itemsUpdated,
        wishlistItemsAdded: totalWishlistAdded,
        importedByType: importedByType,
        wishlistedByType: wishlistedByType,
        updatedByType: updatedByType,
        errors: errors,
      );
    } on Exception catch (e) {
      return TraktImportResult.failure('Import failed: $e');
    }
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

  Future<_ImportItemResult> _importOrUpdateItem({
    required int collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    required ItemStatus status,
    DateTime? completedAt,
  }) async {
    final CollectionItem? existing = await _repository.findItem(
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
    );

    if (existing == null) {
      final int? itemId = await _repository.addItem(
        collectionId: collectionId,
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
        status: status,
      );

      if (itemId == null) return _ImportItemResult.skipped;

      if (completedAt != null) {
        await _database.updateItemActivityDates(
          itemId,
          completedAt: completedAt,
          lastActivityAt: completedAt,
        );
      }

      return _ImportItemResult.added;
    }

    bool updated = false;

    // Status merge protects `dropped` and never downgrades existing status.
    final ItemStatus? mergedStatus = mergeExternalStatus(
      currentStatus: existing.status,
      externalStatus: status,
    );
    if (mergedStatus != null) {
      await _repository.updateItemStatus(
        existing.id,
        mergedStatus,
        mediaType: mediaType,
      );
      updated = true;
    }

    // Set completedAt only if local is null — never overwrite existing dates.
    if (completedAt != null && existing.completedAt == null) {
      await _database.updateItemActivityDates(
        existing.id,
        completedAt: completedAt,
      );
      updated = true;
    }

    return updated ? _ImportItemResult.updated : _ImportItemResult.skipped;
  }
}

enum _ImportItemResult { added, updated, skipped }

extension TraktImportResultToUniversal on TraktImportResult {
  UniversalImportResult toUniversal() {
    if (!success) {
      return UniversalImportResult.failure(
        sourceName: 'Trakt',
        error: error ?? 'Unknown error',
      );
    }

    return UniversalImportResult(
      sourceName: 'Trakt',
      success: true,
      collection: collection,
      importedByType: importedByType,
      wishlistedByType: wishlistedByType,
      updatedByType: updatedByType,
      skipped: itemsSkipped,
      errors: errors,
    );
  }
}
