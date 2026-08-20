import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Index order matters — [AppShell] switches on it and screens pass one in as
/// the starting tab.
enum NavTab {
  /// Home screen (all items).
  home,

  /// Collections.
  collections,

  /// Tier lists.
  tierLists,

  /// Releases (new episodes of tracked shows).
  releases,

  /// Wishlist (search notes).
  wishlist,

  /// Search.
  search,

  /// Settings.
  settings;

  /// Icon shown when the tab is not selected.
  IconData get icon => switch (this) {
        NavTab.home => Icons.home_outlined,
        NavTab.collections => Icons.shelves,
        NavTab.tierLists => Icons.leaderboard_outlined,
        NavTab.releases => Icons.notifications_none,
        NavTab.wishlist => Icons.bookmark_border,
        NavTab.search => Icons.search_outlined,
        NavTab.settings => Icons.settings_outlined,
      };

  /// Icon shown when the tab is selected.
  IconData get selectedIcon => switch (this) {
        NavTab.home => Icons.home,
        NavTab.collections => Icons.shelves,
        NavTab.tierLists => Icons.leaderboard,
        NavTab.releases => Icons.notifications,
        NavTab.wishlist => Icons.bookmark,
        NavTab.search => Icons.search,
        NavTab.settings => Icons.settings,
      };

  /// Localised menu label.
  String localizedLabel(S l) => switch (this) {
        NavTab.home => l.navMain,
        NavTab.collections => l.navCollections,
        NavTab.tierLists => l.navTierLists,
        NavTab.releases => l.navReleases,
        NavTab.wishlist => l.navWishlist,
        NavTab.search => l.search,
        NavTab.settings => l.navSettings,
      };
}
