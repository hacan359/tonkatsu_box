// Построение списка пунктов навигации для бокового и нижнего меню.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'nav_icon_button.dart';

/// Формирует упорядоченный список [NavDestination] для меню.
///
/// Порядок и содержимое идентичны для [AppSidebar] и [AppBottomBar],
/// чтобы индекс выбранного таба соответствовал одному и тому же пункту
/// на любой раскладке.
List<NavDestination> buildNavDestinations({
  required BuildContext context,
  required int wishlistCount,
  required Color profileColor,
  required bool hasUpdate,
}) {
  final S loc = S.of(context);
  return <NavDestination>[
    NavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: loc.navMain,
    ),
    NavDestination(
      icon: Icons.shelves,
      selectedIcon: Icons.shelves,
      label: loc.navCollections,
    ),
    NavDestination(
      icon: Icons.leaderboard_outlined,
      selectedIcon: Icons.leaderboard,
      label: loc.navTierLists,
    ),
    NavDestination(
      icon: Icons.bookmark_border,
      selectedIcon: Icons.bookmark,
      label: loc.navWishlist,
      badgeCount: wishlistCount,
    ),
    NavDestination(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: loc.navSearch,
    ),
    NavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: loc.navSettings,
      iconColor: profileColor,
      pulsing: hasUpdate,
    ),
  ];
}
