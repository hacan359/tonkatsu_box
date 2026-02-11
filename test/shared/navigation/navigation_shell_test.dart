// Тесты для NavigationShell.

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
  });
}
