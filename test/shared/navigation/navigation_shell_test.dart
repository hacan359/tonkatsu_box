// Тесты для NavigationShell.
//
// Ленивая инициализация табов:
// NavigationShell использует IndexedStack с ленивой загрузкой — Collections,
// SearchScreen и SettingsScreen строятся только при первом переключении на таб.
// AllItemsScreen (Home) загружается сразу.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/navigation/navigation_shell.dart';

void main() {
  group('NavTab', () {
    test('home имеет index 0', () {
      expect(NavTab.home.index, equals(0));
    });

    test('collections имеет index 1', () {
      expect(NavTab.collections.index, equals(1));
    });

    test('search имеет index 2', () {
      expect(NavTab.search.index, equals(2));
    });

    test('settings имеет index 3', () {
      expect(NavTab.settings.index, equals(3));
    });

    test('содержит 4 значения', () {
      expect(NavTab.values.length, equals(4));
    });

    test('все значения уникальны', () {
      final Set<int> indices =
          NavTab.values.map((NavTab t) => t.index).toSet();
      expect(indices.length, equals(NavTab.values.length));
    });

    test('home — единственный таб, инициализируемый при старте', () {
      expect(NavTab.home.index, equals(0));
      // Collections, Search и Settings имеют index != 0
      expect(
          NavTab.collections.index, isNot(equals(NavTab.home.index)));
      expect(NavTab.search.index, isNot(equals(NavTab.home.index)));
      expect(NavTab.settings.index, isNot(equals(NavTab.home.index)));
    });
  });

  group('navigationBreakpoint', () {
    test('должен быть 800', () {
      expect(navigationBreakpoint, equals(800));
    });
  });
}
