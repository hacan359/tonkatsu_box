import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/navigation/nav_destinations.dart';

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
}
