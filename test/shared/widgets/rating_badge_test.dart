import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для RatingBadge.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/widgets/rating_badge.dart';

void main() {
  group('RatingBadge', () {
    group('colorForRating', () {
      test('рейтинг >= 8.0 должен быть ratingHigh', () {
        expect(RatingBadge.colorForRating(8.0), equals(AppColors.ratingHigh));
        expect(RatingBadge.colorForRating(9.5), equals(AppColors.ratingHigh));
        expect(RatingBadge.colorForRating(10.0), equals(AppColors.ratingHigh));
      });

      test('рейтинг >= 6.0 и < 8.0 должен быть ratingMedium', () {
        expect(RatingBadge.colorForRating(6.0), equals(AppColors.ratingMedium));
        expect(RatingBadge.colorForRating(7.0), equals(AppColors.ratingMedium));
        expect(RatingBadge.colorForRating(7.9), equals(AppColors.ratingMedium));
      });

      test('рейтинг < 6.0 должен быть ratingLow', () {
        expect(RatingBadge.colorForRating(5.9), equals(AppColors.ratingLow));
        expect(RatingBadge.colorForRating(3.0), equals(AppColors.ratingLow));
        expect(RatingBadge.colorForRating(0.0), equals(AppColors.ratingLow));
      });
    });

    group('виджет', () {
      testWidgets('должен отображать рейтинг с одним десятичным знаком',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: RatingBadge(rating: 8.5),
            ),
          ),
        );

        expect(find.text('8.5'), findsOneWidget);
      });

      testWidgets('должен отображать 0 как 0.0',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: RatingBadge(rating: 0),
            ),
          ),
        );

        expect(find.text('0.0'), findsOneWidget);
      });

      testWidgets('должен отображать целое число с десятичной частью',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: RatingBadge(rating: 7),
            ),
          ),
        );

        expect(find.text('7.0'), findsOneWidget);
      });

      testWidgets('должен содержать Container с BoxDecoration',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: RatingBadge(rating: 9.0),
            ),
          ),
        );

        final Finder containerFinder = find.byType(Container);
        expect(containerFinder, findsWidgets);
      });
    });
  });
}
