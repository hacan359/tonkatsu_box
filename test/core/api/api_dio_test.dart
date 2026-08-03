import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/api_dio.dart';

void main() {
  group('createApiDio', () {
    test('carries timeouts, base URL and headers into BaseOptions', () {
      final Dio dio = createApiDio(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 7),
        baseUrl: 'https://example.test/api/',
        headers: const <String, String>{'User-Agent': 'TonkatsuBox/test'},
      );

      expect(dio.options.connectTimeout, const Duration(seconds: 3));
      expect(dio.options.receiveTimeout, const Duration(seconds: 7));
      expect(dio.options.baseUrl, 'https://example.test/api/');
      expect(dio.options.headers['user-agent'], 'TonkatsuBox/test');
    });

    test('defaults to no base URL and JSON responses', () {
      final Dio dio = createApiDio(
        connectTimeout: const Duration(seconds: 1),
        receiveTimeout: const Duration(seconds: 1),
      );

      expect(dio.options.baseUrl, isEmpty);
      expect(dio.options.responseType, ResponseType.json);
    });

    test('honours a non-JSON response type', () {
      final Dio dio = createApiDio(
        connectTimeout: const Duration(seconds: 1),
        receiveTimeout: const Duration(seconds: 1),
        responseType: ResponseType.plain,
      );

      expect(dio.options.responseType, ResponseType.plain);
    });

    test('returns an independent instance per call', () {
      final Dio first = createApiDio(
        connectTimeout: const Duration(seconds: 1),
        receiveTimeout: const Duration(seconds: 1),
        baseUrl: 'https://first.test',
      );
      final Dio second = createApiDio(
        connectTimeout: const Duration(seconds: 1),
        receiveTimeout: const Duration(seconds: 1),
        baseUrl: 'https://second.test',
      );

      expect(first.options.baseUrl, 'https://first.test');
      expect(second.options.baseUrl, 'https://second.test');
    });
  });
}
