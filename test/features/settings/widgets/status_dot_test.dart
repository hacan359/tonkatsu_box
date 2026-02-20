import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/status_dot.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

void main() {
  Widget createWidget({
    required String label,
    required StatusType type,
    bool compact = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StatusDot(label: label, type: type, compact: compact),
      ),
    );
  }

  group('StatusDot', () {
    group('StatusType rendering', () {
      testWidgets('success shows check_circle icon with success color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success),
        );

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        final Icon icon =
            tester.widget<Icon>(find.byIcon(Icons.check_circle));
        expect(icon.color, equals(AppColors.success));
        expect(find.text('OK'), findsOneWidget);
      });

      testWidgets('warning shows warning_amber icon with warning color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Warning', type: StatusType.warning),
        );

        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
        final Icon icon =
            tester.widget<Icon>(find.byIcon(Icons.warning_amber));
        expect(icon.color, equals(AppColors.warning));
      });

      testWidgets('error shows error icon with error color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Error', type: StatusType.error),
        );

        expect(find.byIcon(Icons.error), findsOneWidget);
        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.error));
        expect(icon.color, equals(AppColors.error));
      });

      testWidgets('inactive shows help_outline icon with tertiary color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Unknown', type: StatusType.inactive),
        );

        expect(find.byIcon(Icons.help_outline), findsOneWidget);
        final Icon icon =
            tester.widget<Icon>(find.byIcon(Icons.help_outline));
        expect(icon.color, equals(AppColors.textTertiary));
      });
    });

    group('compact mode', () {
      testWidgets('normal mode uses 18px icon size',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success),
        );

        final Icon icon =
            tester.widget<Icon>(find.byIcon(Icons.check_circle));
        expect(icon.size, equals(18));
      });

      testWidgets('compact mode uses 16px icon size',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success, compact: true),
        );

        final Icon icon =
            tester.widget<Icon>(find.byIcon(Icons.check_circle));
        expect(icon.size, equals(16));
      });
    });

    testWidgets('displays label text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(label: 'Connected', type: StatusType.success),
      );

      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('long label is ellipsized', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          label: 'A' * 200,
          type: StatusType.success,
        ),
      );

      final Text text = tester.widget<Text>(find.text('A' * 200));
      expect(text.overflow, equals(TextOverflow.ellipsis));
    });

    group('text color matches status', () {
      testWidgets('success label has success color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success),
        );
        final Text text = tester.widget<Text>(find.text('OK'));
        expect(text.style?.color, equals(AppColors.success));
      });

      testWidgets('error label has error color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Fail', type: StatusType.error),
        );
        final Text text = tester.widget<Text>(find.text('Fail'));
        expect(text.style?.color, equals(AppColors.error));
      });

      testWidgets('warning label has warning color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Warn', type: StatusType.warning),
        );
        final Text text = tester.widget<Text>(find.text('Warn'));
        expect(text.style?.color, equals(AppColors.warning));
      });

      testWidgets('inactive label has tertiary color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'None', type: StatusType.inactive),
        );
        final Text text = tester.widget<Text>(find.text('None'));
        expect(text.style?.color, equals(AppColors.textTertiary));
      });
    });

    group('Row layout', () {
      testWidgets('uses min mainAxisSize', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Test', type: StatusType.success),
        );
        final Row row = tester.widget<Row>(find.byType(Row));
        expect(row.mainAxisSize, equals(MainAxisSize.min));
      });
    });
  });
}
