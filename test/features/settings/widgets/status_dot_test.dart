import 'package:xerabora/l10n/app_localizations.dart';
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
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: StatusDot(label: label, type: type, compact: compact),
      ),
    );
  }

  /// Finds the circular badge Container inside StatusDot.
  Finder findBadge() {
    return find.descendant(
      of: find.byType(StatusDot),
      matching: find.byWidgetPredicate(
        (Widget w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
    );
  }

  BoxDecoration getBadgeDecoration(WidgetTester tester) {
    final Container container = tester.widget<Container>(findBadge());
    return container.decoration! as BoxDecoration;
  }

  group('StatusDot', () {
    group('StatusType rendering', () {
      testWidgets('success shows ✓ symbol with success color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success),
        );

        expect(find.text('✓'), findsOneWidget);
        final BoxDecoration decoration = getBadgeDecoration(tester);
        expect(
          (decoration.border! as Border).top.color,
          equals(AppColors.success),
        );
        expect(find.text('OK'), findsOneWidget);
      });

      testWidgets('warning shows ! symbol with warning color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Warning', type: StatusType.warning),
        );

        expect(find.text('!'), findsOneWidget);
        final BoxDecoration decoration = getBadgeDecoration(tester);
        expect(
          (decoration.border! as Border).top.color,
          equals(AppColors.warning),
        );
      });

      testWidgets('error shows ✕ symbol with error color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Error', type: StatusType.error),
        );

        expect(find.text('✕'), findsOneWidget);
        final BoxDecoration decoration = getBadgeDecoration(tester);
        expect(
          (decoration.border! as Border).top.color,
          equals(AppColors.error),
        );
      });

      testWidgets('inactive shows ? symbol with tertiary color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Unknown', type: StatusType.inactive),
        );

        expect(find.text('?'), findsOneWidget);
        final BoxDecoration decoration = getBadgeDecoration(tester);
        expect(
          (decoration.border! as Border).top.color,
          equals(AppColors.textTertiary),
        );
      });
    });

    group('badge decoration', () {
      testWidgets('has circle shape', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success),
        );

        final BoxDecoration decoration = getBadgeDecoration(tester);
        expect(decoration.shape, equals(BoxShape.circle));
      });

      testWidgets('has semi-transparent background',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success),
        );

        final BoxDecoration decoration = getBadgeDecoration(tester);
        expect(decoration.color, isNotNull);
        // 12% opacity background
        expect(decoration.color!.a, closeTo(0.12, 0.01));
      });

      testWidgets('has 1.5px border width', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success),
        );

        final BoxDecoration decoration = getBadgeDecoration(tester);
        final Border border = decoration.border! as Border;
        expect(border.top.width, equals(1.5));
      });
    });

    group('compact mode', () {
      testWidgets('normal mode uses 18px badge size',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success),
        );

        final Container container = tester.widget<Container>(findBadge());
        expect(container.constraints?.maxWidth, equals(18));
        expect(container.constraints?.maxHeight, equals(18));
      });

      testWidgets('compact mode uses 16px badge size',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(
              label: 'OK', type: StatusType.success, compact: true),
        );

        final Container container = tester.widget<Container>(findBadge());
        expect(container.constraints?.maxWidth, equals(16));
        expect(container.constraints?.maxHeight, equals(16));
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
