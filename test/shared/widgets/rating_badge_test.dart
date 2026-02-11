// Тесты для RatingBadge.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/widgets/rating_badge.dart';

void main() {
  Widget buildWidget(double rating) {
    return MaterialApp(
      home: Scaffold(
        body: RatingBadge(normalizedRating: rating),
      ),
    );
  }

  group('RatingBadge', () {
    testWidgets('отображает рейтинг как целое число 0-100', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(0.85));

      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('округляет рейтинг', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(0.777));

      expect(find.text('78'), findsOneWidget);
    });

    testWidgets('отображает 0 для нулевого рейтинга', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(0.0));

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('отображает 100 для максимального рейтинга', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(1.0));

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('зелёный цвет для высокого рейтинга (>=0.75)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(0.85));

      final Container container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final BoxDecoration decoration =
          container.decoration! as BoxDecoration;
      final Border border = decoration.border! as Border;

      expect(border.top.color, equals(AppColors.success.withAlpha(80)));
    });

    testWidgets('жёлтый цвет для среднего рейтинга (>=0.50, <0.75)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(0.60));

      final Container container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final BoxDecoration decoration =
          container.decoration! as BoxDecoration;
      final Border border = decoration.border! as Border;

      expect(border.top.color, equals(AppColors.warning.withAlpha(80)));
    });

    testWidgets('красный цвет для низкого рейтинга (<0.50)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(0.30));

      final Container container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final BoxDecoration decoration =
          container.decoration! as BoxDecoration;
      final Border border = decoration.border! as Border;

      expect(border.top.color, equals(AppColors.error.withAlpha(80)));
    });

    testWidgets('граничное значение 0.75 — зелёный', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(0.75));

      final Container container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final BoxDecoration decoration =
          container.decoration! as BoxDecoration;
      final Border border = decoration.border! as Border;

      expect(border.top.color, equals(AppColors.success.withAlpha(80)));
    });

    testWidgets('граничное значение 0.50 — жёлтый', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(0.50));

      final Container container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final BoxDecoration decoration =
          container.decoration! as BoxDecoration;
      final Border border = decoration.border! as Border;

      expect(border.top.color, equals(AppColors.warning.withAlpha(80)));
    });
  });
}
