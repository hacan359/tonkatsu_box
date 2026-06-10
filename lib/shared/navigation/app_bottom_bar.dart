// Bottom navigation bar — horizontal, for narrow screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/releases/providers/releases_provider.dart';
import '../../features/welcome/providers/menu_tour_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';
import '../theme/app_colors.dart';
import 'liquid_indicator.dart';
import 'nav_destinations.dart';
import 'nav_icon_button.dart';
import 'nav_tab.dart';
import 'nav_tour_keys.dart';

/// Height of the bottom bar.
const double kAppBottomBarHeight = 64;

/// Bottom navigation bar (horizontal).
///
/// Used on narrow screens instead of [AppSidebar]. Settings is not here — it
/// lives in [AppTopBar].
class AppBottomBar extends ConsumerWidget {
  /// Creates an [AppBottomBar].
  const AppBottomBar({
    required this.selectedTab,
    required this.onDestinationSelected,
    super.key,
  });

  /// The active tab.
  final NavTab selectedTab;

  /// Called when a tab is selected.
  final void Function(NavTab tab) onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int wishlistCount = ref.watch(activeWishlistCountProvider);
    final NavTourKeys tourKeys = ref.watch(navTourKeysProvider);
    // The tour keys are stable app-wide singletons; attach them only while the
    // menu tour runs. Otherwise two shells alive at once (e.g. the DB-reset
    // `pushReplacement`) would reuse the same GlobalKeys and crash the tree.
    final bool tourActive = ref.watch(menuTourControllerProvider);

    final List<NavDestination> destinations = buildNavDestinations(
      context: context,
      wishlistCount: wishlistCount,
      releasesTodayCount: ref.watch(releasesTodayCountProvider),
    );
    final int selectedIndex =
        destinations.indexWhere((NavDestination d) => d.tab == selectedTab);

    return SizedBox(
      height: kAppBottomBarHeight + MediaQuery.paddingOf(context).bottom,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double itemWidth = constraints.maxWidth / destinations.length;
              return SizedBox(
                height: kAppBottomBarHeight,
                child: Stack(
                  children: <Widget>[
                    LiquidIndicator(
                      selectedIndex: selectedIndex,
                      itemExtent: itemWidth,
                      crossExtent: kAppBottomBarHeight,
                      axis: Axis.horizontal,
                    ),
                    Row(
                      children: <Widget>[
                        for (final NavDestination d in destinations)
                          NavIconButton(
                            key: tourActive ? tourKeys.keyFor(d.tab) : null,
                            destination: d,
                            active: d.tab == selectedTab,
                            width: itemWidth,
                            height: kAppBottomBarHeight,
                            onTap: () => onDestinationSelected(d.tab),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
