import 'package:dio/dio.dart';

import '../../shared/constants/platform_features.dart';
import 'proxy_rewrite_interceptor.dart';

/// The single place every API client gets its [Dio] from — the one seam where
/// the web build routes calls through the selfhost server's proxy.
Dio createApiDio({
  required Duration connectTimeout,
  required Duration receiveTimeout,
  String baseUrl = '',
  Map<String, String>? headers,
  ResponseType responseType = ResponseType.json,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers,
      responseType: responseType,
    ),
  );
  // Rewriting the resolved URI covers both shapes in the codebase: a client
  // with a baseUrl and one that builds a full URL per request.
  if (kIsWebBuild) dio.interceptors.add(ProxyRewriteInterceptor());
  return dio;
}
