import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/kodi_application_info.dart';
import '../../shared/models/kodi_episode.dart';
import '../../shared/models/kodi_movie.dart';
import '../../shared/models/kodi_tv_show.dart';
import 'api_error_detail.dart';

/// Kodi JSON-RPC client. Talks HTTP to `http://{host}:{port}/jsonrpc` with
/// optional Basic Auth. Used for passive watch-sync: the local library is
/// polled and our collections updated to match.
/// Docs: https://kodi.wiki/view/JSON-RPC_API

/// Long-lived singleton. `KodiSettingsNotifier` calls [KodiApi.setConnection]
/// when settings load or change.
final Provider<KodiApi> kodiApiProvider = Provider<KodiApi>((Ref ref) {
  final KodiApi api = KodiApi();
  ref.onDispose(api.dispose);
  return api;
});

class KodiApiException implements Exception {
  const KodiApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'KodiApiException($statusCode): $message';
}

class KodiLogEntry {
  const KodiLogEntry({
    required this.timestamp,
    required this.method,
    required this.level,
    required this.message,
  });

  final DateTime timestamp;
  final String method;
  final String level;
  final String message;

  String get formatted {
    final String time =
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return '[$time] [$level] $method — $message';
  }
}

/// Minimal Kodi JSON-RPC client: ping, app properties, movie/show/episode
/// fetch + a [rawCall] escape hatch used by the Debug panel. Reconfigured at
/// runtime via [setConnection] / [clearConnection] — one instance lives for
/// the lifetime of the app.
class KodiApi {
  /// [timeout] applies to both connect and receive — tuned for LAN.
  KodiApi({Dio? dio, Duration? timeout})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: timeout ?? _defaultTimeout,
              receiveTimeout: timeout ?? _defaultTimeout,
            ));

  static final Logger _log = Logger('KodiApi');
  static const Duration _defaultTimeout = Duration(seconds: 5);

  final Dio _dio;

  String? _host;
  int? _port;
  String? _username;
  String? _password;
  int _nextId = 1;

  /// Ring-buffer of the last [_maxLogEntries] requests, surfaced in the
  /// Debug panel.
  final List<KodiLogEntry> requestLog = <KodiLogEntry>[];

  static const int _maxLogEntries = 50;

  /// Credentials are optional — Kodi can be configured to accept anonymous
  /// JSON-RPC, in which case omit them and we skip `Authorization`.
  void setConnection({
    required String host,
    required int port,
    String? username,
    String? password,
  }) {
    _host = host.trim();
    _port = port;
    _username = username;
    _password = password;
  }

  void clearConnection() {
    _host = null;
    _port = null;
    _username = null;
    _password = null;
  }

  bool get isConfigured =>
      _host != null &&
      _host!.isNotEmpty &&
      _port != null &&
      _port! > 0 &&
      _port! <= 65535;

  String? get baseUrl => isConfigured ? 'http://$_host:$_port/jsonrpc' : null;

  Future<bool> ping() async {
    final Map<String, dynamic> response = await rawCall('JSONRPC.Ping', null);
    return response['result'] == 'pong';
  }

  Future<KodiApplicationInfo> getApplicationProperties() async {
    final Map<String, dynamic> response = await rawCall(
      'Application.GetProperties',
      <String, dynamic>{
        'properties': <String>['version', 'name'],
      },
    );
    final Map<String, dynamic> result =
        (response['result'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return KodiApplicationInfo.fromJson(result);
  }

  /// Pagination is [start]/[end] (inclusive/exclusive). 200 is a safe batch;
  /// callers loop when the library is larger.
  Future<List<KodiMovie>> getMovies({int start = 0, int end = 200}) async {
    final Map<String, dynamic> response = await rawCall(
      'VideoLibrary.GetMovies',
      <String, dynamic>{
        'properties': <String>[
          'title',
          'year',
          'playcount',
          'lastplayed',
          'uniqueid',
          'userrating',
          'set',
          'dateadded',
          'rating',
        ],
        'limits': <String, int>{'start': start, 'end': end},
      },
    );
    return _parseList(response, 'movies', KodiMovie.fromJson);
  }

  Future<List<KodiTvShow>> getTvShows({int start = 0, int end = 200}) async {
    final Map<String, dynamic> response = await rawCall(
      'VideoLibrary.GetTVShows',
      <String, dynamic>{
        'properties': <String>[
          'title',
          'year',
          'playcount',
          'lastplayed',
          'uniqueid',
          'userrating',
        ],
        'limits': <String, int>{'start': start, 'end': end},
      },
    );
    return _parseList(response, 'tvshows', KodiTvShow.fromJson);
  }

  /// [tvShowId] is Kodi's internal `tvshowid`. When `null`, episodes from
  /// every show are returned — that can be huge, callers must page.
  Future<List<KodiEpisode>> getEpisodes({
    int? tvShowId,
    int start = 0,
    int end = 200,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'properties': <String>[
        'showtitle',
        'season',
        'episode',
        'playcount',
        'lastplayed',
        'uniqueid',
      ],
      'limits': <String, int>{'start': start, 'end': end},
    };
    if (tvShowId != null) {
      params['tvshowid'] = tvShowId;
    }
    final Map<String, dynamic> response =
        await rawCall('VideoLibrary.GetEpisodes', params);
    return _parseList(response, 'episodes', KodiEpisode.fromJson);
  }

  /// Returns the whole `{jsonrpc, id, result | error}` envelope. JSON-RPC
  /// `error` is translated into a [KodiApiException] so the Debug panel can
  /// show it; otherwise callers extract `result` themselves.
  Future<Map<String, dynamic>> rawCall(
    String method,
    Map<String, dynamic>? params,
  ) async {
    if (!isConfigured) {
      throw const KodiApiException('Kodi connection is not configured');
    }

    final int requestId = _nextId++;
    final Map<String, dynamic> body = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      'id': requestId,
    };
    if (params != null) {
      body['params'] = params;
    }

    final String url = baseUrl!;

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          headers: <String, String>{
            if (_hasCredentials)
              'Authorization':
                  'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
          },
          contentType: 'application/json',
        ),
      );

      if (response.statusCode != 200) {
        throw KodiApiException(
          'Unexpected HTTP status from Kodi',
          statusCode: response.statusCode,
        );
      }

      final Object? raw = response.data;
      if (raw is! Map<String, dynamic>) {
        // Most common cause: Kodi served the web UI HTML page because remote
        // control over HTTP is disabled in its settings.
        throw const KodiApiException(
          'Kodi returned non-JSON response — check "Allow remote control via HTTP"',
        );
      }

      if (raw.containsKey('error')) {
        final Map<String, dynamic>? error =
            raw['error'] as Map<String, dynamic>?;
        final String msg = (error?['message'] as String?) ?? 'JSON-RPC error';
        _addLog(method, 'error', msg);
        throw KodiApiException(
          msg,
          detail: 'Kodi error for $method: ${jsonEncode(error)}',
        );
      }

      _addLog(method, 'info', 'OK');
      return raw;
    } on DioException catch (e) {
      final int? statusCode = e.response?.statusCode;
      final String message = _messageForDioException(e, statusCode);
      _addLog(method, 'error', message);
      _log.warning('Kodi API error on $method: $message', e);
      throw KodiApiException(
        message,
        statusCode: statusCode,
        detail: buildApiErrorDetail(
          apiName: 'Kodi',
          exception: e,
          userMessage: message,
        ),
      );
    }
  }

  void _addLog(String method, String level, String message) {
    requestLog.add(KodiLogEntry(
      timestamp: DateTime.now(),
      method: method,
      level: level,
      message: message,
    ));
    if (requestLog.length > _maxLogEntries) {
      requestLog.removeAt(0);
    }
  }

  /// Lets the import/sync service attach its own progress lines to the same
  /// ring-buffer that the Debug panel reads.
  void addLog(String method, String level, String message) =>
      _addLog(method, level, message);

  void dispose() {
    _dio.close();
  }

  bool get _hasCredentials =>
      _username != null &&
      _username!.isNotEmpty &&
      _password != null &&
      _password!.isNotEmpty;

  String _messageForDioException(DioException e, int? statusCode) {
    if (statusCode == 401) {
      return 'Authentication failed — check Kodi username/password';
    }
    if (statusCode == 404) {
      return 'Kodi HTTP API is not available — enable "Allow remote control via HTTP" in Kodi settings';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Kodi did not respond in time ($_host:$_port)';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to Kodi at $_host:$_port — is it running?';
    }
    return e.message ?? 'Network error talking to Kodi';
  }

  List<T> _parseList<T>(
    Map<String, dynamic> response,
    String key,
    T Function(Map<String, dynamic>) parser,
  ) {
    final Map<String, dynamic>? result =
        response['result'] as Map<String, dynamic>?;
    if (result == null) return <T>[];
    final List<dynamic> items = (result[key] as List<dynamic>?) ?? <dynamic>[];
    return items
        .map((dynamic item) => parser(item as Map<String, dynamic>))
        .toList();
  }
}
