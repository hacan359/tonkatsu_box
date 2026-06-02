import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

/// Builds a dense context-menu entry: an icon and a label in a single row.
///
/// Replaces the bulky `ListTile` inside a `PopupMenuItem`. [color] tints both
/// the icon and the text (e.g. [AppColors.error] for destructive actions).
PopupMenuItem<T> contextMenuItem<T>({
  required T value,
  required IconData icon,
  required String label,
  Color? color,
}) {
  return PopupMenuItem<T>(
    value: value,
    height: 42,
    child: Row(
      children: <Widget>[
        Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(fontSize: 14, color: color ?? AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}
