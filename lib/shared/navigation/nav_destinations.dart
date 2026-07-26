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
    _dest(loc, NavTab.home),
    _dest(loc, NavTab.collections),
    _dest(loc, NavTab.tierLists),
    _dest(loc, NavTab.releases, badgeCount: releasesTodayCount),
    _dest(loc, NavTab.wishlist, badgeCount: wishlistCount),
    _dest(loc, NavTab.search),
  ];
}

NavDestination _dest(S loc, NavTab tab, {int badgeCount = 0}) => NavDestination(
      tab: tab,
      icon: tab.icon,
      selectedIcon: tab.selectedIcon,
      label: tab.localizedLabel(loc),
      badgeCount: badgeCount,
    );

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
