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
