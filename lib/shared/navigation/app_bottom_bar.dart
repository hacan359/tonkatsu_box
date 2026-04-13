// Нижнее меню приложения — горизонтальное, для узких экранов.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/wishlist/providers/wishlist_provider.dart';
import '../theme/app_colors.dart';
import 'liquid_indicator.dart';
import 'nav_destinations.dart';
import 'nav_icon_button.dart';
import 'nav_tab.dart';

/// Высота нижнего меню.
const double kAppBottomBarHeight = 64;

/// Нижнее меню приложения (горизонтальное).
///
/// Используется на узких экранах вместо [AppSidebar]. Settings здесь
/// нет — она в [AppTopBar].
class AppBottomBar extends ConsumerWidget {
  /// Создаёт [AppBottomBar].
  const AppBottomBar({
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
      height: kAppBottomBarHeight + MediaQuery.paddingOf(context).bottom,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double itemWidth = constraints.maxWidth / destinations.length;
              return SizedBox(
                height: kAppBottomBarHeight,
                child: Stack(
                  children: <Widget>[
                    LiquidIndicator(
                      selectedIndex: selectedIndex,
                      itemExtent: itemWidth,
                      crossExtent: kAppBottomBarHeight,
                      axis: Axis.horizontal,
                    ),
                    Row(
                      children: <Widget>[
                        for (final NavDestination d in destinations)
                          NavIconButton(
                            destination: d,
                            active: d.tab == selectedTab,
                            width: itemWidth,
                            height: kAppBottomBarHeight,
                            onTap: () => onDestinationSelected(d.tab),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
