import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/releases/providers/releases_provider.dart';
import 'package:tonkatsu_box/features/welcome/providers/menu_tour_provider.dart';
import 'package:tonkatsu_box/features/wishlist/providers/wishlist_provider.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/navigation/app_bottom_bar.dart';
import 'package:tonkatsu_box/shared/navigation/nav_tab.dart';
import 'package:tonkatsu_box/shared/navigation/nav_tour_keys.dart';

void main() {
  group('AppBottomBar tour keys', () {
    List<Override> overrides() => <Override>[
          activeWishlistCountProvider.overrideWithValue(0),
          releasesTodayCountProvider.overrideWithValue(0),
        ];

    Widget bar() => AppBottomBar(
          selectedTab: NavTab.home,
          onDestinationSelected: (_) {},
          onCenterTap: () {},
        );

    Widget wrap(Widget child, {required ProviderContainer container}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets(
        'two bars coexist without a duplicate-key crash when the tour is off',
        (WidgetTester tester) async {
      final ProviderContainer container =
          ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      // Mimics the DB-reset `pushReplacement`: the old and new shells (each
      // with a nav bar) are briefly alive at once.
      await tester.pumpWidget(wrap(
        Column(children: <Widget>[bar(), bar()]),
        container: container,
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('attaches the stable tour keys while the menu tour runs',
        (WidgetTester tester) async {
      final ProviderContainer container =
          ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      container.read(menuTourControllerProvider.notifier).start();
      final NavTourKeys keys = container.read(navTourKeysProvider);

      await tester.pumpWidget(wrap(bar(), container: container));

      expect(find.byKey(keys.keyFor(NavTab.home)), findsOneWidget);
    });

    testWidgets('does not attach the tour keys when the tour is off',
        (WidgetTester tester) async {
      final ProviderContainer container =
          ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      final NavTourKeys keys = container.read(navTourKeysProvider);

      await tester.pumpWidget(wrap(bar(), container: container));

      expect(find.byKey(keys.keyFor(NavTab.home)), findsNothing);
    });
  });
}
