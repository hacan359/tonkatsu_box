// Виджет-тесты для StarRatingBar.
// Фокус: количество заполненных / пустых звёзд отражает рейтинг,
// тапы по звёздам вызывают onChanged с ожидаемым значением. Не проверяем
// конкретные цвета / размеры — design decisions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/l10n/app_localizations.dart';
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
      testWidgets('без рейтинга показывает 10 пустых звёзд',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(onChanged: (_) {}));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star_border), findsNWidgets(10));
        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('rating=7 даёт 7 filled + 3 empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(rating: 7, onChanged: (_) {}));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsNWidgets(7));
        expect(find.byIcon(Icons.star_border), findsNWidgets(3));
      });

      testWidgets('rating=10 даёт все filled', (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(rating: 10, onChanged: (_) {}));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsNWidgets(10));
        expect(find.byIcon(Icons.star_border), findsNothing);
      });

      testWidgets('rating=1 даёт 1 filled + 9 empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(rating: 1, onChanged: (_) {}));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsNWidgets(1));
        expect(find.byIcon(Icons.star_border), findsNWidgets(9));
      });
    });

    group('взаимодействие', () {
      testWidgets('тап по 5-й звезде вызывает onChanged(5)',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(
            buildTestWidget(onChanged: (int? r) => changedRating = r));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.star_border).at(4));
        await tester.pumpAndSettle();

        expect(changedRating, 5);
      });

      testWidgets('тап по 1-й звезде вызывает onChanged(1)',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(
            buildTestWidget(onChanged: (int? r) => changedRating = r));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.star_border).first);
        await tester.pumpAndSettle();

        expect(changedRating, 1);
      });

      testWidgets('тап по 10-й звезде вызывает onChanged(10)',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(
            buildTestWidget(onChanged: (int? r) => changedRating = r));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.star_border).last);
        await tester.pumpAndSettle();

        expect(changedRating, 10);
      });

      testWidgets('повторный тап по текущему рейтингу сбрасывает в null',
          (WidgetTester tester) async {
        int? changedRating = 5;
        await tester.pumpWidget(buildTestWidget(
          rating: 5,
          onChanged: (int? r) => changedRating = r,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.star).at(4));
        await tester.pumpAndSettle();

        expect(changedRating, isNull);
      });

      testWidgets('тап по звезде ниже текущего снижает рейтинг',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(buildTestWidget(
          rating: 8,
          onChanged: (int? r) => changedRating = r,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.star).at(2));
        await tester.pumpAndSettle();

        expect(changedRating, 3);
      });

      testWidgets('тап по звезде выше текущего повышает рейтинг',
          (WidgetTester tester) async {
        int? changedRating;
        await tester.pumpWidget(buildTestWidget(
          rating: 3,
          onChanged: (int? r) => changedRating = r,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.star_border).at(4));
        await tester.pumpAndSettle();

        expect(changedRating, 8);
      });
    });

    group('maxStars константа', () {
      test('maxStars = 10', () {
        expect(StarRatingBar.maxStars, 10);
      });
    });
  });
}
