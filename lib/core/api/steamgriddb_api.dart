import 'package:core/models/steamgriddb_game.dart';
import 'package:core/models/steamgriddb_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_key_initializer.dart';
import 'steamgriddb/steamgriddb_games_api.dart';
import 'steamgriddb/steamgriddb_http_client.dart';
import 'steamgriddb/steamgriddb_images_api.dart';
export 'steamgriddb/steamgriddb_types.dart';

final Provider<SteamGridDbApi> steamGridDbApiProvider =
    Provider<SteamGridDbApi>((Ref ref) {
  final SteamGridDbApi api = SteamGridDbApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  if (keys.steamGridDbApiKey != null && keys.steamGridDbApiKey!.isNotEmpty) {
    api.setApiKey(keys.steamGridDbApiKey!);
  }
  return api;
});

/// SteamGridDB API v2 facade. See `steamgriddb/README.md` for the layer
/// breakdown.
class SteamGridDbApi {
  SteamGridDbApi({Dio? dio}) : _client = SteamGridDbHttpClient(dio: dio) {
    _games = SteamGridDbGamesApi(_client);
    _images = SteamGridDbImagesApi(_client);
  }

  final SteamGridDbHttpClient _client;
  late final SteamGridDbGamesApi _games;
  late final SteamGridDbImagesApi _images;

  void setApiKey(String apiKey) => _client.setApiKey(apiKey);

  void clearApiKey() => _client.clearApiKey();

  Future<bool> validateApiKey(String apiKey) => _client.validateApiKey(apiKey);

  Future<List<SteamGridDbGame>> searchGames(String term) =>
      _games.searchGames(term);

  Future<List<SteamGridDbImage>> getGrids(int gameId) =>
      _images.getGrids(gameId);

  Future<List<SteamGridDbImage>> getHeroes(int gameId) =>
      _images.getHeroes(gameId);

  Future<List<SteamGridDbImage>> getLogos(int gameId) =>
      _images.getLogos(gameId);

  Future<List<SteamGridDbImage>> getIcons(int gameId) =>
      _images.getIcons(gameId);

  void dispose() => _client.dispose();
}
