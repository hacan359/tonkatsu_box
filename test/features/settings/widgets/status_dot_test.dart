import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/settings/widgets/status_dot.dart';

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

  group('StatusDot', () {
    group('StatusType rendering', () {
      testWidgets('success shows ✓ symbol', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'OK', type: StatusType.success),
        );
        expect(find.text('✓'), findsOneWidget);
      });

      testWidgets('warning shows ! symbol', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Warning', type: StatusType.warning),
        );
        expect(find.text('!'), findsOneWidget);
      });

      testWidgets('error shows ✕ symbol', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Error', type: StatusType.error),
        );
        expect(find.text('✕'), findsOneWidget);
      });

      testWidgets('inactive shows ? symbol', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(label: 'Unknown', type: StatusType.inactive),
        );
        expect(find.text('?'), findsOneWidget);
      });
    });

    testWidgets('displays label text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(label: 'Connected', type: StatusType.success),
      );

      expect(find.text('Connected'), findsOneWidget);
    });

  });
}
