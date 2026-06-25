// Builds the navigation destinations for the side and bottom menus.
//
// Settings is not included here — it lives behind the gear in [AppTopBar].

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'nav_icon_button.dart';
import 'nav_tab.dart';

/// Builds the ordered list of [NavDestination]s for the menu.
///
/// The order is identical for [AppSidebar] and [AppBottomBar]. Settings is
/// absent — it opens via the gear in [AppTopBar].
List<NavDestination> buildNavDestinations({
  required BuildContext context,
  required int wishlistCount,
  required int releasesTodayCount,
}) {
  final S loc = S.of(context);
  return <NavDestination>[
    NavDestination(
      tab: NavTab.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: loc.navMain,
    ),
    NavDestination(
      tab: NavTab.collections,
      icon: Icons.shelves,
      selectedIcon: Icons.shelves,
      label: loc.navCollections,
    ),
    NavDestination(
      tab: NavTab.tierLists,
      icon: Icons.leaderboard_outlined,
      selectedIcon: Icons.leaderboard,
      label: loc.navTierLists,
    ),
    NavDestination(
      tab: NavTab.releases,
      icon: Icons.notifications_none,
      selectedIcon: Icons.notifications,
      label: loc.navReleases,
      badgeCount: releasesTodayCount,
    ),
    NavDestination(
      tab: NavTab.wishlist,
      icon: Icons.bookmark_border,
      selectedIcon: Icons.bookmark,
      label: loc.navWishlist,
      badgeCount: wishlistCount,
    ),
    NavDestination(
      tab: NavTab.search,
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: loc.navSearch,
    ),
  ];
}

/// Slot the centre button occupies in the nav row/rail. [AppShell] draws the
/// button (a docked logo); the bars reserve an empty slot here so the tabs
/// split evenly around it.
const int kNavCenterSlot = 3;

/// Maps the selected destination index to its visual slot once the empty
/// centre slot is accounted for. Returns [kNavCenterSlot] while the centre
/// button is active, -1 when nothing is selected, and otherwise shifts any
/// destination at or past the centre by one to skip the reserved slot.
int navSelectedSlot({required int selectedIndex, required bool centerActive}) {
  if (centerActive) return kNavCenterSlot;
  if (selectedIndex < 0) return -1;
  return selectedIndex < kNavCenterSlot ? selectedIndex : selectedIndex + 1;
}
