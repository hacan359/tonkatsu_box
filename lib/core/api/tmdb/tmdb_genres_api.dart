import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import 'tmdb_http_client.dart';
import 'tmdb_types.dart';

/// Genre catalogs (`/genre/{movie,tv}/list`) plus the per-language cache that
/// search / discover / multi-search use to expand `genre_ids` into the
/// `genres` shape the models expect. The two maps are language-dependent, so
/// the facade calls [clearCache] whenever the language changes or the key is
/// cleared.
class TmdbGenresApi {
  TmdbGenresApi(this._client);

  static final Logger _log = Logger('TmdbApi');

  final TmdbHttpClient _client;

  Map<int, String>? _movieGenreMap;
  Map<int, String>? _tvGenreMap;

  void clearCache() {
    _movieGenreMap = null;
    _tvGenreMap = null;
  }

  /// Seeds the genre cache directly. The test-only entry point is
  /// `TmdbApi.setGenreCacheForTesting`, which delegates here.
  void setCacheForTesting({
    Map<int, String>? movieGenres,
    Map<int, String>? tvGenres,
  }) {
    _movieGenreMap = movieGenres;
    _tvGenreMap = tvGenres;
  }

  Future<List<TmdbGenre>> getMovieGenres() async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response =
          await _client.get('/genre/movie/list');

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to fetch movie genres',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> genres = data['genres'] as List<dynamic>;

      return genres
          .map((dynamic item) =>
              TmdbGenre.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch movie genres');
    }
  }

  Future<List<TmdbGenre>> getTvGenres() async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get('/genre/tv/list');

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to fetch TV genres',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> genres = data['genres'] as List<dynamic>;

      return genres
          .map((dynamic item) =>
              TmdbGenre.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch TV genres');
    }
  }

  Future<Map<int, String>> ensureMovieGenreMap() async {
    if (_movieGenreMap != null) return _movieGenreMap!;
    try {
      final List<TmdbGenre> genres = await getMovieGenres();
      _movieGenreMap = <int, String>{
        for (final TmdbGenre g in genres) g.id: g.name,
      };
    } catch (e) {
      _log.warning('Failed to load movie genre map', e);
      _movieGenreMap = <int, String>{};
    }
    return _movieGenreMap!;
  }

  Future<Map<int, String>> ensureTvGenreMap() async {
    if (_tvGenreMap != null) return _tvGenreMap!;
    try {
      final List<TmdbGenre> genres = await getTvGenres();
      _tvGenreMap = <int, String>{
        for (final TmdbGenre g in genres) g.id: g.name,
      };
    } catch (e) {
      _log.warning('Failed to load TV genre map', e);
      _tvGenreMap = <int, String>{};
    }
    return _tvGenreMap!;
  }

  /// Expands `genre_ids` into `genres` objects on each item so downstream
  /// `Model.fromJson` sees the same shape as the detail endpoint.
  void resolveGenreIds(
    List<Map<String, dynamic>> items,
    Map<int, String> genreMap,
  ) {
    for (final Map<String, dynamic> item in items) {
      if (item['genres'] != null) continue;
      final List<dynamic>? genreIds = item['genre_ids'] as List<dynamic>?;
      if (genreIds == null) continue;
      item['genres'] = <Map<String, dynamic>>[
        for (final dynamic id in genreIds)
          if (genreMap.containsKey(id as int))
            <String, dynamic>{'id': id, 'name': genreMap[id]},
      ];
      item.remove('genre_ids');
    }
  }
}
