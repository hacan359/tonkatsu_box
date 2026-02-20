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
    final (Color color, String symbol) = switch (type) {
      StatusType.success => (AppColors.success, '✓'),
      StatusType.warning => (AppColors.warning, '!'),
      StatusType.error => (AppColors.error, '✕'),
      StatusType.inactive => (AppColors.textTertiary, '?'),
    };
    final double sz = compact ? 16 : 18;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
          ),
        ),
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
