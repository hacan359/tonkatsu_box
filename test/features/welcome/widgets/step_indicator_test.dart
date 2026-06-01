import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/welcome/widgets/step_indicator.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

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
        await tester.pumpWidget(
            createWidget(label: 'Welcome', showLabel: false));

        expect(find.text('Welcome'), findsNothing);
      });
    });

    group('active state', () {
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

    group('priority: isDone overrides isActive', () {
      testWidgets('isDone + isActive → показан checkmark',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(isDone: true, isActive: true, label: 'Both'),
        );

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.text('1'), findsNothing);
      });
    });
  });
}
