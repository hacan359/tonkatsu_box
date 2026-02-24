import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для SectionHeader.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/section_header.dart';

void main() {
  Widget buildWidget({
    String title = 'Test Section',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: SectionHeader(
          title: title,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }

  group('SectionHeader', () {
    testWidgets('отображает заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(title: 'My Collections'));

      expect(find.text('My Collections'), findsOneWidget);
    });

    testWidgets('не показывает кнопку без actionLabel', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('не показывает кнопку без onAction', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(actionLabel: 'See all'));

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('показывает кнопку при наличии actionLabel и onAction', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(
        actionLabel: 'See all',
        onAction: () {},
      ));

      expect(find.text('See all'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('вызывает onAction при нажатии', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(buildWidget(
        actionLabel: 'Sort',
        onAction: () => tapped = true,
      ));

      await tester.tap(find.text('Sort'));
      expect(tapped, isTrue);
    });
  });
}
