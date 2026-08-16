import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'nav_icon_button.dart';
import 'nav_tab.dart';

/// One order for both [AppSidebar] and [AppBottomBar]. Settings is absent —
/// it opens from the gear in [AppTopBar].
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

/// [AppShell] draws the centre button; the bars only reserve this slot so the
/// tabs split evenly around it.
const int kNavCenterSlot = 3;

/// Destination index to visual slot: [kNavCenterSlot] while the centre button
/// is active, -1 for nothing selected, else shifted past the reserved slot.
int navSelectedSlot({required int selectedIndex, required bool centerActive}) {
  if (centerActive) return kNavCenterSlot;
  if (selectedIndex < 0) return -1;
  return selectedIndex < kNavCenterSlot ? selectedIndex : selectedIndex + 1;
}
