import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/welcome/widgets/menu_tour_items.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/navigation/nav_tab.dart';

void main() {
  Future<List<MenuTourItem>> buildItems(WidgetTester tester) async {
    late List<MenuTourItem> items;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            items = buildMenuTourItems(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return items;
  }

  group('buildMenuTourItems', () {
    testWidgets('count is every NavTab plus the Personalization step',
        (WidgetTester tester) async {
      final List<MenuTourItem> items = await buildItems(tester);

      expect(items.length, NavTab.values.length + 1);
    });

    testWidgets('covers every NavTab exactly once, in menu order',
        (WidgetTester tester) async {
      final List<MenuTourItem> items = await buildItems(tester);

      final List<NavTab?> tabs =
          items.map((MenuTourItem i) => i.tab).where((NavTab? t) => t != null).toList();

      expect(tabs.toSet(), NavTab.values.toSet());
      expect(tabs, NavTab.values);
    });

    testWidgets('includes exactly one Personalization step',
        (WidgetTester tester) async {
      final List<MenuTourItem> items = await buildItems(tester);

      expect(
        items.where((MenuTourItem i) => i.isPersonalization).length,
        1,
      );
    });

    testWidgets('includes the Settings gear', (WidgetTester tester) async {
      final List<MenuTourItem> items = await buildItems(tester);

      expect(
        items.any((MenuTourItem i) => i.tab == NavTab.settings),
        isTrue,
      );
    });

    testWidgets('every item has a non-empty label and description',
        (WidgetTester tester) async {
      final List<MenuTourItem> items = await buildItems(tester);

      for (final MenuTourItem item in items) {
        expect(item.label, isNotEmpty);
        expect(item.description, isNotEmpty);
      }
    });
  });
}
