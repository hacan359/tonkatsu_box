import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_spacing.dart';
import 'package:tonkatsu_box/shared/utils/poster_grid_delegate.dart';

void main() {
  /// Resolves the geometry at [size] the way a real grid would.
  Future<({SliverGridDelegate delegate, double padding})> geometryAt(
    WidgetTester tester,
    Size size, {
    double cardScale = 1.0,
  }) async {
    late ({SliverGridDelegate delegate, double padding}) result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: Builder(
          builder: (BuildContext context) {
            result = posterGridGeometry(context, cardScale: cardScale);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  group('posterGridGeometry', () {
    testWidgets('should use fixed mobile columns on a phone-width screen',
        (WidgetTester tester) async {
      final ({SliverGridDelegate delegate, double padding}) g =
          await geometryAt(tester, const Size(360, 640));

      expect(g.delegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
      expect(
        (g.delegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        AppSpacing.gridColumnsMobile,
      );
    });

    testWidgets('should use more columns at tablet width',
        (WidgetTester tester) async {
      final ({SliverGridDelegate delegate, double padding}) g =
          await geometryAt(tester, const Size(600, 900));

      expect(
        (g.delegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        AppSpacing.gridColumnsTablet,
      );
    });

    testWidgets('should switch to a max-extent grid on a desktop width',
        (WidgetTester tester) async {
      final ({SliverGridDelegate delegate, double padding}) g =
          await geometryAt(tester, const Size(1400, 900));

      expect(g.delegate, isA<SliverGridDelegateWithMaxCrossAxisExtent>());
    });

    testWidgets('should scale the desktop card width by the card scale',
        (WidgetTester tester) async {
      final ({SliverGridDelegate delegate, double padding}) small =
          await geometryAt(tester, const Size(1400, 900), cardScale: 0.8);
      final ({SliverGridDelegate delegate, double padding}) large =
          await geometryAt(tester, const Size(1400, 900), cardScale: 1.4);

      final double smallExtent =
          (small.delegate as SliverGridDelegateWithMaxCrossAxisExtent)
              .maxCrossAxisExtent;
      final double largeExtent =
          (large.delegate as SliverGridDelegateWithMaxCrossAxisExtent)
              .maxCrossAxisExtent;
      expect(largeExtent, greaterThan(smallExtent));
    });

    testWidgets('should reduce columns as the card scale grows on a phone',
        (WidgetTester tester) async {
      final ({SliverGridDelegate delegate, double padding}) small =
          await geometryAt(tester, const Size(360, 640), cardScale: 0.7);
      final ({SliverGridDelegate delegate, double padding}) large =
          await geometryAt(tester, const Size(360, 640), cardScale: 1.6);

      final int smallColumns =
          (small.delegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount;
      final int largeColumns =
          (large.delegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount;
      expect(largeColumns, lessThan(smallColumns));
    });

    testWidgets('should report a padding every caller can apply',
        (WidgetTester tester) async {
      final ({SliverGridDelegate delegate, double padding}) g =
          await geometryAt(tester, const Size(360, 640));

      expect(g.padding, greaterThan(0));
    });
  });
}
