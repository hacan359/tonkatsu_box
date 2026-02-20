// Строка настройки — обёртка над ListTile для единого стиля.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// Строка настройки с заголовком, подзаголовком и trailing виджетом.
class SettingsRow extends StatelessWidget {
  /// Создаёт [SettingsRow].
  const SettingsRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.showDivider = false,
    this.compact = false,
    super.key,
  });

  /// Основной текст строки.
  final String title;

  /// Дополнительный текст.
  final String? subtitle;

  /// Иконка слева.
  final IconData? icon;

  /// Виджет справа (Switch, IconButton и т.п.).
  final Widget? trailing;

  /// Обработчик нажатия.
  final VoidCallback? onTap;

  /// Доступность строки.
  final bool enabled;

  /// Показывать разделитель сверху.
  final bool showDivider;

  /// Уменьшенный размер для мобильных экранов.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (showDivider) const Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: compact,
          hoverColor: AppColors.surfaceLight.withValues(alpha: 0.37),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          leading: icon != null ? Icon(icon, size: compact ? 18 : 20) : null,
          title: Text(title),
          subtitle: subtitle != null
              ? Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
              : null,
          trailing: trailing,
          onTap: onTap,
          enabled: enabled,
        ),
      ],
    );
  }
}
