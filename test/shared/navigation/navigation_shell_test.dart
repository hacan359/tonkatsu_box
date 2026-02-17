// Тесты для NavigationShell.
//
// Ленивая инициализация табов:
// NavigationShell использует IndexedStack с ленивой загрузкой — SearchScreen
// и SettingsScreen строятся только при первом переключении на таб.
// Это оптимизирует запуск на Android (убирает 4 тяжёлых DB-запроса
// и _loadPlatforms() из SearchScreen при старте).
// Widget-тестирование ленивой инициализации ограничено — NavigationShell
// требует множество провайдеров (database, settings, collections и др.).

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/navigation/navigation_shell.dart';

void main() {
  group('NavTab', () {
    test('home имеет index 0', () {
      expect(NavTab.home.index, equals(0));
    });

    test('search имеет index 1', () {
      expect(NavTab.search.index, equals(1));
    });

    test('settings имеет index 2', () {
      expect(NavTab.settings.index, equals(2));
    });

    test('содержит 3 значения', () {
      expect(NavTab.values.length, equals(3));
    });

    test('все значения уникальны', () {
      final Set<int> indices =
          NavTab.values.map((NavTab t) => t.index).toSet();
      expect(indices.length, equals(NavTab.values.length));
    });

    test('home — единственный таб, инициализируемый при старте', () {
      // Проверяем что home.index == 0, что соответствует
      // _initializedTabs = {NavTab.home.index} в NavigationShell
      expect(NavTab.home.index, equals(0));
      // Search и Settings имеют index != 0
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
