// Клиент для работы с AniList GraphQL API.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'api_error_detail.dart';
import '../../shared/models/anime.dart';
import '../../shared/models/manga.dart';

/// Провайдер для AniList API клиента.
final Provider<AniListApi> aniListApiProvider =
    Provider<AniListApi>((Ref ref) {
  return AniListApi();
});

/// Исключение при ошибках AniList API.
class AniListApiException implements Exception {
  /// Создаёт [AniListApiException].
  const AniListApiException(this.message, {this.statusCode, this.detail});

  /// Сообщение об ошибке.
  final String message;

  /// HTTP код ответа (если есть).
  final int? statusCode;

  /// Подробная отладочная информация (URL, метод, причина).
  final String? detail;

  @override
  String toString() =>
      'AniListApiException: $message (status: $statusCode)';
}

/// Клиент для работы с AniList GraphQL API.
///
/// Использует публичный GraphQL endpoint без авторизации.
/// Лимит: 90 запросов/мин.
/// Документация: https://anilist.gitbook.io/anilist-apiv2-docs
class AniListApi {
  /// Создаёт экземпляр [AniListApi].
  AniListApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            ));

  static final Logger _log = Logger('AniListApi');

  static const Duration _timeout = Duration(seconds: 5);
  static const String _baseUrl = 'https://graphql.anilist.co';

  /// GraphQL query для поиска/browse манги.
  static const String _searchQuery = r'''
query ($page: Int, $perPage: Int, $search: String, $genres: [String],
       $format: MediaFormat, $status: MediaStatus,
       $startDateGreater: FuzzyDateInt, $startDateLesser: FuzzyDateInt,
       $sort: [MediaSort]) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      total
      currentPage
      lastPage
      hasNextPage
    }
    media(type: MANGA, search: $search, genre_in: $genres,
          format: $format, status: $status,
          startDate_greater: $startDateGreater,
          startDate_lesser: $startDateLesser,
          sort: $sort) {
      id
      title { romaji english native }
      coverImage { large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      meanScore
      popularity
      status
      startDate { year month day }
      chapters
      volumes
      format
      countryOfOrigin
      staff(sort: RELEVANCE, perPage: 5) {
        edges {
          node { name { full } }
          role
        }
      }
    }
  }
}
''';

  /// GraphQL query для получения манги по ID.
  static const String _getByIdQuery = r'''
query ($id: Int) {
  Media(id: $id, type: MANGA) {
    id
    title { romaji english native }
    coverImage { large medium }
    description(asHtml: false)
    genres
    averageScore
    meanScore
    popularity
    status
    startDate { year month day }
    chapters
    volumes
    format
    countryOfOrigin
    staff(sort: RELEVANCE, perPage: 5) {
      edges {
        node { name { full } }
        role
      }
    }
  }
}
''';

  /// GraphQL query для получения нескольких манг по ID.
  static const String _getByIdsQuery = r'''
query ($page: Int, $perPage: Int, $ids: [Int]) {
  Page(page: $page, perPage: $perPage) {
    media(type: MANGA, id_in: $ids) {
      id
      title { romaji english native }
      coverImage { large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      meanScore
      popularity
      status
      startDate { year month day }
      chapters
      volumes
      format
      countryOfOrigin
      staff(sort: RELEVANCE, perPage: 5) {
        edges {
          node { name { full } }
          role
        }
      }
    }
  }
}
''';

  /// GraphQL query для поиска/browse аниме.
  static const String _animeSearchQuery = r'''
query ($page: Int, $perPage: Int, $search: String, $genres: [String],
       $status: MediaStatus, $format: MediaFormat,
       $season: MediaSeason, $seasonYear: Int,
       $sort: [MediaSort]) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      total
      currentPage
      lastPage
      hasNextPage
    }
    media(type: ANIME, search: $search, genre_in: $genres,
          status: $status, format: $format,
          season: $season, seasonYear: $seasonYear,
          sort: $sort) {
      id
      title { romaji english native }
      coverImage { large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      meanScore
      popularity
      status
      season
      seasonYear
      startDate { year month day }
      episodes
      duration
      format
      source
      studios(isMain: true) { nodes { name } }
      nextAiringEpisode { airingAt episode }
    }
  }
}
''';

  /// GraphQL query для получения аниме по ID.
  static const String _animeGetByIdQuery = r'''
query ($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    title { romaji english native }
    coverImage { large medium }
    bannerImage
    description(asHtml: false)
    genres
    averageScore
    meanScore
    popularity
    status
    season
    seasonYear
    startDate { year month day }
    episodes
    duration
    format
    source
    studios(isMain: true) { nodes { name } }
    nextAiringEpisode { airingAt episode }
  }
}
''';

  /// GraphQL query для получения нескольких аниме по ID.
  static const String _animeGetByIdsQuery = r'''
query ($page: Int, $perPage: Int, $ids: [Int]) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, id_in: $ids) {
      id
      title { romaji english native }
      coverImage { large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      meanScore
      popularity
      status
      season
      seasonYear
      startDate { year month day }
      episodes
      duration
      format
      source
      studios(isMain: true) { nodes { name } }
      nextAiringEpisode { airingAt episode }
    }
  }
}
''';

  final Dio _dio;

  /// Ищет мангу по названию.
  ///
  /// Возвращает кортеж (список, есть ли ещё, кол-во страниц).
  /// Throws [AniListApiException] при ошибке.
  Future<(List<Manga>, bool hasMore, int totalPages)> searchManga({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    if (query.trim().isEmpty) {
      return (<Manga>[], false, 0);
    }

    return browseManga(query: query, page: page, perPage: perPage);
  }

  /// Просматривает мангу с фильтрами.
  ///
  /// [genres] — жанры (OR match). Пустой или null = без фильтра.
  /// [format] — формат: MANGA, MANHWA, MANHUA, ONE_SHOT, NOVEL, LIGHT_NOVEL.
  /// [status] — статус: FINISHED / RELEASING / NOT_YET_RELEASED / CANCELLED / HIATUS.
  /// [startYear] — публикация началась в указанном году (FuzzyDate YYYYMMDD).
  /// [sort] — сортировка: SCORE_DESC, POPULARITY_DESC, START_DATE_DESC и др.
  ///
  /// Возвращает кортеж (список, есть ли ещё, кол-во страниц).
  /// Throws [AniListApiException] при ошибке.
  Future<(List<Manga>, bool hasMore, int totalPages)> browseManga({
    String? query,
    List<String>? genres,
    String? format,
    String? status,
    int? startYear,
    int? endYear,
    String sort = 'SCORE_DESC',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final Map<String, dynamic> variables = <String, dynamic>{
        'page': page,
        'perPage': perPage,
        'sort': <String>[sort],
      };

      if (query != null && query.trim().isNotEmpty) {
        variables['search'] = query;
      }
      if (genres != null && genres.isNotEmpty) {
        variables['genres'] = genres;
      }
      if (format != null) {
        variables['format'] = format;
      }
      if (status != null) {
        variables['status'] = status;
      }
      // FuzzyDateInt: YYYYMMDD. Начало года = YYYY0101, конец = YYYY1231.
      if (startYear != null) {
        variables['startDateGreater'] = startYear * 10000 + 101;
      }
      if (endYear != null) {
        variables['startDateLesser'] = endYear * 10000 + 1231;
      }

      final Response<dynamic> response = await _dio.post<dynamic>(
        _baseUrl,
        data: <String, dynamic>{
          'query': _searchQuery,
          'variables': variables,
        },
      );

      return _parsePageResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search manga');
    }
  }

  /// Получает мангу по AniList ID.
  ///
  /// Возвращает мангу или null, если не найдена.
  /// Throws [AniListApiException] при ошибке.
  Future<Manga?> getMangaById(int id) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _baseUrl,
        data: <String, dynamic>{
          'query': _getByIdQuery,
          'variables': <String, dynamic>{'id': id},
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw AniListApiException(
          'Failed to fetch manga',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final Map<String, dynamic>? dataField =
          data['data'] as Map<String, dynamic>?;
      if (dataField == null) {
        _checkErrors(data);
        return null;
      }

      final Map<String, dynamic>? media =
          dataField['Media'] as Map<String, dynamic>?;
      if (media == null) return null;

      return Manga.fromJson(media);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch manga');
    }
  }

  /// Получает несколько манг по списку ID.
  ///
  /// Throws [AniListApiException] при ошибке.
  /// Максимум элементов на страницу AniList API.
  static const int _maxPerPage = 50;

  Future<List<Manga>> getMangaByIds(List<int> ids) async {
    if (ids.isEmpty) return <Manga>[];

    final List<Manga> allMangas = <Manga>[];

    // AniList API ограничивает perPage до 50, батчим запросы
    for (int i = 0; i < ids.length; i += _maxPerPage) {
      final List<int> batch = ids.sublist(
        i,
        i + _maxPerPage > ids.length ? ids.length : i + _maxPerPage,
      );
      final List<Manga> batchResult = await _fetchMangaBatch(batch);
      allMangas.addAll(batchResult);
    }

    return allMangas;
  }

  Future<List<Manga>> _fetchMangaBatch(List<int> ids) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _baseUrl,
        data: <String, dynamic>{
          'query': _getByIdsQuery,
          'variables': <String, dynamic>{
            'page': 1,
            'perPage': ids.length,
            'ids': ids,
          },
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw AniListApiException(
          'Failed to fetch manga by IDs',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final Map<String, dynamic>? dataField =
          data['data'] as Map<String, dynamic>?;
      if (dataField == null) {
        _checkErrors(data);
        return <Manga>[];
      }

      final Map<String, dynamic>? pageData =
          dataField['Page'] as Map<String, dynamic>?;
      if (pageData == null) return <Manga>[];

      final List<dynamic> mediaList =
          pageData['media'] as List<dynamic>? ?? <dynamic>[];

      return mediaList
          .map((dynamic item) =>
              Manga.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch manga by IDs');
    }
  }

  /// Просматривает аниме с фильтрами.
  ///
  /// [genres] — жанры (OR match). Пустой или null = без фильтра.
  /// [status] — статус: RELEASING, FINISHED, NOT_YET_RELEASED, CANCELLED.
  /// [format] — формат: TV, MOVIE, OVA, ONA, SPECIAL, MUSIC, TV_SHORT.
  /// [season] — сезон: WINTER / SPRING / SUMMER / FALL (нужен [seasonYear]).
  /// [seasonYear] — год сезона. Самостоятельно — год выпуска аниме.
  /// [sort] — сортировка: SCORE_DESC, POPULARITY_DESC, TRENDING_DESC и др.
  ///
  /// Возвращает кортеж (список, есть ли ещё, кол-во страниц).
  /// Throws [AniListApiException] при ошибке.
  Future<(List<Anime>, bool hasMore, int totalPages)> browseAnime({
    String? query,
    List<String>? genres,
    String? status,
    String? format,
    String? season,
    int? seasonYear,
    String sort = 'POPULARITY_DESC',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final Map<String, dynamic> variables = <String, dynamic>{
        'page': page,
        'perPage': perPage,
        'sort': <String>[sort],
      };

      if (query != null && query.trim().isNotEmpty) {
        variables['search'] = query;
      }
      if (genres != null && genres.isNotEmpty) {
        variables['genres'] = genres;
      }
      if (status != null) {
        variables['status'] = status;
      }
      if (format != null) {
        variables['format'] = format;
      }
      if (season != null) {
        variables['season'] = season;
      }
      if (seasonYear != null) {
        variables['seasonYear'] = seasonYear;
      }

      final Response<dynamic> response = await _dio.post<dynamic>(
        _baseUrl,
        data: <String, dynamic>{
          'query': _animeSearchQuery,
          'variables': variables,
        },
      );

      return _parseAnimePageResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search anime');
    }
  }

  /// Получает аниме по AniList ID.
  ///
  /// Возвращает аниме или null, если не найдено.
  /// Throws [AniListApiException] при ошибке.
  Future<Anime?> getAnimeById(int id) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _baseUrl,
        data: <String, dynamic>{
          'query': _animeGetByIdQuery,
          'variables': <String, dynamic>{'id': id},
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw AniListApiException(
          'Failed to fetch anime',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final Map<String, dynamic>? dataField =
          data['data'] as Map<String, dynamic>?;
      if (dataField == null) {
        _checkErrors(data);
        return null;
      }

      final Map<String, dynamic>? media =
          dataField['Media'] as Map<String, dynamic>?;
      if (media == null) return null;

      return Anime.fromJson(media);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch anime');
    }
  }

  /// Получает несколько аниме по списку ID.
  ///
  /// Throws [AniListApiException] при ошибке.
  Future<List<Anime>> getAnimeByIds(List<int> ids) async {
    if (ids.isEmpty) return <Anime>[];

    final List<Anime> allAnime = <Anime>[];

    for (int i = 0; i < ids.length; i += _maxPerPage) {
      final List<int> batch = ids.sublist(
        i,
        i + _maxPerPage > ids.length ? ids.length : i + _maxPerPage,
      );
      final List<Anime> batchResult = await _fetchAnimeBatch(batch);
      allAnime.addAll(batchResult);
    }

    return allAnime;
  }

  Future<List<Anime>> _fetchAnimeBatch(List<int> ids) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _baseUrl,
        data: <String, dynamic>{
          'query': _animeGetByIdsQuery,
          'variables': <String, dynamic>{
            'page': 1,
            'perPage': ids.length,
            'ids': ids,
          },
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw AniListApiException(
          'Failed to fetch anime by IDs',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final Map<String, dynamic>? dataField =
          data['data'] as Map<String, dynamic>?;
      if (dataField == null) {
        _checkErrors(data);
        return <Anime>[];
      }

      final Map<String, dynamic>? pageData =
          dataField['Page'] as Map<String, dynamic>?;
      if (pageData == null) return <Anime>[];

      final List<dynamic> mediaList =
          pageData['media'] as List<dynamic>? ?? <dynamic>[];

      return mediaList
          .map((dynamic item) =>
              Anime.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch anime by IDs');
    }
  }

  /// Парсит Page response из AniList GraphQL (аниме).
  (List<Anime>, bool hasMore, int totalPages) _parseAnimePageResponse(
    Response<dynamic> response,
  ) {
    if (response.statusCode != 200 || response.data == null) {
      throw AniListApiException(
        'Unexpected response',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> data =
        response.data as Map<String, dynamic>;
    final Map<String, dynamic>? dataField =
        data['data'] as Map<String, dynamic>?;
    if (dataField == null) {
      _checkErrors(data);
      return (<Anime>[], false, 0);
    }

    final Map<String, dynamic>? pageData =
        dataField['Page'] as Map<String, dynamic>?;
    if (pageData == null) return (<Anime>[], false, 0);

    final Map<String, dynamic>? pageInfo =
        pageData['pageInfo'] as Map<String, dynamic>?;
    final bool hasMore = pageInfo?['hasNextPage'] as bool? ?? false;
    final int lastPage = pageInfo?['lastPage'] as int? ?? 1;

    final List<dynamic> mediaList =
        pageData['media'] as List<dynamic>? ?? <dynamic>[];

    final List<Anime> animes = mediaList
        .map((dynamic item) =>
            Anime.fromJson(item as Map<String, dynamic>))
        .toList();

    return (animes, hasMore, lastPage);
  }

  /// Парсит Page response из AniList GraphQL.
  (List<Manga>, bool hasMore, int totalPages) _parsePageResponse(
    Response<dynamic> response,
  ) {
    if (response.statusCode != 200 || response.data == null) {
      throw AniListApiException(
        'Unexpected response',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> data =
        response.data as Map<String, dynamic>;
    final Map<String, dynamic>? dataField =
        data['data'] as Map<String, dynamic>?;
    if (dataField == null) {
      _checkErrors(data);
      return (<Manga>[], false, 0);
    }

    final Map<String, dynamic>? pageData =
        dataField['Page'] as Map<String, dynamic>?;
    if (pageData == null) return (<Manga>[], false, 0);

    final Map<String, dynamic>? pageInfo =
        pageData['pageInfo'] as Map<String, dynamic>?;
    final bool hasMore = pageInfo?['hasNextPage'] as bool? ?? false;
    final int lastPage = pageInfo?['lastPage'] as int? ?? 1;

    final List<dynamic> mediaList =
        pageData['media'] as List<dynamic>? ?? <dynamic>[];

    final List<Manga> mangas = mediaList
        .map((dynamic item) =>
            Manga.fromJson(item as Map<String, dynamic>))
        .toList();

    return (mangas, hasMore, lastPage);
  }

  /// Проверяет GraphQL errors в ответе и логирует их.
  void _checkErrors(Map<String, dynamic> data) {
    final List<dynamic>? errors = data['errors'] as List<dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      final Map<String, dynamic> firstError =
          errors.first as Map<String, dynamic>;
      final String message =
          firstError['message'] as String? ?? 'Unknown GraphQL error';
      _log.warning('AniList GraphQL error: $message');
    }
  }

  /// Обрабатывает DioException и возвращает AniListApiException.
  AniListApiException _handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;

    if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return AniListApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'AniList',
        exception: e,
        userMessage: message,
      ),
    );
  }

  /// Закрывает HTTP клиент.
  void dispose() {
    _dio.close();
  }
}
