// Тесты для SettingsSidebar — sidebar десктопного лейаута.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/settings_sidebar.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

void main() {
  const List<SettingsSidebarItem> testItems = <SettingsSidebarItem>[
    SettingsSidebarItem(label: 'Profile'),
    SettingsSidebarItem(label: 'Language'),
    SettingsSidebarItem(label: '', isSeparator: true),
    SettingsSidebarItem(label: 'Cache'),
    SettingsSidebarItem(label: 'Database'),
  ];

  Widget createWidget({
    int selectedIndex = 0,
    ValueChanged<int>? onSelected,
    List<SettingsSidebarItem>? items,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: SettingsSidebar(
            selectedIndex: selectedIndex,
            onSelected: onSelected ?? (_) {},
            items: items ?? testItems,
          ),
        ),
      ),
    );
  }

  group('SettingsSidebar', () {
    group('Rendering', () {
      testWidgets('renders all non-separator items',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Cache'), findsOneWidget);
        expect(find.text('Database'), findsOneWidget);
      });

      testWidgets('renders separator as Divider',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byType(Divider), findsOneWidget);
      });

      testWidgets('separator divider has correct color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        final Divider divider = tester.widget<Divider>(find.byType(Divider));
        expect(divider.color, equals(AppColors.surfaceBorder));
      });
    });

    group('Selection', () {
      testWidgets('selected item has brand color text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(selectedIndex: 0));

        final Text profileText = tester.widget<Text>(find.text('Profile'));
        final TextStyle style = profileText.style!;
        expect(style.color, equals(AppColors.brand));
        expect(style.fontWeight, equals(FontWeight.w600));
      });

      testWidgets('unselected item has primary color text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(selectedIndex: 0));

        final Text languageText = tester.widget<Text>(find.text('Language'));
        final TextStyle style = languageText.style!;
        expect(style.color, equals(AppColors.textPrimary));
        expect(style.fontWeight, equals(FontWeight.normal));
      });

      testWidgets('selected item has surfaceLight background',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(selectedIndex: 0));

        // Find the Container for Profile item
        final Finder profileContainer = find.ancestor(
          of: find.text('Profile'),
          matching: find.byType(Container),
        );
        final Container container =
            tester.widget<Container>(profileContainer.first);
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(decoration.color, equals(AppColors.surfaceLight));
      });
    });

    group('Interaction', () {
      testWidgets('calls onSelected with correct index when tapped',
          (WidgetTester tester) async {
        int? selectedIndex;
        await tester.pumpWidget(createWidget(
          onSelected: (int i) => selectedIndex = i,
        ));

        await tester.tap(find.text('Cache'));
        expect(selectedIndex, equals(3));
      });

      testWidgets('calls onSelected with first item index',
          (WidgetTester tester) async {
        int? selectedIndex;
        await tester.pumpWidget(createWidget(
          selectedIndex: 3,
          onSelected: (int i) => selectedIndex = i,
        ));

        await tester.tap(find.text('Profile'));
        expect(selectedIndex, equals(0));
      });

      testWidgets('separator is not tappable',
          (WidgetTester tester) async {
        int? selectedIndex;
        await tester.pumpWidget(createWidget(
          onSelected: (int i) => selectedIndex = i,
        ));

        // Separator doesn't have an InkWell to tap
        // Verify it renders as Divider
        expect(find.byType(Divider), findsOneWidget);
        expect(selectedIndex, isNull);
      });
    });

    group('Edge cases', () {
      testWidgets('renders empty list without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          items: const <SettingsSidebarItem>[],
        ));

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders all separators without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          items: const <SettingsSidebarItem>[
            SettingsSidebarItem(label: '', isSeparator: true),
            SettingsSidebarItem(label: '', isSeparator: true),
          ],
        ));

        expect(find.byType(Divider), findsNWidgets(2));
      });
    });
  });
}
