// Индикатор статуса с иконкой и текстовой меткой.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Тип статуса для отображения.
enum StatusType {
  /// Успешное состояние.
  success,

  /// Предупреждение.
  warning,

  /// Ошибка.
  error,

  /// Неактивное/неизвестное состояние.
  inactive,
}

/// Компактный индикатор статуса: иконка + текст.
class StatusDot extends StatelessWidget {
  /// Создаёт [StatusDot].
  const StatusDot({
    required this.label,
    required this.type,
    this.compact = false,
    super.key,
  });

  /// Текстовая метка статуса.
  final String label;

  /// Тип статуса (определяет иконку и цвет).
  final StatusType type;

  /// Уменьшенный размер для мобильных экранов.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (type) {
      StatusType.success => (AppColors.success, Icons.check_circle),
      StatusType.warning => (AppColors.warning, Icons.warning_amber),
      StatusType.error => (AppColors.error, Icons.error),
      StatusType.inactive => (AppColors.textTertiary, Icons.help_outline),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: compact ? 16 : 18),
        SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
