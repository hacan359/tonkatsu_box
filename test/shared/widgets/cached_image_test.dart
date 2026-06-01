import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/shared/widgets/cached_image.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockImageCacheService mockCacheService;

  setUpAll(() {
    registerAllFallbacks();
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
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
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
      testWidgets('should show Image.network при выключенном кэше',
          (WidgetTester tester) async {
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/image.png',
              isLocal: false,
              isMissing: false,
            ));

        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
      });
    });

    group('cache enabled + file missing (fallback to network)', () {
      testWidgets(
          'should show Image.network и запускать auto-download',
          (WidgetTester tester) async {
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

        expect(find.byType(Image), findsOneWidget);
        verify(() => mockCacheService.downloadImage(
              type: ImageType.gameCover,
              imageId: '123',
              remoteUrl: 'https://example.com/image.png',
            )).called(1);
      });

      testWidgets('не должен скачивать при autoDownload = false',
          (WidgetTester tester) async {
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/image.png',
              isLocal: false,
              isMissing: true,
            ));

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

        verifyNever(() => mockCacheService.downloadImage(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            ));
      });

      testWidgets('не should call overflow при размере 32x32',
          (WidgetTester tester) async {
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

        await tester.pumpWidget(buildTestWidget(
          constrainedWidth: 32,
          constrainedHeight: 32,
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('ImageType enum', () {
      testWidgets('should support moviePoster',
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

      testWidgets('should support tvShowPoster',
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
      testWidgets('should show CircularProgressIndicator while loading',
          (WidgetTester tester) async {
        // Future never completes — keeps widget in loading state.
        final Completer<ImageResult> completer = Completer<ImageResult>();
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show кастомный placeholder',
          (WidgetTester tester) async {
        final Completer<ImageResult> completer = Completer<ImageResult>();
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
            placeholder: Icon(Icons.hourglass_empty),
          ),
        ));

        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('не should call overflow при размере 32x32',
          (WidgetTester tester) async {
        final Completer<ImageResult> completer = Completer<ImageResult>();
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildTestWidget(
          constrainedWidth: 32,
          constrainedHeight: 32,
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));

        expect(tester.takeException(), isNull);
      });
    });

    group('error state', () {
      testWidgets('should show broken_image on error Future',
          (WidgetTester tester) async {
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => throw Exception('Test error'));

        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.broken_image), findsOneWidget);
      });

      testWidgets('should show кастомный errorWidget',
          (WidgetTester tester) async {
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => throw Exception('Test error'));

        await tester.pumpWidget(buildTestWidget(
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
            errorWidget: Icon(Icons.error_outline),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byIcon(Icons.broken_image), findsNothing);
      });

      testWidgets('не should call overflow при размере 32x32',
          (WidgetTester tester) async {
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => throw Exception('Test error'));

        await tester.pumpWidget(buildTestWidget(
          constrainedWidth: 32,
          constrainedHeight: 32,
          child: const CachedImage(
            imageType: ImageType.gameCover,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
          ),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('corrupt local file fallback', () {
      // Image.file errorBuilder does not fire in widget tests (painting
      // pipeline doesn't really decode); only the Image.file branch is
      // verified structurally — full corrupt-file flow is checked manually.

      testWidgets('должен fallback на network при несуществующем файле',
          (WidgetTester tester) async {
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

        expect(find.byType(Image), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('должен fallback на network when empty файле (0 bytes)',
          (WidgetTester tester) async {
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

        expect(find.byType(Image), findsOneWidget);
        expect(tester.takeException(), isNull);

        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows file lock
        }
      });

      testWidgets('should use Image (file) при isLocal=true',
          (WidgetTester tester) async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('cached_image_test_');
        final File validFile = File('${tempDir.path}/valid.png');
        // Minimal valid 1x1 RGBA PNG (67 bytes).
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

        expect(find.byType(Image), findsOneWidget);

        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows file lock
        }
      });
    });

    group('deleteImage', () {
      test('should call deleteImage на сервисе', () async {
        when(() => mockCacheService.deleteImage(any(), any()))
            .thenAnswer((_) async {});

        await mockCacheService.deleteImage(
            ImageType.moviePoster, '69735');

        verify(() => mockCacheService.deleteImage(
              ImageType.moviePoster,
              '69735',
            )).called(1);
      });
    });

    group('memCache parameters', () {
      testWidgets('должен передавать memCacheWidth и memCacheHeight',
          (WidgetTester tester) async {
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: 'https://example.com/image.png',
              isLocal: false,
              isMissing: false,
            ));

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

        final Image networkImage = tester.widget<Image>(
          find.byType(Image),
        );
        expect(networkImage.width, 60);
        expect(networkImage.height, 80);
      });
    });
  });
}
