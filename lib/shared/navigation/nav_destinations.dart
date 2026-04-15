// Построение списка пунктов навигации для бокового и нижнего меню.
//
// Settings сюда не входит — она вынесена в шестерёнку в [AppTopBar].

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'nav_icon_button.dart';
import 'nav_tab.dart';

/// Формирует упорядоченный список [NavDestination] для меню.
///
/// Порядок идентичен для [AppSidebar] и [AppBottomBar]. Settings
/// отсутствует — она открывается через шестерёнку в [AppTopBar].
List<NavDestination> buildNavDestinations({
  required BuildContext context,
  required int wishlistCount,
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
