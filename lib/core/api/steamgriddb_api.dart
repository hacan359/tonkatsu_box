import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/steamgriddb_game.dart';
import '../../shared/models/steamgriddb_image.dart';
import '../services/api_key_initializer.dart';
import 'api_error_detail.dart';

final Provider<SteamGridDbApi> steamGridDbApiProvider =
    Provider<SteamGridDbApi>((Ref ref) {
  final SteamGridDbApi api = SteamGridDbApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  if (keys.steamGridDbApiKey != null && keys.steamGridDbApiKey!.isNotEmpty) {
    api.setApiKey(keys.steamGridDbApiKey!);
  }
  return api;
});

class SteamGridDbApiException implements Exception {
  const SteamGridDbApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() =>
      'SteamGridDbApiException: $message (status: $statusCode)';
}

/// SteamGridDB API v2 client. Uses a Bearer token.
/// Docs: https://www.steamgriddb.com/api/v2
class SteamGridDbApi {
  SteamGridDbApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            ));

  // ignore: unused_field
  static final Logger _log = Logger('SteamGridDbApi');

  static const Duration _timeout = Duration(seconds: 5);
  static const String _baseUrl = 'https://www.steamgriddb.com/api/v2';

  final Dio _dio;

  String? _apiKey;

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void clearApiKey() {
    _apiKey = null;
  }

  Future<bool> validateApiKey(String apiKey) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/autocomplete/test',
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<List<SteamGridDbGame>> searchGames(String term) async {
    _ensureApiKey();

    if (term.trim().isEmpty) {
      return <SteamGridDbGame>[];
    }

    try {
      final String encodedTerm = Uri.encodeComponent(term.trim());
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/autocomplete/$encodedTerm',
        options: _authOptions(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw SteamGridDbApiException(
          'Failed to search games',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> body =
          response.data as Map<String, dynamic>;
      final List<dynamic> data = body['data'] as List<dynamic>;

      return data
          .map((dynamic item) =>
              SteamGridDbGame.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search games');
    }
  }

  Future<List<SteamGridDbImage>> getGrids(int gameId) async {
    return _fetchImages('grids/game', gameId);
  }

  Future<List<SteamGridDbImage>> getHeroes(int gameId) async {
    return _fetchImages('heroes/game', gameId);
  }

  Future<List<SteamGridDbImage>> getLogos(int gameId) async {
    return _fetchImages('logos/game', gameId);
  }

  Future<List<SteamGridDbImage>> getIcons(int gameId) async {
    return _fetchImages('icons/game', gameId);
  }

  Future<List<SteamGridDbImage>> _fetchImages(
    String endpoint,
    int gameId,
  ) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/$endpoint/$gameId',
        options: _authOptions(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw SteamGridDbApiException(
          'Failed to fetch images',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> body =
          response.data as Map<String, dynamic>;
      final List<dynamic> data = body['data'] as List<dynamic>;

      return data
          .map((dynamic item) =>
              SteamGridDbImage.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch images');
    }
  }

  Options _authOptions() {
    return Options(
      headers: <String, dynamic>{
        'Authorization': 'Bearer $_apiKey',
      },
    );
  }

  SteamGridDbApiException _handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;

    if (statusCode == 401) {
      message = 'Invalid or expired API key';
    } else if (statusCode == 404) {
      message = 'Game not found';
    } else if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return SteamGridDbApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'SteamGridDB',
        exception: e,
        userMessage: message,
      ),
    );
  }

  void _ensureApiKey() {
    if (_apiKey == null) {
      throw const SteamGridDbApiException('API key not set');
    }
  }

  void dispose() {
    _dio.close();
  }
}
