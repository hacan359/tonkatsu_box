import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/welcome/providers/menu_tour_provider.dart';
import 'package:tonkatsu_box/features/welcome/widgets/menu_tour_overlay.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/navigation/nav_tab.dart';
import 'package:tonkatsu_box/shared/navigation/nav_tour_keys.dart';
import 'package:tonkatsu_box/shared/theme/app_theme.dart';

/// Tour controller that starts already active, so the overlay shows on pump.
class _ActiveTourController extends MenuTourController {
  @override
  bool build() => true;
}

void main() {
  // A minimal fake shell: one keyed box per NavTab (standing in for the real
  // nav buttons) plus the overlay, all under the real app theme.
  Widget harness() {
    return ProviderScope(
      overrides: <Override>[
        menuTourControllerProvider.overrideWith(_ActiveTourController.new),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            final NavTourKeys keys = ref.watch(navTourKeysProvider);
            final bool active = ref.watch(menuTourControllerProvider);
            return Scaffold(
              body: Stack(
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final NavTab tab in NavTab.values)
                          SizedBox(
                            key: keys.keyFor(tab),
                            width: 64,
                            height: 56,
                          ),
                        // The Personalization centre button (genre cloud +
                        // recommendations) is a tour target too.
                        SizedBox(
                          key: keys.personalization,
                          width: 64,
                          height: 56,
                        ),
                      ],
                    ),
                  ),
                  if (active) const Positioned.fill(child: MenuTourOverlay()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // The overlay runs an infinite pulse animation, so pumpAndSettle would hang —
  // pump a couple of frames to let the post-frame rect read run instead.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('MenuTourOverlay', () {
    testWidgets('shows over the real buttons without exception',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness());
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(MenuTourOverlay), findsOneWidget);
      // Card with its Next control is visible once a button rect is found.
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('stepping through every item ends the tour',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness());
      await settle(tester);

      // One step per NavTab plus the Personalization centre button.
      for (int i = 0; i < NavTab.values.length + 1; i++) {
        await tester.tap(find.byType(FilledButton));
        await settle(tester);
      }

      expect(find.byType(MenuTourOverlay), findsNothing);
    });

    testWidgets('skip ends the tour immediately',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness());
      await settle(tester);

      await tester.tap(find.byType(TextButton));
      await settle(tester);

      expect(find.byType(MenuTourOverlay), findsNothing);
    });
  });
}
