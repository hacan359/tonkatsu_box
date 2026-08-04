import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/statistics/layout/stats_layout.dart';
import 'package:tonkatsu_box/features/statistics/layout/stats_layout_desktop.dart';
import 'package:tonkatsu_box/features/statistics/layout/stats_layout_mobile.dart';
import 'package:tonkatsu_box/features/statistics/layout/stats_layout_scope.dart';

void main() {
  group('StatsLayoutScope', () {
    group('of', () {
      testWidgets('should return the layout published by the scope', (
        WidgetTester tester,
      ) async {
        late StatsLayout seen;
        await tester.pumpWidget(
          StatsLayoutScope(
            layout: kStatsLayoutMobile,
            child: Builder(
              builder: (BuildContext context) {
                seen = StatsLayoutScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(seen, same(kStatsLayoutMobile));
      });

      testWidgets('should fall back to the wide layout without a scope', (
        WidgetTester tester,
      ) async {
        // The offscreen share card renders outside any page, and a section
        // rendered on its own in a test must not assert.
        late StatsLayout seen;
        await tester.pumpWidget(
          Builder(
            builder: (BuildContext context) {
              seen = StatsLayoutScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        );

        expect(seen, same(kStatsLayoutDesktop));
      });

      testWidgets('should return the nearest scope when nested', (
        WidgetTester tester,
      ) async {
        late StatsLayout seen;
        await tester.pumpWidget(
          StatsLayoutScope(
            layout: kStatsLayoutDesktop,
            child: StatsLayoutScope(
              layout: kStatsLayoutMobile,
              child: Builder(
                builder: (BuildContext context) {
                  seen = StatsLayoutScope.of(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(seen, same(kStatsLayoutMobile));
      });
    });

    group('updateShouldNotify', () {
      test('should notify only when the layout changes', () {
        const StatsLayoutScope desktop = StatsLayoutScope(
          layout: kStatsLayoutDesktop,
          child: SizedBox.shrink(),
        );
        const StatsLayoutScope mobile = StatsLayoutScope(
          layout: kStatsLayoutMobile,
          child: SizedBox.shrink(),
        );

        expect(mobile.updateShouldNotify(desktop), isTrue);
        expect(desktop.updateShouldNotify(desktop), isFalse);
      });
    });
  });
}
