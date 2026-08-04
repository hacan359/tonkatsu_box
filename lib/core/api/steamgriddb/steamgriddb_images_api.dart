import 'package:core/models/steamgriddb_image.dart';
import 'package:dio/dio.dart';

import 'steamgriddb_http_client.dart';
import 'steamgriddb_types.dart';

/// Per-game artwork: grids, heroes, logos, icons.
class SteamGridDbImagesApi {
  SteamGridDbImagesApi(this._client);

  final SteamGridDbHttpClient _client;

  Future<List<SteamGridDbImage>> getGrids(int gameId) =>
      _fetchImages('grids/game', gameId);

  Future<List<SteamGridDbImage>> getHeroes(int gameId) =>
      _fetchImages('heroes/game', gameId);

  Future<List<SteamGridDbImage>> getLogos(int gameId) =>
      _fetchImages('logos/game', gameId);

  Future<List<SteamGridDbImage>> getIcons(int gameId) =>
      _fetchImages('icons/game', gameId);

  Future<List<SteamGridDbImage>> _fetchImages(
    String endpoint,
    int gameId,
  ) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response =
          await _client.get('/$endpoint/$gameId');

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
      throw _client.handleDioException(e, 'Failed to fetch images');
    }
  }
}
