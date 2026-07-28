// Branded loading indicator. Like any Flutter animation it is driven by the
// UI thread — it only animates while heavy work stays off the main isolate
// (layoutGenreCloudAsync, Isolate.run in imports). Pure widget code, so the
// selfhost web target (dev/backlog/selfhost-web) renders it unchanged.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_assets.dart';

/// Animated app-logo loader: each pulse the logo breathes (grows and shrinks
/// back) while rotating a quarter turn, looping until removed.
class LogoLoader extends StatefulWidget {
  /// Creates a [LogoLoader].
  const LogoLoader({this.size = 64, super.key});

  /// Width and height of the loader.
  final double size;

  @override
  State<LogoLoader> createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader>
    with SingleTickerProviderStateMixin {
  /// One pulse: grow to [_scaleMax], shrink back, and complete a quarter
  /// turn. The controller spans four pulses (a full revolution) so a plain
  /// `repeat()` wraps at an identical pose — no restart bookkeeping.
  static const Duration _pulse = Duration(milliseconds: 1200);

  /// Scale bounds of the pulse.
  static const double _scaleMin = 0.85;
  static const double _scaleMax = 1.05;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _pulse * 4)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pulse scale at in-pulse time [t]: min at the edges, max mid-pulse, so
  /// consecutive pulses chain into a continuous breath.
  static double _scaleAt(double t) =>
      _scaleMin + (_scaleMax - _scaleMin) * math.sin(math.pi * t);

  /// Rotation for pulse [quarter] at in-pulse time [t]: eased quarter turn on
  /// top of the turns already completed.
  static double _angleAt(int quarter, double t) =>
      (quarter + Curves.easeInOut.transform(t)) * math.pi / 2;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double cycles = _controller.value * 4;
            final int quarter = cycles.floor().clamp(0, 3);
            final double t = cycles - quarter;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationZ(_angleAt(quarter, t))
                ..scaleByDouble(_scaleAt(t), _scaleAt(t), 1, 1),
              child: child,
            );
          },
          child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
