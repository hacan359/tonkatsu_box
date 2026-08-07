import 'package:core/models/anime.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/api/anilist_api.dart';
import '../../../core/api/mangabaka_api.dart';
import '../../../core/api/mangadex_api.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../anime_taste_input.dart';
import '../engine/recommendation_models.dart';
import '../engine/recommender.dart';
import '../manga_taste_input.dart';
import '../tmdb_taste_input.dart';

final Logger _log = Logger('Recommendations');

/// How the Recommendations tab should render.
enum RecommendationStatus {
  /// No completed titles with features in any domain — nothing to learn from.
  empty,

  /// Only the movie/TV profile exists and the TMDB key is missing — kept
  /// apart from [noCandidates] so the message points at the real fix.
  noApiKey,

  /// Profiles exist, but every fetch came back with nothing usable — a
  /// network error, or everything matching is already owned.
  noCandidates,

  /// Recommendations are ready.
  ready,
}

/// A single recommended title, resolved for the UI.
class RecommendedItem {
  /// Creates a recommended item.
  const RecommendedItem({
    required this.tasteId,
    required this.media,
    required this.mediaType,
    required this.source,
    required this.externalId,
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.apiRating,
    required this.score,
    required this.predictedRating,
  });

  /// Engine id (`movie:<id>` / `tv:<id>` / `anime:<source>:<id>` / …).
  final String tasteId;

  /// The underlying [Movie] / [TvShow] / [Anime] / [Manga], handed to the
  /// search add-to-collection handlers so the pick can be added from here.
  final Object media;

  /// The recommended title's media type.
  final MediaType mediaType;

  /// Provider the candidate came from (TMDB / AniList / MangaBaka / …).
  final DataSource source;

  /// The title's id in [source]'s id space.
  final int externalId;

  /// Display title.
  final String title;

  /// Poster URL, or `null` when the source has no poster.
  final String? posterUrl;

  /// Release / first-air year, or `null`.
  final int? year;

  /// The source's community rating (0–10), or `null`.
  final double? apiRating;

  /// Engine match score.
  final double score;

  /// Predicted personal rating (1–10), or `null` when not predictable.
  final double? predictedRating;

  /// External page of the underlying [media].
  String? get externalUrl => switch (media) {
        final Movie m => m.externalUrl,
        final TvShow t => t.externalUrl,
        final Anime a => a.externalUrl,
        final Manga m => m.externalUrl,
        _ => null,
      };
}

/// A row of recommendations under one "because you liked …" header.
class RecommendationRowUi {
  /// Creates a UI recommendation row.
  const RecommendationRowUi({
    required this.becauseTitles,
    required this.genres,
    required this.items,
  });

  /// Top member labels of the cluster the row came from.
  final List<String> becauseTitles;

  /// The cluster's defining genres — shown as the rationale ("our aggregation")
  /// so coarse-genre misses are at least explainable while gathering feedback.
  final List<String> genres;

  /// Items to show in the row.
  final List<RecommendedItem> items;
}

/// The full result for the Recommendations tab.
class RecommendationResult {
  /// Creates a recommendation result.
  const RecommendationResult({required this.status, required this.rows});

  /// Convenience constructor for a non-`ready` state with no rows.
  const RecommendationResult.state(this.status) : rows = const <RecommendationRowUi>[];

  /// What to render.
  final RecommendationStatus status;

  /// Recommendation rows (empty unless [status] is [RecommendationStatus.ready]).
  final List<RecommendationRowUi> rows;
}

/// Genres (across clusters) to query candidates by — generous enough to reach
/// TV-only genre names, which tend to rank below movie genres in the clusters.
const int _maxGenresToQuery = 8;

/// How many candidate pages to pull per genre/domain before moving on.
const int _maxPagesPerGenre = 2;

/// Stop fetching a domain (movies or TV) once it has this many fresh
/// candidates. Tracked per domain so a flood of movie genres can't starve TV.
const int _perDomainTarget = 60;

/// Only consider TMDB titles with at least this many votes — filters out
/// obscure entries that would otherwise dominate by popularity-desc.
const int _minVoteCount = 50;

/// Max items shown per row.
const int _maxItemsPerRow = 20;

/// How many liked titles to seed similarity/recommendations from.
const int _maxSeedTitles = 8;

/// How many of each cluster's strongest titles to take as seeds.
const int _seedsPerCluster = 2;

/// One independent pipeline per domain (movie/TV, anime, manga per source);
/// rows concatenate, and a domain with nothing to say contributes none.
final AutoDisposeFutureProvider<RecommendationResult> recommendationsProvider =
    FutureProvider.autoDispose<RecommendationResult>((Ref ref) async {
  // Read once, don't watch: watching would re-run the whole fetch+score
  // pipeline on every add. Refresh re-runs it on demand.
  final List<CollectionItem> library =
      ref.read(allItemsNotifierProvider).valueOrNull ??
          const <CollectionItem>[];

  // Watch only what should recompute the tab: anime/manga titles render in
  // this language, so flipping it re-titles the rows.
  final String titleLanguage = ref.watch(
    settingsNotifierProvider
        .select((SettingsState s) => s.animeMangaTitleLanguage),
  );

  // Domains hit unrelated backends — run them concurrently.
  final (_MovieTvOutcome movieTv, _NicheOutcome anime, _NicheOutcome manga) =
      await (
    _movieTvDomain(ref, library),
    _animeDomain(ref, library, titleLanguage),
    _mangaDomain(ref, library, titleLanguage),
  ).wait;

  // Pin fetched results across tab unmounts; cheap no-fetch states stay
  // uncached on purpose so they recompute per visit.
  final bool movieTvFetched =
      movieTv.status == RecommendationStatus.ready ||
          movieTv.status == RecommendationStatus.noCandidates;
  if (movieTvFetched || anime.hadProfile || manga.hadProfile) {
    ref.keepAlive();
  }

  final List<RecommendationRowUi> rows = <RecommendationRowUi>[
    ...movieTv.rows,
    ...anime.rows,
    ...manga.rows,
  ];
  if (rows.isNotEmpty) {
    return RecommendationResult(status: RecommendationStatus.ready, rows: rows);
  }
  if (movieTv.status == RecommendationStatus.noApiKey) {
    return const RecommendationResult.state(RecommendationStatus.noApiKey);
  }
  if (movieTv.status == RecommendationStatus.noCandidates ||
      anime.hadProfile ||
      manga.hadProfile) {
    return const RecommendationResult.state(RecommendationStatus.noCandidates);
  }
  return const RecommendationResult.state(RecommendationStatus.empty);
});

typedef _MovieTvOutcome = ({
  RecommendationStatus status,
  List<RecommendationRowUi> rows,
});

/// Rows + a flag for the keyless domains: [hadProfile] separates "nothing to
/// learn from" (empty) from "learned but found nothing" (noCandidates).
typedef _NicheOutcome = ({
  List<RecommendationRowUi> rows,
  bool hadProfile,
});

const _NicheOutcome _nicheNothing =
    (rows: <RecommendationRowUi>[], hadProfile: false);

Future<_MovieTvOutcome> _movieTvDomain(
  Ref ref,
  List<CollectionItem> library,
) async {
  // Genres are matched by TMDB *id* (GenreKeyResolver) so library and
  // candidates line up regardless of the language each was cached in.
  final ({String language, bool hasKey}) tmdbSettings = ref.watch(
    settingsNotifierProvider.select((SettingsState s) =>
        (language: s.tmdbLanguage, hasKey: s.hasTmdbKey)),
  );
  final bool ru = tmdbSettings.language.startsWith('ru');
  final DatabaseService db = ref.watch(databaseServiceProvider);
  final Map<String, String> movieEn =
      await db.movieDao.getTmdbGenreMap('movie', lang: 'en');
  final Map<String, String> movieRu =
      await db.movieDao.getTmdbGenreMap('movie', lang: 'ru');
  final Map<String, String> tvEn =
      await db.movieDao.getTmdbGenreMap('tv', lang: 'en');
  final Map<String, String> tvRu =
      await db.movieDao.getTmdbGenreMap('tv', lang: 'ru');
  final GenreKeyResolver movieGenres =
      GenreKeyResolver.fromGenreMaps(<Map<String, String>>[movieEn, movieRu]);
  final GenreKeyResolver tvGenres =
      GenreKeyResolver.fromGenreMaps(<Map<String, String>>[tvEn, tvRu]);
  // Genre id -> display name in the content language, for the row captions.
  final Map<String, String> genreDisplay = <String, String>{
    ...(ru ? movieRu : movieEn),
    ...(ru ? tvRu : tvEn),
  };

  // 1. Taste titles from completed movie/TV with genres, deduped by taste id.
  final List<TasteTitle> completed = _completedTitles(
    library,
    (CollectionItem item) => tasteTitleFromItem(
      item,
      movieGenres: movieGenres,
      tvGenres: tvGenres,
    ),
  );
  if (completed.isEmpty) {
    return (
      status: RecommendationStatus.empty,
      rows: const <RecommendationRowUi>[],

    );
  }

  // 2. Learn the profile.
  final Recommender recommender = Recommender(completed);
  if (recommender.profile.isEmpty) {
    // Completed titles exist but none carry a positive signal.
    return (
      status: RecommendationStatus.empty,
      rows: const <RecommendationRowUi>[],

    );
  }

  // 3. No key means candidates can't be fetched at all — report that plainly
  // rather than letting it fall through to the generic "nothing found".
  if (!tmdbSettings.hasKey) {
    return (
      status: RecommendationStatus.noApiKey,
      rows: const <RecommendationRowUi>[],

    );
  }

  // The shared client, not a fresh one: only it picks up a TMDB key entered
  // at runtime (a fresh Dio reads the startup-only apiKeysProvider snapshot).
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Set<String> owned = ownedTasteIds(library);
  final _CandidatePool pool = _CandidatePool();
  // Per-title similarity first — far less coarse than discover-by-genre;
  // seeds are the strongest titles in each taste cluster.
  await _fetchFromSeeds(
    tmdb: tmdb,
    seeds: _seedSelection(recommender.profile),
    owned: owned,
    pool: pool,
  );
  // Top up with discover-by-genre for breadth where similarity came back thin.
  await _fetchByDiscover(
    tmdb: tmdb,
    topGenreIds: _topGenresForDiscovery(recommender.profile),
    movieGenres: movieGenres,
    tvGenres: tvGenres,
    owned: owned,
    pool: pool,
  );

  // 4. Vectorize candidates and score them.
  final Map<String, TasteTitle> candidateById = <String, TasteTitle>{};
  final Map<String, RecommendedItem Function(double score, double? predicted)>
      builderById =
      <String, RecommendedItem Function(double score, double? predicted)>{};

  pool.movies.forEach((String id, Movie m) {
    final TasteTitle? t = tasteTitleFromMovie(m, movieGenres);
    if (t == null) return;
    candidateById[id] = t;
    builderById[id] = (double score, double? predicted) => RecommendedItem(
          tasteId: id,
          media: m,
          mediaType: MediaType.movie,
          source: DataSource.tmdb,
          externalId: m.tmdbId,
          title: m.title,
          posterUrl: m.posterUrl,
          year: m.releaseYear,
          apiRating: m.rating,
          score: score,
          predictedRating: predicted,
        );
  });
  pool.tvShows.forEach((String id, TvShow tv) {
    final TasteTitle? t = tasteTitleFromTvShow(tv, tvGenres);
    if (t == null) return;
    candidateById[id] = t;
    builderById[id] = (double score, double? predicted) => RecommendedItem(
          tasteId: id,
          media: tv,
          mediaType: MediaType.tvShow,
          source: DataSource.tmdb,
          externalId: tv.tmdbId,
          title: tv.title,
          posterUrl: tv.posterUrl,
          year: tv.firstAirYear,
          apiRating: tv.rating,
          score: score,
          predictedRating: predicted,
        );
  });

  final List<RecommendationRowUi> rows = _resolveRows(
    recommender: recommender,
    candidateById: candidateById,
    builderById: builderById,
    genreLabel: (String g) => genreDisplay[g] ?? g,
  );
  return (
    status: rows.isEmpty
        ? RecommendationStatus.noCandidates
        : RecommendationStatus.ready,
    rows: rows,

  );
}

/// Anime domain: AniList profile and AniList candidates — one tag vocabulary
/// on both sides. Kitsu titles carry no genres/tags, so they can't join.
Future<_NicheOutcome> _animeDomain(
  Ref ref,
  List<CollectionItem> library,
  String titleLanguage,
) async {
  final List<TasteTitle> completed =
      _completedTitles(library, tasteTitleFromAnimeItem);
  if (completed.isEmpty) return _nicheNothing;

  final Recommender recommender = Recommender(completed);
  if (recommender.profile.isEmpty) return _nicheNothing;

  // All seeds ride one aliased request — a single hit on AniList's rate limit.
  final AniListApi aniList = ref.watch(aniListApiProvider);
  final List<int> seedIds = <int>[
    for (final String tasteId in _seedTasteIds(recommender.profile))
      if (_idFromTasteId(tasteId) case final int id) id,
  ];
  final Map<int, List<Anime>> fetched = await _safeBatch(
    () => aniList.getAnimeRecommendationsBatch(seedIds),
  );

  final Set<String> owned = ownedAnimeTasteIds(library);
  final Map<String, Anime> pool = <String, Anime>{};
  for (final Anime a in fetched.values.expand((List<Anime> l) => l)) {
    final String id = animeTasteId(a.source, a.id);
    if (owned.contains(id) || pool.containsKey(id)) continue;
    pool[id] = a;
  }

  final Map<String, TasteTitle> candidateById = <String, TasteTitle>{};
  final Map<String, RecommendedItem Function(double, double?)> builderById =
      <String, RecommendedItem Function(double, double?)>{};
  pool.forEach((String id, Anime a) {
    final TasteTitle? t = tasteTitleFromAnime(a);
    if (t == null) return;
    candidateById[id] = t;
    builderById[id] = (double score, double? predicted) => RecommendedItem(
          tasteId: id,
          media: a,
          mediaType: MediaType.anime,
          source: a.source,
          externalId: a.id,
          title: a.titleByLanguage(titleLanguage),
          posterUrl: a.coverUrl,
          year: a.releaseYear,
          apiRating: a.rating10,
          score: score,
          predictedRating: predicted,
        );
  });

  return (
    rows: _resolveRows(
      recommender: recommender,
      candidateById: candidateById,
      builderById: builderById,
      genreLabel: (String g) => g,
    ),
    hadProfile: true,
  );
}

/// Manga domain: one profile per source (vocabularies never mix), candidates
/// from that source's own similarity backend, rows appended per source.
Future<_NicheOutcome> _mangaDomain(
  Ref ref,
  List<CollectionItem> library,
  String titleLanguage,
) async {
  // Clients are read before any await: an autoDispose ref must not be touched
  // once the tab unmounts mid-fetch.
  final _MangaBackends backends = (
    aniList: ref.watch(aniListApiProvider),
    mangaBaka: ref.watch(mangaBakaApiProvider),
    mangaDex: ref.watch(mangaDexApiProvider),
  );
  final Set<String> owned = ownedMangaTasteIds(library);
  final List<RecommendationRowUi> rows = <RecommendationRowUi>[];
  bool hadProfile = false;

  for (final DataSource source in mangaTasteSources) {
    final List<TasteTitle> completed = _completedTitles(
      library,
      (CollectionItem item) => tasteTitleFromMangaItem(item, source),
    );
    if (completed.isEmpty) continue;

    // MangaDex is seeded by UUID, which lives only on the library item's
    // externalUrl — harvested here so seeds can resolve it.
    final Map<String, String> uuidByTasteId = <String, String>{
      if (source == DataSource.mangadex)
        for (final CollectionItem item in library)
          if (item.manga case final Manga m
              when m.source == DataSource.mangadex &&
                  mangaDexUuidFromUrl(m.externalUrl).isNotEmpty)
            mangaTasteId(m.source, m.id): mangaDexUuidFromUrl(m.externalUrl),
    };

    final Recommender recommender = Recommender(completed);
    if (recommender.profile.isEmpty) continue;
    hadProfile = true;

    final List<List<Manga>> results = await _mangaSeedRecommendations(
      backends,
      source,
      _seedTasteIds(recommender.profile),
      uuidByTasteId,
    );

    final Map<String, Manga> pool = <String, Manga>{};
    for (final Manga m in results.expand((List<Manga> l) => l)) {
      final String id = mangaTasteId(m.source, m.id);
      if (owned.contains(id) || pool.containsKey(id)) continue;
      pool[id] = m;
    }

    final Map<String, TasteTitle> candidateById = <String, TasteTitle>{};
    final Map<String, RecommendedItem Function(double, double?)> builderById =
        <String, RecommendedItem Function(double, double?)>{};
    pool.forEach((String id, Manga m) {
      final TasteTitle? t = tasteTitleFromManga(m);
      if (t == null) return;
      candidateById[id] = t;
      builderById[id] = (double score, double? predicted) => RecommendedItem(
            tasteId: id,
            media: m,
            mediaType: MediaType.manga,
            source: m.source,
            externalId: m.id,
            title: m.titleByLanguage(titleLanguage),
            posterUrl: m.coverUrl,
            year: m.releaseYear,
            apiRating: m.rating10,
            score: score,
            predictedRating: predicted,
          );
    });

    rows.addAll(
      _resolveRows(
        recommender: recommender,
        candidateById: candidateById,
        builderById: builderById,
        genreLabel: (String g) => g,
      ),
    );
  }

  return (rows: rows, hadProfile: hadProfile);
}

typedef _MangaBackends = ({
  AniListApi aniList,
  MangaBakaApi mangaBaka,
  MangaDexApi mangaDex,
});

/// AniList seeds ride one aliased request (rate-limit budget); MangaBaka /
/// MangaDex have no batch endpoint and are queried per seed, concurrently.
Future<List<List<Manga>>> _mangaSeedRecommendations(
  _MangaBackends backends,
  DataSource source,
  List<String> seedTasteIds,
  Map<String, String> uuidByTasteId,
) async {
  if (source == DataSource.anilist) {
    final List<int> ids = <int>[
      for (final String tasteId in seedTasteIds)
        if (_idFromTasteId(tasteId) case final int id) id,
    ];
    final Map<int, List<Manga>> byId = await _safeBatch(
      () => backends.aniList.getMangaRecommendationsBatch(ids),
    );
    return byId.values.toList();
  }
  return Future.wait(
    <Future<List<Manga>>>[
      for (final String tasteId in seedTasteIds)
        _safeDiscover<Manga>(() {
          if (source == DataSource.mangadex) {
            final String? uuid = uuidByTasteId[tasteId];
            if (uuid == null) return Future<List<Manga>>.value(const <Manga>[]);
            return backends.mangaDex.getRecommendations(uuid);
          }
          final int? id = _idFromTasteId(tasteId);
          if (id == null) return Future<List<Manga>>.value(const <Manga>[]);
          return backends.mangaBaka.getRecommendations(id);
        }),
    ],
  );
}

/// Like [_safeDiscover] for the aliased batch calls: a failure degrades to an
/// empty map instead of erroring the tab.
Future<Map<int, List<T>>> _safeBatch<T>(
  Future<Map<int, List<T>>> Function() call,
) async {
  try {
    return await call();
  } on Object catch (error, stack) {
    _log.warning('batch candidate fetch failed', error, stack);
    return <int, List<T>>{};
  }
}

/// Completed titles vectorized by [toTaste], deduped by taste id — a title in
/// several collections must be learned once or it skews IDF and weights.
List<TasteTitle> _completedTitles(
  List<CollectionItem> library,
  TasteTitle? Function(CollectionItem) toTaste,
) {
  final Map<String, TasteTitle> byId = <String, TasteTitle>{};
  for (final CollectionItem item in library) {
    if (item.status != ItemStatus.completed) continue;
    final TasteTitle? t = toTaste(item);
    if (t == null) continue;
    final TasteTitle? existing = byId[t.id];
    byId[t.id] = existing == null ? t : _mergeTasteSignals(existing, t);
  }
  return byId.values.toList();
}

/// Resolves engine rows to UI rows: strongest matches taken, then shown
/// highest-rated first — match-score order looks shuffled against ratings.
List<RecommendationRowUi> _resolveRows({
  required Recommender recommender,
  required Map<String, TasteTitle> candidateById,
  required Map<String, RecommendedItem Function(double, double?)> builderById,
  required String Function(String) genreLabel,
}) {
  if (candidateById.isEmpty) return const <RecommendationRowUi>[];
  final List<RecommendationRow> engineRows =
      recommender.recommend(candidateById.values.toList());

  final List<RecommendationRowUi> rows = <RecommendationRowUi>[];
  for (final RecommendationRow row in engineRows) {
    final List<RecommendedItem> items = <RecommendedItem>[];
    for (final ScoredTitle scored in row.items.take(_maxItemsPerRow)) {
      final RecommendedItem Function(double, double?)? build =
          builderById[scored.id];
      final TasteTitle? taste = candidateById[scored.id];
      if (build == null || taste == null) continue;
      items.add(build(scored.score, recommender.predictRating(taste)));
    }
    items.sort(byRatingDesc);
    if (items.isNotEmpty) {
      rows.add(
        RecommendationRowUi(
          becauseTitles: row.becauseTitles,
          genres: <String>[
            for (final String g in row.topGenres) genreLabel(g),
          ],
          items: items,
        ),
      );
    }
  }
  return rows;
}

/// Source rating desc, predicted rating as tiebreak, then match score;
/// unrated items sort last so the row leads with its strongest picks.
@visibleForTesting
int byRatingDesc(RecommendedItem a, RecommendedItem b) {
  final int byApi = _compareRatingDesc(a.apiRating, b.apiRating);
  if (byApi != 0) return byApi;
  final int byPredicted = _compareRatingDesc(a.predictedRating, b.predictedRating);
  if (byPredicted != 0) return byPredicted;
  return b.score.compareTo(a.score);
}

/// Descending compare where `null` sorts last.
int _compareRatingDesc(double? a, double? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

/// Keeps the strongest signal across copies of one title: favorite if either
/// is, the higher rating; features and label are identical, so [a]'s are kept.
TasteTitle _mergeTasteSignals(TasteTitle a, TasteTitle b) {
  return TasteTitle(
    id: a.id,
    label: a.label,
    features: a.features,
    rating: _maxRating(a.rating, b.rating),
    isFavorite: a.isFavorite || b.isFavorite,
  );
}

/// Higher of two ratings; the non-null one when only one is set.
double? _maxRating(double? a, double? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a >= b ? a : b;
}

/// The candidates gathered from discover, keyed by engine id.
class _CandidatePool {
  final Map<String, Movie> movies = <String, Movie>{};
  final Map<String, TvShow> tvShows = <String, TvShow>{};

  void addMovies(Iterable<Movie> items, Set<String> owned) {
    for (final Movie m in items) {
      final String id = movieTasteId(m.tmdbId);
      if (owned.contains(id) || movies.containsKey(id)) continue;
      movies[id] = m;
    }
  }

  void addTvShows(Iterable<TvShow> items, Set<String> owned) {
    for (final TvShow tv in items) {
      final String id = tvTasteId(tv.tmdbId);
      if (owned.contains(id) || tvShows.containsKey(id)) continue;
      tvShows[id] = tv;
    }
  }
}

/// Union of each cluster's top genre keys (TMDB id strings), capped — these
/// drive the discover queries.
List<String> _topGenresForDiscovery(TasteProfile profile) {
  const int perCluster = 3;
  final List<String> ordered = <String>[];
  final Set<String> seen = <String>{};
  for (final TasteCluster c in profile.clusters) {
    for (final String g in c.topGenres.take(perCluster)) {
      if (seen.add(g)) ordered.add(g);
    }
  }
  return ordered.take(_maxGenresToQuery).toList();
}

/// The strongest titles in each cluster (members come pre-sorted by weight),
/// as taste ids for similarity/recommendation lookups.
List<String> _seedTasteIds(TasteProfile profile) {
  final List<String> seeds = <String>[];
  final Set<String> seen = <String>{};
  for (final TasteCluster c in profile.clusters) {
    for (final TasteTitle t in c.members.take(_seedsPerCluster)) {
      if (seen.add(t.id)) seeds.add(t.id);
    }
    if (seeds.length >= _maxSeedTitles) break;
  }
  return seeds.take(_maxSeedTitles).toList();
}

/// The trailing numeric segment of a taste id (`movie:603`,
/// `anime:anilist:21`), or null when it isn't numeric.
int? _idFromTasteId(String tasteId) =>
    int.tryParse(tasteId.substring(tasteId.lastIndexOf(':') + 1));

List<({String type, int tmdbId})> _seedSelection(TasteProfile profile) {
  final List<({String type, int tmdbId})> seeds =
      <({String type, int tmdbId})>[];
  for (final String tasteId in _seedTasteIds(profile)) {
    final int sep = tasteId.indexOf(':');
    final int? tmdbId = _idFromTasteId(tasteId);
    if (sep < 0 || tmdbId == null) continue;
    seeds.add((type: tasteId.substring(0, sep), tmdbId: tmdbId));
  }
  return seeds;
}

/// Fills [pool] with TMDB recommendations + similar titles for each seed, run
/// concurrently. Owned titles and duplicates are skipped.
Future<void> _fetchFromSeeds({
  required TmdbApi tmdb,
  required List<({String type, int tmdbId})> seeds,
  required Set<String> owned,
  required _CandidatePool pool,
}) async {
  final List<({List<Movie> movies, List<TvShow> tvShows})> results =
      await Future.wait(
    seeds.map((({String type, int tmdbId}) s) => _similarFor(tmdb, s)),
  );
  for (final ({List<Movie> movies, List<TvShow> tvShows}) r in results) {
    pool.addMovies(r.movies, owned);
    pool.addTvShows(r.tvShows, owned);
  }
}

Future<({List<Movie> movies, List<TvShow> tvShows})> _similarFor(
  TmdbApi tmdb,
  ({String type, int tmdbId}) seed,
) async {
  if (seed.type == 'movie') {
    final List<Movie> recs = await _safeDiscover<Movie>(
      () => tmdb.getMovieRecommendations(seed.tmdbId),
    );
    final List<Movie> similar = await _safeDiscover<Movie>(
      () => tmdb.getSimilarMovies(seed.tmdbId),
    );
    return (movies: <Movie>[...recs, ...similar], tvShows: const <TvShow>[]);
  }
  final List<TvShow> recs = await _safeDiscover<TvShow>(
    () => tmdb.getTvRecommendations(seed.tmdbId),
  );
  final List<TvShow> similar = await _safeDiscover<TvShow>(
    () => tmdb.getSimilarTvShows(seed.tmdbId),
  );
  return (movies: const <Movie>[], tvShows: <TvShow>[...recs, ...similar]);
}

/// Tops up [pool] with discover-by-genre up to [_perDomainTarget]; each genre
/// id is queried in whichever domain (movie / TV) actually defines it.
Future<void> _fetchByDiscover({
  required TmdbApi tmdb,
  required List<String> topGenreIds,
  required GenreKeyResolver movieGenres,
  required GenreKeyResolver tvGenres,
  required Set<String> owned,
  required _CandidatePool pool,
}) async {
  for (final String genreId in topGenreIds) {
    final bool moviesFull = pool.movies.length >= _perDomainTarget;
    final bool tvFull = pool.tvShows.length >= _perDomainTarget;
    if (moviesFull && tvFull) break;

    final int? id = int.tryParse(genreId);
    if (id == null) continue;

    if (!moviesFull && movieGenres.hasId(genreId)) {
      for (int page = 1; page <= _maxPagesPerGenre; page++) {
        final List<Movie> results = await _safeDiscover<Movie>(
          () => tmdb.discoverMovies(
            genreId: id,
            voteCountGte: _minVoteCount,
            page: page,
          ),
        );
        if (results.isEmpty) break;
        pool.addMovies(results, owned);
      }
    }

    if (!tvFull && tvGenres.hasId(genreId)) {
      for (int page = 1; page <= _maxPagesPerGenre; page++) {
        final List<TvShow> results = await _safeDiscover<TvShow>(
          () => tmdb.discoverTvShows(
            genreId: id,
            voteCountGte: _minVoteCount,
            page: page,
          ),
        );
        if (results.isEmpty) break;
        pool.addTvShows(results, owned);
      }
    }
  }
}

/// Runs a candidate list call, swallowing failures (network, rate limits) to an
/// empty list so the tab degrades to "no candidates" instead of erroring.
Future<List<T>> _safeDiscover<T>(Future<List<T>> Function() call) async {
  try {
    return await call();
  } on Object catch (error, stack) {
    _log.warning('candidate fetch failed', error, stack);
    return <T>[];
  }
}

/// Adds the recommendation target-collections provider for the recs tab — its
/// own selection, independent of the Search tab's [searchTargetCollectionsProvider].
final StateProvider<Set<int>> recommendationTargetCollectionsProvider =
    StateProvider<Set<int>>((Ref ref) => <int>{});

/// Engine ids currently in any collection, for the "added" card mark. The
/// collected-id providers hold values across reloads; all-items would blank.
final AutoDisposeFutureProvider<Set<String>>
    collectedRecommendationIdsProvider =
    FutureProvider.autoDispose<Set<String>>((Ref ref) async {
  final (
    Map<int, List<CollectedItemInfo>> movies,
    Map<int, List<CollectedItemInfo>> tv,
    Map<int, List<CollectedItemInfo>> anime,
    Map<int, List<CollectedItemInfo>> manga,
  ) = await (
    ref.watch(collectedMovieIdsProvider.future),
    ref.watch(collectedTvShowIdsProvider.future),
    ref.watch(collectedAnimeIdsProvider.future),
    ref.watch(collectedMangaIdsProvider.future),
  ).wait;
  return <String>{
    for (final int id in movies.keys) movieTasteId(id),
    for (final int id in tv.keys) tvTasteId(id),
    for (final MapEntry<int, List<CollectedItemInfo>> e in anime.entries)
      for (final CollectedItemInfo info in e.value)
        animeTasteId(info.source, e.key),
    for (final MapEntry<int, List<CollectedItemInfo>> e in manga.entries)
      for (final CollectedItemInfo info in e.value)
        mangaTasteId(info.source, e.key),
  };
});
