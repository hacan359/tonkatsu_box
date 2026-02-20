// Секция настроек — Card с заголовком, иконкой и дочерними элементами.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Секция настроек с заголовком, иконкой и содержимым.
class SettingsSection extends StatelessWidget {
  /// Создаёт [SettingsSection].
  const SettingsSection({
    required this.title,
    required this.children,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.compact = false,
    super.key,
  });

  /// Заголовок секции.
  final String title;

  /// Иконка секции.
  final IconData? icon;

  /// Цвет иконки (по умолчанию [AppColors.brand]).
  final Color? iconColor;

  /// Подзаголовок секции.
  final String? subtitle;

  /// Виджет справа от заголовка (SourceBadge, кнопка и т.п.).
  final Widget? trailing;

  /// Дочерние виджеты секции.
  final List<Widget> children;

  /// Уменьшенный размер для мобильных экранов.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double padding = compact ? AppSpacing.sm : AppSpacing.md;
    final double iconSize = compact ? 16 : 20;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    color: iconColor ?? AppColors.brand,
                    size: iconSize,
                  ),
                  SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.h3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!, style: AppTypography.bodySmall),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (children.isNotEmpty) ...<Widget>[
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}
