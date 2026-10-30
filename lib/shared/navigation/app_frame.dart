import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_app_bar.dart';
import 'app_bottom_bar.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';

/// Contour stroke along the screen edge, inside the safe area. Square
/// corners: the frame follows the window, only the zones are rounded.
const double kFrameStroke = 2.5;

/// Rounding of a zone's corners where it meets the content.
const double kFrameRadius = 22;

/// Desktop: how far the floating zones sit from the contour.
const double kFrameZoneMargin = 10;

/// Spike switch for the media-type chevrons: 1 = a third capsule in the
/// middle of the top zone, 2 = a glass band right under the zone.
const int kChevronSpike = 1;

/// The app's glass chrome over full-bleed content: a thin contour along the
/// edges that thickens into the top zone and the menu zone. Content learns
/// what the zones cover through `MediaQuery.padding`.
class AppFrame extends StatelessWidget {
  const AppFrame({
    required this.compact,
    required this.topZone,
    required this.menuZone,
    required this.child,
    super.key,
  });

  /// Phone layout: the menu zone sits at the bottom instead of the left.
  final bool compact;
  final Widget topZone;
  final Widget menuZone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final EdgeInsets sys = media.padding;
    // On the phone the zones grow out of the contour; on desktop they lie
    // on it as capsules with a margin, so nothing sits in a corner.
    final double margin = compact ? 0 : kFrameZoneMargin;
    final double topZoneBottom = sys.top + margin + kAppTopBarHeight;
    final EdgeInsets covered = EdgeInsets.fromLTRB(
      compact ? sys.left : sys.left + margin * 2 + kAppSidebarWidth,
      topZoneBottom,
      sys.right,
      compact ? sys.bottom + kAppBottomBarHeight : sys.bottom,
    );
    const Radius r = Radius.circular(kFrameRadius);

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: MediaQuery(
            data: media.copyWith(padding: covered),
            child: child,
          ),
        ),
        // Zones first, the contour over them: one outlined body.
        if (compact)
          Positioned(
            left: sys.left,
            right: sys.right,
            bottom: sys.bottom,
            child: GlassPill(
              height: null,
              padding: EdgeInsets.zero,
              bordered: false,
              borderRadius: const BorderRadius.only(topLeft: r, topRight: r),
              child: menuZone,
            ),
          )
        else
          Positioned(
            left: sys.left + margin,
            top: topZoneBottom,
            bottom: sys.bottom + margin,
            child: Center(
              child: GlassPill(
                height: null,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(kAppSidebarWidth / 2),
                child: menuZone,
              ),
            ),
          ),
        Positioned(
          top: sys.top + margin,
          left: sys.left + margin,
          right: sys.right + margin,
          child: topZone,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _FrameContourPainter(safe: sys)),
          ),
        ),
      ],
    );
  }
}

/// Two strokes: a translucent surface band with a hairline on its outer
/// edge, so the frame reads on both a dark and a pale backdrop.
class _FrameContourPainter extends CustomPainter {
  const _FrameContourPainter({required this.safe});

  final EdgeInsets safe;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Rect.fromLTRB(
      safe.left + kFrameStroke / 2,
      safe.top + kFrameStroke / 2,
      size.width - safe.right - kFrameStroke / 2,
      size.height - safe.bottom - kFrameStroke / 2,
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = kFrameStroke
        ..color = AppColors.surface.withAlpha(210),
    );
    canvas.drawRect(
      bounds.inflate(kFrameStroke / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.surfaceBorder.withAlpha(140),
    );
  }

  @override
  bool shouldRepaint(_FrameContourPainter oldDelegate) =>
      oldDelegate.safe != safe;
}
