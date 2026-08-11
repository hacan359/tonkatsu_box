import 'package:core/models/movie.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_key_initializer.dart';
import 'tvdb/tvdb_http_client.dart';
import 'tvdb/tvdb_movies_api.dart';
import 'tvdb/tvdb_search_api.dart';
import 'tvdb/tvdb_series_api.dart';
export 'tvdb/tvdb_types.dart';

/// TheTVDB v4 facade (`https://api4.thetvdb.com/v4`). Movies and TV series.
///
/// [locale] is the app language; TheTVDB never localizes a response, so every
/// mapper picks the title and overview out of the translation payload.
class TvdbApi {
  TvdbApi({Dio? dio}) : _client = TvdbHttpClient(dio: dio) {
    _search = TvdbSearchApi(_client);
    _movies = TvdbMoviesApi(_client);
    _series = TvdbSeriesApi(_client);
  }

  final TvdbHttpClient _client;
  late final TvdbSearchApi _search;
  late final TvdbMoviesApi _movies;
  late final TvdbSeriesApi _series;

  String _locale = 'en';

  bool get hasApiKey => _client.hasApiKey;

  void setApiKey(String apiKey) => _client.setApiKey(apiKey);

  void clearApiKey() => _client.clearApiKey();

  void setLocale(String locale) => _locale = locale;

  Future<bool> validateApiKey(String apiKey) => _client.validateApiKey(apiKey);

  Future<List<Movie>> searchMovies(
    String query, {
    int limit = 25,
    int offset = 0,
    int? year,
  }) =>
      _search.searchMovies(
        query,
        locale: _locale,
        limit: limit,
        offset: offset,
        year: year,
      );

  Future<List<TvShow>> searchSeries(
    String query, {
    int limit = 25,
    int offset = 0,
    int? year,
  }) =>
      _search.searchSeries(
        query,
        locale: _locale,
        limit: limit,
        offset: offset,
        year: year,
      );

  Future<Movie?> getMovie(int id) => _movies.getMovie(id, locale: _locale);

  Future<List<Movie>> browseMovies({
    int? genreId,
    int? year,
    int? statusId,
    String sort = 'score',
    int page = 0,
  }) =>
      _movies.browse(
        locale: _locale,
        genreId: genreId,
        year: year,
        statusId: statusId,
        sort: sort,
        page: page,
      );

  Future<TvShow?> getSeries(int id) => _series.getSeries(id, locale: _locale);

  Future<List<TvSeason>> getSeasons(int id) => _series.getSeasons(id);

  Future<List<TvEpisode>> getAllEpisodes(int id) => _series.getAllEpisodes(id);

  Future<List<TvShow>> browseSeries({
    int? genreId,
    int? year,
    int? statusId,
    String sort = 'score',
    int page = 0,
  }) =>
      _series.browse(
        locale: _locale,
        genreId: genreId,
        year: year,
        statusId: statusId,
        sort: sort,
        page: page,
      );

  Future<List<({int id, String name})>> getGenres() => _series.getGenres();

  void dispose() => _client.dispose();
}

final Provider<TvdbApi> tvdbApiProvider = Provider<TvdbApi>((Ref ref) {
  final TvdbApi api = TvdbApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  final String? key = keys.tvdbApiKey;
  if (key != null && key.isNotEmpty) api.setApiKey(key);
  return api;
});
