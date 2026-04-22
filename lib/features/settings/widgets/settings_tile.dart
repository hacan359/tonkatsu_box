// Тонкая строка настроек — заголовок + значение + chevron.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    this.leadingAssetPath,
    this.leadingAssetColored = false,
    this.leadingColor,
    this.statusDotColor,
    super.key,
  }) : assert(
          leadingIcon == null || leadingAssetPath == null,
          'leadingIcon и leadingAssetPath взаимоисключающие',
        );

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

  /// SVG-ассет в цветной капсуле (альтернатива [leadingIcon]).
  /// По умолчанию рендерится белым поверх [leadingColor].
  final String? leadingAssetPath;

  /// Если `true` — SVG рендерится в родных цветах на нейтральной подложке
  /// (капсула не заливается [leadingColor]). Для брендовых логотипов.
  final bool leadingAssetColored;

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
            if (leadingIcon != null || leadingAssetPath != null) ...<Widget>[
              _LeadingBubble(
                icon: leadingIcon,
                assetPath: leadingAssetPath,
                assetColored: leadingAssetColored,
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
    required this.assetPath,
    required this.assetColored,
    required this.color,
    required this.size,
    required this.iconSize,
  });

  final IconData? icon;
  final String? assetPath;
  final bool assetColored;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final bool useColored = assetPath != null && assetColored;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: useColored ? AppColors.surfaceLight : color,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      child: assetPath != null
          ? SvgPicture.asset(
              assetPath!,
              // Brand-SVG-иконки из simpleicons имеют внутренние поля —
              // рендерим чуть крупнее, чтобы визуально совпадали с Material.
              width: iconSize * 1.25,
              height: iconSize * 1.25,
              colorFilter: assetColored
                  ? null
                  : const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            )
          : Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}
