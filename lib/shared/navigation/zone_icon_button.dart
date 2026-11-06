import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'frame_metrics.dart';
import 'nav_icon_button.dart';
import 'service_badges.dart';

/// Round button for the frame's top zone: back, settings, anything else
/// that shares the magnifier's footprint.
class ZoneIconButton extends StatelessWidget {
  const ZoneIconButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.badge = false,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  /// Pulsing dot on the glyph, for "an update is waiting".
  final bool badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget glyph = Icon(
      icon,
      size: kTopBarIconSize,
      color: color ?? AppColors.textTertiary,
    );
    if (badge) glyph = NavPulsingBadge(child: glyph);
    final Widget button = SizedBox(
      width: kFrameZoneButtonSize,
      height: kFrameZoneButtonSize,
      child: InkResponse(
        onTap: onTap,
        radius: kFrameZoneButtonSize * 0.6,
        containedInkWell: false,
        highlightShape: BoxShape.circle,
        child: Center(child: glyph),
      ),
    );
    final String? message = tooltip;
    return message == null ? button : Tooltip(message: message, child: button);
  }
}
