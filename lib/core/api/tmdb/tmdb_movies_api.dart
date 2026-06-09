import 'package:dio/dio.dart';

import '../../../shared/models/movie.dart';
import 'tmdb_genres_api.dart';
import 'tmdb_http_client.dart';
import 'tmdb_types.dart';

/// Movie endpoints: search, detail, lists (popular / trending / top-rated /
/// upcoming / now-playing / recommendations / similar) and discover.
class TmdbMoviesApi {
  TmdbMoviesApi(this._client, this._genres);

  final TmdbHttpClient _client;
  final TmdbGenresApi _genres;

  Future<List<Movie>> searchMovies(
    String query, {
    int page = 1,
    int? year,
  }) async {
    _client.ensureApiKey();

    if (query.trim().isEmpty) {
      return <Movie>[];
    }

    try {
      final Response<dynamic> response = await _client.get(
        '/search/movie',
        queryParameters: <String, dynamic>{
          'query': query.trim(),
          'page': page,
          'year': ?year,
        },
      );

      final List<Map<String, dynamic>> items =
          _client.extractResults(response, 'Failed to search movies');
      final Map<int, String> genreMap = await _genres.ensureMovieGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => Movie.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search movies');
    }
  }

  Future<TmdbPagedResult<Movie>> searchMoviesPaged(
    String query, {
    int page = 1,
    int? year,
  }) async {
    _client.ensureApiKey();

    if (query.trim().isEmpty) {
      return const TmdbPagedResult<Movie>(
        results: <Movie>[],
        page: 1,
        totalPages: 0,
        totalResults: 0,
      );
    }

    try {
      final Response<dynamic> response = await _client.get(
        '/search/movie',
        queryParameters: <String, dynamic>{
          'query': query.trim(),
          'page': page,
          'year': ?year,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to search movies',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] as List<dynamic>;
      final int currentPage = (data['page'] as int?) ?? 1;
      final int totalPages = (data['total_pages'] as int?) ?? 0;
      final int totalResults = (data['total_results'] as int?) ?? 0;

      final List<Map<String, dynamic>> items = results
          .map((dynamic item) => item as Map<String, dynamic>)
          .toList();
      final Map<int, String> genreMap = await _genres.ensureMovieGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return TmdbPagedResult<Movie>(
        results: items
            .map((Map<String, dynamic> json) => Movie.fromJson(json))
            .toList(),
        page: currentPage,
        totalPages: totalPages,
        totalResults: totalResults,
      );
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search movies');
    }
  }

  Future<Movie?> getMovie(int tmdbId) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get('/movie/$tmdbId');

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to fetch movie',
          statusCode: response.statusCode,
        );
      }

      return Movie.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _client.handleDioException(e, 'Failed to fetch movie');
    }
  }

  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get(
        '/movie/popular',
        queryParameters: <String, dynamic>{'page': page},
      );

      final List<Map<String, dynamic>> items =
          _client.extractResults(response, 'Failed to fetch popular movies');
      final Map<int, String> genreMap = await _genres.ensureMovieGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => Movie.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch popular movies');
    }
  }

  Future<List<Movie>> getMovieRecommendations(int tmdbId, {int page = 1}) {
    return _fetchMovieList('/movie/$tmdbId/recommendations', page: page);
  }

  Future<List<Movie>> getSimilarMovies(int tmdbId, {int page = 1}) {
    return _fetchMovieList('/movie/$tmdbId/similar', page: page);
  }

  Future<List<Movie>> getTrendingMovies({
    String timeWindow = 'week',
    int page = 1,
  }) {
    return _fetchMovieList('/trending/movie/$timeWindow', page: page);
  }

  Future<List<Movie>> getTopRatedMovies({int page = 1}) {
    return _fetchMovieList('/movie/top_rated', page: page);
  }

  Future<List<Movie>> getUpcomingMovies({int page = 1}) {
    return _fetchMovieList('/movie/upcoming', page: page);
  }

  Future<List<Movie>> getNowPlayingMovies({int page = 1}) {
    return _fetchMovieList('/movie/now_playing', page: page);
  }

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
  }) async {
    _client.ensureApiKey();

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'sort_by': sortBy,
        'page': page,
      };
      if (genreIds != null) {
        params['with_genres'] = genreIds;
      } else if (genreId != null) {
        params['with_genres'] = genreId;
      }
      if (year != null) params['primary_release_year'] = year;
      if (releaseDateGte != null) {
        params['primary_release_date.gte'] = releaseDateGte;
      }
      if (releaseDateLte != null) {
        params['primary_release_date.lte'] = releaseDateLte;
      }
      if (voteCountGte != null) params['vote_count.gte'] = voteCountGte;
      if (voteAverageGte != null) {
        params['vote_average.gte'] = voteAverageGte;
      }
      if (originalLanguage != null) {
        params['with_original_language'] = originalLanguage;
      }

      final Response<dynamic> response = await _client.get(
        '/discover/movie',
        queryParameters: params,
      );

      final List<Map<String, dynamic>> items =
          _client.extractResults(response, 'Failed to discover movies');
      final Map<int, String> genreMap = await _genres.ensureMovieGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => Movie.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to discover movies');
    }
  }

  Future<List<Movie>> _fetchMovieList(String path, {int page = 1}) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get(
        path,
        queryParameters: <String, dynamic>{'page': page},
      );

      final List<Map<String, dynamic>> items =
          _client.extractResults(response, 'Failed to fetch movies from $path');
      final Map<int, String> genreMap = await _genres.ensureMovieGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => Movie.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch movies');
    }
  }
}
