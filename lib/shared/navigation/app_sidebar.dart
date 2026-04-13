// Боковое меню приложения — вертикальное, для широких экранов.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/wishlist/providers/wishlist_provider.dart';
import '../theme/app_colors.dart';
import 'liquid_indicator.dart';
import 'nav_destinations.dart';
import 'nav_icon_button.dart';
import 'nav_tab.dart';

/// Ширина бокового меню.
const double kAppSidebarWidth = 64;

/// Высота одной кнопки таба.
const double _kItemHeight = 56;

/// Боковое меню приложения (вертикальное).
///
/// Содержит только иконки (без подписей и логотипа), располагает кнопки
/// вертикально по центру и подсвечивает активный пункт анимированным
/// [LiquidIndicator]. Settings здесь нет — она в [AppTopBar].
class AppSidebar extends ConsumerWidget {
  /// Создаёт [AppSidebar].
  const AppSidebar({
    required this.selectedTab,
    required this.onDestinationSelected,
    super.key,
  });

  /// Активный таб.
  final NavTab selectedTab;

  /// Колбэк при выборе таба.
  final void Function(NavTab tab) onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int wishlistCount = ref.watch(activeWishlistCountProvider);

    final List<NavDestination> destinations = buildNavDestinations(
      context: context,
      wishlistCount: wishlistCount,
    );
    final int selectedIndex =
        destinations.indexWhere((NavDestination d) => d.tab == selectedTab);

    return SizedBox(
      width: kAppSidebarWidth,
      child: ColoredBox(
        color: AppColors.surface,
        child: Stack(
          children: <Widget>[
            const Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: VerticalDivider(
                thickness: 1,
                width: 1,
                color: AppColors.surfaceBorder,
              ),
            ),
            Center(
              child: SizedBox(
                height: _kItemHeight * destinations.length,
                child: Stack(
                  children: <Widget>[
                    LiquidIndicator(
                      selectedIndex: selectedIndex,
                      itemExtent: _kItemHeight,
                      crossExtent: kAppSidebarWidth,
                    ),
                    Column(
                      children: <Widget>[
                        for (final NavDestination d in destinations)
                          NavIconButton(
                            destination: d,
                            active: d.tab == selectedTab,
                            width: kAppSidebarWidth,
                            height: _kItemHeight,
                            onTap: () => onDestinationSelected(d.tab),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
