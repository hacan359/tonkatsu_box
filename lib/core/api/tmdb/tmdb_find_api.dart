import 'package:dio/dio.dart';

import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import 'tmdb_genres_api.dart';
import 'tmdb_http_client.dart';
import 'tmdb_types.dart';

/// Cross-type lookups: `/find/{id}` by external ID and `/search/multi`. Both
/// can return movies and TV shows in one response.
class TmdbFindApi {
  TmdbFindApi(this._client, this._genres);

  final TmdbHttpClient _client;
  final TmdbGenresApi _genres;

  /// Used for matching Kodi items: older scrapers store IMDB IDs instead of
  /// TMDB. 404 is treated as "not found" and returns an empty result.
  Future<TmdbFindResult> findByImdbId(String imdbId) {
    return _findByExternalId(imdbId, 'imdb_id');
  }

  /// Kodi often uses the TVDB scraper for TV shows. The `tvdb_id` source on
  /// TMDB also returns episodes / seasons, but we only consume `tv_results`.
  Future<TmdbFindResult> findByTvdbId(int tvdbId) {
    return _findByExternalId(tvdbId.toString(), 'tvdb_id');
  }

  Future<TmdbFindResult> _findByExternalId(
    String externalId,
    String source,
  ) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get(
        '/find/$externalId',
        queryParameters: <String, dynamic>{'external_source': source},
      );

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to find by external ID',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> movieItems =
          (data['movie_results'] as List<dynamic>?) ?? <dynamic>[];
      final List<dynamic> tvItems =
          (data['tv_results'] as List<dynamic>?) ?? <dynamic>[];

      return TmdbFindResult(
        movies: movieItems
            .map((dynamic item) =>
                Movie.fromJson(item as Map<String, dynamic>))
            .toList(),
        tvShows: tvItems
            .map((dynamic item) =>
                TvShow.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const TmdbFindResult();
      }
      throw _client.handleDioException(e, 'Failed to find by external ID');
    }
  }

  Future<List<MultiSearchResult>> multiSearch(
    String query, {
    int page = 1,
  }) async {
    _client.ensureApiKey();

    if (query.trim().isEmpty) {
      return <MultiSearchResult>[];
    }

    try {
      final Response<dynamic> response = await _client.get(
        '/search/multi',
        queryParameters: <String, dynamic>{
          'query': query.trim(),
          'page': page,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to multi search',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] as List<dynamic>;

      final List<Map<String, dynamic>> items = results
          .map((dynamic item) => item as Map<String, dynamic>)
          .toList();

      // Movies and TV shows have separate genre catalogs on TMDB.
      final List<Map<String, dynamic>> movieItems = items
          .where((Map<String, dynamic> j) => j['media_type'] == 'movie')
          .toList();
      final List<Map<String, dynamic>> tvItems = items
          .where((Map<String, dynamic> j) => j['media_type'] == 'tv')
          .toList();

      if (movieItems.isNotEmpty) {
        final Map<int, String> movieGenreMap =
            await _genres.ensureMovieGenreMap();
        _genres.resolveGenreIds(movieItems, movieGenreMap);
      }
      if (tvItems.isNotEmpty) {
        final Map<int, String> tvGenreMap = await _genres.ensureTvGenreMap();
        _genres.resolveGenreIds(tvItems, tvGenreMap);
      }

      final List<MultiSearchResult> searchResults = <MultiSearchResult>[];

      for (final Map<String, dynamic> json in items) {
        final String? mediaType = json['media_type'] as String?;

        if (mediaType == 'movie') {
          searchResults.add(MultiSearchResult(
            mediaType: TmdbMediaType.movie,
            movie: Movie.fromJson(json),
          ));
        } else if (mediaType == 'tv') {
          searchResults.add(MultiSearchResult(
            mediaType: TmdbMediaType.tv,
            tvShow: TvShow.fromJson(json),
          ));
        }
        // Drop 'person' and any other unsupported media_type.
      }

      return searchResults;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to multi search');
    }
  }
}
