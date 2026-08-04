import 'package:core/models/steamgriddb_game.dart';
import 'package:dio/dio.dart';

import 'steamgriddb_http_client.dart';
import 'steamgriddb_types.dart';

/// Game search (`/search/autocomplete`).
class SteamGridDbGamesApi {
  SteamGridDbGamesApi(this._client);

  final SteamGridDbHttpClient _client;

  Future<List<SteamGridDbGame>> searchGames(String term) async {
    _client.ensureApiKey();

    if (term.trim().isEmpty) {
      return <SteamGridDbGame>[];
    }

    try {
      final String encodedTerm = Uri.encodeComponent(term.trim());
      final Response<dynamic> response =
          await _client.get('/search/autocomplete/$encodedTerm');

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
      throw _client.handleDioException(e, 'Failed to search games');
    }
  }
}
