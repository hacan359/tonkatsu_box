import 'package:xerabora/l10n/app_localizations.dart';
// Виджет-тесты для StarRatingBar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/widgets/star_rating_bar.dart';

void main() {
  Widget buildTestWidget({
    int? rating,
    double starSize = 28.0,
    required ValueChanged<int?> onChanged,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: StarRatingBar(
          rating: rating,
          starSize: starSize,
          onChanged: onChanged,
        ),
      ),
    );
  }

  group('StarRatingBar', () {
    group('отображение', () {
      testWidgets('должен отображать 10 звёзд', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(onChanged: (_) {}));
        await tester.pumpAndSettle();

        // 10 star_border icons (no rating set)
        expect(find.byIcon(Icons.star_border), findsNWidgets(10));
        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('должен заполнять звёзды до текущего рейтинга',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(rating: 7, onChanged: (_) {}));
        await tester.pumpAndSettle();

        // 7 filled stars + 3 empty stars
        expect(find.byIcon(Icons.star), findsNWidgets(7));
        expect(find.byIcon(Icons.star_border), findsNWidgets(3));
      });

      testWidgets('должен заполнять все 10 звёзд при рейтинге 10',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(rating: 10, onChanged: (_) {}));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsNWidgets(10));
        expect(find.byIcon(Icons.star_border), findsNothing);
      });

      testWidgets('должен заполнять 1 звезду при рейтинге 1',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(rating: 1, onChanged: (_) {}));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsNWidgets(1));
        expect(find.byIcon(Icons.star_border), findsNWidgets(9));
      });

      testWidgets('должен показывать все пустые звёзды при rating == null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(onChanged: (_) {}));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star_border), findsNWidgets(10));
      });
    });

    group('цвета', () {
      testWidgets('заполненные звёзды должны быть AppColors.ratingStar',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(rating: 3, onChanged: (_) {}));
        await tester.pumpAndSettle();

        final Iterable<Icon> filledIcons = tester
            .widgetList<Icon>(find.byIcon(Icons.star));
        for (final Icon icon in filledIcons) {
          expect(icon.color, AppColors.ratingStar);
        }
      });

      testWidgets('пустые звёзды должны быть AppColors.textTertiary',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(rating: 3, onChanged: (_) {}));
        await tester.pumpAndSettle();

        final Iterable<Icon> emptyIcons = tester
            .widgetList<Icon>(find.byIcon(Icons.star_border));
        for (final Icon icon in emptyIcons) {
          expect(icon.color, AppColors.textTertiary);
        }
      });
    });

    group('размер', () {
      testWidgets('должен использовать размер по умолчанию 28',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(onChanged: (_) {}));
        await tester.pumpAndSettle();

        final Icon firstIcon =
            tester.widget<Icon>(find.byIcon(Icons.star_border).first);
        expect(firstIcon.size, 28.0);
      });

      testWidgets('должен использовать кастомный размер',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(starSize: 20.0, onChanged: (_) {}));
        await tester.pumpAndSettle();

        final Icon firstIcon =
            tester.widget<Icon>(find.byIcon(Icons.star_border).first);
        expect(firstIcon.size, 20.0);
      });
    });

    group('взаимодействие', () {
      testWidgets('клик на звезду должен вызывать onChanged с индексом',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(
            buildTestWidget(onChanged: (int? r) => changedRating = r));
        await tester.pumpAndSettle();

        // Нажимаем на 5-ю звезду (star_border, index 4)
        await tester.tap(find.byIcon(Icons.star_border).at(4));
        await tester.pumpAndSettle();

        expect(changedRating, 5);
      });

      testWidgets('клик на 1-ю звезду должен вызывать onChanged(1)',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(
            buildTestWidget(onChanged: (int? r) => changedRating = r));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.star_border).first);
        await tester.pumpAndSettle();

        expect(changedRating, 1);
      });

      testWidgets('клик на 10-ю звезду должен вызывать onChanged(10)',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(
            buildTestWidget(onChanged: (int? r) => changedRating = r));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.star_border).last);
        await tester.pumpAndSettle();

        expect(changedRating, 10);
      });

      testWidgets(
          'повторный клик на текущий рейтинг должен сбрасывать (null)',
          (WidgetTester tester) async {
        int? changedRating = 5;
        await tester.pumpWidget(buildTestWidget(
          rating: 5,
          onChanged: (int? r) => changedRating = r,
        ));
        await tester.pumpAndSettle();

        // Нажимаем на 5-ю заполненную звезду (сброс)
        await tester.tap(find.byIcon(Icons.star).at(4));
        await tester.pumpAndSettle();

        expect(changedRating, isNull);
      });

      testWidgets(
          'клик на звезду ниже текущего рейтинга должен менять рейтинг',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(buildTestWidget(
          rating: 8,
          onChanged: (int? r) => changedRating = r,
        ));
        await tester.pumpAndSettle();

        // Нажимаем 3-ю звезду (снижаем рейтинг)
        await tester.tap(find.byIcon(Icons.star).at(2));
        await tester.pumpAndSettle();

        expect(changedRating, 3);
      });

      testWidgets(
          'клик на звезду выше текущего рейтинга должен повышать рейтинг',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(buildTestWidget(
          rating: 3,
          onChanged: (int? r) => changedRating = r,
        ));
        await tester.pumpAndSettle();

        // Нажимаем 8-ю звезду (пустую, повышаем рейтинг)
        await tester.tap(find.byIcon(Icons.star_border).at(4));
        await tester.pumpAndSettle();

        expect(changedRating, 8);
      });
    });

    group('maxStars константа', () {
      test('должен быть равен 10', () {
        expect(StarRatingBar.maxStars, 10);
      });
    });

    group('InkWell для геймпада', () {
      testWidgets('каждая звезда должна быть обёрнута в InkWell',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(onChanged: (_) {}));
        await tester.pumpAndSettle();

        // 10 InkWell (по одному на каждую звезду)
        expect(find.byType(InkWell), findsNWidgets(10));
      });
    });
  });
}
