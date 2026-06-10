// Side navigation rail — vertical, for wide screens.

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

/// Width of the side rail.
const double kAppSidebarWidth = 64;

/// Maximum height of one tab button. On short screens the buttons shrink
/// proportionally to stay within the available height.
const double _kItemHeight = 56;

/// Minimum tab-button height — below this the icon becomes hard to read.
const double _kItemHeightMin = 36;

/// Side navigation rail (vertical).
///
/// Icons only (no labels or logo); centers the buttons vertically and
/// highlights the active item with an animated [LiquidIndicator]. Settings is
/// not here — it lives in [AppTopBar].
class AppSidebar extends ConsumerWidget {
  /// Creates an [AppSidebar].
  const AppSidebar({
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
    // Tour keys are app-wide singletons; attach only during the menu tour so two
    // shells alive at once (DB-reset `pushReplacement`) can't reuse the same
    // GlobalKeys and crash the tree.
    final bool tourActive = ref.watch(menuTourControllerProvider);

    final List<NavDestination> destinations = buildNavDestinations(
      context: context,
      wishlistCount: wishlistCount,
      releasesTodayCount: ref.watch(releasesTodayCountProvider),
    );
    final int selectedIndex =
        destinations.indexWhere((NavDestination d) => d.tab == selectedTab);

    return SizedBox(
      width: kAppSidebarWidth,
      child: ColoredBox(
        color: AppColors.surface,
        child: Stack(
          children: <Widget>[
            const Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: VerticalDivider(
                thickness: 1,
                width: 1,
                color: AppColors.surfaceBorder,
              ),
            ),
            LayoutBuilder(
              builder: (BuildContext ctx, BoxConstraints c) {
                // Shrink button height when the screen is shorter than ideal,
                // but never below the minimum or the icons blur together.
                final double itemHeight = (c.maxHeight / destinations.length)
                    .clamp(_kItemHeightMin, _kItemHeight);
                final double totalHeight = itemHeight * destinations.length;
                return Center(
                  child: SizedBox(
                    height: totalHeight,
                    child: Stack(
                      children: <Widget>[
                        LiquidIndicator(
                          selectedIndex: selectedIndex,
                          itemExtent: itemHeight,
                          crossExtent: kAppSidebarWidth,
                        ),
                        Column(
                          children: <Widget>[
                            for (final NavDestination d in destinations)
                              NavIconButton(
                                key: tourActive ? tourKeys.keyFor(d.tab) : null,
                                destination: d,
                                active: d.tab == selectedTab,
                                width: kAppSidebarWidth,
                                height: itemHeight,
                                onTap: () => onDestinationSelected(d.tab),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
