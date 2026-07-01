import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/nav_tab.dart';

/// One entry of the interactive menu tour. [tab] carries the highlighted nav
/// tab so the item set can be proven to match the real menu (see
/// `menu_tour_items_test`); it is null for the Personalization centre button,
/// which is a shell-level destination rather than a [NavTab].
class MenuTourItem {
  const MenuTourItem({
    required this.tab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.description,
  });

  final NavTab? tab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String description;

  /// Whether this step highlights the Personalization centre button instead of
  /// a [NavTab] button.
  bool get isPersonalization => tab == null;
}

/// Builds the tour items in the order they sit in the live menu: the six
/// destinations from `buildNavDestinations` with the Personalization centre
/// button slotted into the middle (matching `kNavCenterSlot`), then the
/// Settings gear from the top bar. Every [NavTab] is covered exactly once.
List<MenuTourItem> buildMenuTourItems(BuildContext context) {
  final S l = S.of(context);
  return <MenuTourItem>[
    _tabItem(l, NavTab.home),
    _tabItem(l, NavTab.collections),
    _tabItem(l, NavTab.tierLists),
    _personalizationItem(l),
    _tabItem(l, NavTab.releases),
    _tabItem(l, NavTab.wishlist),
    _tabItem(l, NavTab.search),
    _tabItem(l, NavTab.settings),
  ];
}

MenuTourItem _tabItem(S l, NavTab tab) => MenuTourItem(
      tab: tab,
      icon: _icon(tab),
      activeIcon: _activeIcon(tab),
      label: _label(l, tab),
      description: _description(l, tab),
    );

/// The Personalization centre button: the genre cloud and recommendations
/// built from your rated items.
MenuTourItem _personalizationItem(S l) => MenuTourItem(
      tab: null,
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: l.genreCloudTitle,
      description: l.welcomeHowPersonalizationDesc,
    );

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
