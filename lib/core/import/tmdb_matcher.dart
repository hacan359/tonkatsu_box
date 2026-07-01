import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/tv_show.dart';
import '../api/tmdb_api.dart';
import 'rate_limited_retry.dart';

/// A resolved TMDB match for one imported title, carrying the fetched media so
/// the adapter can batch-upsert it.
class TmdbMatch {
  const TmdbMatch({
    required this.tmdbId,
    required this.mediaType,
    this.platformId,
    this.movie,
    this.show,
  });

  final int tmdbId;
  final MediaType mediaType;
  final int? platformId;
  final Movie? movie;
  final TvShow? show;
}

/// Matches a title against TMDB by name. Shared by importers whose rows carry
/// no TMDB id (e.g. Kinorium). Tries the primary query then the fallback, each
/// first constrained by year then unconstrained, picks the best by year, and
/// throttles + retries (429) every request.
class TmdbMatcher {
  TmdbMatcher(
    this._api, {
    RateLimitedRetry retry = const RateLimitedRetry(),
    Duration throttle = const Duration(milliseconds: 150),
  })  : _retry = retry,
        _throttle = throttle;

  final TmdbApi _api;
  final RateLimitedRetry _retry;
  final Duration _throttle;

  /// Matches [primaryQuery] (with [fallbackQuery] as a second try) on the movie
  /// endpoint. [animationHint] forces the animation media type even when TMDB
  /// genres don't say so.
  Future<TmdbMatch?> matchMovie({
    required String primaryQuery,
    String? fallbackQuery,
    int? year,
    bool animationHint = false,
    void Function(Duration wait, int attempt)? onRateLimit,
  }) async {
    final Movie? movie = await _search<Movie>(
      primaryQuery: primaryQuery,
      fallbackQuery: fallbackQuery,
      year: year,
      onRateLimit: onRateLimit,
      search: (String q, int? y) => _api.searchMovies(q, year: y),
      yearOf: (Movie m) => m.releaseYear,
    );
    if (movie == null) return null;
    final bool isAnim = animationHint || isAnimationByGenres(movie.genres);
    return TmdbMatch(
      tmdbId: movie.tmdbId,
      mediaType: isAnim ? MediaType.animation : MediaType.movie,
      platformId: isAnim ? AnimationSource.movie : null,
      movie: movie,
    );
  }

  /// Matches [primaryQuery] (with [fallbackQuery] as a second try) on the TV
  /// endpoint.
  Future<TmdbMatch?> matchTvShow({
    required String primaryQuery,
    String? fallbackQuery,
    int? year,
    bool animationHint = false,
    void Function(Duration wait, int attempt)? onRateLimit,
  }) async {
    final TvShow? show = await _search<TvShow>(
      primaryQuery: primaryQuery,
      fallbackQuery: fallbackQuery,
      year: year,
      onRateLimit: onRateLimit,
      search: (String q, int? y) => _api.searchTvShows(q, firstAirDateYear: y),
      yearOf: (TvShow s) => s.firstAirYear,
    );
    if (show == null) return null;
    final bool isAnim = animationHint || isAnimationByGenres(show.genres);
    return TmdbMatch(
      tmdbId: show.tmdbId,
      mediaType: isAnim ? MediaType.animation : MediaType.tvShow,
      platformId: isAnim ? AnimationSource.tvShow : null,
      show: show,
    );
  }

  Future<T?> _search<T>({
    required String primaryQuery,
    required String? fallbackQuery,
    required int? year,
    required void Function(Duration wait, int attempt)? onRateLimit,
    required Future<List<T>> Function(String query, int? year) search,
    required int? Function(T result) yearOf,
  }) async {
    final String trimmedPrimary = primaryQuery.trim();
    final List<String> queries = <String>[trimmedPrimary];
    final String? fallback = fallbackQuery?.trim();
    if (fallback != null &&
        fallback.isNotEmpty &&
        fallback.toLowerCase() != trimmedPrimary.toLowerCase()) {
      queries.add(fallback);
    }
    final List<int?> years = year != null ? <int?>[year, null] : <int?>[null];

    for (final String query in queries) {
      if (query.isEmpty) continue;
      for (final int? candidateYear in years) {
        final List<T> results = await _retry.run<List<T>>(
          () => search(query, candidateYear),
          isRateLimit: (Object e) =>
              e is TmdbApiException && e.statusCode == 429,
          onRetry: onRateLimit,
        );
        await Future<void>.delayed(_throttle);
        if (results.isNotEmpty) {
          return _pickBest<T>(results, year, yearOf);
        }
      }
    }
    return null;
  }

  /// Prefers a result whose year matches (year filters are dropped on later
  /// attempts, so the first hit may be the wrong edition); otherwise the most
  /// relevant (first) result.
  T _pickBest<T>(List<T> results, int? year, int? Function(T result) yearOf) {
    if (year != null) {
      for (final T result in results) {
        if (yearOf(result) == year) return result;
      }
    }
    return results.first;
  }

  /// True when TMDB genres mark the title as animation (genre name or id 16).
  static bool isAnimationByGenres(List<String>? genres) {
    if (genres == null || genres.isEmpty) return false;
    return genres.any(
      (String g) => g.toLowerCase() == 'animation' || g == '16',
    );
  }
}
