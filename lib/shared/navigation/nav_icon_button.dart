import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nav_tab.dart';

class NavDestination {
  const NavDestination({
    required this.tab,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final NavTab tab;

  final IconData icon;

  final IconData selectedIcon;

  final String label;

  /// 0 hides the badge.
  final int badgeCount;
}

/// `width × height` is the cell, not the icon — the icon centers inside it.
class NavIconButton extends StatelessWidget {
  const NavIconButton({
    required this.destination,
    required this.active,
    required this.width,
    required this.height,
    required this.onTap,
    super.key,
  });

  final NavDestination destination;

  final bool active;

  final double width;

  final double height;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        active ? AppColors.textPrimary.withAlpha(230) : AppColors.textTertiary;

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

class NavPulsingBadge extends StatefulWidget {
  const NavPulsingBadge({required this.child, super.key});

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
