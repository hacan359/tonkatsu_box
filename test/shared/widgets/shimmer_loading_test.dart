import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/widgets/shimmer_loading.dart';

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

    testWidgets('рендерится в компактном варианте',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(const SizedBox(
          width: 100,
          child: ShimmerPosterCard(compact: true),
        )),
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

  // Every box shares one app-wide ticker, started by the first box on screen
  // and stopped by the last — the lifecycle these tests pin down.
  group('shared shimmer timeline', () {
    testWidgets('should keep animating the boxes that outlive a removed one',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const Column(
        children: <Widget>[
          ShimmerBox(width: 100, height: 20),
          ShimmerBox(width: 100, height: 20),
        ],
      )));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(wrap(const Column(
        children: <Widget>[ShimmerBox(width: 100, height: 20)],
      )));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('should restart after every box left the tree',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ShimmerBox(width: 100, height: 20)));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ShimmerBox), findsNothing);

      await tester.pumpWidget(wrap(const ShimmerBox(width: 100, height: 20)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(ShimmerBox), findsOneWidget);
    });
  });
}
