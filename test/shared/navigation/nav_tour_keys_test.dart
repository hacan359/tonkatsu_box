import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/navigation/nav_tab.dart';
import 'package:tonkatsu_box/shared/navigation/nav_tour_keys.dart';

void main() {
  group('NavTourKeys', () {
    test('returns the same key for a tab across calls', () {
      final NavTourKeys keys = NavTourKeys();
      for (final NavTab tab in NavTab.values) {
        expect(keys.keyFor(tab), same(keys.keyFor(tab)));
      }
    });

    test('returns a distinct key per tab', () {
      final NavTourKeys keys = NavTourKeys();
      final Set<GlobalKey> unique = <GlobalKey>{
        for (final NavTab tab in NavTab.values) keys.keyFor(tab),
      };
      expect(unique.length, NavTab.values.length);
    });

    test('personalization key is stable and distinct from the tab keys', () {
      final NavTourKeys keys = NavTourKeys();
      expect(keys.personalization, same(keys.personalization));

      final Set<GlobalKey> tabKeys = <GlobalKey>{
        for (final NavTab tab in NavTab.values) keys.keyFor(tab),
      };
      expect(tabKeys.contains(keys.personalization), isFalse);
    });

    test('provider exposes a single shared instance', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(navTourKeysProvider),
        same(container.read(navTourKeysProvider)),
      );
    });
  });
}
