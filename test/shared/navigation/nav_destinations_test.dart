import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/navigation/nav_destinations.dart';
import 'package:tonkatsu_box/shared/navigation/nav_tab.dart';

void main() {
  group('navSelectedSlot', () {
    test('should highlight the centre slot when the centre button is active',
        () {
      expect(
        navSelectedSlot(selectedIndex: 0, centerActive: true),
        kNavCenterSlot,
      );
      expect(
        navSelectedSlot(selectedIndex: 5, centerActive: true),
        kNavCenterSlot,
      );
    });

    test('should return -1 when nothing is selected', () {
      expect(
        navSelectedSlot(selectedIndex: -1, centerActive: false),
        -1,
      );
    });

    test('should keep destinations before the centre slot in place', () {
      for (int i = 0; i < kNavCenterSlot; i++) {
        expect(navSelectedSlot(selectedIndex: i, centerActive: false), i);
      }
    });

    test('should shift destinations at or past the centre slot by one', () {
      expect(
        navSelectedSlot(selectedIndex: kNavCenterSlot, centerActive: false),
        kNavCenterSlot + 1,
      );
      expect(
        navSelectedSlot(selectedIndex: kNavCenterSlot + 2, centerActive: false),
        kNavCenterSlot + 3,
      );
    });
  });

  group('navStepSlot', () {
    NavTab? step(NavTab tab, {bool center = false, bool forward = true}) =>
        navStepSlot(current: tab, centerActive: center, forward: forward);

    test('tier lists forward opens Personalization', () {
      expect(step(NavTab.tierLists), isNull);
    });

    test('from Personalization forward is releases, back is tier lists', () {
      // The tab under the hub must not matter.
      expect(step(NavTab.search, center: true), NavTab.releases);
      expect(step(NavTab.search, center: true, forward: false),
          NavTab.tierLists);
    });

    test('wraps around at both ends', () {
      expect(step(NavTab.search), NavTab.home);
      expect(step(NavTab.home, forward: false), NavTab.search);
    });

    test('settings is off the cycle and restarts at either end', () {
      expect(step(NavTab.settings), NavTab.home);
      expect(step(NavTab.settings, forward: false), NavTab.search);
    });

    test('the slot order matches the bar: centre slot is Personalization',
        () {
      expect(kNavSlotOrder[kNavCenterSlot], isNull);
      expect(kNavSlotOrder.whereType<NavTab>(), isNot(contains(NavTab.settings)));
    });
  });
}
