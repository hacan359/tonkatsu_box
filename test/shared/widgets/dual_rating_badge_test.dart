import 'package:xerabora/l10n/app_localizations.dart';
// Виджет-тесты для DualRatingBadge.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/dual_rating_badge.dart';

void main() {
  Widget buildBadge({
    int? userRating,
    double? apiRating,
    bool compact = false,
    bool inline = false,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: DualRatingBadge(
          userRating: userRating,
          apiRating: apiRating,
          compact: compact,
          inline: inline,
        ),
      ),
    );
  }

  group('DualRatingBadge', () {
    group('hasRating', () {
      test('должен вернуть true когда есть userRating', () {
        const DualRatingBadge badge = DualRatingBadge(userRating: 8);
        expect(badge.hasRating, isTrue);
      });

      test('должен вернуть true когда есть apiRating > 0', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: 7.5);
        expect(badge.hasRating, isTrue);
      });

      test('должен вернуть true когда оба рейтинга', () {
        const DualRatingBadge badge = DualRatingBadge(
          userRating: 8,
          apiRating: 7.5,
        );
        expect(badge.hasRating, isTrue);
      });

      test('должен вернуть false когда нет рейтингов', () {
        const DualRatingBadge badge = DualRatingBadge();
        expect(badge.hasRating, isFalse);
      });

      test('должен вернуть false когда apiRating == 0', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: 0.0);
        expect(badge.hasRating, isFalse);
      });

      test('должен вернуть false когда apiRating отрицательный', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: -1.0);
        expect(badge.hasRating, isFalse);
      });
    });

    group('formattedRating', () {
      test('должен форматировать оба рейтинга через слеш', () {
        const DualRatingBadge badge = DualRatingBadge(
          userRating: 8,
          apiRating: 7.5,
        );
        expect(badge.formattedRating, '8 / 7.5');
      });

      test('должен показывать только userRating', () {
        const DualRatingBadge badge = DualRatingBadge(userRating: 10);
        expect(badge.formattedRating, '10');
      });

      test('должен показывать только apiRating', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: 6.3);
        expect(badge.formattedRating, '6.3');
      });

      test('должен вернуть пустую строку без рейтингов', () {
        const DualRatingBadge badge = DualRatingBadge();
        expect(badge.formattedRating, '');
      });

      test('должен форматировать apiRating с одним десятичным знаком', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: 9.0);
        expect(badge.formattedRating, '9.0');
      });

      test('должен форматировать userRating=1 и apiRating=0.1', () {
        const DualRatingBadge badge = DualRatingBadge(
          userRating: 1,
          apiRating: 0.1,
        );
        expect(badge.formattedRating, '1 / 0.1');
      });

      test('должен игнорировать apiRating == 0 при наличии userRating', () {
        const DualRatingBadge badge = DualRatingBadge(
          userRating: 5,
          apiRating: 0.0,
        );
        expect(badge.formattedRating, '5');
      });
    });

    group('рендеринг badge', () {
      testWidgets('должен показать SizedBox.shrink без рейтинга',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildBadge());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('должен показать текст рейтинга',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildBadge(userRating: 8));
        await tester.pumpAndSettle();

        expect(find.text('8'), findsOneWidget);
      });

      testWidgets('должен показать оба рейтинга',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildBadge(userRating: 8, apiRating: 7.5));
        await tester.pumpAndSettle();

        expect(find.text('8 / 7.5'), findsOneWidget);
      });

      testWidgets('должен показать только apiRating',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildBadge(apiRating: 6.3));
        await tester.pumpAndSettle();

        expect(find.text('6.3'), findsOneWidget);
      });
    });

    group('inline режим', () {
      testWidgets('должен показать текст', (WidgetTester tester) async {
        await tester
            .pumpWidget(buildBadge(userRating: 8, apiRating: 7.5, inline: true));
        await tester.pumpAndSettle();

        expect(find.text('8 / 7.5'), findsOneWidget);
      });

      testWidgets('без рейтинга не показывает текст',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildBadge(inline: true));
        await tester.pumpAndSettle();

        expect(find.textContaining('/'), findsNothing);
      });
    });
  });
}
