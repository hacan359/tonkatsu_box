import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/services/collection_browser_service.dart';
import 'package:tonkatsu_box/features/collections/models/collections_index.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('CollectionBrowserService.fetchIndex', () {
    late MockDio dio;
    late CollectionBrowserService service;

    const String indexJson =
        '{"version":2,"totalCollections":5,"totalItems":100}';

    Response<String> ok(String body) => Response<String>(
          requestOptions: RequestOptions(path: '/index.json'),
          data: body,
          statusCode: 200,
        );

    setUp(() {
      dio = MockDio();
      service = CollectionBrowserService(dio: dio);
      when(() => dio.get<String>(any()))
          .thenAnswer((_) async => ok(indexJson));
    });

    test('parses the fetched index', () async {
      final CollectionsIndex index = await service.fetchIndex();
      expect(index.version, 2);
      expect(index.totalCollections, 5);
      expect(index.totalItems, 100);
    });

    test('caches the result across calls', () async {
      await service.fetchIndex();
      await service.fetchIndex();
      verify(() => dio.get<String>(any())).called(1);
    });

    test('forceRefresh bypasses the cache', () async {
      await service.fetchIndex();
      await service.fetchIndex(forceRefresh: true);
      verify(() => dio.get<String>(any())).called(2);
    });

    test('clearCache forces a re-fetch', () async {
      await service.fetchIndex();
      service.clearCache();
      await service.fetchIndex();
      verify(() => dio.get<String>(any())).called(2);
    });

    test('wraps a DioException in CollectionBrowserException', () async {
      when(() => dio.get<String>(any())).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/index.json')),
      );
      await expectLater(
        service.fetchIndex(),
        throwsA(isA<CollectionBrowserException>()),
      );
    });
  });
}
