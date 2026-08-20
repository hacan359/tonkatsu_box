import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/nav_tab.dart';

/// [tab] is null for the Personalization centre button, which is a shell-level
/// destination rather than a [NavTab].
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

/// Ordered as the live menu is: `buildNavDestinations` with the centre button
/// at `kNavCenterSlot`, then the Settings gear. Every [NavTab] appears once.
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
      icon: tab.icon,
      activeIcon: tab.selectedIcon,
      label: tab.localizedLabel(l),
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

String _description(S l, NavTab tab) => switch (tab) {
      NavTab.home => l.welcomeHowMainDesc,
      NavTab.collections => l.welcomeHowCollectionsDesc,
      NavTab.tierLists => l.welcomeHowTierListsDesc,
      NavTab.releases => l.welcomeHowReleasesDesc,
      NavTab.wishlist => l.welcomeHowWishlistDesc,
      NavTab.search => l.welcomeHowSearchDesc,
      NavTab.settings => l.welcomeHowSettingsDesc,
    };
