// Тесты для PosterCard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/widgets/poster_card.dart';

void main() {
  Widget buildWidget({
    String title = 'Test Game',
    String? imageUrl,
    String? subtitle,
    Color? accentColor,
    String? statusLabel,
    Color? statusColor,
    VoidCallback? onTap,
    IconData placeholderIcon = Icons.image,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 150,
          height: 200,
          child: PosterCard(
            title: title,
            imageUrl: imageUrl,
            subtitle: subtitle,
            accentColor: accentColor,
            statusLabel: statusLabel,
            statusColor: statusColor,
            onTap: onTap,
            placeholderIcon: placeholderIcon,
          ),
        ),
      ),
    );
  }

  group('PosterCard', () {
    testWidgets('отображает название', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(title: 'Zelda'));

      expect(find.text('Zelda'), findsOneWidget);
    });

    testWidgets('отображает подзаголовок', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(subtitle: '2023'));

      expect(find.text('2023'), findsOneWidget);
    });

    testWidgets('не отображает подзаголовок если null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      // Только title, без subtitle
      expect(find.text('Test Game'), findsOneWidget);
    });

    testWidgets('показывает placeholder без imageUrl', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(
        placeholderIcon: Icons.videogame_asset,
      ));

      expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
    });

    testWidgets('показывает бейдж статуса', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(
        statusLabel: 'Playing',
        statusColor: AppColors.statusInProgress,
      ));

      expect(find.text('Playing'), findsOneWidget);
    });

    testWidgets('не показывает бейдж статуса если null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      // Проверяем, что нет лишних Text кроме title
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('показывает акцентную полоску', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(
        accentColor: AppColors.gameAccent,
      ));

      // Находим Container с высотой 3 (акцентная полоска)
      final Finder containers = find.byType(Container);
      bool foundAccent = false;
      for (final Element element in containers.evaluate()) {
        final Container container = element.widget as Container;
        if (container.constraints?.maxHeight == 3 ||
            (container.color == AppColors.gameAccent)) {
          foundAccent = true;
          break;
        }
      }
      expect(foundAccent, isTrue);
    });

    testWidgets('вызывает onTap при нажатии', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(buildWidget(
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });

    testWidgets('не падает без onTap', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      // Просто рендерится без ошибок
      expect(find.byType(PosterCard), findsOneWidget);
    });
  });
}
