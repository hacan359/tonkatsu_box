// Боковое меню приложения — вертикальное, для широких экранов.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/profile_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';
import '../../core/services/update_service.dart';
import '../theme/app_colors.dart';
import 'liquid_indicator.dart';
import 'nav_destinations.dart';
import 'nav_icon_button.dart';

/// Ширина бокового меню.
const double kAppSidebarWidth = 64;

/// Высота одной кнопки таба.
const double _kItemHeight = 56;

/// Боковое меню приложения (вертикальное).
///
/// Содержит только иконки (без подписей и логотипа), располагает кнопки
/// вертикально по центру и подсвечивает активный пункт анимированным
/// [LiquidIndicator].
///
/// Логотип в меню отсутствует — он размещается в будущем топбаре.
class AppSidebar extends ConsumerWidget {
  /// Создаёт [AppSidebar].
  const AppSidebar({
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
                      children: List<Widget>.generate(destinations.length,
                          (int i) {
                        return NavIconButton(
                          destination: destinations[i],
                          active: i == selectedIndex,
                          width: kAppSidebarWidth,
                          height: _kItemHeight,
                          onTap: () => onDestinationSelected(i),
                        );
                      }),
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
