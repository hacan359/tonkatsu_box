import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/movie.dart';
import '../../shared/models/tmdb_review.dart';
import '../../shared/models/tv_episode.dart';
import '../../shared/models/tv_season.dart';
import '../../shared/models/tv_show.dart';
import '../services/api_key_initializer.dart';
import 'tmdb/tmdb_find_api.dart';
import 'tmdb/tmdb_genres_api.dart';
import 'tmdb/tmdb_http_client.dart';
import 'tmdb/tmdb_movies_api.dart';
import 'tmdb/tmdb_reviews_api.dart';
import 'tmdb/tmdb_tv_api.dart';
import 'tmdb/tmdb_types.dart';

export 'tmdb/tmdb_types.dart';

final Provider<TmdbApi> tmdbApiProvider = Provider<TmdbApi>((Ref ref) {
  final TmdbApi api = TmdbApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  if (keys.tmdbApiKey != null && keys.tmdbApiKey!.isNotEmpty) {
    api.setApiKey(keys.tmdbApiKey!);
  }
  return api;
});

/// TMDB v3 facade. See `tmdb/README.md` for the layer breakdown:
/// `tmdb_http_client` (transport + key/language state), `tmdb_genres_api`
/// (catalog + per-language cache), `tmdb_movies_api`, `tmdb_tv_api`,
/// `tmdb_reviews_api`, `tmdb_find_api`, `tmdb_types` (DTOs).
class TmdbApi {
  TmdbApi({Dio? dio, String language = 'ru-RU'})
      : _client = TmdbHttpClient(dio: dio, language: language) {
    _genres = TmdbGenresApi(_client);
    _movies = TmdbMoviesApi(_client, _genres);
    _tv = TmdbTvApi(_client, _genres);
    _reviews = TmdbReviewsApi(_client);
    _find = TmdbFindApi(_client, _genres);
  }

  final TmdbHttpClient _client;
  late final TmdbGenresApi _genres;
  late final TmdbMoviesApi _movies;
  late final TmdbTvApi _tv;
  late final TmdbReviewsApi _reviews;
  late final TmdbFindApi _find;

  String get language => _client.language;

  void setLanguage(String language) {
    if (_client.language != language) {
      // Genre names are language-dependent — drop the cache so the next
      // request refetches them in the new language.
      _genres.clearCache();
    }
    _client.setLanguage(language);
  }

  void setApiKey(String apiKey) => _client.setApiKey(apiKey);

  void clearApiKey() {
    _client.clearApiKey();
    _genres.clearCache();
  }

  @visibleForTesting
  void setGenreCacheForTesting({
    Map<int, String>? movieGenres,
    Map<int, String>? tvGenres,
  }) =>
      _genres.setCacheForTesting(
        movieGenres: movieGenres,
        tvGenres: tvGenres,
      );

  Future<bool> validateApiKey(String apiKey) => _client.validateApiKey(apiKey);

  Future<List<Movie>> searchMovies(
    String query, {
    int page = 1,
    int? year,
  }) =>
      _movies.searchMovies(query, page: page, year: year);

  Future<TmdbPagedResult<Movie>> searchMoviesPaged(
    String query, {
    int page = 1,
    int? year,
  }) =>
      _movies.searchMoviesPaged(query, page: page, year: year);

  Future<Movie?> getMovie(int tmdbId) => _movies.getMovie(tmdbId);

  Future<List<Movie>> getPopularMovies({int page = 1}) =>
      _movies.getPopularMovies(page: page);

  Future<List<Movie>> getMovieRecommendations(int tmdbId, {int page = 1}) =>
      _movies.getMovieRecommendations(tmdbId, page: page);

  Future<List<Movie>> getSimilarMovies(int tmdbId, {int page = 1}) =>
      _movies.getSimilarMovies(tmdbId, page: page);

  Future<List<Movie>> getTrendingMovies({
    String timeWindow = 'week',
    int page = 1,
  }) =>
      _movies.getTrendingMovies(timeWindow: timeWindow, page: page);

  Future<List<Movie>> getTopRatedMovies({int page = 1}) =>
      _movies.getTopRatedMovies(page: page);

  Future<List<Movie>> getUpcomingMovies({int page = 1}) =>
      _movies.getUpcomingMovies(page: page);

  Future<List<Movie>> getNowPlayingMovies({int page = 1}) =>
      _movies.getNowPlayingMovies(page: page);

  Future<List<Movie>> discoverMovies({
    int? genreId,
    String? genreIds,
    int? year,
    String? releaseDateGte,
    String? releaseDateLte,
    int? voteCountGte,
    double? voteAverageGte,
    String? originalLanguage,
    String sortBy = 'popularity.desc',
    int page = 1,
  }) =>
      _movies.discoverMovies(
        genreId: genreId,
        genreIds: genreIds,
        year: year,
        releaseDateGte: releaseDateGte,
        releaseDateLte: releaseDateLte,
        voteCountGte: voteCountGte,
        voteAverageGte: voteAverageGte,
        originalLanguage: originalLanguage,
        sortBy: sortBy,
        page: page,
      );

  Future<List<TvShow>> searchTvShows(
    String query, {
    int page = 1,
    int? firstAirDateYear,
  }) =>
      _tv.searchTvShows(query, page: page, firstAirDateYear: firstAirDateYear);

  Future<TmdbPagedResult<TvShow>> searchTvShowsPaged(
    String query, {
    int page = 1,
    int? firstAirDateYear,
  }) =>
      _tv.searchTvShowsPaged(
        query,
        page: page,
        firstAirDateYear: firstAirDateYear,
      );

  Future<TvShow?> getTvShow(int tmdbId) => _tv.getTvShow(tmdbId);

  Future<List<TvSeason>> getTvSeasons(int tmdbId) =>
      _tv.getTvSeasons(tmdbId);

  Future<List<TvEpisode>> getSeasonEpisodes(
    int tmdbShowId,
    int seasonNumber,
  ) =>
      _tv.getSeasonEpisodes(tmdbShowId, seasonNumber);

  Future<List<TvShow>> getPopularTvShows({int page = 1}) =>
      _tv.getPopularTvShows(page: page);

  Future<List<TvShow>> getTvRecommendations(int tmdbId, {int page = 1}) =>
      _tv.getTvRecommendations(tmdbId, page: page);

  Future<List<TvShow>> getSimilarTvShows(int tmdbId, {int page = 1}) =>
      _tv.getSimilarTvShows(tmdbId, page: page);

  Future<List<TvShow>> getTrendingTvShows({
    String timeWindow = 'week',
    int page = 1,
  }) =>
      _tv.getTrendingTvShows(timeWindow: timeWindow, page: page);

  Future<List<TvShow>> getTopRatedTvShows({int page = 1}) =>
      _tv.getTopRatedTvShows(page: page);

  Future<List<TvShow>> getOnTheAirTvShows({int page = 1}) =>
      _tv.getOnTheAirTvShows(page: page);

  Future<List<TvShow>> discoverTvShows({
    int? genreId,
    String? genreIds,
    int? year,
    String? firstAirDateGte,
    String? firstAirDateLte,
    int? voteCountGte,
    double? voteAverageGte,
    String? originalLanguage,
    List<int>? withoutGenreIds,
    String sortBy = 'popularity.desc',
    int page = 1,
  }) =>
      _tv.discoverTvShows(
        genreId: genreId,
        genreIds: genreIds,
        year: year,
        firstAirDateGte: firstAirDateGte,
        firstAirDateLte: firstAirDateLte,
        voteCountGte: voteCountGte,
        voteAverageGte: voteAverageGte,
        originalLanguage: originalLanguage,
        withoutGenreIds: withoutGenreIds,
        sortBy: sortBy,
        page: page,
      );

  Future<TmdbFindResult> findByImdbId(String imdbId) =>
      _find.findByImdbId(imdbId);

  Future<TmdbFindResult> findByTvdbId(int tvdbId) =>
      _find.findByTvdbId(tvdbId);

  Future<List<MultiSearchResult>> multiSearch(String query, {int page = 1}) =>
      _find.multiSearch(query, page: page);

  Future<List<TmdbReview>> getMovieReviews(int tmdbId, {int page = 1}) =>
      _reviews.getMovieReviews(tmdbId, page: page);

  Future<List<TmdbReview>> getTvReviews(int tmdbId, {int page = 1}) =>
      _reviews.getTvReviews(tmdbId, page: page);

  Future<List<TmdbGenre>> getMovieGenres() => _genres.getMovieGenres();

  Future<List<TmdbGenre>> getTvGenres() => _genres.getTvGenres();

  void dispose() => _client.dispose();
}
