import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/shared/theme/app_spacing.dart';
import 'package:tonkatsu_box/shared/widgets/shimmer_loading.dart';

import '../../helpers/test_helpers.dart';

void main() {
  /// The delegate the skeleton grid resolved — the same one the real grid
  /// builds, so a card-size change must move it.
  Future<SliverGridDelegateWithMaxCrossAxisExtent> desktopDelegate(
    WidgetTester tester,
    double cardScale,
  ) async {
    // The shimmer animates forever, so pumpAndSettle would never return.
    await tester.pumpApp(
      const ShimmerPosterGrid(itemCount: 4),
      settle: false,
      overrides: <Override>[
        settingsNotifierProvider
            .overrideWith(() => _FakeSettingsNotifier(cardScale)),
      ],
    );
    final GridView grid = tester.widget<GridView>(find.byType(GridView));
    return grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
  }

  group('ShimmerPosterGrid', () {
    testWidgets('should render without exceptions',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const ShimmerPosterGrid(itemCount: 4),
        settle: false,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ShimmerPosterCard), findsWidgets);
    });

    testWidgets('should widen the placeholders on a large card scale',
        (WidgetTester tester) async {
      final SliverGridDelegateWithMaxCrossAxisExtent delegate =
          await desktopDelegate(tester, 1.5);

      expect(
        delegate.maxCrossAxisExtent,
        greaterThan(AppSpacing.desktopMaxCardWidth),
      );
    });

    testWidgets('should narrow the placeholders on a small card scale',
        (WidgetTester tester) async {
      final SliverGridDelegateWithMaxCrossAxisExtent delegate =
          await desktopDelegate(tester, 0.7);

      expect(
        delegate.maxCrossAxisExtent,
        lessThan(AppSpacing.desktopMaxCardWidth),
      );
    });

    testWidgets('should render on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const ShimmerPosterGrid(itemCount: 6),
        settle: false,
      );

      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this._cardScale);

  final double _cardScale;

  @override
  SettingsState build() => SettingsState(cardScale: _cardScale);
}
