// Тонкая строка настроек — заголовок + значение + chevron.

import 'package:flutter/material.dart';

import '../../../shared/constants/platform_features.dart';
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
    this.subtitle,
    this.value,
    this.valueColor,
    this.titleColor,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.leadingIcon,
    this.leadingColor,
    this.statusDotColor,
    super.key,
  });

  /// Основной текст строки.
  final String title;

  /// Подзаголовок под основным текстом (приглушённый цвет).
  final String? subtitle;

  /// Значение справа (серым цветом по умолчанию).
  final String? value;

  /// Цвет для [value]. Если null — textTertiary.
  final Color? valueColor;

  /// Цвет заголовка (по умолчанию — textPrimary).
  final Color? titleColor;

  /// Обработчик нажатия.
  final VoidCallback? onTap;

  /// Виджет справа (Switch, SegmentedButton и т.п.).
  final Widget? trailing;

  /// Показывать ли chevron_right.
  final bool showChevron;

  /// Иконка в цветной капсуле слева (iOS-style). Если null — капсула скрыта.
  final IconData? leadingIcon;

  /// Цвет фона капсулы с иконкой.
  final Color? leadingColor;

  /// Цветная точка-статус рядом с заголовком (например, зелёная = активно).
  final Color? statusDotColor;

  @override
  Widget build(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final double titleSize = compact ? 12 : 13;
    final double subtitleSize = compact ? 10.5 : 12;
    final double valueSize = compact ? 11.5 : 13;
    final double bubbleSize = compact ? 24 : 28;
    final double bubbleIconSize = compact ? 14 : 17;
    final double vPad = compact ? 10 : 12;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: vPad,
        ),
        child: Row(
          children: <Widget>[
            if (leadingIcon != null) ...<Widget>[
              _LeadingBubble(
                icon: leadingIcon!,
                color: leadingColor ?? AppColors.textTertiary,
                size: bubbleSize,
                iconSize: bubbleIconSize,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.body.copyWith(
                            fontSize: titleSize,
                            color: titleColor ?? AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (statusDotColor != null) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          width: compact ? 7 : 8,
                          height: compact ? 7 : 8,
                          decoration: BoxDecoration(
                            color: statusDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: subtitleSize,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            if (value != null)
              Expanded(
                flex: 2,
                child: Text(
                  value!,
                  style: AppTypography.body.copyWith(
                    fontSize: valueSize,
                    color: valueColor ?? AppColors.textTertiary,
                    fontWeight:
                        valueColor != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ?trailing,
            if (showChevron && onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Icon(
                  Icons.chevron_right,
                  size: compact ? 16 : 18,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Цветная капсула с белой иконкой (iOS-style leading bubble).
class _LeadingBubble extends StatelessWidget {
  const _LeadingBubble({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}
