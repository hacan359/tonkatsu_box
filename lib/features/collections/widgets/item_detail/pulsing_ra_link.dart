import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';

class PulsingRaLink extends StatefulWidget {
  const PulsingRaLink({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  State<PulsingRaLink> createState() => _PulsingRaLinkState();
}

class _PulsingRaLinkState extends State<PulsingRaLink>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 0.6).animate(
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _opacity,
          builder: (BuildContext context, Widget? child) {
            return Opacity(opacity: _opacity.value, child: child);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: Image.asset(
              'assets/images/ra_logo.png',
              width: 18,
              height: 18,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}
