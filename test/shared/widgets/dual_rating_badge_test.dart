import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/dual_rating_badge.dart';

void main() {
  Widget buildBadge({
    double? userRating,
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
      test('should return true когда есть userRating', () {
        const DualRatingBadge badge = DualRatingBadge(userRating: 8);
        expect(badge.hasRating, isTrue);
      });

      test('should return true когда есть apiRating > 0', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: 7.5);
        expect(badge.hasRating, isTrue);
      });

      test('should return true когда оба рейтинга', () {
        const DualRatingBadge badge = DualRatingBadge(
          userRating: 8,
          apiRating: 7.5,
        );
        expect(badge.hasRating, isTrue);
      });

      test('should return false когда нет рейтингов', () {
        const DualRatingBadge badge = DualRatingBadge();
        expect(badge.hasRating, isFalse);
      });

      test('should return false когда apiRating == 0', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: 0.0);
        expect(badge.hasRating, isFalse);
      });

      test('should return false когда apiRating отрицательный', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: -1.0);
        expect(badge.hasRating, isFalse);
      });
    });

    group('formattedRating', () {
      test('should format оба рейтинга через слеш', () {
        const DualRatingBadge badge = DualRatingBadge(
          userRating: 8,
          apiRating: 7.5,
        );
        expect(badge.formattedRating, '8.0 / 7.5');
      });

      test('should show только userRating', () {
        const DualRatingBadge badge = DualRatingBadge(userRating: 10);
        expect(badge.formattedRating, '10.0');
      });

      test('should show только apiRating', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: 6.3);
        expect(badge.formattedRating, '6.3');
      });

      test('should return пустую строку без рейтингов', () {
        const DualRatingBadge badge = DualRatingBadge();
        expect(badge.formattedRating, '');
      });

      test('should format apiRating с одним десятичным знаком', () {
        const DualRatingBadge badge = DualRatingBadge(apiRating: 9.0);
        expect(badge.formattedRating, '9.0');
      });

      test('should format userRating=1 и apiRating=0.1', () {
        const DualRatingBadge badge = DualRatingBadge(
          userRating: 1,
          apiRating: 0.1,
        );
        expect(badge.formattedRating, '1.0 / 0.1');
      });

      test('должен игнорировать apiRating == 0 при наличии userRating', () {
        const DualRatingBadge badge = DualRatingBadge(
          userRating: 5,
          apiRating: 0.0,
        );
        expect(badge.formattedRating, '5.0');
      });
    });

    group('рендеринг badge', () {
      testWidgets('should show SizedBox.shrink без рейтинга',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildBadge());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('should show текст рейтинга',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildBadge(userRating: 8));
        await tester.pumpAndSettle();

        expect(find.text('8.0'), findsOneWidget);
      });

      testWidgets('should show оба рейтинга',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildBadge(userRating: 8, apiRating: 7.5));
        await tester.pumpAndSettle();

        expect(find.text('8.0 / 7.5'), findsOneWidget);
      });

      testWidgets('should show только apiRating',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildBadge(apiRating: 6.3));
        await tester.pumpAndSettle();

        expect(find.text('6.3'), findsOneWidget);
      });
    });

    group('inline режим', () {
      testWidgets('should show текст', (WidgetTester tester) async {
        await tester
            .pumpWidget(buildBadge(userRating: 8, apiRating: 7.5, inline: true));
        await tester.pumpAndSettle();

        expect(find.text('8.0 / 7.5'), findsOneWidget);
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
