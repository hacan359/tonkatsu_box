import 'package:core/models/movie.dart';
import 'package:dio/dio.dart';

import 'tvdb_http_client.dart';

/// `short=true` drops artworks/characters (157 KB → 26 KB) yet keeps the
/// poster; `meta=translations` is the only way to get a movie overview.
class TvdbMoviesApi {
  TvdbMoviesApi(this._client);

  final TvdbHttpClient _client;

  Future<Movie?> getMovie(int id, {required String locale}) async {
    try {
      final Response<dynamic> response = await _client.get(
        'movies/$id/extended',
        queryParameters: <String, dynamic>{
          'meta': 'translations',
          'short': true,
        },
      );
      final Map<String, dynamic>? data = _client.dataObject(response);
      if (data == null) return null;
      return Movie.fromTvdb(data, locale: locale);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load TheTVDB movie');
    }
  }

  /// `/movies/filter` needs no query, so it powers the browse tab. [genreId]
  /// comes from `/genres`, which is one shared list for movies and series.
  Future<List<Movie>> browse({
    required String locale,
    int? genreId,
    int? year,
    int? statusId,
    String sort = 'score',
    int page = 0,
  }) async {
    try {
      final Response<dynamic> response = await _client.get(
        'movies/filter',
        queryParameters: <String, dynamic>{
          'lang': 'eng',
          'sort': sort.isEmpty ? 'score' : sort,
          'page': page,
          'genre': ?genreId,
          'year': ?year,
          'status': ?statusId,
        },
      );
      return _client
          .dataList(response)
          .map((Map<String, dynamic> j) => Movie.fromTvdb(j, locale: locale))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to browse TheTVDB movies');
    }
  }
}
