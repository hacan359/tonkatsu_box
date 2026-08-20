import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';

import '../../helpers/test_helpers.dart';

DioException _statusError(int status) {
  final RequestOptions options = RequestOptions(path: 'front-500');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCacheService.downloadImage', () {
    late MockDio dio;
    late ImageCacheService service;
    late Directory tmp;

    setUp(() {
      dio = MockDio();
      service = ImageCacheService(dio: dio);
      tmp = Directory.systemTemp.createTempSync('image_cache_test');
      SharedPreferences.setMockInitialValues(<String, Object>{
        'image_cache_path': tmp.path,
        'image_cache_enabled': true,
      });
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    test('should stop retrying a cover after a 404', () async {
      when(() => dio.download(any(), any<dynamic>())).thenThrow(_statusError(404));

      expect(
        await service.downloadImage(
          type: ImageType.audioCover,
          imageId: 'a1',
          remoteUrl: 'https://covers.example/a1',
        ),
        isFalse,
      );
      expect(
        await service.downloadImage(
          type: ImageType.audioCover,
          imageId: 'a1',
          remoteUrl: 'https://covers.example/a1',
        ),
        isFalse,
      );

      verify(() => dio.download(any(), any<dynamic>())).called(1);
    });

    test('should retry a cover after a transient failure', () async {
      when(() => dio.download(any(), any<dynamic>())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'front-500'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      await service.downloadImage(
        type: ImageType.audioCover,
        imageId: 'a2',
        remoteUrl: 'https://covers.example/a2',
      );
      await service.downloadImage(
        type: ImageType.audioCover,
        imageId: 'a2',
        remoteUrl: 'https://covers.example/a2',
      );

      verify(() => dio.download(any(), any<dynamic>())).called(2);
    });

    test('should retry after a throttling 503 instead of blanking the cover',
        () async {
      when(() => dio.download(any(), any<dynamic>())).thenThrow(_statusError(503));

      await service.downloadImage(
        type: ImageType.audioCover,
        imageId: 'a3',
        remoteUrl: 'https://covers.example/a3',
      );
      await service.downloadImage(
        type: ImageType.audioCover,
        imageId: 'a3',
        remoteUrl: 'https://covers.example/a3',
      );

      verify(() => dio.download(any(), any<dynamic>())).called(2);
    });

    test('should treat non-image payload as permanent', () async {
      when(() => dio.download(any(), any<dynamic>())).thenAnswer((Invocation inv)
          async {
        final String path = inv.positionalArguments[1] as String;
        File(path).writeAsStringSync('<html>error page</html>');
        return Response<dynamic>(
          requestOptions: RequestOptions(path: 'front-500'),
          statusCode: 200,
        );
      });

      expect(
        await service.downloadImage(
          type: ImageType.audioCover,
          imageId: 'a4',
          remoteUrl: 'https://covers.example/a4',
        ),
        isFalse,
      );
      await service.downloadImage(
        type: ImageType.audioCover,
        imageId: 'a4',
        remoteUrl: 'https://covers.example/a4',
      );

      verify(() => dio.download(any(), any<dynamic>())).called(1);
    });
  });

  group('ImageCacheService.localPathIfCached', () {
    // Minimal file passing the magic-byte validator: JPEG head + tail.
    const List<int> validJpegBytes = <int>[
      0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0xFF, 0xD9, //
    ];

    late ImageCacheService service;
    late Directory tmp;

    setUp(() {
      service = ImageCacheService(dio: MockDio());
      tmp = Directory.systemTemp.createTempSync('image_cache_sync_test');
      SharedPreferences.setMockInitialValues(<String, Object>{
        'image_cache_path': tmp.path,
        'image_cache_enabled': true,
      });
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    File cachedFile(String imageId) => File(
        p.join(tmp.path, ImageType.audioCover.folder, '$imageId.png'));

    test('should return null before the first async lookup', () {
      cachedFile('a1')
        ..createSync(recursive: true)
        ..writeAsBytesSync(validJpegBytes);

      expect(service.localPathIfCached(ImageType.audioCover, 'a1'), isNull);
    });

    test('should resolve a cached file synchronously after one async lookup',
        () async {
      final File file = cachedFile('a1')
        ..createSync(recursive: true)
        ..writeAsBytesSync(validJpegBytes);
      await service.getImageUri(
        type: ImageType.audioCover,
        imageId: 'a1',
        remoteUrl: 'https://covers.example/a1',
      );

      expect(
        service.localPathIfCached(ImageType.audioCover, 'a1'),
        file.path,
      );
    });

    test('should return null for a missing or truncated file', () async {
      cachedFile('broken')
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[0xFF, 0xD8]);
      await service.getImageUri(
        type: ImageType.audioCover,
        imageId: 'warmup',
        remoteUrl: 'https://covers.example/warmup',
      );

      expect(
        service.localPathIfCached(ImageType.audioCover, 'missing'),
        isNull,
      );
      expect(
        service.localPathIfCached(ImageType.audioCover, 'broken'),
        isNull,
      );
    });

    test('should stop resolving after the cache path changes', () async {
      final File file = cachedFile('a1')
        ..createSync(recursive: true)
        ..writeAsBytesSync(validJpegBytes);
      await service.getImageUri(
        type: ImageType.audioCover,
        imageId: 'a1',
        remoteUrl: 'https://covers.example/a1',
      );
      expect(
        service.localPathIfCached(ImageType.audioCover, 'a1'),
        file.path,
      );

      await service.setCachePath(p.join(tmp.path, 'elsewhere'));

      expect(service.localPathIfCached(ImageType.audioCover, 'a1'), isNull);
    });
  });
}
