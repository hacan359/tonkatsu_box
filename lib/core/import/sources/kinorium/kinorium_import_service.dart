import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../data/repositories/wishlist_repository.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/data_source.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/movie.dart';
import '../../../../shared/models/tv_show.dart';
import '../../../../shared/models/universal_import_result.dart';
import '../../../../shared/models/wishlist_tag.dart';
import '../../../api/tmdb_api.dart';
import '../../../database/database_service.dart';
import '../../../services/import_service.dart';
import '../../import_source.dart';
import '../../import_writer.dart';
import '../../tmdb_matcher.dart';
import 'kinorium_csv_parser.dart';
import 'kinorium_entry.dart';

final Provider<KinoriumImportService> kinoriumImportServiceProvider =
    Provider<KinoriumImportService>((Ref ref) {
  return KinoriumImportService(
    repository: ref.watch(collectionRepositoryProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
    tmdbApi: ref.watch(tmdbApiProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

class KinoriumImportOptions extends ImportOptions {
  const KinoriumImportOptions({
    required this.filePath,
    super.collectionId,
    this.isWishlist = false,
    this.importNotes = false,
    this.reasons = const KinoriumWishlistReasons.english(),
  });

  final String filePath;

  /// The "Watchlist" (Kinorium's «Буду смотреть» list) toggle. `true` imports
  /// every row as [ItemStatus.planned]; `false` imports as
  /// [ItemStatus.completed] and carries over the rating and watch date.
  final bool isWishlist;

  /// Append actors/directors/notes to the item comment.
  final bool importNotes;

  /// Localized texts for why a row was wishlisted instead of imported.
  final KinoriumWishlistReasons reasons;
}

/// Localized reasons a Kinorium row landed in the wishlist. Built in the UI
/// (the import service has no [BuildContext]) and passed via the options; the
/// service falls back to [KinoriumWishlistReasons.english] when none is given.
class KinoriumWishlistReasons {
  const KinoriumWishlistReasons({
    required this.notFound,
    required this.apiError,
    required this.unsupportedType,
    required this.duplicate,
  });

  /// English defaults so the service and tests work without the UI layer.
  const KinoriumWishlistReasons.english()
      : notFound = 'Not found on TMDB',
        apiError = 'TMDB error or rate limit',
        unsupportedType = _englishUnsupportedType,
        duplicate = _englishDuplicate;

  final String notFound;
  final String apiError;
  final String Function(String type) unsupportedType;
  final String Function(String otherTitle) duplicate;

  static String _englishUnsupportedType(String type) =>
      'Unsupported type: $type';
  static String _englishDuplicate(String otherTitle) =>
      'Duplicate of "$otherTitle"';
}

/// Imports a Kinorium CSV export by matching each title against TMDB.
///
/// First adapter on the shared import layer: it parses the file, resolves rows
/// with [TmdbMatcher] (Kinorium rows carry no TMDB id, so every row costs a
/// throttled, 429-retried search), then hands the whole scope to [ImportWriter]
/// — collecting first and writing once is far faster than per-row inserts and
/// avoids a half-filled collection appearing mid-import.
class KinoriumImportService implements ImportSource {
  KinoriumImportService({
    required CollectionRepository repository,
    required WishlistRepository wishlistRepository,
    required TmdbApi tmdbApi,
    required DatabaseService database,
    KinoriumCsvParser parser = const KinoriumCsvParser(),
  })  : _writer = ImportWriter(
          collections: repository,
          wishlist: wishlistRepository,
        ),
        _matcher = TmdbMatcher(tmdbApi),
        _database = database,
        _parser = parser;

  final ImportWriter _writer;
  final TmdbMatcher _matcher;
  final DatabaseService _database;
  final KinoriumCsvParser _parser;

  static final Logger _log = Logger('KinoriumImportService');

  @override
  String get displayName => 'Kinorium';

  @override
  Future<UniversalImportResult> import(
    covariant KinoriumImportOptions options, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(const ImportProgress(
        stage: ImportStage.reading,
        current: 0,
        total: 1,
      ));

      final File file = File(options.filePath);
      if (!await file.exists()) {
        return const UniversalImportResult.failure(
          sourceName: 'Kinorium',
          error: 'File not found',
        );
      }

      final List<KinoriumEntry> entries =
          _parser.parseBytes(await file.readAsBytes());
      if (entries.isEmpty) {
        return const UniversalImportResult.failure(
          sourceName: 'Kinorium',
          error: 'No rows found in file',
        );
      }

      // Phase 1 — match every row against TMDB (the slow, network-bound part).
      final KinoriumWishlistReasons reasons = options.reasons;
      final List<(KinoriumEntry, TmdbMatch)> matched =
          <(KinoriumEntry, TmdbMatch)>[];
      // Each unmatched row carries the reason it was wishlisted instead of
      // imported, surfaced in the wishlist note so the user knows what to fix.
      final List<(KinoriumEntry, String)> unmatched =
          <(KinoriumEntry, String)>[];
      final List<String> errors = <String>[];
      int skipped = 0;
      final Map<String, TmdbMatch?> matchCache = <String, TmdbMatch?>{};

      for (int i = 0; i < entries.length; i++) {
        final KinoriumEntry entry = entries[i];

        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: i,
          total: entries.length,
          message: 'Matching "${entry.title}"...',
        ));

        // Not representable as a collection item (episodes, unrecognized
        // types). Route to the wishlist instead of dropping, so nothing the
        // file lists disappears silently.
        if (!_isSupported(entry)) {
          unmatched.add((entry, reasons.unsupportedType(entry.typeLabel)));
          continue;
        }
        if (!entry.hasValidQuery) {
          unmatched.add((entry, reasons.notFound));
          continue;
        }

        TmdbMatch? match;
        bool apiFailed = false;
        try {
          match = await _resolveMatch(
            entry,
            matchCache,
            i,
            entries.length,
            onProgress,
          );
        } on TmdbApiException catch (e) {
          apiFailed = true;
          _log.warning('TMDB search failed for "${entry.title}": ${e.message}');
        }

        if (match == null) {
          unmatched.add((entry, apiFailed ? reasons.apiError : reasons.notFound));
        } else {
          matched.add((entry, match));
        }
      }

      // Two rows can resolve to the same TMDB id (a real re-listing, or a
      // mismatch where different titles collapse onto one film). Keep the first
      // and send the rest to the wishlist rather than dropping them as silent
      // duplicates, so a wrong collapse is recoverable by hand.
      final Set<String> seenKeys = <String>{};
      final Map<String, String> firstTitleByKey = <String, String>{};
      final List<(KinoriumEntry, TmdbMatch)> uniqueMatched =
          <(KinoriumEntry, TmdbMatch)>[];
      for (final (KinoriumEntry, TmdbMatch) pair in matched) {
        final String key = ImportWriter.itemKey(
          pair.$2.mediaType,
          pair.$2.tmdbId,
          pair.$2.platformId,
        );
        if (seenKeys.add(key)) {
          uniqueMatched.add(pair);
          firstTitleByKey[key] = pair.$1.title;
        } else {
          unmatched.add(
            (pair.$1, reasons.duplicate(firstTitleByKey[key] ?? '')),
          );
        }
      }

      // Phase 2 — write the whole scope in batches.
      onProgress?.call(ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 0,
        total: 1,
        message: 'Saving ${uniqueMatched.length} items...',
      ));

      await _upsertMedia(uniqueMatched);

      final Collection? collection = await _writer.resolveCollection(
        collectionId: options.collectionId,
        newCollectionName:
            options.isWishlist ? 'Kinorium: Watchlist' : 'Kinorium',
        author: 'Kinorium',
      );
      if (collection == null) {
        return const UniversalImportResult.failure(
          sourceName: 'Kinorium',
          error: 'Collection not found',
        );
      }

      final ItemStatus status =
          options.isWishlist ? ItemStatus.planned : ItemStatus.completed;

      final ImportWriteResult write = await _writer.writeItems(
        collectionId: collection.id,
        candidates: <ImportCandidate>[
          for (final (KinoriumEntry, TmdbMatch) pair in uniqueMatched)
            _candidate(pair.$1, pair.$2, status, options),
        ],
      );
      skipped += write.skipped;

      final Map<MediaType, int> wishlistedByType = await _writer.writeWishlist(
        entries: <WishlistCandidate>[
          for (final (KinoriumEntry, String) u in unmatched)
            WishlistCandidate(
              text: u.$1.title,
              mediaType: _wishlistType(u.$1),
              note: _composeNote(u.$1, includeCastCrew: true, reason: u.$2),
            ),
        ],
        tag: buildImportTag('Kinorium'),
      );

      onProgress?.call(const ImportProgress(
        stage: ImportStage.completed,
        current: 1,
        total: 1,
      ));

      return UniversalImportResult(
        sourceName: 'Kinorium',
        success: true,
        collection: collection,
        importedByType: write.importedByType,
        updatedByType: write.updatedByType,
        wishlistedByType: wishlistedByType,
        skipped: skipped,
        errors: errors,
      );
    } on KinoriumParseException catch (e) {
      return UniversalImportResult.failure(
        sourceName: 'Kinorium',
        error: e.message,
      );
    } on Exception catch (e) {
      return UniversalImportResult.failure(
        sourceName: 'Kinorium',
        error: 'Import failed: $e',
      );
    }
  }

  /// Batch-upserts the matched media into the cache so collection items can
  /// hydrate. Dedups by tmdb id (the file may list the same title twice).
  Future<void> _upsertMedia(List<(KinoriumEntry, TmdbMatch)> matched) async {
    final Map<int, Movie> movies = <int, Movie>{};
    final Map<int, TvShow> shows = <int, TvShow>{};
    for (final (KinoriumEntry, TmdbMatch) pair in matched) {
      final TmdbMatch match = pair.$2;
      if (match.movie != null) movies[match.tmdbId] = match.movie!;
      if (match.show != null) shows[match.tmdbId] = match.show!;
    }
    if (movies.isNotEmpty) {
      await _database.movieDao.upsertMovies(movies.values.toList());
    }
    if (shows.isNotEmpty) {
      await _database.tvShowDao.upsertTvShows(shows.values.toList());
    }
  }

  ImportCandidate _candidate(
    KinoriumEntry entry,
    TmdbMatch match,
    ItemStatus status,
    KinoriumImportOptions options,
  ) {
    return ImportCandidate(
      mediaType: match.mediaType,
      externalId: match.tmdbId,
      platformId: match.platformId,
      insertRow: _collectionRow(entry, match, status, options),
      changedFields: (CollectionItem existing) =>
          _changedFields(entry, existing, options),
    );
  }

  /// Columns to refresh on a re-sync: rating and note, but only when Kinorium
  /// supplies a value that differs from the stored one (never wipes existing
  /// data when the export has nothing).
  Map<String, dynamic> _changedFields(
    KinoriumEntry entry,
    CollectionItem current,
    KinoriumImportOptions options,
  ) {
    final Map<String, dynamic> fields = <String, dynamic>{};
    final double? rating = entry.myRating;
    if (rating != null && rating != current.userRating) {
      fields['user_rating'] = rating;
    }
    final String note =
        _composeNote(entry, includeCastCrew: options.importNotes);
    if (note != current.userComment) {
      fields['user_comment'] = note;
    }
    return fields;
  }

  Map<String, dynamic> _collectionRow(
    KinoriumEntry entry,
    TmdbMatch match,
    ItemStatus status,
    KinoriumImportOptions options,
  ) {
    final int? dateEpoch = (!options.isWishlist && entry.date != null)
        ? entry.date!.millisecondsSinceEpoch ~/ 1000
        : null;
    return <String, dynamic>{
      'media_type': match.mediaType.value,
      'external_id': match.tmdbId,
      'platform_id': match.platformId,
      'source': DataSource.tmdb.name,
      'status': status.value,
      'user_rating': entry.myRating,
      'completed_at': dateEpoch,
      'last_activity_at': dateEpoch,
      'user_comment': _composeNote(entry, includeCastCrew: options.importNotes),
    };
  }

  /// Searches TMDB (cached per identical query) and returns the match, or null
  /// when nothing matched.
  Future<TmdbMatch?> _resolveMatch(
    KinoriumEntry entry,
    Map<String, TmdbMatch?> cache,
    int index,
    int total,
    ImportProgressCallback? onProgress,
  ) async {
    final String key = '${entry.type.isTvLike ? 't' : 'm'}'
        '|${entry.searchQuery.toLowerCase()}|${entry.year ?? ''}';
    if (cache.containsKey(key)) {
      return cache[key];
    }

    void onRateLimit(Duration wait, int attempt) {
      onProgress?.call(ImportProgress(
        stage: ImportStage.addingItems,
        current: index,
        total: total,
        message: 'Rate limited, waiting ${wait.inSeconds}s (attempt $attempt)...',
      ));
    }

    final TmdbMatch? match = entry.type.isTvLike
        ? await _matcher.matchTvShow(
            primaryQuery: entry.searchQuery,
            fallbackQuery: entry.title,
            year: entry.year,
            animationHint: entry.type.isAnimationHint,
            onRateLimit: onRateLimit,
          )
        : await _matcher.matchMovie(
            primaryQuery: entry.searchQuery,
            fallbackQuery: entry.title,
            year: entry.year,
            animationHint: entry.type.isAnimationHint,
            onRateLimit: onRateLimit,
          );

    cache[key] = match;
    return match;
  }

  /// Builds the item comment. An optional [reason] (why the row was wishlisted)
  /// leads, then cast & crew when [includeCastCrew] is set (the wishlist always
  /// passes it), any original Note text, and always a Kinorium search link
  /// (markdown, so the note renders a clickable "Link" instead of a raw URL).
  String _composeNote(
    KinoriumEntry entry, {
    required bool includeCastCrew,
    String? reason,
  }) {
    final String url = 'https://en.kinorium.com/search/?q='
        '${Uri.encodeComponent(entry.searchQuery)}';
    final List<String> parts = <String>[
      ?reason,
      if (includeCastCrew && entry.directors != null)
        'Directors: ${entry.directors}',
      if (includeCastCrew && entry.actors != null) 'Actors: ${entry.actors}',
      if (entry.note != null) entry.note!,
      '[Link]($url)',
    ];
    return parts.join('\n');
  }

  bool _isSupported(KinoriumEntry entry) =>
      entry.type.isMovieLike || entry.type.isTvLike;

  MediaType _wishlistType(KinoriumEntry entry) =>
      entry.type.isTvLike ? MediaType.tvShow : MediaType.movie;
}
