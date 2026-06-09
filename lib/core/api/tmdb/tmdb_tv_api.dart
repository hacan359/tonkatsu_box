import 'package:dio/dio.dart';

import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import 'tmdb_genres_api.dart';
import 'tmdb_http_client.dart';
import 'tmdb_types.dart';

/// TV endpoints: search, detail, seasons / episodes, lists (popular /
/// trending / top-rated / on-the-air / recommendations / similar) and
/// discover.
class TmdbTvApi {
  TmdbTvApi(this._client, this._genres);

  final TmdbHttpClient _client;
  final TmdbGenresApi _genres;

  Future<List<TvShow>> searchTvShows(
    String query, {
    int page = 1,
    int? firstAirDateYear,
  }) async {
    _client.ensureApiKey();

    if (query.trim().isEmpty) {
      return <TvShow>[];
    }

    try {
      final Response<dynamic> response = await _client.get(
        '/search/tv',
        queryParameters: <String, dynamic>{
          'query': query.trim(),
          'page': page,
          'first_air_date_year': ?firstAirDateYear,
        },
      );

      final List<Map<String, dynamic>> items =
          _client.extractResults(response, 'Failed to search TV shows');
      final Map<int, String> genreMap = await _genres.ensureTvGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => TvShow.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search TV shows');
    }
  }

  Future<TmdbPagedResult<TvShow>> searchTvShowsPaged(
    String query, {
    int page = 1,
    int? firstAirDateYear,
  }) async {
    _client.ensureApiKey();

    if (query.trim().isEmpty) {
      return const TmdbPagedResult<TvShow>(
        results: <TvShow>[],
        page: 1,
        totalPages: 0,
        totalResults: 0,
      );
    }

    try {
      final Response<dynamic> response = await _client.get(
        '/search/tv',
        queryParameters: <String, dynamic>{
          'query': query.trim(),
          'page': page,
          'first_air_date_year': ?firstAirDateYear,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to search TV shows',
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
      final Map<int, String> genreMap = await _genres.ensureTvGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return TmdbPagedResult<TvShow>(
        results: items
            .map((Map<String, dynamic> json) => TvShow.fromJson(json))
            .toList(),
        page: currentPage,
        totalPages: totalPages,
        totalResults: totalResults,
      );
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search TV shows');
    }
  }

  Future<TvShow?> getTvShow(int tmdbId) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get('/tv/$tmdbId');

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to fetch TV show',
          statusCode: response.statusCode,
        );
      }

      return TvShow.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _client.handleDioException(e, 'Failed to fetch TV show');
    }
  }

  Future<List<TvSeason>> getTvSeasons(int tmdbId) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get('/tv/$tmdbId');

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to fetch TV show seasons',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> seasons =
          data['seasons'] as List<dynamic>? ?? <dynamic>[];

      return seasons
          .map((dynamic item) => TvSeason.fromJson(
                item as Map<String, dynamic>,
                showId: tmdbId,
              ))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch TV show seasons');
    }
  }

  Future<List<TvEpisode>> getSeasonEpisodes(
    int tmdbShowId,
    int seasonNumber,
  ) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response =
          await _client.get('/tv/$tmdbShowId/season/$seasonNumber');

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to fetch season episodes',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> episodes =
          data['episodes'] as List<dynamic>? ?? <dynamic>[];

      return episodes
          .map((dynamic item) => TvEpisode.fromJson(
                item as Map<String, dynamic>,
                showId: tmdbShowId,
                season: seasonNumber,
              ))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch season episodes');
    }
  }

  Future<List<TvShow>> getPopularTvShows({int page = 1}) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get(
        '/tv/popular',
        queryParameters: <String, dynamic>{'page': page},
      );

      final List<Map<String, dynamic>> items = _client.extractResults(
          response, 'Failed to fetch popular TV shows');
      final Map<int, String> genreMap = await _genres.ensureTvGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => TvShow.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch popular TV shows');
    }
  }

  Future<List<TvShow>> getTvRecommendations(int tmdbId, {int page = 1}) {
    return _fetchTvShowList('/tv/$tmdbId/recommendations', page: page);
  }

  Future<List<TvShow>> getSimilarTvShows(int tmdbId, {int page = 1}) {
    return _fetchTvShowList('/tv/$tmdbId/similar', page: page);
  }

  Future<List<TvShow>> getTrendingTvShows({
    String timeWindow = 'week',
    int page = 1,
  }) {
    return _fetchTvShowList('/trending/tv/$timeWindow', page: page);
  }

  Future<List<TvShow>> getTopRatedTvShows({int page = 1}) {
    return _fetchTvShowList('/tv/top_rated', page: page);
  }

  Future<List<TvShow>> getOnTheAirTvShows({int page = 1}) {
    return _fetchTvShowList('/tv/on_the_air', page: page);
  }

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
      if (year != null) params['first_air_date_year'] = year;
      if (firstAirDateGte != null) {
        params['first_air_date.gte'] = firstAirDateGte;
      }
      if (firstAirDateLte != null) {
        params['first_air_date.lte'] = firstAirDateLte;
      }
      if (voteCountGte != null) params['vote_count.gte'] = voteCountGte;
      if (voteAverageGte != null) {
        params['vote_average.gte'] = voteAverageGte;
      }
      if (originalLanguage != null) {
        params['with_original_language'] = originalLanguage;
      }
      if (withoutGenreIds != null && withoutGenreIds.isNotEmpty) {
        params['without_genres'] = withoutGenreIds.join(',');
      }

      final Response<dynamic> response = await _client.get(
        '/discover/tv',
        queryParameters: params,
      );

      final List<Map<String, dynamic>> items =
          _client.extractResults(response, 'Failed to discover TV shows');
      final Map<int, String> genreMap = await _genres.ensureTvGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => TvShow.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to discover TV shows');
    }
  }

  Future<List<TvShow>> _fetchTvShowList(String path, {int page = 1}) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get(
        path,
        queryParameters: <String, dynamic>{'page': page},
      );

      final List<Map<String, dynamic>> items = _client.extractResults(
          response, 'Failed to fetch TV shows from $path');
      final Map<int, String> genreMap = await _genres.ensureTvGenreMap();
      _genres.resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => TvShow.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch TV shows');
    }
  }
}
