// Общая кнопка-иконка для [AppSidebar] и [AppBottomBar].

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Описание одного пункта навигации.
class NavDestination {
  /// Создаёт [NavDestination].
  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    this.iconColor,
    this.pulsing = false,
  });

  /// Иконка в неактивном состоянии.
  final IconData icon;

  /// Иконка в активном состоянии.
  final IconData selectedIcon;

  /// Локализованное имя (для Tooltip).
  final String label;

  /// Счётчик для Badge (0 — без бейджа).
  final int badgeCount;

  /// Кастомный цвет иконки в неактивном состоянии (например, цвет профиля
  /// для Settings). Игнорируется в активном состоянии.
  final Color? iconColor;

  /// Показывать пульсирующий Badge (для индикации обновлений).
  final bool pulsing;
}

/// Кнопка-иконка фиксированного размера.
///
/// Используется в [AppSidebar] (вертикальное меню) и [AppBottomBar]
/// (горизонтальное меню). Размер `width × height` задаёт ячейку —
/// иконка центрируется внутри.
class NavIconButton extends StatelessWidget {
  /// Создаёт [NavIconButton].
  const NavIconButton({
    required this.destination,
    required this.active,
    required this.width,
    required this.height,
    required this.onTap,
    super.key,
  });

  /// Описание пункта.
  final NavDestination destination;

  /// Активен ли пункт (выбран).
  final bool active;

  /// Ширина ячейки.
  final double width;

  /// Высота ячейки.
  final double height;

  /// Колбэк при тапе.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = active
        ? AppColors.textPrimary.withAlpha(230)
        : (destination.iconColor ?? AppColors.textTertiary);

    Widget icon = Icon(
      active ? destination.selectedIcon : destination.icon,
      size: 22,
      color: iconColor,
    );

    if (destination.badgeCount > 0) {
      icon = Badge(
        label: Text('${destination.badgeCount}'),
        child: icon,
      );
    } else if (destination.pulsing) {
      icon = NavPulsingBadge(child: icon);
    }

    return SizedBox(
      width: width,
      height: height,
      child: Tooltip(
        message: destination.label,
        waitDuration: const Duration(milliseconds: 400),
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          containedInkWell: false,
          highlightShape: BoxShape.circle,
          child: Center(child: icon),
        ),
      ),
    );
  }
}

/// Маленький пульсирующий Badge для индикации обновления.
class NavPulsingBadge extends StatefulWidget {
  /// Создаёт [NavPulsingBadge].
  const NavPulsingBadge({required this.child, super.key});

  /// Виджет, к которому прикрепляется badge.
  final Widget child;

  @override
  State<NavPulsingBadge> createState() => _NavPulsingBadgeState();
}

class _NavPulsingBadgeState extends State<NavPulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Badge(
          backgroundColor: AppColors.statusInProgress.withAlpha(
            (_animation.value * 255).round(),
          ),
          smallSize: 8,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
