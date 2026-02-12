// Тесты для PosterCard.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/theme/app_spacing.dart';
import 'package:xerabora/shared/widgets/poster_card.dart';
import 'package:xerabora/shared/widgets/rating_badge.dart';

class MockImageCacheService extends Mock implements ImageCacheService {}

void main() {
  late MockImageCacheService mockCacheService;

  setUpAll(() {
    registerFallbackValue(ImageType.platformLogo);
  });

  setUp(() {
    mockCacheService = MockImageCacheService();
    // По умолчанию: кэш выключен, возвращаем remote URL
    when(() => mockCacheService.getImageUri(
          type: any(named: 'type'),
          imageId: any(named: 'imageId'),
          remoteUrl: any(named: 'remoteUrl'),
        )).thenAnswer((_) async => const ImageResult(
          uri: 'https://example.com/poster.jpg',
          isLocal: false,
          isMissing: false,
        ));
  });

  Widget buildTestWidget({
    required Widget child,
    double width = 200,
  }) {
    return ProviderScope(
      overrides: <Override>[
        imageCacheServiceProvider.overrideWithValue(mockCacheService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: child,
          ),
        ),
      ),
    );
  }

  group('PosterCard', () {
    group('рендеринг', () {
      testWidgets('должен рендериться с обязательными параметрами',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
          ),
        ));

        expect(find.byType(PosterCard), findsOneWidget);
        expect(find.text('Test Game'), findsOneWidget);
      });

      testWidgets('должен содержать AspectRatio с правильным соотношением',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
          ),
        ));

        final AspectRatio aspectRatio = tester.widget<AspectRatio>(
          find.byType(AspectRatio),
        );
        expect(aspectRatio.aspectRatio, AppSpacing.posterAspectRatio);
      });

      testWidgets('должен содержать ClipRRect со скруглением',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
          ),
        ));

        expect(find.byType(ClipRRect), findsOneWidget);
      });

      testWidgets('название должно обрезаться при длинном тексте',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Very Long Game Title That Should Be Truncated',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
          ),
        ));

        final Text titleText = tester.widget<Text>(
          find.text('Very Long Game Title That Should Be Truncated'),
        );
        expect(titleText.maxLines, 2);
        expect(titleText.overflow, TextOverflow.ellipsis);
      });
    });

    group('рейтинг', () {
      testWidgets('должен показывать RatingBadge при rating > 0',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
            rating: 8.5,
          ),
        ));

        expect(find.byType(RatingBadge), findsOneWidget);
      });

      testWidgets('не должен показывать RatingBadge при rating = null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
          ),
        ));

        expect(find.byType(RatingBadge), findsNothing);
      });

      testWidgets('не должен показывать RatingBadge при rating = 0',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
            rating: 0,
          ),
        ));

        expect(find.byType(RatingBadge), findsNothing);
      });
    });

    group('отметка "в коллекции"', () {
      testWidgets('должен показывать галочку при isInCollection = true',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
            isInCollection: true,
          ),
        ));

        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('не должен показывать галочку при isInCollection = false',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
          ),
        ));

        expect(find.byIcon(Icons.check), findsNothing);
      });

      testWidgets('галочка должна иметь зелёный фон',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
            isInCollection: true,
          ),
        ));

        // Ищем Container с BoxDecoration и AppColors.success
        final Finder containers = find.byType(Container);
        bool foundSuccessContainer = false;
        for (final Element element in containers.evaluate()) {
          final Container container = element.widget as Container;
          final BoxDecoration? decoration =
              container.decoration as BoxDecoration?;
          if (decoration != null && decoration.color == AppColors.success) {
            foundSuccessContainer = true;
            break;
          }
        }
        expect(foundSuccessContainer, isTrue);
      });
    });

    group('подзаголовок', () {
      testWidgets('должен показывать год',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
            year: 2024,
          ),
        ));

        expect(find.text('2024'), findsOneWidget);
      });

      testWidgets('должен показывать subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
            subtitle: 'RPG',
          ),
        ));

        expect(find.text('RPG'), findsOneWidget);
      });

      testWidgets('должен показывать год и subtitle через разделитель',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
            year: 2024,
            subtitle: 'RPG',
          ),
        ));

        expect(find.text('2024 · RPG'), findsOneWidget);
      });

      testWidgets('не должен показывать подзаголовок без year и subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'Test Game',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
          ),
        ));

        // Только title — нет подзаголовка с годом/жанром
        final Finder texts = find.byType(Text);
        expect(texts, findsOneWidget); // Только title
      });
    });

    group('взаимодействие', () {
      testWidgets('должен вызывать onTap при нажатии',
          (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(buildTestWidget(
          child: PosterCard(
            title: 'Tap Test',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
            onTap: () => tapped = true,
          ),
        ));

        // Тапаем по тексту заголовка — он внутри GestureDetector
        await tester.tap(find.text('Tap Test'));
        expect(tapped, isTrue);
      });

      testWidgets('должен вызывать onLongPress при долгом нажатии',
          (WidgetTester tester) async {
        bool longPressed = false;

        await tester.pumpWidget(buildTestWidget(
          child: PosterCard(
            title: 'LongPress Test',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
            onLongPress: () => longPressed = true,
          ),
        ));

        await tester.longPress(find.text('LongPress Test'));
        expect(longPressed, isTrue);
      });

      testWidgets('должен работать без onTap и onLongPress',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'No Callback',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '123',
          ),
        ));

        // Не должно бросать исключение
        await tester.tap(find.text('No Callback'));
        expect(tester.takeException(), isNull);
      });
    });

    group('комбинированный тест', () {
      testWidgets('должен отображать все элементы одновременно',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const PosterCard(
            title: 'The Witcher 3',
            imageUrl: 'https://example.com/poster.jpg',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '456',
            rating: 9.2,
            year: 2015,
            subtitle: 'RPG',
            isInCollection: true,
          ),
        ));

        // Все элементы присутствуют
        expect(find.text('The Witcher 3'), findsOneWidget);
        expect(find.text('2015 · RPG'), findsOneWidget);
        expect(find.byType(RatingBadge), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });
  });
}
