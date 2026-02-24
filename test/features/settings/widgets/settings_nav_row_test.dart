import 'package:xerabora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/settings_nav_row.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

void main() {
  Widget createWidget({
    String title = 'Navigate',
    IconData icon = Icons.arrow_forward,
    VoidCallback? onTap,
    String? subtitle,
    bool enabled = true,
    bool showDivider = false,
    bool compact = false,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: SettingsNavRow(
          title: title,
          icon: icon,
          onTap: onTap ?? () {},
          subtitle: subtitle,
          enabled: enabled,
          showDivider: showDivider,
          compact: compact,
        ),
      ),
    );
  }

  group('SettingsNavRow', () {
    group('content rendering', () {
      testWidgets('shows title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Settings Page'));
        expect(find.text('Settings Page'), findsOneWidget);
      });

      testWidgets('shows leading icon', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.key),
        );
        expect(find.byIcon(Icons.key), findsOneWidget);
      });

      testWidgets('always shows chevron_right trailing',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('shows subtitle when provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', subtitle: 'Extra info'),
        );
        expect(find.text('Extra info'), findsOneWidget);
      });

      testWidgets('no subtitle when null', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        final ListTile tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.subtitle, isNull);
      });
    });

    group('interactions', () {
      testWidgets('fires onTap callback', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          createWidget(title: 'Tap me', onTap: () => tapped = true),
        );

        await tester.tap(find.text('Tap me'));
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

      testWidgets('compact icon size is 18', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.key, compact: true),
        );
        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.key));
        expect(icon.size, equals(18));
      });

      testWidgets('normal icon size is 20', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.key),
        );
        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.key));
        expect(icon.size, equals(20));
      });
    });

    group('contentPadding', () {
      testWidgets('uses zero contentPadding', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        final ListTile tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.contentPadding, equals(EdgeInsets.zero));
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

      testWidgets('leading icon uses textSecondary color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.key),
        );
        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.key));
        expect(icon.color, equals(AppColors.textSecondary));
      });

      testWidgets('chevron uses textTertiary color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        final Icon chevron =
            tester.widget<Icon>(find.byIcon(Icons.chevron_right));
        expect(chevron.color, equals(AppColors.textTertiary));
      });
    });
  });
}
