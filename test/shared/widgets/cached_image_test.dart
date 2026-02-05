import 'dart:async';

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
    group('missing cache error', () {
      testWidgets('должен показывать иконку cloud_off при отсутствии кэша',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: null,
              isLocal: true,
              isMissing: true,
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
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      });

      testWidgets('не должен вызывать overflow при размере 32x32',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: null,
              isLocal: true,
              isMissing: true,
            ));

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

        // Assert - проверяем что нет overflow ошибок
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      });

      testWidgets('не должен вызывать overflow при размере 24x24',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: null,
              isLocal: true,
              isMissing: true,
            ));

        // Act
        await tester.pumpWidget(buildTestWidget(
          constrainedWidth: 24,
          constrainedHeight: 24,
          child: const CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 24,
            height: 24,
          ),
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      });

      testWidgets('должен вызывать onMissingCache callback',
          (WidgetTester tester) async {
        // Arrange
        bool callbackCalled = false;
        when(() => mockCacheService.getImageUri(
              type: any(named: 'type'),
              imageId: any(named: 'imageId'),
              remoteUrl: any(named: 'remoteUrl'),
            )).thenAnswer((_) async => const ImageResult(
              uri: null,
              isLocal: true,
              isMissing: true,
            ));

        // Act
        await tester.pumpWidget(buildTestWidget(
          child: CachedImage(
            imageType: ImageType.platformLogo,
            imageId: 'test_id',
            remoteUrl: 'https://example.com/image.png',
            width: 32,
            height: 32,
            onMissingCache: () {
              callbackCalled = true;
            },
          ),
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackCalled, isTrue);
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
      testWidgets('должен показывать broken_image при null result',
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
  });
}
