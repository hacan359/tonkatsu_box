import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/nav_tab.dart';

/// One entry of the interactive menu tour. Carries its [tab] so the item set
/// can be proven to match the real menu — see `menu_tour_items_test`.
class MenuTourItem {
  const MenuTourItem({
    required this.tab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.description,
  });

  final NavTab tab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String description;
}

/// Builds the tour items, one per [NavTab] in menu order: the six destinations
/// from `buildNavDestinations` plus the Settings gear from the top bar.
/// Iterating [NavTab.values] guarantees the count equals the real menu.
List<MenuTourItem> buildMenuTourItems(BuildContext context) {
  final S l = S.of(context);
  return <MenuTourItem>[
    for (final NavTab tab in NavTab.values)
      MenuTourItem(
        tab: tab,
        icon: _icon(tab),
        activeIcon: _activeIcon(tab),
        label: _label(l, tab),
        description: _description(l, tab),
      ),
  ];
}

IconData _icon(NavTab tab) => switch (tab) {
      NavTab.home => Icons.home_outlined,
      NavTab.collections => Icons.shelves,
      NavTab.tierLists => Icons.leaderboard_outlined,
      NavTab.releases => Icons.notifications_none,
      NavTab.wishlist => Icons.bookmark_border,
      NavTab.search => Icons.search_outlined,
      NavTab.settings => Icons.settings_outlined,
    };

IconData _activeIcon(NavTab tab) => switch (tab) {
      NavTab.home => Icons.home,
      NavTab.collections => Icons.shelves,
      NavTab.tierLists => Icons.leaderboard,
      NavTab.releases => Icons.notifications,
      NavTab.wishlist => Icons.bookmark,
      NavTab.search => Icons.search,
      NavTab.settings => Icons.settings,
    };

String _label(S l, NavTab tab) => switch (tab) {
      NavTab.home => l.navMain,
      NavTab.collections => l.navCollections,
      NavTab.tierLists => l.navTierLists,
      NavTab.releases => l.navReleases,
      NavTab.wishlist => l.navWishlist,
      NavTab.search => l.navSearch,
      NavTab.settings => l.navSettings,
    };

String _description(S l, NavTab tab) => switch (tab) {
      NavTab.home => l.welcomeHowMainDesc,
      NavTab.collections => l.welcomeHowCollectionsDesc,
      NavTab.tierLists => l.welcomeHowTierListsDesc,
      NavTab.releases => l.welcomeHowReleasesDesc,
      NavTab.wishlist => l.welcomeHowWishlistDesc,
      NavTab.search => l.welcomeHowSearchDesc,
      NavTab.settings => l.welcomeHowSettingsDesc,
    };
