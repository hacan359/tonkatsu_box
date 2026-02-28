// API клиент для TMDB (TheMovieDB).

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/movie.dart';
import '../../shared/models/tmdb_review.dart';
import '../../shared/models/tv_episode.dart';
import '../../shared/models/tv_season.dart';
import '../../shared/models/tv_show.dart';

/// Результат пагинированного поиска TMDB.
class TmdbPagedResult<T> {
  /// Создаёт [TmdbPagedResult].
  const TmdbPagedResult({
    required this.results,
    required this.page,
    required this.totalPages,
    required this.totalResults,
  });

  /// Список результатов текущей страницы.
  final List<T> results;

  /// Номер текущей страницы.
  final int page;

  /// Общее количество страниц.
  final int totalPages;

  /// Общее количество результатов.
  final int totalResults;

  /// Есть ли ещё страницы.
  bool get hasMore => page < totalPages;
}

/// Провайдер для TMDB API клиента.
final Provider<TmdbApi> tmdbApiProvider = Provider<TmdbApi>((Ref ref) {
  return TmdbApi();
});

/// Исключение при ошибках TMDB API.
class TmdbApiException implements Exception {
  /// Создаёт [TmdbApiException].
  const TmdbApiException(this.message, {this.statusCode});

  /// Сообщение об ошибке.
  final String message;

  /// HTTP код ответа (если есть).
  final int? statusCode;

  @override
  String toString() => 'TmdbApiException: $message (status: $statusCode)';
}

/// Жанр из TMDB.
class TmdbGenre {
  /// Создаёт [TmdbGenre].
  const TmdbGenre({required this.id, required this.name});

  /// Создаёт [TmdbGenre] из JSON.
  factory TmdbGenre.fromJson(Map<String, dynamic> json) {
    return TmdbGenre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  /// ID жанра.
  final int id;

  /// Название жанра.
  final String name;
}

/// Тип результата мультипоиска.
enum TmdbMediaType {
  /// Фильм.
  movie,

  /// Сериал.
  tv,
}

/// Результат мультипоиска: фильм или сериал.
class MultiSearchResult {
  /// Создаёт [MultiSearchResult].
  const MultiSearchResult({
    required this.mediaType,
    this.movie,
    this.tvShow,
  });

  /// Тип медиа.
  final TmdbMediaType mediaType;

  /// Фильм (если mediaType == movie).
  final Movie? movie;

  /// Сериал (если mediaType == tv).
  final TvShow? tvShow;
}

/// Клиент для работы с TMDB API v3.
///
/// Использует API Key (v3 auth) для аутентификации.
/// Документация: https://developers.themoviedb.org/3
class TmdbApi {
  /// Создаёт экземпляр [TmdbApi].
  TmdbApi({Dio? dio, String language = 'ru-RU'})
      : _dio = dio ?? Dio(),
        _language = language;

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  final Dio _dio;

  /// Язык для локализации ответов TMDB API.
  String _language;

  /// Текущий язык для локализации ответов.
  String get language => _language;

  /// Устанавливает язык для локализации ответов.
  ///
  /// Сбрасывает кэш жанров, т.к. названия зависят от языка.
  void setLanguage(String language) {
    if (_language != language) {
      _movieGenreMap = null;
      _tvGenreMap = null;
    }
    _language = language;
  }

  String? _apiKey;

  /// Кэш жанров фильмов: id → name.
  Map<int, String>? _movieGenreMap;

  /// Кэш жанров сериалов: id → name.
  Map<int, String>? _tvGenreMap;

  /// Устанавливает API ключ для аутентификации.
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Очищает API ключ и кэш жанров.
  void clearApiKey() {
    _apiKey = null;
    _movieGenreMap = null;
    _tvGenreMap = null;
  }

  /// Предустанавливает кэш маппинга жанров (только для тестов).
  @visibleForTesting
  void setGenreCacheForTesting({
    Map<int, String>? movieGenres,
    Map<int, String>? tvGenres,
  }) {
    _movieGenreMap = movieGenres;
    _tvGenreMap = tvGenres;
  }

  /// Проверяет валидность API ключа.
  ///
  /// Возвращает true, если ключ корректен.
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/configuration',
        queryParameters: <String, dynamic>{
          'api_key': apiKey,
        },
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  // ===== Фильмы =====

  /// Ищет фильмы по названию.
  ///
  /// [query] — строка поиска.
  /// [page] — номер страницы (по умолчанию 1).
  /// [year] — фильтр по году релиза (опционально).
  ///
  /// Возвращает список найденных фильмов.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<Movie>> searchMovies(
    String query, {
    int page = 1,
    int? year,
  }) async {
    _ensureApiKey();

    if (query.trim().isEmpty) {
      return <Movie>[];
    }

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'api_key': _apiKey,
        'language': language,
        'query': query.trim(),
        'page': page,
      };
      if (year != null) {
        params['year'] = year;
      }
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/movie',
        queryParameters: params,
      );

      final List<Map<String, dynamic>> items =
          _extractResults(response, 'Failed to search movies');
      final Map<int, String> genreMap = await _ensureMovieGenreMap();
      _resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => Movie.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search movies');
    }
  }

  /// Ищет фильмы по названию с информацией о пагинации.
  ///
  /// [query] — строка поиска.
  /// [page] — номер страницы (по умолчанию 1).
  ///
  /// Возвращает [TmdbPagedResult] с фильмами и метаданными пагинации.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<TmdbPagedResult<Movie>> searchMoviesPaged(
    String query, {
    int page = 1,
  }) async {
    _ensureApiKey();

    if (query.trim().isEmpty) {
      return const TmdbPagedResult<Movie>(
        results: <Movie>[],
        page: 1,
        totalPages: 0,
        totalResults: 0,
      );
    }

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'api_key': _apiKey,
        'language': language,
        'query': query.trim(),
        'page': page,
      };
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/movie',
        queryParameters: params,
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
      final Map<int, String> genreMap = await _ensureMovieGenreMap();
      _resolveGenreIds(items, genreMap);

      return TmdbPagedResult<Movie>(
        results: items
            .map((Map<String, dynamic> json) => Movie.fromJson(json))
            .toList(),
        page: currentPage,
        totalPages: totalPages,
        totalResults: totalResults,
      );
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search movies');
    }
  }

  /// Получает фильм по ID.
  ///
  /// Возвращает фильм или null, если не найден.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<Movie?> getMovie(int tmdbId) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/movie/$tmdbId',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
        },
      );

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
      throw _handleDioException(e, 'Failed to fetch movie');
    }
  }

  /// Получает популярные фильмы.
  ///
  /// [page] — номер страницы (по умолчанию 1).
  ///
  /// Возвращает список популярных фильмов.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/movie/popular',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
          'page': page,
        },
      );

      final List<Map<String, dynamic>> items =
          _extractResults(response, 'Failed to fetch popular movies');
      final Map<int, String> genreMap = await _ensureMovieGenreMap();
      _resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => Movie.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch popular movies');
    }
  }

  // ===== Сериалы =====

  /// Ищет сериалы по названию.
  ///
  /// [query] — строка поиска.
  /// [page] — номер страницы (по умолчанию 1).
  /// [firstAirDateYear] — фильтр по году первого показа (опционально).
  ///
  /// Возвращает список найденных сериалов.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<TvShow>> searchTvShows(
    String query, {
    int page = 1,
    int? firstAirDateYear,
  }) async {
    _ensureApiKey();

    if (query.trim().isEmpty) {
      return <TvShow>[];
    }

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'api_key': _apiKey,
        'language': language,
        'query': query.trim(),
        'page': page,
      };
      if (firstAirDateYear != null) {
        params['first_air_date_year'] = firstAirDateYear;
      }
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/tv',
        queryParameters: params,
      );

      final List<Map<String, dynamic>> items =
          _extractResults(response, 'Failed to search TV shows');
      final Map<int, String> genreMap = await _ensureTvGenreMap();
      _resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => TvShow.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search TV shows');
    }
  }

  /// Ищет сериалы по названию с информацией о пагинации.
  ///
  /// [query] — строка поиска.
  /// [page] — номер страницы (по умолчанию 1).
  ///
  /// Возвращает [TmdbPagedResult] с сериалами и метаданными пагинации.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<TmdbPagedResult<TvShow>> searchTvShowsPaged(
    String query, {
    int page = 1,
  }) async {
    _ensureApiKey();

    if (query.trim().isEmpty) {
      return const TmdbPagedResult<TvShow>(
        results: <TvShow>[],
        page: 1,
        totalPages: 0,
        totalResults: 0,
      );
    }

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'api_key': _apiKey,
        'language': language,
        'query': query.trim(),
        'page': page,
      };
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/tv',
        queryParameters: params,
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
      final Map<int, String> genreMap = await _ensureTvGenreMap();
      _resolveGenreIds(items, genreMap);

      return TmdbPagedResult<TvShow>(
        results: items
            .map((Map<String, dynamic> json) => TvShow.fromJson(json))
            .toList(),
        page: currentPage,
        totalPages: totalPages,
        totalResults: totalResults,
      );
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search TV shows');
    }
  }

  /// Получает сериал по ID.
  ///
  /// Возвращает сериал или null, если не найден.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<TvShow?> getTvShow(int tmdbId) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/tv/$tmdbId',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
        },
      );

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
      throw _handleDioException(e, 'Failed to fetch TV show');
    }
  }

  /// Получает сезоны сериала.
  ///
  /// Извлекает сезоны из деталей сериала.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<TvSeason>> getTvSeasons(int tmdbId) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/tv/$tmdbId',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to fetch TV show seasons',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> seasons = data['seasons'] as List<dynamic>? ?? <dynamic>[];

      return seasons
          .map((dynamic item) => TvSeason.fromJson(
                item as Map<String, dynamic>,
                showId: tmdbId,
              ))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch TV show seasons');
    }
  }

  /// Получает эпизоды конкретного сезона сериала.
  ///
  /// [tmdbShowId] — ID сериала в TMDB.
  /// [seasonNumber] — номер сезона.
  ///
  /// Возвращает список эпизодов сезона.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<TvEpisode>> getSeasonEpisodes(
    int tmdbShowId,
    int seasonNumber,
  ) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/tv/$tmdbShowId/season/$seasonNumber',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
        },
      );

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
      throw _handleDioException(e, 'Failed to fetch season episodes');
    }
  }

  /// Получает популярные сериалы.
  ///
  /// [page] — номер страницы (по умолчанию 1).
  ///
  /// Возвращает список популярных сериалов.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<TvShow>> getPopularTvShows({int page = 1}) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/tv/popular',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
          'page': page,
        },
      );

      final List<Map<String, dynamic>> items =
          _extractResults(response, 'Failed to fetch popular TV shows');
      final Map<int, String> genreMap = await _ensureTvGenreMap();
      _resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => TvShow.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch popular TV shows');
    }
  }

  // ===== Рекомендации и похожие =====

  /// Рекомендации к фильму.
  ///
  /// [tmdbId] — ID фильма.
  /// [page] — номер страницы (по умолчанию 1).
  Future<List<Movie>> getMovieRecommendations(int tmdbId, {int page = 1}) async {
    return _fetchMovieList('$_baseUrl/movie/$tmdbId/recommendations', page: page);
  }

  /// Похожие фильмы.
  ///
  /// [tmdbId] — ID фильма.
  /// [page] — номер страницы (по умолчанию 1).
  Future<List<Movie>> getSimilarMovies(int tmdbId, {int page = 1}) async {
    return _fetchMovieList('$_baseUrl/movie/$tmdbId/similar', page: page);
  }

  /// Рекомендации к сериалу.
  ///
  /// [tmdbId] — ID сериала.
  /// [page] — номер страницы (по умолчанию 1).
  Future<List<TvShow>> getTvRecommendations(int tmdbId, {int page = 1}) async {
    return _fetchTvShowList('$_baseUrl/tv/$tmdbId/recommendations', page: page);
  }

  /// Похожие сериалы.
  ///
  /// [tmdbId] — ID сериала.
  /// [page] — номер страницы (по умолчанию 1).
  Future<List<TvShow>> getSimilarTvShows(int tmdbId, {int page = 1}) async {
    return _fetchTvShowList('$_baseUrl/tv/$tmdbId/similar', page: page);
  }

  // ===== Trending =====

  /// Трендовые фильмы.
  ///
  /// [timeWindow] — временное окно ('day' или 'week').
  /// [page] — номер страницы (по умолчанию 1).
  Future<List<Movie>> getTrendingMovies({
    String timeWindow = 'week',
    int page = 1,
  }) async {
    return _fetchMovieList(
      '$_baseUrl/trending/movie/$timeWindow',
      page: page,
    );
  }

  /// Трендовые сериалы.
  ///
  /// [timeWindow] — временное окно ('day' или 'week').
  /// [page] — номер страницы (по умолчанию 1).
  Future<List<TvShow>> getTrendingTvShows({
    String timeWindow = 'week',
    int page = 1,
  }) async {
    return _fetchTvShowList(
      '$_baseUrl/trending/tv/$timeWindow',
      page: page,
    );
  }

  // ===== Curated Lists =====

  /// Лучшие фильмы всех времён.
  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    return _fetchMovieList('$_baseUrl/movie/top_rated', page: page);
  }

  /// Скоро в кино.
  Future<List<Movie>> getUpcomingMovies({int page = 1}) async {
    return _fetchMovieList('$_baseUrl/movie/upcoming', page: page);
  }

  /// Сейчас в кинотеатрах.
  Future<List<Movie>> getNowPlayingMovies({int page = 1}) async {
    return _fetchMovieList('$_baseUrl/movie/now_playing', page: page);
  }

  /// Лучшие сериалы всех времён.
  Future<List<TvShow>> getTopRatedTvShows({int page = 1}) async {
    return _fetchTvShowList('$_baseUrl/tv/top_rated', page: page);
  }

  /// Сериалы, выходящие сейчас.
  Future<List<TvShow>> getOnTheAirTvShows({int page = 1}) async {
    return _fetchTvShowList('$_baseUrl/tv/on_the_air', page: page);
  }

  // ===== Discover =====

  /// Discover фильмов с фильтрами.
  ///
  /// [genreId] — ID жанра (один жанр).
  /// [genreIds] — строка жанров через запятую (например '16,28').
  /// [year] — конкретный год выпуска.
  /// [releaseDateGte] — дата начала диапазона (YYYY-MM-DD), для декад.
  /// [releaseDateLte] — дата конца диапазона (YYYY-MM-DD), для декад.
  /// [voteCountGte] — минимальное количество голосов.
  Future<List<Movie>> discoverMovies({
    int? genreId,
    String? genreIds,
    int? year,
    String? releaseDateGte,
    String? releaseDateLte,
    int? voteCountGte,
    String sortBy = 'popularity.desc',
    int page = 1,
  }) async {
    _ensureApiKey();

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'api_key': _apiKey,
        'language': language,
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

      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/discover/movie',
        queryParameters: params,
      );

      final List<Map<String, dynamic>> items =
          _extractResults(response, 'Failed to discover movies');
      final Map<int, String> genreMap = await _ensureMovieGenreMap();
      _resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => Movie.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to discover movies');
    }
  }

  /// Discover сериалов с фильтрами.
  ///
  /// [genreId] — ID жанра (один жанр).
  /// [genreIds] — строка жанров через запятую (например '16,10765').
  /// [year] — конкретный год первого эфира.
  /// [firstAirDateGte] — дата начала диапазона (YYYY-MM-DD), для декад.
  /// [firstAirDateLte] — дата конца диапазона (YYYY-MM-DD), для декад.
  /// [voteCountGte] — минимальное количество голосов.
  /// [withoutGenreIds] — исключить жанры (например [16] для анимации).
  Future<List<TvShow>> discoverTvShows({
    int? genreId,
    String? genreIds,
    int? year,
    String? firstAirDateGte,
    String? firstAirDateLte,
    int? voteCountGte,
    List<int>? withoutGenreIds,
    String sortBy = 'popularity.desc',
    int page = 1,
  }) async {
    _ensureApiKey();

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'api_key': _apiKey,
        'language': language,
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
      if (withoutGenreIds != null && withoutGenreIds.isNotEmpty) {
        params['without_genres'] = withoutGenreIds.join(',');
      }

      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/discover/tv',
        queryParameters: params,
      );

      final List<Map<String, dynamic>> items =
          _extractResults(response, 'Failed to discover TV shows');
      final Map<int, String> genreMap = await _ensureTvGenreMap();
      _resolveGenreIds(items, genreMap);

      return items
          .map((Map<String, dynamic> json) => TvShow.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to discover TV shows');
    }
  }

  // ===== Reviews =====

  /// Отзывы к фильму.
  ///
  /// Всегда запрашивает на en-US (отзывов на других языках мало).
  Future<List<TmdbReview>> getMovieReviews(int tmdbId, {int page = 1}) async {
    return _fetchReviews('$_baseUrl/movie/$tmdbId/reviews', page: page);
  }

  /// Отзывы к сериалу.
  ///
  /// Всегда запрашивает на en-US (отзывов на других языках мало).
  Future<List<TmdbReview>> getTvReviews(int tmdbId, {int page = 1}) async {
    return _fetchReviews('$_baseUrl/tv/$tmdbId/reviews', page: page);
  }

  // ===== Общее =====

  /// Мультипоиск (фильмы + сериалы).
  ///
  /// [query] — строка поиска.
  /// [page] — номер страницы (по умолчанию 1).
  ///
  /// Возвращает список результатов (фильмы и сериалы).
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<MultiSearchResult>> multiSearch(
    String query, {
    int page = 1,
  }) async {
    _ensureApiKey();

    if (query.trim().isEmpty) {
      return <MultiSearchResult>[];
    }

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/multi',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
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

      // Резолвим жанры отдельно для фильмов и сериалов
      final List<Map<String, dynamic>> movieItems = items
          .where((Map<String, dynamic> j) => j['media_type'] == 'movie')
          .toList();
      final List<Map<String, dynamic>> tvItems = items
          .where((Map<String, dynamic> j) => j['media_type'] == 'tv')
          .toList();

      if (movieItems.isNotEmpty) {
        final Map<int, String> movieGenreMap = await _ensureMovieGenreMap();
        _resolveGenreIds(movieItems, movieGenreMap);
      }
      if (tvItems.isNotEmpty) {
        final Map<int, String> tvGenreMap = await _ensureTvGenreMap();
        _resolveGenreIds(tvItems, tvGenreMap);
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
        // Пропускаем 'person' и другие типы
      }

      return searchResults;
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to multi search');
    }
  }

  /// Возвращает список жанров фильмов.
  ///
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<TmdbGenre>> getMovieGenres() async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/genre/movie/list',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
        },
      );

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
      throw _handleDioException(e, 'Failed to fetch movie genres');
    }
  }

  /// Возвращает список жанров сериалов.
  ///
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<TmdbGenre>> getTvGenres() async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/genre/tv/list',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
        },
      );

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
      throw _handleDioException(e, 'Failed to fetch TV genres');
    }
  }

  /// Обрабатывает DioException и возвращает TmdbApiException.
  TmdbApiException _handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;

    if (statusCode == 401) {
      message = 'Invalid API key';
    } else if (statusCode == 404) {
      message = 'Resource not found';
    } else if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return TmdbApiException(message, statusCode: statusCode);
  }

  // ===== Приватные хелперы =====

  /// Загружает и кэширует маппинг жанров фильмов.
  Future<Map<int, String>> _ensureMovieGenreMap() async {
    if (_movieGenreMap != null) return _movieGenreMap!;
    try {
      final List<TmdbGenre> genres = await getMovieGenres();
      _movieGenreMap = <int, String>{
        for (final TmdbGenre g in genres) g.id: g.name,
      };
    } catch (_) {
      _movieGenreMap = <int, String>{};
    }
    return _movieGenreMap!;
  }

  /// Загружает и кэширует маппинг жанров сериалов.
  Future<Map<int, String>> _ensureTvGenreMap() async {
    if (_tvGenreMap != null) return _tvGenreMap!;
    try {
      final List<TmdbGenre> genres = await getTvGenres();
      _tvGenreMap = <int, String>{
        for (final TmdbGenre g in genres) g.id: g.name,
      };
    } catch (_) {
      _tvGenreMap = <int, String>{};
    }
    return _tvGenreMap!;
  }

  /// Резолвит `genre_ids` в `genres` (объекты с `name`) в JSON элементах.
  void _resolveGenreIds(
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

  /// Загружает список фильмов из paged endpoint.
  Future<List<Movie>> _fetchMovieList(String url, {int page = 1}) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        url,
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
          'page': page,
        },
      );

      final List<Map<String, dynamic>> items =
          _extractResults(response, 'Failed to fetch movies from $url');
      final Map<int, String> genreMap = await _ensureMovieGenreMap();
      _resolveGenreIds(items, genreMap);

      return items.map((Map<String, dynamic> json) => Movie.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch movies');
    }
  }

  /// Загружает список сериалов из paged endpoint.
  Future<List<TvShow>> _fetchTvShowList(String url, {int page = 1}) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        url,
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
          'page': page,
        },
      );

      final List<Map<String, dynamic>> items =
          _extractResults(response, 'Failed to fetch TV shows from $url');
      final Map<int, String> genreMap = await _ensureTvGenreMap();
      _resolveGenreIds(items, genreMap);

      return items.map((Map<String, dynamic> json) => TvShow.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch TV shows');
    }
  }

  /// Загружает отзывы из paged endpoint.
  Future<List<TmdbReview>> _fetchReviews(String url, {int page = 1}) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        url,
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': 'en-US',
          'page': page,
        },
      );

      return _parseResultsList<TmdbReview>(
        response,
        (Map<String, dynamic> json) => TmdbReview.fromJson(json),
        'Failed to fetch reviews from $url',
      );
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch reviews');
    }
  }

  /// Парсит стандартный paged response TMDB в список объектов.
  List<T> _parseResultsList<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
    String errorMessage,
  ) {
    final List<Map<String, dynamic>> items =
        _extractResults(response, errorMessage);
    return items.map(fromJson).toList();
  }

  /// Извлекает массив `results` из ответа TMDB API.
  List<Map<String, dynamic>> _extractResults(
    Response<dynamic> response,
    String errorMessage,
  ) {
    if (response.statusCode != 200 || response.data == null) {
      throw TmdbApiException(
        errorMessage,
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> data =
        response.data as Map<String, dynamic>;
    final List<dynamic> results = data['results'] as List<dynamic>;

    return results
        .map((dynamic item) => item as Map<String, dynamic>)
        .toList();
  }

  void _ensureApiKey() {
    if (_apiKey == null) {
      throw const TmdbApiException('API key not set');
    }
  }

  /// Закрывает HTTP клиент.
  void dispose() {
    _dio.close();
  }
}
