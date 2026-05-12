// Клиент для работы с AniList GraphQL API.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'api_error_detail.dart';
import '../../shared/models/anime.dart';
import '../../shared/models/manga.dart';
import '../../shared/models/media_type.dart';

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

/// AniList user does not exist or has no public lists.
class AniListUserNotFoundException extends AniListApiException {
  /// Creates an [AniListUserNotFoundException].
  const AniListUserNotFoundException(String username)
      : super('AniList user "$username" not found', statusCode: 404);
}

/// AniList profile is private — public list endpoints will not return data.
class AniListPrivateProfileException extends AniListApiException {
  /// Creates an [AniListPrivateProfileException].
  const AniListPrivateProfileException(String username)
      : super(
          'AniList user "$username" has a private profile',
          statusCode: 403,
        );
}

/// Entry from a user's anime or manga list on AniList.
class AniListListEntry {
  /// Creates an [AniListListEntry].
  const AniListListEntry({
    required this.mediaId,
    required this.mediaType,
    required this.rawStatus,
    required this.progress,
    required this.progressVolumes,
    required this.repeat,
    this.scoreRaw100,
    this.notes,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
    this.anime,
    this.manga,
  });

  /// AniList media ID.
  final int mediaId;

  /// Either [MediaType.anime] or [MediaType.manga].
  final MediaType mediaType;

  /// Raw AniList status: CURRENT / PLANNING / COMPLETED / DROPPED / PAUSED / REPEATING.
  final String rawStatus;

  /// Episodes watched (anime) or chapters read (manga).
  final int progress;

  /// Volumes read. Always 0 for anime.
  final int progressVolumes;

  /// Rewatch / reread count.
  final int repeat;

  /// Score on the 0..100 scale, or null if unset.
  final int? scoreRaw100;

  /// User notes attached to the entry.
  final String? notes;

  /// Start date (year/month/day from AniList fuzzy date).
  final DateTime? startedAt;

  /// Completion date.
  final DateTime? completedAt;

  /// Last time the entry was updated on AniList.
  final DateTime? updatedAt;

  /// Populated when [mediaType] is [MediaType.anime].
  final Anime? anime;

  /// Populated when [mediaType] is [MediaType.manga].
  final Manga? manga;
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
      coverImage { extraLarge large medium }
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
    coverImage { extraLarge large medium }
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
      coverImage { extraLarge large medium }
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
       $startDateGreater: FuzzyDateInt, $startDateLesser: FuzzyDateInt,
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
          startDate_greater: $startDateGreater,
          startDate_lesser: $startDateLesser,
          sort: $sort) {
      id
      title { romaji english native }
      coverImage { extraLarge large medium }
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
    coverImage { extraLarge large medium }
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

  /// GraphQL query для получения аниме по списку MAL ID.
  static const String _animeGetByMalIdsQuery = r'''
query ($page: Int, $perPage: Int, $malIds: [Int]) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, idMal_in: $malIds) {
      id
      idMal
      title { romaji english native }
      coverImage { extraLarge large medium }
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

  /// GraphQL query для получения манги по списку MAL ID.
  static const String _mangaGetByMalIdsQuery = r'''
query ($page: Int, $perPage: Int, $malIds: [Int]) {
  Page(page: $page, perPage: $perPage) {
    media(type: MANGA, idMal_in: $malIds) {
      id
      idMal
      title { romaji english native }
      coverImage { extraLarge large medium }
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

  /// GraphQL query для получения нескольких аниме по ID.
  static const String _animeGetByIdsQuery = r'''
query ($page: Int, $perPage: Int, $ids: [Int]) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, id_in: $ids) {
      id
      title { romaji english native }
      coverImage { extraLarge large medium }
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
  /// [startYear] / [endYear] — диапазон года выпуска (startDate). Надёжный
  ///   способ фильтровать «по году», работает для всех аниме.
  /// [sort] — сортировка: SCORE_DESC, POPULARITY_DESC, TRENDING_DESC и др.
  ///
  /// Возвращает кортеж (список, есть ли ещё, кол-во страниц).
  /// Throws [AniListApiException] при ошибке.
  Future<(List<Anime>, bool hasMore, int totalPages)> browseAnime({
    String? query,
    List<String>? genres,
    String? status,
    String? format,
    int? startYear,
    int? endYear,
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

  /// Получает аниме по списку MAL ID.
  ///
  /// Возвращает карту `malId → Anime`. ID, не найденные на AniList,
  /// в карте отсутствуют. Throws [AniListApiException] при ошибке.
  Future<Map<int, Anime>> getAnimeByMalIds(List<int> malIds) async {
    if (malIds.isEmpty) return <int, Anime>{};

    final Map<int, Anime> result = <int, Anime>{};

    for (int i = 0; i < malIds.length; i += _maxPerPage) {
      final List<int> batch = malIds.sublist(
        i,
        i + _maxPerPage > malIds.length ? malIds.length : i + _maxPerPage,
      );
      final Map<int, Anime> batchResult = await _fetchAnimeByMalBatch(batch);
      result.addAll(batchResult);
    }

    return result;
  }

  /// Получает мангу по списку MAL ID.
  ///
  /// Возвращает карту `malId → Manga`. ID, не найденные на AniList,
  /// в карте отсутствуют. Throws [AniListApiException] при ошибке.
  Future<Map<int, Manga>> getMangaByMalIds(List<int> malIds) async {
    if (malIds.isEmpty) return <int, Manga>{};

    final Map<int, Manga> result = <int, Manga>{};

    for (int i = 0; i < malIds.length; i += _maxPerPage) {
      final List<int> batch = malIds.sublist(
        i,
        i + _maxPerPage > malIds.length ? malIds.length : i + _maxPerPage,
      );
      final Map<int, Manga> batchResult = await _fetchMangaByMalBatch(batch);
      result.addAll(batchResult);
    }

    return result;
  }

  Future<Map<int, Anime>> _fetchAnimeByMalBatch(List<int> malIds) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _baseUrl,
        data: <String, dynamic>{
          'query': _animeGetByMalIdsQuery,
          'variables': <String, dynamic>{
            'page': 1,
            'perPage': malIds.length,
            'malIds': malIds,
          },
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw AniListApiException(
          'Failed to fetch anime by MAL IDs',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final Map<String, dynamic>? dataField =
          data['data'] as Map<String, dynamic>?;
      if (dataField == null) {
        _checkErrors(data);
        return <int, Anime>{};
      }

      final Map<String, dynamic>? pageData =
          dataField['Page'] as Map<String, dynamic>?;
      if (pageData == null) return <int, Anime>{};

      final List<dynamic> mediaList =
          pageData['media'] as List<dynamic>? ?? <dynamic>[];

      final Map<int, Anime> map = <int, Anime>{};
      for (final dynamic item in mediaList) {
        final Map<String, dynamic> json = item as Map<String, dynamic>;
        final int? malId = json['idMal'] as int?;
        if (malId == null) continue;
        map[malId] = Anime.fromJson(json);
      }
      return map;
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch anime by MAL IDs');
    }
  }

  Future<Map<int, Manga>> _fetchMangaByMalBatch(List<int> malIds) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _baseUrl,
        data: <String, dynamic>{
          'query': _mangaGetByMalIdsQuery,
          'variables': <String, dynamic>{
            'page': 1,
            'perPage': malIds.length,
            'malIds': malIds,
          },
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw AniListApiException(
          'Failed to fetch manga by MAL IDs',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final Map<String, dynamic>? dataField =
          data['data'] as Map<String, dynamic>?;
      if (dataField == null) {
        _checkErrors(data);
        return <int, Manga>{};
      }

      final Map<String, dynamic>? pageData =
          dataField['Page'] as Map<String, dynamic>?;
      if (pageData == null) return <int, Manga>{};

      final List<dynamic> mediaList =
          pageData['media'] as List<dynamic>? ?? <dynamic>[];

      final Map<int, Manga> map = <int, Manga>{};
      for (final dynamic item in mediaList) {
        final Map<String, dynamic> json = item as Map<String, dynamic>;
        final int? malId = json['idMal'] as int?;
        if (malId == null) continue;
        map[malId] = Manga.fromJson(json);
      }
      return map;
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch manga by MAL IDs');
    }
  }

  /// MediaListCollection returns every list (Watching, Completed, etc.) for a
  /// user in a single response — there is no pagination at this level.
  static const String _userAnimeListQuery = r'''
query ($userName: String) {
  MediaListCollection(userName: $userName, type: ANIME) {
    lists {
      isCustomList
      entries {
        status
        score(format: POINT_100)
        progress
        progressVolumes
        repeat
        notes
        startedAt { year month day }
        completedAt { year month day }
        updatedAt
        media {
          id
          isAdult
          title { romaji english native }
          coverImage { extraLarge large medium }
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
  }
}
''';

  static const String _userMangaListQuery = r'''
query ($userName: String) {
  MediaListCollection(userName: $userName, type: MANGA) {
    lists {
      isCustomList
      entries {
        status
        score(format: POINT_100)
        progress
        progressVolumes
        repeat
        notes
        startedAt { year month day }
        completedAt { year month day }
        updatedAt
        media {
          id
          isAdult
          title { romaji english native }
          coverImage { extraLarge large medium }
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
  }
}
''';

  /// Fetches the public anime or manga list of an AniList user.
  ///
  /// Custom lists are skipped because their entries are duplicates of the
  /// canonical-list entries with identical status/progress/score. `isAdult`
  /// media is filtered out.
  ///
  /// Throws [AniListUserNotFoundException] when the user does not exist,
  /// [AniListPrivateProfileException] when the profile is private,
  /// [AniListApiException] otherwise. Only [MediaType.anime] and
  /// [MediaType.manga] are accepted; other types raise [ArgumentError].
  Future<List<AniListListEntry>> fetchUserMediaList({
    required String userName,
    required MediaType type,
  }) async {
    if (type != MediaType.anime && type != MediaType.manga) {
      throw ArgumentError.value(type, 'type', 'Only anime/manga supported');
    }

    final String trimmed = userName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(userName, 'userName', 'must not be empty');
    }

    final String query = type == MediaType.anime
        ? _userAnimeListQuery
        : _userMangaListQuery;

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _baseUrl,
        data: <String, dynamic>{
          'query': query,
          'variables': <String, dynamic>{'userName': trimmed},
        },
      );

      if (response.statusCode == 404) {
        throw AniListUserNotFoundException(trimmed);
      }
      if (response.statusCode != 200 || response.data == null) {
        throw AniListApiException(
          'Failed to fetch user media list',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;

      // AniList returns GraphQL errors with HTTP 200; check the body before data.
      final List<dynamic>? errors = data['errors'] as List<dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final Map<String, dynamic> firstError =
            errors.first as Map<String, dynamic>;
        final String message =
            (firstError['message'] as String? ?? '').toLowerCase();
        if (message.contains('not found') || message.contains('does not exist')) {
          throw AniListUserNotFoundException(trimmed);
        }
        if (message.contains('private')) {
          throw AniListPrivateProfileException(trimmed);
        }
        _log.warning('AniList GraphQL error: ${firstError['message']}');
        throw AniListApiException(
          firstError['message'] as String? ?? 'GraphQL error',
        );
      }

      final Map<String, dynamic>? dataField =
          data['data'] as Map<String, dynamic>?;
      final Map<String, dynamic>? collection =
          dataField?['MediaListCollection'] as Map<String, dynamic>?;
      if (collection == null) {
        return <AniListListEntry>[];
      }

      final List<dynamic> lists =
          collection['lists'] as List<dynamic>? ?? <dynamic>[];

      final Map<int, AniListListEntry> dedup = <int, AniListListEntry>{};

      for (final dynamic listRaw in lists) {
        final Map<String, dynamic> list = listRaw as Map<String, dynamic>;
        // Кастомные списки дублируют записи из основных — пропускаем.
        if (list['isCustomList'] as bool? ?? false) continue;

        final List<dynamic> entries =
            list['entries'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic entryRaw in entries) {
          final AniListListEntry? entry = _parseListEntry(
            entryRaw as Map<String, dynamic>,
            type,
          );
          if (entry != null) {
            dedup[entry.mediaId] = entry;
          }
        }
      }

      return dedup.values.toList();
    } on DioException catch (e) {
      // AniList returns HTTP 404 when the username does not exist.
      if (e.response?.statusCode == 404) {
        throw AniListUserNotFoundException(trimmed);
      }
      throw _handleDioException(e, 'Failed to fetch user media list');
    }
  }

  AniListListEntry? _parseListEntry(
    Map<String, dynamic> json,
    MediaType type,
  ) {
    final Map<String, dynamic>? media =
        json['media'] as Map<String, dynamic>?;
    if (media == null) return null;

    // Hentai / adult content is excluded from imports.
    if (media['isAdult'] as bool? ?? false) return null;

    final int? mediaId = media['id'] as int?;
    if (mediaId == null) return null;

    final String status = (json['status'] as String? ?? '').trim();

    final int scoreRaw = (json['score'] as num?)?.toInt() ?? 0;
    final int? scoreRaw100 = scoreRaw > 0 ? scoreRaw : null;

    final int progress = (json['progress'] as num?)?.toInt() ?? 0;
    final int progressVolumes =
        (json['progressVolumes'] as num?)?.toInt() ?? 0;
    final int repeat = (json['repeat'] as num?)?.toInt() ?? 0;

    final String? notesRaw = (json['notes'] as String?)?.trim();
    final String? notes =
        (notesRaw == null || notesRaw.isEmpty) ? null : notesRaw;

    final DateTime? startedAt =
        _parseFuzzyDate(json['startedAt'] as Map<String, dynamic>?);
    final DateTime? completedAt =
        _parseFuzzyDate(json['completedAt'] as Map<String, dynamic>?);

    final int? updatedAtUnix = (json['updatedAt'] as num?)?.toInt();
    final DateTime? updatedAt = (updatedAtUnix != null && updatedAtUnix > 0)
        ? DateTime.fromMillisecondsSinceEpoch(
            updatedAtUnix * 1000,
            isUtc: true,
          )
        : null;

    final Anime? anime =
        type == MediaType.anime ? Anime.fromJson(media) : null;
    final Manga? manga =
        type == MediaType.manga ? Manga.fromJson(media) : null;

    return AniListListEntry(
      mediaId: mediaId,
      mediaType: type,
      rawStatus: status,
      progress: progress,
      progressVolumes: progressVolumes,
      repeat: repeat,
      scoreRaw100: scoreRaw100,
      notes: notes,
      startedAt: startedAt,
      completedAt: completedAt,
      updatedAt: updatedAt,
      anime: anime,
      manga: manga,
    );
  }

  static DateTime? _parseFuzzyDate(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final int? year = raw['year'] as int?;
    if (year == null) return null;
    final int month = raw['month'] as int? ?? 1;
    final int day = raw['day'] as int? ?? 1;
    try {
      return DateTime.utc(year, month, day);
    } on ArgumentError {
      return null;
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
