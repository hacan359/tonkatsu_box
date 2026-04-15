// Компактная строка навигации для pushed sub-screens.
//
// Заменяет AppBar на pushed экранах: стрелка назад + название.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Компактная строка «← Название» для pushed sub-screens.
///
/// Высота 44px, нижний бордер. Используется вместо [AppBar]
/// на экранах внутри tab Navigator.
class SubScreenTitleBar extends StatelessWidget {
  /// Создаёт [SubScreenTitleBar].
  const SubScreenTitleBar({
    required this.title,
    this.onBack,
    super.key,
  });

  /// Заголовок экрана.
  final String title;

  /// Callback кнопки назад. Если null — `Navigator.of(context).pop()`.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            color: AppColors.textTertiary,
            visualDensity: VisualDensity.compact,
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
