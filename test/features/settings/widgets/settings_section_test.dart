import 'package:xerabora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/settings_section.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/theme/app_spacing.dart';

void main() {
  Widget createWidget({
    String title = 'Section',
    List<Widget> children = const <Widget>[],
    IconData? icon,
    Color? iconColor,
    String? subtitle,
    Widget? trailing,
    bool compact = false,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: SettingsSection(
          title: title,
          icon: icon,
          iconColor: iconColor,
          subtitle: subtitle,
          trailing: trailing,
          compact: compact,
          children: children,
        ),
      ),
    );
  }

  group('SettingsSection', () {
    group('title and header', () {
      testWidgets('shows title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Profile'));
        expect(find.text('Profile'), findsOneWidget);
      });

      testWidgets('shows subtitle when provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', subtitle: 'Description here'),
        );
        expect(find.text('Description here'), findsOneWidget);
      });

      testWidgets('no subtitle renders only title',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        // Only one Text widget for title
        expect(find.text('Title'), findsOneWidget);
      });
    });

    group('icon', () {
      testWidgets('shows icon with default brand color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.person),
        );

        expect(find.byIcon(Icons.person), findsOneWidget);
        final Icon iconWidget =
            tester.widget<Icon>(find.byIcon(Icons.person));
        expect(iconWidget.color, equals(AppColors.brand));
      });

      testWidgets('shows icon with custom color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(
            title: 'Danger',
            icon: Icons.warning_amber,
            iconColor: AppColors.error,
          ),
        );

        final Icon iconWidget =
            tester.widget<Icon>(find.byIcon(Icons.warning_amber));
        expect(iconWidget.color, equals(AppColors.error));
      });

      testWidgets('no icon when not provided', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        // No icons in the section header
        expect(find.byType(Icon), findsNothing);
      });
    });

    group('trailing', () {
      testWidgets('shows trailing widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(
            title: 'Title',
            trailing: const Text('Badge'),
          ),
        );
        expect(find.text('Badge'), findsOneWidget);
      });

      testWidgets('no trailing when null', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        // Just title text
        expect(find.text('Title'), findsOneWidget);
      });
    });

    group('children', () {
      testWidgets('renders children', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(
            title: 'Title',
            children: const <Widget>[
              Text('Child 1'),
              Text('Child 2'),
            ],
          ),
        );

        expect(find.text('Child 1'), findsOneWidget);
        expect(find.text('Child 2'), findsOneWidget);
      });

      testWidgets('empty children renders only header',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'Title'));
        expect(find.text('Title'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('compact mode', () {
      testWidgets('normal icon size is 20', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.star),
        );
        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.star));
        expect(icon.size, equals(20));
      });

      testWidgets('compact icon size is 16', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', icon: Icons.star, compact: true),
        );
        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.star));
        expect(icon.size, equals(16));
      });

      testWidgets('normal mode uses md padding', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(title: 'Title', children: const <Widget>[Text('X')]),
        );

        // Find the Padding that wraps the Column (direct child of Card)
        final Iterable<Padding> paddings = tester.widgetList<Padding>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(Padding),
          ),
        );
        final bool hasMdPadding = paddings.any(
          (Padding p) => p.padding == const EdgeInsets.all(AppSpacing.md),
        );
        expect(hasMdPadding, isTrue);
      });

      testWidgets('compact mode uses sm padding',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(
            title: 'Title',
            compact: true,
            children: const <Widget>[Text('X')],
          ),
        );

        final Iterable<Padding> paddings = tester.widgetList<Padding>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(Padding),
          ),
        );
        final bool hasSmPadding = paddings.any(
          (Padding p) => p.padding == const EdgeInsets.all(AppSpacing.sm),
        );
        expect(hasSmPadding, isTrue);
      });
    });

    testWidgets('wraps in Card widget', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(title: 'Title'));
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
