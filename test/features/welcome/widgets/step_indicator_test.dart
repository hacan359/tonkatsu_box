import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для StepIndicator — индикатор шага Welcome Wizard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/welcome/widgets/step_indicator.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

void main() {
  Widget createWidget({
    int number = 1,
    String label = 'Step',
    bool isActive = false,
    bool isDone = false,
    bool showLabel = true,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: StepIndicator(
          number: number,
          label: label,
          isActive: isActive,
          isDone: isDone,
          showLabel: showLabel,
          onTap: onTap,
        ),
      ),
    );
  }

  group('StepIndicator', () {
    group('pending state', () {
      testWidgets('shows number in circle', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(number: 3));

        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows label when showLabel is true',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(label: 'Welcome'));

        expect(find.text('Welcome'), findsOneWidget);
      });

      testWidgets('hides label when showLabel is false',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(label: 'Welcome', showLabel: false));

        expect(find.text('Welcome'), findsNothing);
      });

      testWidgets('uses surfaceBorder for circle color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Find circle container by BoxDecoration with circle shape
        final Finder circleFinder = find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        );
        expect(circleFinder, findsOneWidget);

        final Container circle = tester.widget<Container>(circleFinder);
        final BoxDecoration decoration = circle.decoration! as BoxDecoration;
        expect(decoration.color, equals(AppColors.surfaceBorder));
      });

      testWidgets('uses textTertiary for label color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(label: 'Test'));

        final Text labelText = tester.widget<Text>(find.text('Test'));
        expect(labelText.style?.color, equals(AppColors.textTertiary));
      });
    });

    group('active state', () {
      testWidgets('uses brand color for circle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isActive: true));

        final Finder circleFinder = find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        );
        final Container circle = tester.widget<Container>(circleFinder);
        final BoxDecoration decoration = circle.decoration! as BoxDecoration;
        expect(decoration.color, equals(AppColors.brand));
      });

      testWidgets('uses brand color for label text',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(isActive: true, label: 'Active'),
        );

        final Text labelText = tester.widget<Text>(find.text('Active'));
        expect(labelText.style?.color, equals(AppColors.brand));
      });

      testWidgets('has brand-tinted background',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isActive: true));

        // Active state has brand.withAlpha(25) background
        final Finder containers = find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color ==
                  AppColors.brand.withAlpha(25),
        );
        expect(containers, findsOneWidget);
      });

      testWidgets('shows number, not checkmark',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(number: 2, isActive: true));

        expect(find.text('2'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsNothing);
      });
    });

    group('done state', () {
      testWidgets('shows checkmark instead of number',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isDone: true, number: 1));

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.text('1'), findsNothing);
      });

      testWidgets('uses success color for circle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isDone: true));

        final Finder circleFinder = find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        );
        final Container circle = tester.widget<Container>(circleFinder);
        final BoxDecoration decoration = circle.decoration! as BoxDecoration;
        expect(decoration.color, equals(AppColors.success));
      });

      testWidgets('uses success color for label text',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(isDone: true, label: 'Done'),
        );

        final Text labelText = tester.widget<Text>(find.text('Done'));
        expect(labelText.style?.color, equals(AppColors.success));
      });

      testWidgets('has success-tinted background',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isDone: true));

        final Finder containers = find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color ==
                  AppColors.success.withAlpha(15),
        );
        expect(containers, findsOneWidget);
      });
    });

    group('interaction', () {
      testWidgets('calls onTap when tapped', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          createWidget(onTap: () => tapped = true),
        );

        await tester.tap(find.byType(StepIndicator));
        expect(tapped, isTrue);
      });

      testWidgets('does not crash when onTap is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        await tester.tap(find.byType(StepIndicator));
        expect(tester.takeException(), isNull);
      });
    });

    group('layout', () {
      testWidgets('circle is 22x22', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Circle container with BoxShape.circle and SizedBox 22x22
        final Finder circleFinder = find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        );
        expect(circleFinder, findsOneWidget);

        // Verify rendered size
        final Size circleSize = tester.getSize(circleFinder);
        expect(circleSize.width, equals(22));
        expect(circleSize.height, equals(22));
      });

      testWidgets('label has fontSize 11', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(label: 'Test'));

        final Text labelText = tester.widget<Text>(find.text('Test'));
        expect(labelText.style?.fontSize, equals(11));
      });

      testWidgets('checkmark icon is size 13',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isDone: true));

        final Icon checkIcon = tester.widget<Icon>(find.byIcon(Icons.check));
        expect(checkIcon.size, equals(13));
      });
    });

    group('priority: isDone overrides isActive visually', () {
      testWidgets(
          'when both isDone and isActive are true, shows success colors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(isDone: true, isActive: true, label: 'Both'),
        );

        // isDone takes priority for circle color
        final Finder circleFinder = find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        );
        final Container circle = tester.widget<Container>(circleFinder);
        final BoxDecoration decoration = circle.decoration! as BoxDecoration;
        expect(decoration.color, equals(AppColors.success));

        // Shows checkmark (isDone priority)
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });
  });
}
