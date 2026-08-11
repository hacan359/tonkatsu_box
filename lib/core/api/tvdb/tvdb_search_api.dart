import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';
import 'package:dio/dio.dart';

import 'tvdb_http_client.dart';

/// `/search` — one endpoint for both record kinds, split by `type`.
class TvdbSearchApi {
  TvdbSearchApi(this._client);

  final TvdbHttpClient _client;

  Future<List<Movie>> searchMovies(
    String query, {
    required String locale,
    int limit = 25,
    int offset = 0,
    int? year,
  }) async {
    final List<Map<String, dynamic>> hits =
        await _search(query, 'movie', limit: limit, offset: offset, year: year);
    return hits
        .map((Map<String, dynamic> j) => Movie.fromTvdb(j, locale: locale))
        .toList();
  }

  Future<List<TvShow>> searchSeries(
    String query, {
    required String locale,
    int limit = 25,
    int offset = 0,
    int? year,
  }) async {
    final List<Map<String, dynamic>> hits = await _search(
      query,
      'series',
      limit: limit,
      offset: offset,
      year: year,
    );
    return hits
        .map((Map<String, dynamic> j) => TvShow.fromTvdb(j, locale: locale))
        .toList();
  }

  /// `/search` accepts `year` but silently ignores `genre` in every spelling —
  /// genre narrowing only exists on `/…/filter`.
  Future<List<Map<String, dynamic>>> _search(
    String query,
    String type, {
    required int limit,
    required int offset,
    int? year,
  }) async {
    if (query.trim().isEmpty) return const <Map<String, dynamic>>[];
    try {
      final Response<dynamic> response = await _client.get(
        'search',
        queryParameters: <String, dynamic>{
          'query': query.trim(),
          'type': type,
          'limit': limit,
          'offset': offset,
          'year': ?year,
        },
      );
      return _client.dataList(response);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'TheTVDB search failed');
    }
  }
}
