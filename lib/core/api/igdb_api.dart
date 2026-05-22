import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_key_initializer.dart';
import '../../shared/models/game.dart';
import '../../shared/models/platform.dart';
import 'igdb/igdb_games_api.dart';
import 'igdb/igdb_genres_api.dart';
import 'igdb/igdb_http_client.dart';
import 'igdb/igdb_platforms_api.dart';
import 'igdb/igdb_types.dart';

export 'igdb/igdb_types.dart';

// Credentials seeded from apiKeysProvider loaded in main() before runApp().
final Provider<IgdbApi> igdbApiProvider = Provider<IgdbApi>((Ref ref) {
  final IgdbApi api = IgdbApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  if (keys.igdbClientId != null && keys.igdbAccessToken != null) {
    api.setCredentials(
      clientId: keys.igdbClientId!,
      accessToken: keys.igdbAccessToken!,
      clientSecret: keys.igdbClientSecret,
    );
  }
  return api;
});

/// IGDB v4 facade. See `igdb/` for layer breakdown:
/// `igdb_http_client` (transport+auth), `igdb_games_api`, `igdb_platforms_api`,
/// `igdb_genres_api`, `igdb_types` (DTOs).
class IgdbApi {
  IgdbApi({Dio? dio}) : _client = IgdbHttpClient(dio: dio) {
    _games = IgdbGamesApi(_client);
    _platforms = IgdbPlatformsApi(_client);
    _genres = IgdbGenresApi(_client);
  }

  final IgdbHttpClient _client;
  late final IgdbGamesApi _games;
  late final IgdbPlatformsApi _platforms;
  late final IgdbGenresApi _genres;

  static const int maxMultiQueryBatch = IgdbGamesApi.maxMultiQueryBatch;

  IgdbTokenRefreshedCallback? get onTokenRefreshed => _client.onTokenRefreshed;
  set onTokenRefreshed(IgdbTokenRefreshedCallback? cb) {
    _client.onTokenRefreshed = cb;
  }

  void setCredentials({
    required String clientId,
    required String accessToken,
    String? clientSecret,
  }) =>
      _client.setCredentials(
        clientId: clientId,
        accessToken: accessToken,
        clientSecret: clientSecret,
      );

  void clearCredentials() => _client.clearCredentials();

  Future<TwitchAuthResult> getAccessToken({
    required String clientId,
    required String clientSecret,
  }) =>
      _client.getAccessToken(
        clientId: clientId,
        clientSecret: clientSecret,
      );

  Future<bool> validateCredentials({
    required String clientId,
    required String clientSecret,
  }) =>
      _client.validateCredentials(
        clientId: clientId,
        clientSecret: clientSecret,
      );

  Future<List<Platform>> fetchPlatforms() => _platforms.fetchPlatforms();

  Future<List<Platform>> fetchPlatformsByIds(List<int> ids) =>
      _platforms.fetchPlatformsByIds(ids);

  Future<List<Game>> searchGames({
    required String query,
    List<int>? genreIds,
    List<int>? platformIds,
    List<int>? gameModeIds,
    int? minRating,
    int? year,
    (int, int)? decade,
    int limit = 20,
    int offset = 0,
  }) =>
      _games.searchGames(
        query: query,
        genreIds: genreIds,
        platformIds: platformIds,
        gameModeIds: gameModeIds,
        minRating: minRating,
        year: year,
        decade: decade,
        limit: limit,
        offset: offset,
      );

  Future<Map<int, List<Game>>> multiSearchGamesByName(
    List<({String name, int? platformId})> queries,
  ) =>
      _games.multiSearchGamesByName(queries);

  Future<Map<String, Game>> lookupSteamGames(List<String> steamAppIds) =>
      _games.lookupSteamGames(steamAppIds);

  Future<Game?> getGameById(int gameId) => _games.getGameById(gameId);

  Future<List<Game>> getGamesByIds(List<int> gameIds) =>
      _games.getGamesByIds(gameIds);

  Future<List<Game>> getTopGamesByPlatform({
    required int platformId,
    int minRatingCount = 20,
    int limit = 50,
  }) =>
      _games.getTopGamesByPlatform(
        platformId: platformId,
        minRatingCount: minRatingCount,
        limit: limit,
      );

  Future<List<Game>> browseGames({
    List<int>? genreIds,
    List<int>? platformIds,
    List<int>? gameModeIds,
    int? minRating,
    int? year,
    (int, int)? decade,
    String sortBy = 'rating desc',
    int limit = 20,
    int offset = 0,
    int minRatingCount = 10,
  }) =>
      _games.browseGames(
        genreIds: genreIds,
        platformIds: platformIds,
        gameModeIds: gameModeIds,
        minRating: minRating,
        year: year,
        decade: decade,
        sortBy: sortBy,
        limit: limit,
        offset: offset,
        minRatingCount: minRatingCount,
      );

  Future<List<Map<String, dynamic>>> fetchGenres() => _genres.fetchGenres();

  void dispose() => _client.dispose();
}
