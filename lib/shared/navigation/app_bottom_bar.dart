// Bottom navigation bar — horizontal, for narrow screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/releases/providers/releases_provider.dart';
import '../../features/welcome/providers/menu_tour_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'liquid_indicator.dart';
import 'nav_center_button.dart';
import 'nav_destinations.dart';
import 'nav_icon_button.dart';
import 'nav_tab.dart';
import 'nav_tour_keys.dart';

/// Height of the bottom bar.
const double kAppBottomBarHeight = 64;

/// Bottom navigation bar (horizontal).
///
/// Used on narrow screens instead of [AppSidebar]. Settings is not here — it
/// lives in [AppTopBar]. The middle slot is left empty for the centre button.
class AppBottomBar extends ConsumerWidget {
  /// Creates an [AppBottomBar].
  const AppBottomBar({
    required this.selectedTab,
    required this.onDestinationSelected,
    required this.onCenterTap,
    this.centerActive = false,
    super.key,
  });

  /// The active tab.
  final NavTab selectedTab;

  /// Called when a tab is selected.
  final void Function(NavTab tab) onDestinationSelected;

  /// Called when the centre button is tapped.
  final VoidCallback onCenterTap;

  /// Whether the centre button is the active destination (highlights it and
  /// dims the tabs).
  final bool centerActive;

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

    // One extra slot in the middle is reserved for the centre button.
    final int slotCount = destinations.length + 1;
    final int selectedSlot = navSelectedSlot(
      selectedIndex: selectedIndex,
      centerActive: centerActive,
    );

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
              final double itemWidth = constraints.maxWidth / slotCount;
              return SizedBox(
                height: kAppBottomBarHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    LiquidIndicator(
                      selectedIndex: selectedSlot,
                      itemExtent: itemWidth,
                      crossExtent: kAppBottomBarHeight,
                      axis: Axis.horizontal,
                      // The centre logo is larger than a tab icon, so its
                      // highlight needs to be bigger too.
                      size: centerActive ? 50 : 40,
                    ),
                    Row(
                      children: <Widget>[
                        for (int i = 0; i < destinations.length; i++) ...<Widget>[
                          if (i == kNavCenterSlot)
                            NavCenterButton(
                              width: itemWidth,
                              height: kAppBottomBarHeight,
                              tooltip: S.of(context).genreCloudTitle,
                              onTap: onCenterTap,
                            ),
                          NavIconButton(
                            key: tourActive
                                ? tourKeys.keyFor(destinations[i].tab)
                                : null,
                            destination: destinations[i],
                            active: !centerActive &&
                                destinations[i].tab == selectedTab,
                            width: itemWidth,
                            height: kAppBottomBarHeight,
                            onTap: () =>
                                onDestinationSelected(destinations[i].tab),
                          ),
                        ],
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
