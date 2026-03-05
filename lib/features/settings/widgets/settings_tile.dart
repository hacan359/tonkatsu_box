// Тонкая строка настроек — заголовок + значение + chevron.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Тонкая строка настроек в стиле iOS Settings.
///
/// Содержит заголовок слева, необязательное значение серым цветом
/// (прижато вправо к chevron), trailing-виджет и chevron-иконку.
class SettingsTile extends StatelessWidget {
  /// Создаёт [SettingsTile].
  const SettingsTile({
    required this.title,
    this.value,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    super.key,
  });

  /// Основной текст строки.
  final String title;

  /// Значение справа (серым цветом).
  final String? value;

  /// Обработчик нажатия.
  final VoidCallback? onTap;

  /// Виджет справа (Switch, SegmentedButton и т.п.).
  final Widget? trailing;

  /// Показывать ли chevron_right.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (value != null)
              Expanded(
                flex: 2,
                child: Text(
                  value!,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ?trailing,
            if (showChevron && onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.xs),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
