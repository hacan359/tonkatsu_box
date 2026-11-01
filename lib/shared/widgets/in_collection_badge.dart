import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The one mark for "already in a collection", so every card reads the same.
class InCollectionBadge extends StatelessWidget {
  const InCollectionBadge({
    this.compact = false,
    this.scale = 1.0,
    this.icon = Icons.check,
    super.key,
  });

  final bool compact;

  /// Grows the mark with the card it sits on.
  final double scale;

  /// The tappable "open in collection" variant swaps the check for an arrow.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all((compact ? 2 : 4) * scale),
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: AppColors.onOverlay,
        size: (compact ? 8 : 12) * scale,
      ),
    );
  }
}
