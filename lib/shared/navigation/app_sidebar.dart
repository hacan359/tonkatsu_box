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

/// Width of the side rail.
const double kAppSidebarWidth = 64;

/// Maximum height of one tab button. On short screens the buttons shrink
/// proportionally to stay within the available height.
const double _kItemHeight = 56;

/// Minimum tab-button height — below this the icon becomes hard to read.
const double _kItemHeightMin = 36;

/// Vertical nav rail for wide screens: icons only, active item marked by a
/// [LiquidIndicator]. Settings lives in [AppTopBar].
class AppSidebar extends ConsumerWidget {
  /// Creates an [AppSidebar].
  const AppSidebar({
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
    // App-wide singletons: attaching them outside the tour would let two
    // live shells reuse the same GlobalKeys and crash the tree.
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
            Positioned(
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
                // One extra slot in the middle holds the centre button.
                final int slotCount = destinations.length + 1;
                // Shrink button height when the screen is shorter than ideal,
                // but never below the minimum or the icons blur together.
                final double itemHeight = (c.maxHeight / slotCount)
                    .clamp(_kItemHeightMin, _kItemHeight);
                final double totalHeight = itemHeight * slotCount;
                final int selectedSlot = navSelectedSlot(
                  selectedIndex: selectedIndex,
                  centerActive: centerActive,
                );
                return Center(
                  child: SizedBox(
                    height: totalHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        LiquidIndicator(
                          selectedIndex: selectedSlot,
                          itemExtent: itemHeight,
                          crossExtent: kAppSidebarWidth,
                          // The centre logo is larger than a tab icon, so its
                          // highlight needs to be bigger too.
                          size: centerActive ? 50 : 40,
                          rainbow: centerActive,
                        ),
                        Column(
                          children: <Widget>[
                            for (int i = 0; i < destinations.length; i++) ...<Widget>[
                              if (i == kNavCenterSlot)
                                NavCenterButton(
                                  key: tourActive
                                      ? tourKeys.personalization
                                      : null,
                                  width: kAppSidebarWidth,
                                  height: itemHeight,
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
                                width: kAppSidebarWidth,
                                height: itemHeight,
                                onTap: () =>
                                    onDestinationSelected(destinations[i].tab),
                              ),
                            ],
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
