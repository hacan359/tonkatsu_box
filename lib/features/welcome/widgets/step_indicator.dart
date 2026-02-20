// Step indicator для Welcome Wizard — номер шага с лейблом.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// Индикатор одного шага wizard'а.
///
/// Показывает номер шага в кружке и опциональный лейбл.
/// Три состояния: done (галочка, зелёный), active (brand), pending (серый).
class StepIndicator extends StatelessWidget {
  /// Создаёт [StepIndicator].
  const StepIndicator({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
    this.onTap,
    this.showLabel = true,
    super.key,
  });

  /// Порядковый номер шага (1-based).
  final int number;

  /// Текстовый лейбл шага.
  final String label;

  /// Текущий активный шаг.
  final bool isActive;

  /// Шаг уже пройден.
  final bool isDone;

  /// Обработчик нажатия на индикатор.
  final VoidCallback? onTap;

  /// Показывать ли лейбл (на узких экранах скрываем неактивные).
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final Color circleColor = isDone
        ? AppColors.success
        : isActive
            ? AppColors.brand
            : AppColors.surfaceBorder;

    final Color textColor = isDone
        ? AppColors.success
        : isActive
            ? AppColors.brand
            : AppColors.textTertiary;

    final Color bgColor = isActive
        ? AppColors.brand.withAlpha(25)
        : isDone
            ? AppColors.success.withAlpha(15)
            : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildCircle(circleColor),
            if (showLabel) ...<Widget>[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isDone
          ? const Icon(Icons.check, size: 13, color: Colors.black)
          : Text(
              '$number',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
    );
  }
}
