// Orchestration for the Recommendations tab: learn a taste profile from the
// completed library, gather candidates (primarily TMDB recommendations/similar
// of the titles you liked, topped up with discover-by-genre), exclude owned,
// score them with the engine, and resolve the winners back to renderable items.
//
// autoDispose: the work (network + scoring) runs only while the tab is on
// screen. The library is read once per run (not watched) so adding a pick
// doesn't reload the list mid-browse; the refresh button or reopening the tab
// recomputes fresh.

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../engine/recommendation_models.dart';
import '../engine/recommender.dart';
import '../tmdb_taste_input.dart';

final Logger _log = Logger('Recommendations');

/// How the Recommendations tab should render.
enum RecommendationStatus {
  /// No completed movie/TV titles with genres — nothing to learn from.
  empty,

  /// No TMDB API key configured, so candidates can't be fetched at all. Kept
  /// separate from [noCandidates] so the message points at the real fix
  /// instead of blaming the key when a key is present.
  noApiKey,

  /// A profile and a key exist, but the fetch came back with nothing usable —
  /// a network error, or everything matching is already owned.
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
    required this.tmdbId,
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.apiRating,
    required this.score,
    required this.predictedRating,
  });

  /// Engine id (`movie:<id>` / `tv:<id>`).
  final String tasteId;

  /// The underlying [Movie] / [TvShow], handed to the search add-to-collection
  /// handlers so the pick can be added straight from here.
  final Object media;

  /// [MediaType.movie] or [MediaType.tvShow].
  final MediaType mediaType;

  /// TMDB id.
  final int tmdbId;

  /// Display title.
  final String title;

  /// Poster URL, or `null` when TMDB has no poster.
  final String? posterUrl;

  /// Release / first-air year, or `null`.
  final int? year;

  /// TMDB community rating (0–10), or `null`.
  final double? apiRating;

  /// Engine match score.
  final double score;

  /// Predicted personal rating (1–10), or `null` when not predictable.
  final double? predictedRating;
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

/// How many genres (across clusters) to query candidates by. Generous enough to
/// reach TV-only genre names (e.g. "Sci-Fi & Fantasy"), which tend to rank
/// below movie genres in the clusters.
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

/// Recommendations for the current library. See the file header.
final AutoDisposeFutureProvider<RecommendationResult> recommendationsProvider =
    FutureProvider.autoDispose<RecommendationResult>((Ref ref) async {
  // Read once, don't watch: adding a recommended pick mutates the library, and
  // watching would re-run the whole fetch+score pipeline (flashing the loading
  // spinner) on every add. Refresh re-runs it on demand.
  final List<CollectionItem> library =
      ref.read(allItemsNotifierProvider).valueOrNull ??
          const <CollectionItem>[];

  // Genres are matched by TMDB *id*, not by name, so the library and the
  // candidates line up no matter which language each was cached or fetched in
  // (see GenreKeyResolver). Both language maps feed each resolver; the
  // content-language map drives the human-readable rationale captions.
  // Watch only language + key presence: changing either should recompute
  // (a key added at runtime flips hasKey false->true and refreshes the tab),
  // but unrelated settings shouldn't re-run the whole pipeline.
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
  // The same title can sit in several collections; learning it once keeps it
  // from skewing IDF/weights and from appearing twice in a row's "because you
  // liked" header. Merging keeps the strongest signal: favorite if any of the
  // copies is, and the highest explicit rating.
  final Map<String, TasteTitle> completedById = <String, TasteTitle>{};
  for (final CollectionItem item in library) {
    if (item.status != ItemStatus.completed) continue;
    final TasteTitle? t = tasteTitleFromItem(
      item,
      movieGenres: movieGenres,
      tvGenres: tvGenres,
    );
    if (t == null) continue;
    final TasteTitle? existing = completedById[t.id];
    completedById[t.id] =
        existing == null ? t : _mergeTasteSignals(existing, t);
  }
  final List<TasteTitle> completed = completedById.values.toList();
  if (completed.isEmpty) {
    return const RecommendationResult.state(RecommendationStatus.empty);
  }

  // 2. Learn the profile.
  final Recommender recommender = Recommender(completed);
  if (recommender.profile.isEmpty) {
    // Completed titles exist but none carry a positive signal.
    return const RecommendationResult.state(RecommendationStatus.empty);
  }

  // 3. No key means candidates can't be fetched at all — report that plainly
  // rather than letting it fall through to the generic "nothing found".
  if (!tmdbSettings.hasKey) {
    return const RecommendationResult.state(RecommendationStatus.noApiKey);
  }

  // Fetch candidates from TMDB by the profile's top genres. Use the shared
  // client — the same one Search uses — instead of building a fresh one:
  // SettingsNotifier keeps its key and request language live, so a key entered
  // at runtime is picked up here too. A freshly built client could only read the
  // startup-only apiKeysProvider snapshot, which stayed keyless whenever the key
  // was added after launch — that left this tab perpetually "no candidates".
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Set<String> owned = ownedTasteIds(library);
  final _CandidatePool pool = _CandidatePool();
  // Primary source — "recommended/similar to titles you liked". TMDB's per-title
  // similarity is far less coarse than discover-by-genre, which (sorted by
  // popularity) just surfaces the biggest title sharing a broad genre like
  // "Sci-Fi & Fantasy" — that's the Dark + Wisting → House of the Dragon miss.
  // Seeds are the strongest titles in each taste cluster.
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
          tmdbId: m.tmdbId,
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
          tmdbId: tv.tmdbId,
          title: tv.title,
          posterUrl: tv.posterUrl,
          year: tv.firstAirYear,
          apiRating: tv.rating,
          score: score,
          predictedRating: predicted,
        );
  });

  if (candidateById.isEmpty) {
    return const RecommendationResult.state(RecommendationStatus.noCandidates);
  }

  final List<RecommendationRow> engineRows =
      recommender.recommend(candidateById.values.toList());

  // 5. Resolve engine rows to UI rows. The engine ranks by match score; take
  // the strongest matches, then present them highest-rated first (TMDB rating,
  // predicted personal rating as tiebreak) so the row reads top-down instead of
  // in match-score order, which looks shuffled against the visible ratings.
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
          // topGenres are id keys now; show their content-language names.
          genres: <String>[
            for (final String g in row.topGenres) genreDisplay[g] ?? g,
          ],
          items: items,
        ),
      );
    }
  }

  if (rows.isEmpty) {
    return const RecommendationResult.state(RecommendationStatus.noCandidates);
  }
  return RecommendationResult(status: RecommendationStatus.ready, rows: rows);
});

/// Orders recommended items highest-rated first: TMDB rating, then predicted
/// personal rating as a tiebreak, then engine match score. Items with no rating
/// sort last so the row still leads with its rated, strongest picks.
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

/// Merges two taste entries for the same title sitting in several collections:
/// favorite if either copy is, and the higher of any explicit ratings. Genres
/// (features) and label are identical across copies, so [a]'s are kept.
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
/// as `(type, tmdbId)` seeds for similarity/recommendation lookups.
List<({String type, int tmdbId})> _seedSelection(TasteProfile profile) {
  final List<({String type, int tmdbId})> seeds =
      <({String type, int tmdbId})>[];
  final Set<String> seen = <String>{};
  for (final TasteCluster c in profile.clusters) {
    for (final TasteTitle t in c.members.take(_seedsPerCluster)) {
      if (!seen.add(t.id)) continue;
      final ({String type, int tmdbId})? parsed = _parseTasteId(t.id);
      if (parsed != null) seeds.add(parsed);
    }
    if (seeds.length >= _maxSeedTitles) break;
  }
  return seeds.take(_maxSeedTitles).toList();
}

({String type, int tmdbId})? _parseTasteId(String id) {
  final int sep = id.indexOf(':');
  if (sep < 0) return null;
  final int? tmdbId = int.tryParse(id.substring(sep + 1));
  if (tmdbId == null) return null;
  return (type: id.substring(0, sep), tmdbId: tmdbId);
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

/// Tops up [pool] with discover-by-genre, up to [_perDomainTarget] per domain.
/// [topGenreIds] are genre id strings; each is queried in whichever domain
/// (movie / TV) actually defines that id.
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

/// Runs a TMDB list call, swallowing failures (network, rate limits) to an
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

/// Engine ids (movie/TV) currently in any collection, for marking recommended
/// cards as added. Sourced from the collected-id providers rather than the
/// all-items notifier so the screen can sticky-merge it: those providers carry
/// their value across reloads, where the all-items notifier blanks through
/// AsyncLoading and would flash every mark off.
final AutoDisposeFutureProvider<Set<String>>
    collectedRecommendationIdsProvider =
    FutureProvider.autoDispose<Set<String>>((Ref ref) async {
  final Map<int, List<CollectedItemInfo>> movies =
      await ref.watch(collectedMovieIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> tv =
      await ref.watch(collectedTvShowIdsProvider.future);
  return <String>{
    for (final int id in movies.keys) movieTasteId(id),
    for (final int id in tv.keys) tvTasteId(id),
  };
});
