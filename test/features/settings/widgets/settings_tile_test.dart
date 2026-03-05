// Тесты для SettingsTile — тонкая строка настроек.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/settings_tile.dart';

void main() {
  Widget createWidget({
    String title = 'Test Tile',
    String? value,
    VoidCallback? onTap,
    Widget? trailing,
    bool showChevron = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SettingsTile(
          title: title,
          value: value,
          onTap: onTap,
          trailing: trailing,
          showChevron: showChevron,
        ),
      ),
    );
  }

  group('SettingsTile', () {
    group('Rendering', () {
      testWidgets('renders title text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Test Tile'), findsOneWidget);
      });

      testWidgets('renders value text when provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(value: '3 keys'));

        expect(find.text('3 keys'), findsOneWidget);
      });

      testWidgets('does not render value when null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Only title text is present
        final Finder texts = find.byType(Text);
        expect(texts, findsOneWidget);
      });

      testWidgets('renders trailing widget when provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          trailing: const Switch(value: true, onChanged: null),
        ));

        expect(find.byType(Switch), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('calls onTap when tapped', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(createWidget(onTap: () => tapped = true));

        await tester.tap(find.byType(InkWell));
        expect(tapped, isTrue);
      });

      testWidgets('does not crash when tapped without onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        await tester.tap(find.byType(InkWell));
        expect(tester.takeException(), isNull);
      });
    });
  });
}
