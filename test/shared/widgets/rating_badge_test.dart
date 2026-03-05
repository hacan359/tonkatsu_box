import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для RatingBadge.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/rating_badge.dart';

void main() {
  group('RatingBadge', () {
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
    });
  });
}
