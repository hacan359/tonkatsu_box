// Навигационная строка настроек — ListTile с chevron_right.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// Навигационная строка настроек: иконка, заголовок, chevron.
class SettingsNavRow extends StatelessWidget {
  /// Создаёт [SettingsNavRow].
  const SettingsNavRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.showDivider = false,
    this.compact = false,
    super.key,
  });

  /// Основной текст строки.
  final String title;

  /// Иконка слева.
  final IconData icon;

  /// Дополнительный текст.
  final String? subtitle;

  /// Обработчик нажатия.
  final VoidCallback onTap;

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
          leading: Icon(
            icon,
            size: compact ? 18 : 20,
            color: AppColors.textSecondary,
          ),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
          ),
          onTap: enabled ? onTap : null,
          enabled: enabled,
        ),
      ],
    );
  }
}
