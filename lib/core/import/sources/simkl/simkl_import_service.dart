import 'package:core/models/anime.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/item_status_logic.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/universal_import_result.dart';
import 'package:core/models/wishlist_tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../data/repositories/wishlist_repository.dart';
import '../../../api/kitsu_api.dart';
import '../../../api/simkl_api.dart';
import '../../../api/tmdb_api.dart';
import '../../../database/database_service.dart';
import '../../import_columns.dart';
import '../../import_progress.dart';
import '../../import_source.dart';
import '../../import_writer.dart';
import '../../rate_limited_retry.dart';
import '../../tmdb_matcher.dart';
import '../anilist/anilist_import_service.dart' show ImportMode;

/// Tag applied to entries Simkl reports as `hold`: our [ItemStatus] has no
/// "on hold", so they land as [ItemStatus.planned] and stay findable by tag.
const String kSimklOnHoldTag = 'on-hold';

/// Provider for [SimklImportService].
final Provider<SimklImportService> simklImportServiceProvider =
    Provider<SimklImportService>((Ref ref) {
  return SimklImportService(
    simklApi: ref.watch(simklApiProvider),
    tmdbApi: ref.watch(tmdbApiProvider),
    kitsuApi: ref.watch(kitsuApiProvider),
    database: ref.watch(databaseServiceProvider),
    repository: ref.watch(collectionRepositoryProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

class SimklImportOptions extends ImportOptions {
  const SimklImportOptions({
    required this.mode,
    required this.author,
    required this.newCollectionName,
    super.collectionId,
  });

  final ImportMode mode;

  /// Author / name for a freshly created collection (the Simkl account name).
  final String author;
  final String newCollectionName;
}

/// Simkl import: movies and shows enrich from TMDB, anime resolves to Kitsu
/// (per-episode marks); anything unresolved goes to the text wishlist.
class SimklImportService implements ImportSource {
  SimklImportService({
    required SimklApi simklApi,
    required TmdbApi tmdbApi,
    required KitsuApi kitsuApi,
    required DatabaseService database,
    required CollectionRepository repository,
    required WishlistRepository wishlistRepository,
  })  : _simkl = simklApi,
        _tmdb = tmdbApi,
        _kitsu = kitsuApi,
        _db = database,
        _writer = ImportWriter(
          collections: repository,
          wishlist: wishlistRepository,
        );

  static final Logger _log = Logger('SimklImportService');

  static const RateLimitedRetry _retry = RateLimitedRetry();

  final SimklApi _simkl;
  final TmdbApi _tmdb;
  final KitsuApi _kitsu;
  final DatabaseService _db;
  final ImportWriter _writer;

  @override
  String get displayName => 'Simkl';

  @override
  Future<UniversalImportResult> import(
    covariant SimklImportOptions options, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      return await _import(options, onProgress);
    } on Exception catch (e) {
      final ({String message, String? detail}) err = _extractError(e);
      return UniversalImportResult.failure(
        sourceName: displayName,
        error: 'Import failed: ${err.message}',
        detail: err.detail,
      );
    }
  }

  Future<UniversalImportResult> _import(
    SimklImportOptions options,
    ImportProgressCallback? onProgress,
  ) async {
    onProgress?.call(const ImportProgress(
      stage: ImportStage.reading,
      current: 0,
      total: 0,
    ));

    final SimklAllItems items = await _retry.run(
      _simkl.getAllItems,
      isRateLimit: _isRateLimit,
      onRetry: (Duration wait, int attempt) => onProgress?.call(ImportProgress(
        stage: ImportStage.reading,
        current: 0,
        total: 0,
        retryWaitSeconds: wait.inSeconds,
        retryAttempt: attempt,
        retryMaxAttempts: _retry.maxAttempts,
      )),
    );
    if (items.isEmpty) {
      return UniversalImportResult.failure(
        sourceName: displayName,
        error: 'No data found in the Simkl account',
      );
    }

    final List<WishlistCandidate> wishlistFallback = <WishlistCandidate>[];

    final int tmdbTotal = items.movies.length + items.shows.length;
    final _TmdbFetch movies = await _fetchTmdbCards<Movie>(
      entries: items.movies,
      stage: ImportStage.fetchingMovies,
      onProgress: onProgress,
      grandTotal: tmdbTotal,
      fetch: _tmdb.getMovie,
      cache: (Movie movie) => _db.movieDao.upsertMovie(movie),
      genresOf: (Movie movie) => movie.genres,
    );
    final _TmdbFetch shows = await _fetchTmdbCards<TvShow>(
      entries: items.shows,
      stage: ImportStage.fetchingTvShows,
      onProgress: onProgress,
      grandTotal: tmdbTotal,
      alreadyFetched: items.movies.length,
      fetch: _tmdb.getTvShow,
      cache: (TvShow show) => _db.tvShowDao.upsertTvShow(show),
      genresOf: (TvShow show) => show.genres,
    );

    onProgress?.call(ImportProgress(
      stage: ImportStage.fetchingAnime,
      current: 0,
      total: items.anime.length,
    ));
    final Map<int, Anime> animeBySimklIndex = await _resolveAnime(items.anime);
    onProgress?.call(ImportProgress(
      stage: ImportStage.fetchingAnime,
      current: items.anime.length,
      total: items.anime.length,
    ));

    final List<Anime> animeCards =
        animeBySimklIndex.values.toList(growable: false);
    if (animeCards.isNotEmpty) await _db.animeDao.upsertAnimes(animeCards);

    // Create the collection only after the fetches succeeded.
    final Collection? collection = await _writer.resolveCollection(
      collectionId: options.collectionId,
      newCollectionName: options.newCollectionName,
      author: options.author,
    );
    if (collection == null) {
      return UniversalImportResult.failure(
        sourceName: displayName,
        error: 'Collection not found',
      );
    }

    final List<ImportCandidate> candidates = <ImportCandidate>[];
    final List<_HeldItem> held = <_HeldItem>[];
    final List<_EpisodeMarks> episodeMarks = <_EpisodeMarks>[];

    for (final SimklEntry entry in items.movies) {
      final int? tmdbId = entry.ids.tmdb;
      if (tmdbId == null || !movies.isAnimation.containsKey(tmdbId)) {
        wishlistFallback.add(_wishlistEntry(entry, MediaType.movie));
        continue;
      }
      final bool isAnimation = movies.isAnimation[tmdbId] ?? false;
      final MediaType mediaType =
          isAnimation ? MediaType.animation : MediaType.movie;
      final int? platformId = isAnimation ? AnimationSource.movie : null;
      candidates.add(_candidate(
        entry,
        mediaType: mediaType,
        externalId: tmdbId,
        platformId: platformId,
        simklUrl: _simklUrl(entry, 'movies'),
        mode: options.mode,
      ));
      _trackHold(held, entry, mediaType, tmdbId, platformId);
    }

    for (final SimklEntry entry in items.shows) {
      final int? tmdbId = entry.ids.tmdb;
      if (tmdbId == null || !shows.isAnimation.containsKey(tmdbId)) {
        wishlistFallback.add(_wishlistEntry(entry, MediaType.tvShow));
        continue;
      }
      final bool isAnimation = shows.isAnimation[tmdbId] ?? false;
      final MediaType mediaType =
          isAnimation ? MediaType.animation : MediaType.tvShow;
      final int? platformId = isAnimation ? AnimationSource.tvShow : null;
      candidates.add(_candidate(
        entry,
        mediaType: mediaType,
        externalId: tmdbId,
        platformId: platformId,
        simklUrl: _simklUrl(entry, 'tv'),
        mode: options.mode,
      ));
      _trackHold(held, entry, mediaType, tmdbId, platformId);
      if (entry.hasEpisodeMarks || entry.isCompleted) {
        episodeMarks.add(_EpisodeMarks.forShow(
          entry,
          tmdbId,
          fillAll: entry.isCompleted,
        ));
      }
    }

    for (int i = 0; i < items.anime.length; i++) {
      final SimklEntry entry = items.anime[i];
      final Anime? anime = animeBySimklIndex[i];
      if (anime == null) {
        wishlistFallback.add(_wishlistEntry(entry, MediaType.anime));
        continue;
      }
      candidates.add(_candidate(
        entry,
        mediaType: MediaType.anime,
        externalId: anime.id,
        platformId: null,
        source: DataSource.kitsu,
        simklUrl: _simklUrl(entry, 'anime'),
        mode: options.mode,
      ));
      _trackHold(held, entry, MediaType.anime, anime.id, null);
      if (entry.hasEpisodeMarks || entry.isCompleted) {
        episodeMarks.add(_EpisodeMarks.forAnime(
          entry,
          anime.id,
          fillAll: entry.isCompleted,
        ));
      }
    }

    onProgress?.call(ImportProgress(
      stage: ImportStage.addingItems,
      current: 0,
      total: candidates.length,
    ));
    final ImportWriteResult write = await _writer.writeItems(
      collectionId: collection.id,
      candidates: candidates,
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
    );

    await _writeEpisodeMarks(collection.id, episodeMarks, onProgress);

    await _applyOnHoldTag(write, held);

    final Map<MediaType, int> wishlisted = await _writer.writeWishlist(
      entries: wishlistFallback,
      tag: buildImportTag(displayName),
    );

    onProgress?.call(ImportProgress(
      stage: ImportStage.completed,
      current: 1,
      total: 1,
      imported: sumByType(write.importedByType),
      updated: sumByType(write.updatedByType),
      wishlisted: sumByType(wishlisted),
    ));

    _log.info(
      'Simkl import complete for "${options.author}": '
      'imported ${write.importedByType}, updated ${write.updatedByType}, '
      'wishlisted $wishlisted (total ${items.totalCount})',
    );

    return UniversalImportResult(
      sourceName: displayName,
      success: true,
      collection: collection,
      importedByType: write.importedByType,
      updatedByType: write.updatedByType,
      wishlistedByType: wishlisted,
      skipped: write.skipped,
    );
  }


  /// Fetches the TMDB card per distinct `ids.tmdb`; a failed title is simply
  /// absent and routes to the wishlist. [alreadyFetched] offsets progress.
  Future<_TmdbFetch> _fetchTmdbCards<T>({
    required List<SimklEntry> entries,
    required ImportStage stage,
    required ImportProgressCallback? onProgress,
    required int grandTotal,
    required Future<T?> Function(int tmdbId) fetch,
    required Future<void> Function(T card) cache,
    required List<String>? Function(T card) genresOf,
    int alreadyFetched = 0,
  }) async {
    final _TmdbFetch result = _TmdbFetch();
    final Set<int> ids = <int>{
      for (final SimklEntry e in entries)
        if (e.ids.tmdb != null) e.ids.tmdb!,
    };
    int done = 0;
    for (final int tmdbId in ids) {
      onProgress?.call(ImportProgress(
        stage: stage,
        current: alreadyFetched + done,
        total: grandTotal,
      ));
      try {
        final T? card = await _retry.run(
          () => fetch(tmdbId),
          isRateLimit: _isRateLimit,
          onRetry: (Duration wait, int attempt) =>
              onProgress?.call(ImportProgress(
            stage: stage,
            current: alreadyFetched + done,
            total: grandTotal,
            retryWaitSeconds: wait.inSeconds,
            retryAttempt: attempt,
            retryMaxAttempts: _retry.maxAttempts,
          )),
        );
        if (card != null) {
          await cache(card);
          result.isAnimation[tmdbId] =
              TmdbMatcher.isAnimationByGenres(genresOf(card));
        }
      } on Exception catch (e) {
        _log.warning('Simkl: TMDB ${stage.name} $tmdbId failed: $e');
      }
      done++;
    }
    return result;
  }

  /// Maps each anime entry index to its Kitsu card: direct `kitsu` ids, then
  /// `/mappings` by MAL, then AniDB. Unresolved entries route to the wishlist.
  Future<Map<int, Anime>> _resolveAnime(List<SimklEntry> entries) async {
    final Map<int, Anime> resolved = <int, Anime>{};

    // Lane 1: direct Kitsu ids.
    final Map<int, int> kitsuIdByIndex = <int, int>{
      for (int i = 0; i < entries.length; i++)
        if (entries[i].ids.kitsu != null) i: entries[i].ids.kitsu!,
    };
    if (kitsuIdByIndex.isNotEmpty) {
      try {
        final List<Anime> cards = await _retry.run(
          () => _kitsu.getAnimeByIds(kitsuIdByIndex.values.toSet().toList()),
          isRateLimit: _isRateLimit,
        );
        final Map<int, Anime> byId = <int, Anime>{
          for (final Anime a in cards) a.id: a,
        };
        kitsuIdByIndex.forEach((int index, int kitsuId) {
          final Anime? card = byId[kitsuId];
          if (card != null) resolved[index] = card;
        });
      } on Exception catch (e) {
        _log.warning('Simkl: Kitsu direct id fetch failed: $e');
      }
    }

    // Lane 2 / 3: mappings by MAL, then AniDB, for whatever is left.
    for (final _MappingLane lane in <_MappingLane>[
      _MappingLane('mal', (SimklEntry e) => e.ids.mal, _kitsu.getAnimeByMalIds),
      _MappingLane(
        'anidb',
        (SimklEntry e) => e.ids.anidb,
        _kitsu.getAnimeByAnidbIds,
      ),
    ]) {
      final Map<int, int> pending = <int, int>{
        for (int i = 0; i < entries.length; i++)
          if (!resolved.containsKey(i) && lane.idOf(entries[i]) != null)
            i: lane.idOf(entries[i])!,
      };
      if (pending.isEmpty) continue;
      try {
        final Map<int, Anime> byExternal = await _retry.run(
          () => lane.resolve(pending.values.toSet().toList()),
          isRateLimit: _isRateLimit,
        );
        pending.forEach((int index, int externalId) {
          final Anime? card = byExternal[externalId];
          if (card != null) resolved[index] = card;
        });
      } on Exception catch (e) {
        _log.warning('Simkl: Kitsu ${lane.name} mapping lookup failed: $e');
      }
    }

    return resolved;
  }


  /// Simkl page for the note: `simkl.com/<section>/<id>[/<slug>]`.
  static String? _simklUrl(SimklEntry entry, String section) {
    final int? id = entry.ids.simkl;
    if (id == null) return null;
    final String? slug = entry.ids.slug;
    final String tail = (slug != null && slug.isNotEmpty) ? '/$slug' : '';
    return 'https://simkl.com/$section/$id$tail';
  }

  /// The item note: the Simkl link first, then the user's memo when present.
  static String? _buildUserComment(SimklEntry entry, String? simklUrl) {
    final List<String> lines = <String>[
      if (simklUrl != null) '[Simkl]($simklUrl)',
      if (simklUrl != null && entry.memoText != null) '',
      if (entry.memoText != null) entry.memoText!,
    ];
    return lines.isEmpty ? null : lines.join('\n');
  }

  ImportCandidate _candidate(
    SimklEntry entry, {
    required MediaType mediaType,
    required int externalId,
    required int? platformId,
    required ImportMode mode,
    required String? simklUrl,
    DataSource? source,
  }) {
    final ItemStatus status = _mapStatus(entry);
    return ImportCandidate(
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      label: entry.title.isNotEmpty ? entry.title : '#$externalId',
      insertRow: _insertRow(entry, status,
          mediaType: mediaType,
          externalId: externalId,
          platformId: platformId,
          source: source,
          simklUrl: simklUrl),
      changedFields: (CollectionItem existing) => mode == ImportMode.newOnly
          ? const <String, dynamic>{}
          : _changedFields(entry, existing, simklUrl),
    );
  }

  Map<String, dynamic> _insertRow(
    SimklEntry entry,
    ItemStatus status, {
    required MediaType mediaType,
    required int externalId,
    required int? platformId,
    required DataSource? source,
    required String? simklUrl,
  }) {
    final _ResolvedDates dates = _resolveDates(entry, status);
    return <String, dynamic>{
      'media_type': mediaType.value,
      'external_id': externalId,
      'platform_id': ?platformId,
      'source': ?source?.name,
      'status': status.value,
      'user_rating': ?_resolveRating(entry.userRating),
      'added_at': ?epochSeconds(dates.addedAt),
      'started_at': ?epochSeconds(dates.startedAt),
      'completed_at': ?epochSeconds(dates.completedAt),
      'last_activity_at': ?epochSeconds(dates.lastActivityAt),
      'user_comment': ?_buildUserComment(entry, simklUrl),
    };
  }

  /// Overwrite-mode re-sync: bump status without downgrading, keep earliest
  /// start / latest completion, refresh rating and note.
  Map<String, dynamic> _changedFields(
    SimklEntry entry,
    CollectionItem existing,
    String? simklUrl,
  ) {
    final ItemStatus status = _mapStatus(entry);
    final Map<String, dynamic> fields = <String, dynamic>{};

    final ItemStatus? newStatus = mergeExternalStatus(
      currentStatus: existing.status,
      externalStatus: status,
    );
    if (newStatus != null) {
      fields.addAll(statusDateColumns(newStatus, existing));
    }

    final double? rating = _resolveRating(entry.userRating);
    if (rating != null && rating != existing.userRating) {
      fields['user_rating'] = rating;
    }

    final _ResolvedDates remote = _resolveDates(entry, status);
    if (remote.startedAt != null &&
        (existing.startedAt == null ||
            remote.startedAt!.isBefore(existing.startedAt!))) {
      fields['started_at'] = epochSeconds(remote.startedAt);
    }
    if (remote.completedAt != null &&
        (existing.completedAt == null ||
            remote.completedAt!.isAfter(existing.completedAt!))) {
      fields['completed_at'] = epochSeconds(remote.completedAt);
    }

    final String? comment = _buildUserComment(entry, simklUrl);
    if (comment != null && comment != existing.userComment) {
      fields['user_comment'] = comment;
    }

    return fields;
  }

  /// Date ladder from the working yamtrack implementation: last watch, then
  /// watchlist addition, then nothing (the DB stamps `added_at` itself).
  _ResolvedDates _resolveDates(SimklEntry entry, ItemStatus status) {
    final DateTime? added = entry.lastWatchedAt ?? entry.addedToWatchlistAt;

    DateTime? started;
    for (final SimklSeason season in entry.seasons) {
      for (final SimklEpisodeMark episode in season.episodes) {
        if (episode.watchedAt != null &&
            (started == null || episode.watchedAt!.isBefore(started))) {
          started = episode.watchedAt;
        }
      }
    }

    return _ResolvedDates(
      addedAt: added,
      startedAt: started,
      completedAt:
          status == ItemStatus.completed ? entry.lastWatchedAt ?? added : null,
      lastActivityAt: entry.lastWatchedAt,
    );
  }

  /// Simkl ratings are integer 1–10, same scale as ours.
  static double? _resolveRating(int? rating) {
    if (rating == null || rating <= 0) return null;
    return rating.clamp(1, 10).toDouble();
  }

  static ItemStatus _mapStatus(SimklEntry entry) {
    switch (entry.normalizedStatus) {
      case 'watching':
        return ItemStatus.inProgress;
      case 'plantowatch':
        return ItemStatus.planned;
      case 'completed':
        return ItemStatus.completed;
      case 'dropped':
        return ItemStatus.dropped;
      // No "on hold" in ItemStatus: planned + the on-hold tag keeps the
      // information without inventing a status.
      case 'hold':
        return ItemStatus.planned;
      default:
        _log.warning('Unknown Simkl status: "${entry.status}" → notStarted');
        return ItemStatus.notStarted;
    }
  }

  void _trackHold(
    List<_HeldItem> held,
    SimklEntry entry,
    MediaType mediaType,
    int externalId,
    int? platformId,
  ) {
    if (entry.isOnHold) {
      held.add(_HeldItem(mediaType, externalId, platformId));
    }
  }

  WishlistCandidate _wishlistEntry(SimklEntry entry, MediaType mediaType) {
    final String year = entry.year != null ? ' (${entry.year})' : '';
    return WishlistCandidate(
      text: '${entry.title}$year',
      mediaType: mediaType,
      note: entry.memoText,
    );
  }


  /// Expanding completed titles costs a metadata request per title, so this
  /// phase reports its own progress instead of leaving the bar at 100%.
  Future<void> _writeEpisodeMarks(
    int collectionId,
    List<_EpisodeMarks> marks,
    ImportProgressCallback? onProgress,
  ) async {
    int done = 0;
    for (final _EpisodeMarks mark in marks) {
      onProgress?.call(ImportProgress(
        stage: ImportStage.restoringMedia,
        current: done,
        total: marks.length,
        currentItem: mark.entry.title,
      ));
      try {
        if (mark.isAnime) {
          await _markAnimeEpisodes(collectionId, mark);
        } else {
          await _markShowEpisodes(collectionId, mark);
        }
      } on Exception catch (e) {
        _log.warning(
          'Simkl: episode marks for "${mark.entry.title}" failed: $e',
        );
      }
      done++;
    }
  }

  /// TMDB shows: Simkl numbering matches TMDB directly. `completed` entries
  /// come without `seasons`, so [_EpisodeMarks.fillAll] marks every episode.
  Future<void> _markShowEpisodes(int collectionId, _EpisodeMarks mark) async {
    final int fallbackMs =
        mark.entry.lastWatchedAt?.millisecondsSinceEpoch ??
            mark.entry.addedToWatchlistAt?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;

    final List<_EpisodeRow> rows = <_EpisodeRow>[
      for (final SimklSeason season in mark.entry.seasons)
        for (final SimklEpisodeMark episode in season.episodes)
          (
            season.number,
            episode.number,
            episode.watchedAt?.millisecondsSinceEpoch ?? fallbackMs,
          ),
    ];

    if (mark.fillAll) {
      final List<TvSeason> seasons = await _retry.run(
        () => _tmdb.getTvSeasons(mark.showId),
        isRateLimit: _isRateLimit,
      );
      for (final TvSeason season in seasons) {
        // Season 0 is TMDB specials; the tracker's totals don't count them.
        if (season.seasonNumber < 1) continue;
        final List<TvEpisode> episodes = await _retry.run(
          () => _tmdb.getSeasonEpisodes(mark.showId, season.seasonNumber),
          isRateLimit: _isRateLimit,
        );
        rows.addAll(<_EpisodeRow>[
          for (final TvEpisode episode in episodes)
            (season.seasonNumber, episode.episodeNumber, fallbackMs),
        ]);
      }
    }

    await _db.tvShowDao.markEpisodesWatchedAt(
      collectionId,
      DataSource.tmdb,
      mark.showId,
      rows,
    );
  }

  /// Kitsu anime: Simkl episode numbers are absolute and map onto synthesized
  /// Kitsu seasons via the full episode list; the Simkl season number is ignored.
  Future<void> _markAnimeEpisodes(int collectionId, _EpisodeMarks mark) async {
    final List<TvEpisode> episodes = await _retry.run(
      () => _kitsu.getAnimeEpisodes(mark.showId),
      isRateLimit: _isRateLimit,
    );
    final int fallbackMs =
        mark.entry.lastWatchedAt?.millisecondsSinceEpoch ??
            mark.entry.addedToWatchlistAt?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;

    final Map<int, int> seasonByNumber = <int, int>{
      for (final TvEpisode e in episodes) e.episodeNumber: e.seasonNumber,
    };
    final List<_EpisodeRow> rows = <_EpisodeRow>[
      for (final SimklSeason season in mark.entry.seasons)
        for (final SimklEpisodeMark episode in season.episodes)
          if (seasonByNumber[episode.number] case final int seasonNumber)
            (
              seasonNumber,
              episode.number,
              episode.watchedAt?.millisecondsSinceEpoch ?? fallbackMs,
            ),
      if (mark.fillAll)
        for (final TvEpisode episode in episodes)
          (episode.seasonNumber, episode.episodeNumber, fallbackMs),
    ];

    await _db.tvShowDao.markEpisodesWatchedAt(
      collectionId,
      DataSource.kitsu,
      mark.showId,
      rows,
    );
  }


  Future<void> _applyOnHoldTag(
    ImportWriteResult write,
    List<_HeldItem> held,
  ) async {
    if (held.isEmpty) return;
    try {
      final List<int> itemIds = <int>[
        for (final _HeldItem h in held)
          ?write.idFor(h.mediaType, h.externalId, h.platformId),
      ];
      if (itemIds.isEmpty) return;
      final int tagId =
          await _db.globalTagDao.resolveOrCreate(kSimklOnHoldTag);
      await _db.globalTagDao.addTagToItems(itemIds, tagId);
    } on Exception catch (e) {
      _log.warning('Simkl: applying the on-hold tag failed: $e');
    }
  }

  /// What counts as "wait and retry": the usual 429 from any of the three
  /// APIs, plus Simkl's 412 — that's how it reports an over-quota client id.
  static bool _isRateLimit(Object e) {
    if (e is SimklApiException) {
      return e.statusCode == 429 || e.isClientIdFailure;
    }
    if (e is TmdbApiException) return e.statusCode == 429;
    if (e is KitsuApiException) return e.statusCode == 429;
    return false;
  }

  static ({String message, String? detail}) _extractError(Exception e) {
    if (e is SimklApiException) {
      return (message: e.message, detail: e.detail);
    }
    if (e is KitsuApiException) {
      return (message: e.message, detail: e.detail);
    }
    if (e is TmdbApiException) {
      return (message: e.message, detail: e.detail);
    }
    return (message: e.toString(), detail: null);
  }
}

/// One row for the batched episode-mark write: season, episode, timestamp.
typedef _EpisodeRow = (int, int, int?);

class _TmdbFetch {
  /// tmdbId → "is animation"; a key is present only after a successful fetch.
  final Map<int, bool> isAnimation = <int, bool>{};
}

/// One external-id lane of the Kitsu `/mappings` fallback: which id to read
/// off a Simkl entry and which resolver takes it.
class _MappingLane {
  const _MappingLane(this.name, this.idOf, this.resolve);

  final String name;
  final int? Function(SimklEntry entry) idOf;
  final Future<Map<int, Anime>> Function(List<int> externalIds) resolve;
}

class _HeldItem {
  const _HeldItem(this.mediaType, this.externalId, this.platformId);

  final MediaType mediaType;
  final int externalId;
  final int? platformId;
}

class _EpisodeMarks {
  const _EpisodeMarks._(
    this.entry,
    this.showId, {
    required this.isAnime,
    required this.fillAll,
  });

  factory _EpisodeMarks.forShow(
    SimklEntry entry,
    int tmdbId, {
    bool fillAll = false,
  }) =>
      _EpisodeMarks._(entry, tmdbId, isAnime: false, fillAll: fillAll);

  factory _EpisodeMarks.forAnime(
    SimklEntry entry,
    int kitsuId, {
    bool fillAll = false,
  }) =>
      _EpisodeMarks._(entry, kitsuId, isAnime: true, fillAll: fillAll);

  final SimklEntry entry;
  final int showId;
  final bool isAnime;

  /// Expand the whole title into watched marks (completed entries arrive
  /// from Simkl without the per-episode `seasons` block).
  final bool fillAll;
}

class _ResolvedDates {
  const _ResolvedDates({
    required this.addedAt,
    required this.startedAt,
    required this.completedAt,
    required this.lastActivityAt,
  });

  final DateTime? addedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;
}
