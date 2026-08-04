
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Заголовок секции с опциональной кнопкой действия.
///
/// Используется для разделения контента на экранах:
/// Home screen ("My Collections"), Collection screen ("Games", "Movies").
///
/// Если [actionLabel] и [onAction] заданы — показывает текстовую кнопку справа.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;

  /// Текст кнопки действия (например, "See all", "Sort").
  final String? actionLabel;

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title, style: AppTypography.h2),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, AppSpacing.buttonHeightCompact),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!, style: AppTypography.bodySmall),
          ),
      ],
    );
  }
}
