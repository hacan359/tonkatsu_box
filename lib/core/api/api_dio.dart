import 'package:dio/dio.dart';

/// The single place every API client gets its [Dio] from — one seam for the
/// selfhost web build to route calls through the server proxy.
Dio createApiDio({
  required Duration connectTimeout,
  required Duration receiveTimeout,
  String baseUrl = '',
  Map<String, String>? headers,
  ResponseType responseType = ResponseType.json,
}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers,
      responseType: responseType,
    ),
  );
}
