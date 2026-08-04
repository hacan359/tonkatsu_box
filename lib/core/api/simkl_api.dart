import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/constants/api_defaults.dart';
import 'simkl/simkl_http_client.dart';
import 'simkl/simkl_types.dart';

export 'simkl/simkl_types.dart';

/// Simkl facade backing the library import. Auth is the PIN flow — the one
/// OAuth variant needing no redirect URI, deep link, or client secret.
class SimklApi {
  SimklApi({String? clientId, Dio? dio})
      : _client = SimklHttpClient(
          clientId: clientId ?? ApiDefaults.simklClientId,
          dio: dio,
        );

  final SimklHttpClient _client;

  /// False when neither the build (`SIMKL_CLIENT_ID`) nor the user provided
  /// a client id — the PIN button stays disabled until one is entered.
  bool get hasClientId => _client.hasClientId;

  /// The client id currently in effect (user override or build-time default);
  /// prefills the key field on the import screen.
  String get clientId => _client.clientId;

  void setClientId(String clientId) => _client.setClientId(clientId);

  bool get hasAccessToken => _client.hasAccessToken;

  void setAccessToken(String token) => _client.setAccessToken(token);

  void clearAccessToken() => _client.clearAccessToken();

  /// Issues a fresh PIN (`GET /oauth/pin`).
  Future<SimklPin> requestPin() async {
    final Map<String, dynamic> json = await _client.get('oauth/pin');
    final SimklPin pin = SimklPin.fromJson(json);
    if (pin.userCode.isEmpty) {
      throw const SimklApiException('Simkl did not return a PIN code');
    }
    return pin;
  }

  /// One poll tick: the access token once the user confirmed the code, null
  /// while pending (Simkl answers `result: "KO"`, and 4xx on some edges).
  Future<String?> pollPin(String userCode) async {
    try {
      final Map<String, dynamic> json =
          await _client.get('oauth/pin/$userCode');
      final String? token = json['access_token'] as String?;
      return (token != null && token.isNotEmpty) ? token : null;
    } on SimklApiException catch (e) {
      final int? code = e.statusCode;
      if (code == 400 || code == 404) return null;
      rethrow;
    }
  }

  /// Account info for the connected token (`GET /users/settings`); shown on
  /// the import screen so the user can spot a wrong browser session.
  Future<SimklUser> getUserSettings({String? tokenOverride}) async {
    final Map<String, dynamic> json = await _client.get(
      'users/settings',
      authorized: true,
      tokenOverride: tokenOverride,
    );
    return SimklUser.fromJson(json);
  }

  /// The whole library in one request (`GET /sync/all-items`): sections
  /// `movies`, `shows`, `anime` with per-episode watch dates and memos.
  Future<SimklAllItems> getAllItems() async {
    final Map<String, dynamic> json = await _client.get(
      'sync/all-items/',
      queryParameters: <String, dynamic>{
        'extended': 'full',
        'episode_watched_at': 'yes',
        'memos': 'yes',
      },
      authorized: true,
    );
    return SimklAllItems.fromJson(json);
  }

  void dispose() => _client.dispose();
}

/// Simkl client with the build-time `SIMKL_CLIENT_ID`. The user token is set
/// by the import screen (and only persisted when the user opts in).
final Provider<SimklApi> simklApiProvider =
    Provider<SimklApi>((Ref ref) => SimklApi());
