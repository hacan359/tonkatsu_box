import 'package:core/models/ra_game_progress.dart';
import 'package:core/models/ra_user_profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_key_initializer.dart';
import 'ra/ra_games_api.dart';
import 'ra/ra_http_client.dart';
import 'ra/ra_types.dart';
import 'ra/ra_user_api.dart';
export 'ra/ra_types.dart';

final Provider<RaApi> raApiProvider = Provider<RaApi>((Ref ref) {
  final RaApi api = RaApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  if (keys.raUsername != null && keys.raApiKey != null) {
    api.setCredentials(username: keys.raUsername!, apiKey: keys.raApiKey!);
  }
  return api;
});

/// RetroAchievements facade. See `ra/README.md` for the layer breakdown.
class RaApi {
  RaApi({Dio? dio}) : _client = RaHttpClient(dio: dio) {
    _user = RaUserApi(_client);
    _games = RaGamesApi(_client);
  }

  final RaHttpClient _client;
  late final RaUserApi _user;
  late final RaGamesApi _games;

  String? get username => _client.username;

  bool get hasCredentials => _client.hasCredentials;

  void setCredentials({required String username, required String apiKey}) =>
      _client.setCredentials(username: username, apiKey: apiKey);

  Future<bool> validateCredentials(String username, String apiKey) =>
      _client.validateCredentials(username, apiKey);

  Future<RaUserProfile> getUserProfile(String targetUser) =>
      _user.getUserProfile(targetUser);

  Future<List<RaGameProgress>> getCompletedGames(String targetUser) =>
      _user.getCompletedGames(targetUser);

  Future<Map<int, DateTime>> getUserAwardDates(String targetUser) =>
      _user.getUserAwardDates(targetUser);

  Future<Map<String, dynamic>> getGameSummary(
    String targetUser,
    int raGameId,
  ) =>
      _games.getGameSummary(targetUser, raGameId);

  Future<Map<String, dynamic>> getGameInfoAndUserProgress(
    String targetUser,
    int raGameId,
  ) =>
      _games.getGameInfoAndUserProgress(targetUser, raGameId);

  Future<List<RaGameListEntry>> getGameList(int consoleId) =>
      _games.getGameList(consoleId);

  void dispose() => _client.dispose();
}
