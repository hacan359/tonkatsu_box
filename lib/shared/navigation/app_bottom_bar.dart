// Нижнее меню приложения — горизонтальное, для узких экранов.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/profile_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';
import '../../core/services/update_service.dart';
import '../theme/app_colors.dart';
import 'liquid_indicator.dart';
import 'nav_destinations.dart';
import 'nav_icon_button.dart';

/// Высота нижнего меню.
const double kAppBottomBarHeight = 64;

/// Нижнее меню приложения (горизонтальное).
///
/// Используется на узких экранах вместо [AppSidebar]. Содержит те же 6
/// пунктов навигации в том же порядке — [selectedIndex] совпадает.
class AppBottomBar extends ConsumerWidget {
  /// Создаёт [AppBottomBar].
  const AppBottomBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// Индекс активного таба.
  final int selectedIndex;

  /// Колбэк при выборе таба.
  final void Function(int index) onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int wishlistCount = ref.watch(activeWishlistCountProvider);
    final Color profileColor = ref.watch(currentProfileProvider).colorValue;
    final bool hasUpdate =
        ref.watch(updateCheckProvider).valueOrNull?.hasUpdate ?? false;

    final List<NavDestination> destinations = buildNavDestinations(
      context: context,
      wishlistCount: wishlistCount,
      profileColor: profileColor,
      hasUpdate: hasUpdate,
    );

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
                      children: List<Widget>.generate(destinations.length,
                          (int i) {
                        return NavIconButton(
                          destination: destinations[i],
                          active: i == selectedIndex,
                          width: itemWidth,
                          height: kAppBottomBarHeight,
                          onTap: () => onDestinationSelected(i),
                        );
                      }),
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
