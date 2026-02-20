import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/settings_row.dart';

void main() {
  Widget createWidget({
    String title = 'Test Row',
    String? subtitle,
    IconData? icon,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
    bool showDivider = false,
    bool compact = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SettingsRow(
          title: title,
          subtitle: subtitle,
          icon: icon,
          trailing: trailing,
          onTap: onTap,
          enabled: enabled,
          showDivider: showDivider,
          compact: compact,
        ),
      ),
    );
  }

  group('SettingsRow', () {
    group('content rendering', () {
      testWidgets('shows title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'My Setting'));
        expect(find.text('My Setting'), findsOneWidget);
      });

      testWidgets('shows subtitle when provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', subtitle: 'Description'),
        );
        expect(find.text('Description'), findsOneWidget);
      });

      testWidgets('no subtitle when null', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        final ListTile tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.subtitle, isNull);
      });

      testWidgets('subtitle uses ellipsis overflow',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', subtitle: 'A' * 200),
        );
        final Text subtitleText = tester.widget<Text>(find.text('A' * 200));
        expect(subtitleText.maxLines, equals(1));
        expect(subtitleText.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('shows icon when provided', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.settings),
        );
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('no icon when null', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        final ListTile tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.leading, isNull);
      });

      testWidgets('shows trailing widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(
            title: 'Title',
            trailing: const Switch(value: true, onChanged: null),
          ),
        );
        expect(find.byType(Switch), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('fires onTap callback', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          createWidget(title: 'Tappable', onTap: () => tapped = true),
        );

        await tester.tap(find.text('Tappable'));
        expect(tapped, isTrue);
      });

      testWidgets('disabled tile does not fire onTap',
          (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          createWidget(
            title: 'Disabled',
            onTap: () => tapped = true,
            enabled: false,
          ),
        );

        await tester.tap(find.text('Disabled'));
        expect(tapped, isFalse);
      });
    });

    group('divider', () {
      testWidgets('shows divider when showDivider is true',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', showDivider: true),
        );
        expect(find.byType(Divider), findsOneWidget);
      });

      testWidgets('no divider by default', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        expect(find.byType(Divider), findsNothing);
      });
    });

    group('compact mode', () {
      testWidgets('uses zero contentPadding', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        final ListTile tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.contentPadding, equals(EdgeInsets.zero));
      });

      testWidgets('compact mode sets dense to true',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', compact: true),
        );
        final ListTile tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.dense, isTrue);
      });

      testWidgets('normal mode sets dense to false',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        final ListTile tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.dense, isFalse);
      });

      testWidgets('compact icon uses 18px size', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.star, compact: true),
        );
        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.star));
        expect(icon.size, equals(18));
      });

      testWidgets('normal icon uses 20px size', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.star),
        );
        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.star));
        expect(icon.size, equals(20));
      });
    });

    group('visual polish', () {
      testWidgets('has custom hoverColor', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        final ListTile tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.hoverColor, isNotNull);
        expect(tile.hoverColor!.a, closeTo(0.37, 0.01));
      });

      testWidgets('has rounded shape', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        final ListTile tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.shape, isA<RoundedRectangleBorder>());
        final RoundedRectangleBorder shape =
            tile.shape! as RoundedRectangleBorder;
        expect(
          shape.borderRadius,
          equals(BorderRadius.circular(6)),
        );
      });
    });
  });
}
