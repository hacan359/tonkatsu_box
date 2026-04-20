// Плоская группа настроек с uppercase заголовком и dividers между детьми.

import 'package:flutter/material.dart';

import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Плоская группа настроек в стиле iOS Settings.
///
/// Отображает необязательный uppercase-заголовок мелким шрифтом,
/// необязательный подзаголовок и контейнер с детьми, разделёнными тонкими dividers.
class SettingsGroup extends StatelessWidget {
  /// Создаёт [SettingsGroup].
  const SettingsGroup({
    required this.children,
    this.title,
    this.subtitle,
    this.titleIcon,
    this.titleIconColor,
    super.key,
  });

  /// Необязательный заголовок группы (uppercase, мелкий шрифт).
  final String? title;

  /// Необязательный подзаголовок группы (обычный размер, приглушённый цвет).
  final String? subtitle;

  /// Иконка перед заголовком. Если null — не отображается.
  final IconData? titleIcon;

  /// Цвет иконки заголовка. Если null — textTertiary.
  final Color? titleIconColor;

  /// Дочерние виджеты (обычно [SettingsTile]).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final double headerSize = compact ? 10.5 : 12;
    final double subtitleSize = compact ? 10.5 : 12;
    final double iconSize = compact ? 12 : 14;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (titleIcon != null) ...<Widget>[
                      Icon(
                        titleIcon,
                        size: iconSize,
                        color: titleIconColor ?? AppColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        title!.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: headerSize,
                          color: titleIconColor ?? AppColors.textTertiary,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: subtitleSize,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
