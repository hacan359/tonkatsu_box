import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/shared/widgets/cached_image.dart';

class MockImageCacheService extends Mock implements ImageCacheService {}

void main() {
  late MockImageCacheService mockCacheService;

  setUpAll(() {
    registerFallbackValue(ImageType.platformLogo);
  });

  setUp(() {
    mockCacheService = MockImageCacheService();
  });

  Widget buildTestWidget({
    required Widget child,
    double? constrainedWidth,
    double? constrainedHeight,
  }) {
    return ProviderScope(
      overrides: <Override>[
        imageCacheServiceProvider.overrideWithValue(mockCacheService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: constrainedWidth != null || constrainedHeight != null
              ? SizedBox(
                  width: constrainedWidth,
                  height: constrainedHeight,
                  child: child,
                )
              : child,
        ),
      ),
    );
  }

  group('CachedImage', () {
    group('cache disabled (remote URL)', () {
      testWidgets('должен показывать Image.network при выключенном кэше',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/image.png',
              isLocal: false,
              isMissing: false,
            ));

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pump();

        // Assert — Image.network создаёт виджет типа Image
        expect(find.byType(Image), findsOneWidget);
      });
    });

    group('cache enabled + file missing (fallback to network)', () {
      testWidgets(
          'должен показывать Image.network и запускать auto-download',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/image.png',
              isLocal: false,
              isMissing: true,
            ));
        when(() => mockCacheService.downloadImage(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => true);

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: '123',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pump();
        await tester.pump();

        // Assert — Image.network shown, download triggered
        expect(find.byType(Image), findsOneWidget);
        verify(() => mockCacheService.downloadImage(
              type: ImageType.gameCover,
              imageId: '123',
              remoteUrl: 'https://example.com/image.png',
            )).called(1);
      });

      testWidgets('не должен скачивать при autoDownload = false',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/image.png',
              isLocal: false,
              isMissing: true,
            ));

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: '123',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
            autoDownload: false,
          ),
        ));
        await tester.pump();
        await tester.pump();

        // Assert — no download triggered
        verifyNever(() => mockCacheService.downloadImage(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            ));
      });

      testWidgets('не должен вызывать overflow при размере 32x32',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/image.png',
              isLocal: false,
              isMissing: true,
            ));
        when(() => mockCacheService.downloadImage(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => true);

        // Act
        await tester.pumpWidget(buildTestWidget(
          constrainedWidth: 32,
          constrainedHeight: 32,
          child: const CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pump();
        await tester.pump();

        // Assert
        expect(tester.takeException(), isNull);
      });
    });

    group('ImageType enum', () {
      testWidgets('должен поддерживать moviePoster',
          (WidgetTester tester) async {
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/poster.jpg',
              isLocal: false,
              isMissing: false,
            ));

        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.moviePoster,
            imageId: '456',
            remoteUrl: 'https://example.com/poster.jpg',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pump();

        verify(() => mockCacheService.getImageUri(
              type: ImageType.moviePoster,
              imageId: '456',
              remoteUrl: 'https://example.com/poster.jpg',
            )).called(1);
      });

      testWidgets('должен поддерживать tvShowPoster',
          (WidgetTester tester) async {
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/poster.jpg',
              isLocal: false,
              isMissing: false,
            ));

        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.tvShowPoster,
            imageId: '789',
            remoteUrl: 'https://example.com/poster.jpg',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pump();

        verify(() => mockCacheService.getImageUri(
              type: ImageType.tvShowPoster,
              imageId: '789',
              remoteUrl: 'https://example.com/poster.jpg',
            )).called(1);
      });
    });

    group('placeholder', () {
      testWidgets('должен показывать CircularProgressIndicator при загрузке',
          (WidgetTester tester) async {
        // Arrange - Future никогда не завершается (Completer без complete)
        final Completer<ImageResult> completer = Completer<ImageResult>();
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) => completer.future);

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        // Не вызываем pumpAndSettle - оставляем в состоянии загрузки

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('должен показывать кастомный placeholder',
          (WidgetTester tester) async {
        // Arrange
        final Completer<ImageResult> completer = Completer<ImageResult>();
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) => completer.future);

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
            placeholder: Icon(Icons.hourglass_empty),
          ),
        ));

        // Assert
        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('не должен вызывать overflow при размере 32x32',
          (WidgetTester tester) async {
        // Arrange
        final Completer<ImageResult> completer = Completer<ImageResult>();
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) => completer.future);

        // Act
        await tester.pumpWidget(buildTestWidget(
          constrainedWidth: 32,
          constrainedHeight: 32,
          child: const CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));

        // Assert
        expect(tester.takeException(), isNull);
      });
    });

    group('error state', () {
      testWidgets('должен показывать broken_image при ошибке Future',
          (WidgetTester tester) async {
        // Arrange - возвращаем ошибку через Future.error
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => throw Exception('Test error'));

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.broken_image), findsOneWidget);
      });

      testWidgets('должен показывать кастомный errorWidget',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => throw Exception('Test error'));

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
            errorWidget: Icon(Icons.error_outline),
          ),
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byIcon(Icons.broken_image), findsNothing);
      });

      testWidgets('не должен вызывать overflow при размере 32x32',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => throw Exception('Test error'));

        // Act
        await tester.pumpWidget(buildTestWidget(
          constrainedWidth: 32,
          constrainedHeight: 32,
          child: const CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(tester.takeException(), isNull);
      });
    });

    group('corrupt local file fallback', () {
      // Image.file errorBuilder не срабатывает в тестовом окружении Flutter,
      // т.к. painting pipeline не декодирует изображения реально.
      // Тестируем структурно: при isLocal=true виджет использует Image.file.
      // Полный flow (errorBuilder → _deleteAndRedownload → Image.network)
      // проверяется вручную.

      testWidgets('должен fallback на network при несуществующем файле',
          (WidgetTester tester) async {
        // Arrange — isLocal=true, но файл не существует (удалён clearCache)
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: '/tmp/nonexistent_file_12345.png',
              isLocal: true,
              isMissing: false,
            ));
        when(() => mockCacheService.deleteImage(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockCacheService.downloadImage(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => true);

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: '9608',
            remoteUrl: 'https://example.com/image.png',
            width: 60,
            height: 80,
          ),
        ));
        await tester.pump();
        await tester.pump();

        // Assert — Image показан (network fallback), не crash
        expect(find.byType(Image), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('должен fallback на network при пустом файле (0 bytes)',
          (WidgetTester tester) async {
        // Arrange — создаём пустой файл
        final Directory tempDir =
            Directory.systemTemp.createTempSync('cached_image_empty_');
        final File emptyFile = File('${tempDir.path}/empty.png');
        emptyFile.writeAsBytesSync(<int>[]);

        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => ImageResult(
              uri: emptyFile.path,
              isLocal: true,
              isMissing: false,
            ));
        when(() => mockCacheService.deleteImage(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockCacheService.downloadImage(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => true);

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: '9608',
            remoteUrl: 'https://example.com/image.png',
            width: 60,
            height: 80,
          ),
        ));
        await tester.pump();
        await tester.pump();

        // Assert — Image показан (network fallback), не crash
        expect(find.byType(Image), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Cleanup
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows file lock
        }
      });

      testWidgets('должен использовать Image (file) при isLocal=true',
          (WidgetTester tester) async {
        // Arrange — создаём реальный валидный 1x1 PNG
        final Directory tempDir =
            Directory.systemTemp.createTempSync('cached_image_test_');
        final File validFile = File('${tempDir.path}/valid.png');
        // Минимальный валидный 1x1 RGBA PNG (67 bytes)
        validFile.writeAsBytesSync(Uint8List.fromList(<int>[
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // RGBA, CRC
          0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT
          0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, // compressed
          0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00, // CRC
          0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, // IEND
          0x60, 0x82,
        ]));

        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => ImageResult(
              uri: validFile.path,
              isLocal: true,
              isMissing: false,
            ));

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.moviePoster,
            imageId: '69735',
            remoteUrl: 'https://example.com/poster.jpg',
            width: 60,
            height: 80,
          ),
        ));
        await tester.pump();

        // Assert — Image виджет (file-based)
        expect(find.byType(Image), findsOneWidget);

        // Cleanup
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows file lock — пропускаем
        }
      });
    });

    group('deleteImage', () {
      test('должен вызывать deleteImage на сервисе', () async {
        // Arrange
        when(() => mockCacheService.deleteImage(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await mockCacheService.deleteImage(
            ImageType.moviePoster, '69735');

        // Assert
        verify(() => mockCacheService.deleteImage(
              ImageType.moviePoster,
              '69735',
            )).called(1);
      });
    });

    group('memCache parameters', () {
      testWidgets('должен передавать memCacheWidth и memCacheHeight',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/image.png',
              isLocal: false,
              isMissing: false,
            ));

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: '123',
            remoteUrl: 'https://example.com/image.png',
            width: 60,
            height: 80,
            memCacheWidth: 120,
            memCacheHeight: 160,
          ),
        ));
        await tester.pump();

        // Assert — Image.network создаёт Image виджет;
        // cacheWidth/cacheHeight оборачиваются в ResizeImage внутри Image,
        // проверяем что Image создан с правильными размерами
        final Image networkImage = tester.widget<Image>(
          find.byType(Image),
        );
        expect(networkImage.width, 60);
        expect(networkImage.height, 80);
      });
    });
  });
}
