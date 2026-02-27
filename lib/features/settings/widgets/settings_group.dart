// Плоская группа настроек с uppercase заголовком и dividers между детьми.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Плоская группа настроек в стиле iOS Settings.
///
/// Отображает необязательный uppercase-заголовок мелким шрифтом
/// и контейнер с детьми, разделёнными тонкими dividers.
class SettingsGroup extends StatelessWidget {
  /// Создаёт [SettingsGroup].
  const SettingsGroup({
    required this.children,
    this.title,
    super.key,
  });

  /// Необязательный заголовок группы (uppercase, мелкий шрифт).
  final String? title;

  /// Дочерние виджеты (обычно [SettingsTile]).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              title!.toUpperCase(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.surfaceBorder,
                    indent: AppSpacing.md,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
