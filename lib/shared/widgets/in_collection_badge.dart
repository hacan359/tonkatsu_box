import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The one mark for "already in a collection", so every card reads the same.
class InCollectionBadge extends StatelessWidget {
  const InCollectionBadge({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 2 : 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        color: AppColors.onOverlay,
        size: compact ? 8 : 12,
      ),
    );
  }
}
