// API клиент для TMDB (TheMovieDB).

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/movie.dart';
import '../../shared/models/tv_season.dart';
import '../../shared/models/tv_show.dart';

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
  TmdbApi({Dio? dio, this.language = 'ru-RU'}) : _dio = dio ?? Dio();

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  final Dio _dio;

  /// Язык для локализации ответов.
  final String language;

  String? _apiKey;

  /// Устанавливает API ключ для аутентификации.
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Очищает API ключ.
  void clearApiKey() {
    _apiKey = null;
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
  ///
  /// Возвращает список найденных фильмов.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    _ensureApiKey();

    if (query.trim().isEmpty) {
      return <Movie>[];
    }

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/movie',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
          'query': query.trim(),
          'page': page,
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

      return results
          .map(
              (dynamic item) => Movie.fromJson(item as Map<String, dynamic>))
          .toList();
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

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to fetch popular movies',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] as List<dynamic>;

      return results
          .map(
              (dynamic item) => Movie.fromJson(item as Map<String, dynamic>))
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
  ///
  /// Возвращает список найденных сериалов.
  /// Throws [TmdbApiException] при ошибке запроса.
  Future<List<TvShow>> searchTvShows(String query, {int page = 1}) async {
    _ensureApiKey();

    if (query.trim().isEmpty) {
      return <TvShow>[];
    }

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/tv',
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'language': language,
          'query': query.trim(),
          'page': page,
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

      return results
          .map((dynamic item) =>
              TvShow.fromJson(item as Map<String, dynamic>))
          .toList();
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

      if (response.statusCode != 200 || response.data == null) {
        throw TmdbApiException(
          'Failed to fetch popular TV shows',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] as List<dynamic>;

      return results
          .map((dynamic item) =>
              TvShow.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch popular TV shows');
    }
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

      final List<MultiSearchResult> searchResults = <MultiSearchResult>[];

      for (final dynamic item in results) {
        final Map<String, dynamic> json = item as Map<String, dynamic>;
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
