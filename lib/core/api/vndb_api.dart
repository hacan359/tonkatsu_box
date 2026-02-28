// Клиент для работы с VNDB API.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/visual_novel.dart';

/// Провайдер для VNDB API клиента.
final Provider<VndbApi> vndbApiProvider = Provider<VndbApi>((Ref ref) {
  return VndbApi();
});

/// Исключение при ошибках VNDB API.
class VndbApiException implements Exception {
  /// Создаёт [VndbApiException].
  const VndbApiException(this.message, {this.statusCode});

  /// Сообщение об ошибке.
  final String message;

  /// HTTP код ответа (если есть).
  final int? statusCode;

  @override
  String toString() => 'VndbApiException: $message (status: $statusCode)';
}

/// Клиент для работы с VNDB API.
///
/// Использует публичный API без авторизации.
/// Документация: https://api.vndb.org/kana
class VndbApi {
  /// Создаёт экземпляр [VndbApi].
  VndbApi({Dio? dio}) : _dio = dio ?? Dio();

  static const String _baseUrl = 'https://api.vndb.org/kana';

  /// Стандартные поля для запросов VN.
  static const String _vnFields =
      'title, alttitle, description, image.url, rating, votecount, '
      'released, length_minutes, length, tags.name, tags.rating, '
      'developers.name, platforms';

  final Dio _dio;

  /// Ищет визуальные новеллы по названию.
  ///
  /// Возвращает кортеж (список новелл, есть ли ещё результаты).
  /// Throws [VndbApiException] при ошибке запроса.
  Future<(List<VisualNovel>, bool hasMore)> searchVn({
    required String query,
    int page = 1,
    int results = 20,
  }) async {
    if (query.trim().isEmpty) {
      return (<VisualNovel>[], false);
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/vn',
        data: <String, dynamic>{
          'filters': <dynamic>['search', '=', query],
          'fields': _vnFields,
          'sort': 'searchrank',
          'results': results,
          'page': page,
        },
      );

      return _parseVnResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search visual novels');
    }
  }

  /// Просматривает визуальные новеллы по фильтрам (без текстового поиска).
  ///
  /// [tagId] — ID тега VNDB (например "g7" для Sci-fi).
  /// [sort] — поле сортировки: 'rating', 'released', 'votecount'.
  /// [reverse] — обратный порядок (по умолчанию true = убывание).
  ///
  /// Возвращает кортеж (список новелл, есть ли ещё, количество страниц).
  /// Throws [VndbApiException] при ошибке запроса.
  Future<(List<VisualNovel>, bool hasMore, int totalPages)> browseVn({
    String? tagId,
    String sort = 'rating',
    bool reverse = true,
    int page = 1,
    int results = 20,
  }) async {
    try {
      // Собираем фильтры
      final List<dynamic> filters = <dynamic>[];

      if (tagId != null) {
        filters.add(<dynamic>['tag', '=', tagId]);
      }

      // Минимум голосов для качественных результатов
      filters.add(<dynamic>['votecount', '>=', 10]);

      // Формируем итоговый фильтр
      final dynamic finalFilter = filters.length == 1
          ? filters.first
          : <dynamic>['and', ...filters];

      final Map<String, dynamic> body = <String, dynamic>{
        'filters': finalFilter,
        'fields': _vnFields,
        'sort': sort,
        'reverse': reverse,
        'results': results,
        'page': page,
        'count': true,
      };

      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/vn',
        data: body,
      );

      if (response.statusCode != 200 || response.data == null) {
        throw VndbApiException(
          'Failed to browse visual novels',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> resultsList =
          data['results'] as List<dynamic>? ?? <dynamic>[];
      final bool hasMore = data['more'] as bool? ?? false;
      final int count = data['count'] as int? ?? 0;
      final int totalPages = results > 0 ? (count / results).ceil() : 1;

      final List<VisualNovel> novels = resultsList
          .map((dynamic item) =>
              VisualNovel.fromJson(item as Map<String, dynamic>))
          .toList();

      return (novels, hasMore, totalPages);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to browse visual novels');
    }
  }

  /// Получает визуальную новеллу по ID.
  ///
  /// [id] — ID в формате "v2".
  /// Возвращает новеллу или null, если не найдена.
  /// Throws [VndbApiException] при ошибке запроса.
  Future<VisualNovel?> getVnById(String id) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/vn',
        data: <String, dynamic>{
          'filters': <dynamic>['id', '=', id],
          'fields': _vnFields,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw VndbApiException(
          'Failed to fetch visual novel',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results =
          data['results'] as List<dynamic>? ?? <dynamic>[];

      if (results.isEmpty) return null;

      return VisualNovel.fromJson(results.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch visual novel');
    }
  }

  /// Получает несколько визуальных новелл по списку ID.
  ///
  /// [ids] — список ID в формате "v2", "v17", и т.д.
  /// Throws [VndbApiException] при ошибке запроса.
  Future<List<VisualNovel>> getVnByIds(List<String> ids) async {
    if (ids.isEmpty) return <VisualNovel>[];

    try {
      // VNDB поддерживает ["or", ...ids] для множественного поиска
      final List<dynamic> idFilters = <dynamic>[
        'or',
        ...ids.map((String id) => <dynamic>['id', '=', id]),
      ];

      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/vn',
        data: <String, dynamic>{
          'filters': idFilters,
          'fields': _vnFields,
          'results': ids.length,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw VndbApiException(
          'Failed to fetch visual novels by IDs',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results =
          data['results'] as List<dynamic>? ?? <dynamic>[];

      return results
          .map((dynamic item) =>
              VisualNovel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch visual novels by IDs');
    }
  }

  /// Загружает теги (жанры) из VNDB.
  ///
  /// Загружает только теги категории "cont" (Content) — это жанры.
  /// Сортирует по количеству VN (vn_count desc).
  /// Throws [VndbApiException] при ошибке запроса.
  Future<List<VndbTag>> fetchTags() async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/tag',
        data: <String, dynamic>{
          'filters': <dynamic>['category', '=', 'cont'],
          'fields': 'name',
          'results': 100,
          'sort': 'vn_count',
          'reverse': true,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw VndbApiException(
          'Failed to fetch tags',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results =
          data['results'] as List<dynamic>? ?? <dynamic>[];

      return results
          .map((dynamic item) =>
              VndbTag.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch tags');
    }
  }

  /// Парсит ответ VNDB API с VN.
  (List<VisualNovel>, bool hasMore) _parseVnResponse(
    Response<dynamic> response,
  ) {
    if (response.statusCode != 200 || response.data == null) {
      throw VndbApiException(
        'Unexpected response',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> data =
        response.data as Map<String, dynamic>;
    final List<dynamic> results =
        data['results'] as List<dynamic>? ?? <dynamic>[];
    final bool hasMore = data['more'] as bool? ?? false;

    final List<VisualNovel> novels = results
        .map((dynamic item) =>
            VisualNovel.fromJson(item as Map<String, dynamic>))
        .toList();

    return (novels, hasMore);
  }

  /// Обрабатывает DioException и возвращает VndbApiException.
  VndbApiException _handleDioException(
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

    return VndbApiException(message, statusCode: statusCode);
  }

  /// Закрывает HTTP клиент.
  void dispose() {
    _dio.close();
  }
}
