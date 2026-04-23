// Smoke-тесты для ShimmerLoading виджетов.
// Shimmer — чисто визуальный компонент, поэтому проверяем только что
// виджет рендерится без исключений и анимация не крашит таймер.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/shimmer_loading.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: child),
      );

  group('ShimmerBox', () {
    testWidgets('рендерится', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ShimmerBox(width: 100, height: 50)));
      expect(tester.takeException(), isNull);
      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('анимация продолжается через несколько кадров',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ShimmerBox(width: 100, height: 50)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  });

  group('ShimmerPosterCard', () {
    testWidgets('рендерится', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(const SizedBox(width: 200, child: ShimmerPosterCard())),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ShimmerPosterCard), findsOneWidget);
    });
  });

  group('ShimmerTierListCard', () {
    testWidgets('рендерится', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ShimmerTierListCard()));
      expect(tester.takeException(), isNull);
      expect(find.byType(ShimmerTierListCard), findsOneWidget);
    });
  });

  group('ShimmerTierListDetail', () {
    testWidgets('рендерится', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ShimmerTierListDetail()));
      expect(tester.takeException(), isNull);
      expect(find.byType(ShimmerTierListDetail), findsOneWidget);
    });
  });

  group('ShimmerListTile', () {
    testWidgets('рендерится', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ShimmerListTile()));
      expect(tester.takeException(), isNull);
      expect(find.byType(ShimmerListTile), findsOneWidget);
    });
  });
}
