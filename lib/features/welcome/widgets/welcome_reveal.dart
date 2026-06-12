import 'package:flutter/material.dart';

import '../../../shared/theme/app_durations.dart';

/// Fades and slides its [child] up on mount. Stagger a column by passing an
/// increasing [index] — later items start later within the same animation.
class WelcomeReveal extends StatefulWidget {
  const WelcomeReveal({
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 420),
    super.key,
  });

  final Widget child;
  final int index;
  final Duration duration;

  @override
  State<WelcomeReveal> createState() => _WelcomeRevealState();
}

class _WelcomeRevealState extends State<WelcomeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration + AppDurations.slow,
  );

  // Stagger purely through an Interval — no timers means no pending-timer
  // failures in widget tests that don't pumpAndSettle.
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      (widget.index * 0.08).clamp(0.0, 0.5),
      ((widget.index * 0.08) + 0.6).clamp(0.4, 1.0),
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
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
        return Opacity(
          opacity: _animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
