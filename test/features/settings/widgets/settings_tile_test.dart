// Тесты для SettingsTile — тонкая строка настроек.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/settings_tile.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

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

    group('Chevron', () {
      testWidgets('shows chevron when onTap is provided and showChevron=true',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(onTap: () {}));

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('hides chevron when showChevron=false',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          onTap: () {},
          showChevron: false,
        ));

        expect(find.byIcon(Icons.chevron_right), findsNothing);
      });

      testWidgets('hides chevron when onTap is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.chevron_right), findsNothing);
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

    group('Styling', () {
      testWidgets('value text has tertiary color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(value: 'test value'));

        final Text valueText = tester.widget<Text>(find.text('test value'));
        final TextStyle style = valueText.style!;
        expect(style.color, equals(AppColors.textTertiary));
      });

      testWidgets('chevron icon has tertiary color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(onTap: () {}));

        final Icon chevronIcon =
            tester.widget<Icon>(find.byIcon(Icons.chevron_right));
        expect(chevronIcon.color, equals(AppColors.textTertiary));
      });

      testWidgets('chevron icon has size 18',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(onTap: () {}));

        final Icon chevronIcon =
            tester.widget<Icon>(find.byIcon(Icons.chevron_right));
        expect(chevronIcon.size, equals(18));
      });
    });
  });
}
