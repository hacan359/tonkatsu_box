// Kodi JSON-RPC API клиент.
//
// Общается с Kodi по HTTP (`http://{host}:{port}/jsonrpc`) с Basic Auth.
// Используется для passive watch-sync: периодически читаем библиотеку
// Kodi и обновляем локальные коллекции. См. dev/backlog/integrations/kodi.md.
//
// Документация: https://kodi.wiki/view/JSON-RPC_API

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'api_error_detail.dart';
import '../../shared/models/kodi_application_info.dart';
import '../../shared/models/kodi_episode.dart';
import '../../shared/models/kodi_movie.dart';
import '../../shared/models/kodi_tv_show.dart';

/// Провайдер клиента Kodi JSON-RPC.
///
/// Инстанс долго-живущий; `KodiSettingsNotifier` вызывает
/// [KodiApi.setConnection] при загрузке/изменении настроек.
final Provider<KodiApi> kodiApiProvider = Provider<KodiApi>((Ref ref) {
  final KodiApi api = KodiApi();
  ref.onDispose(api.dispose);
  return api;
});

/// Ошибка Kodi JSON-RPC клиента.
class KodiApiException implements Exception {
  /// Создаёт [KodiApiException].
  const KodiApiException(this.message, {this.statusCode, this.detail});

  /// Человеко-читаемое сообщение для отображения пользователю.
  final String message;

  /// HTTP статус, если доступен.
  final int? statusCode;

  /// Подробная отладочная информация (URL, метод, причина).
  final String? detail;

  @override
  String toString() => 'KodiApiException($statusCode): $message';
}

/// Клиент Kodi JSON-RPC API.
///
/// Минимальный набор методов, нужных для passive watch-sync:
/// [ping], [getApplicationProperties], [getMovies], [getTvShows],
/// [getEpisodes] + [rawCall] для debug-панели.
///
/// Реконфигурируется через [setConnection]/[clearConnection] —
/// один инстанс на всё время жизни приложения.
class KodiApi {
  /// Создаёт [KodiApi].
  ///
  /// [timeout] используется для connect/receive (default 5s — LAN).
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

  /// Задаёт параметры подключения.
  ///
  /// [host] очищается от пробелов. [username]/[password] опциональны —
  /// без них запросы идут без `Authorization` (если Kodi разрешает анонимный
  /// доступ).
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

  /// Очищает параметры подключения.
  void clearConnection() {
    _host = null;
    _port = null;
    _username = null;
    _password = null;
  }

  /// Все параметры подключения заданы.
  bool get isConfigured =>
      _host != null &&
      _host!.isNotEmpty &&
      _port != null &&
      _port! > 0 &&
      _port! <= 65535;

  /// Текущий base URL (или null если [isConfigured] == false).
  String? get baseUrl => isConfigured ? 'http://$_host:$_port/jsonrpc' : null;

  /// Пингует Kodi — возвращает true если JSON-RPC отвечает `"pong"`.
  ///
  /// Throws [KodiApiException] при HTTP/auth ошибках.
  Future<bool> ping() async {
    final Map<String, dynamic> response = await rawCall('JSONRPC.Ping', null);
    return response['result'] == 'pong';
  }

  /// Получает информацию о запущенном экземпляре Kodi
  /// (`Application.GetProperties` — `version`, `name`).
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

  /// Получает фильмы из Kodi VideoLibrary.
  ///
  /// Пагинация через [start]/[end] (inclusive:exclusive); по умолчанию
  /// 200 элементов — безопасный батч. Если библиотека больше — caller
  /// вызывает метод итеративно.
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

  /// Получает сериалы из Kodi VideoLibrary.
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

  /// Получает эпизоды сериалов.
  ///
  /// [tvShowId] — опциональный фильтр (Kodi internal `tvshowid`). Если
  /// null — возвращает эпизоды всех шоу (может быть очень много, батчи
  /// обязательны).
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

  /// Выполняет произвольный JSON-RPC метод.
  ///
  /// Возвращает весь ответ (`{jsonrpc, id, result | error}`); caller
  /// самостоятельно извлекает `result`. При ошибке JSON-RPC выбрасывает
  /// [KodiApiException] — поле `error.message` идёт в [message].
  ///
  /// Используется напрямую из Debug Panel для ручной отладки.
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
        throw const KodiApiException(
          'Kodi returned non-JSON response — check "Allow remote control via HTTP"',
        );
      }

      if (raw.containsKey('error')) {
        final Map<String, dynamic>? error =
            raw['error'] as Map<String, dynamic>?;
        final String msg = (error?['message'] as String?) ?? 'JSON-RPC error';
        throw KodiApiException(
          msg,
          detail: 'Kodi error for $method: ${jsonEncode(error)}',
        );
      }

      return raw;
    } on DioException catch (e) {
      final int? statusCode = e.response?.statusCode;
      final String message = _messageForDioException(e, statusCode);
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

  /// Закрывает HTTP клиент.
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
