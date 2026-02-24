// Ряд chip-кнопок для выбора статуса элемента коллекции.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Горизонтальный ряд chip-кнопок для выбора статуса.
///
/// Все доступные статусы видны сразу. Выбранный чип выделен цветом
/// и жирным текстом. Тап на чип вызывает [onChanged].
///
/// Доступные статусы зависят от [mediaType]:
/// - Для сериалов: все 6 статусов (включая [ItemStatus.onHold])
/// - Для игр/фильмов: 5 статусов (без [ItemStatus.onHold])
class StatusChipRow extends StatelessWidget {
  /// Создаёт [StatusChipRow].
  const StatusChipRow({
    required this.status,
    required this.mediaType,
    required this.onChanged,
    super.key,
  });

  /// Текущий выбранный статус.
  final ItemStatus status;

  /// Тип медиа (влияет на метки и доступные статусы).
  final MediaType mediaType;

  /// Callback при изменении статуса.
  final void Function(ItemStatus) onChanged;

  /// Доступные статусы в зависимости от типа медиа.
  List<ItemStatus> get _availableStatuses {
    if (mediaType == MediaType.tvShow) {
      return ItemStatus.values;
    }
    return ItemStatus.values
        .where((ItemStatus s) => s != ItemStatus.onHold)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _availableStatuses.map((ItemStatus s) {
        final bool isSelected = s == status;
        return _StatusChip(
          status: s,
          mediaType: mediaType,
          isSelected: isSelected,
          onTap: () => onChanged(s),
        );
      }).toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.mediaType,
    required this.isSelected,
    required this.onTap,
  });

  final ItemStatus status;
  final MediaType mediaType;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? statusColor.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isSelected ? statusColor : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              status.icon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              status.localizedLabel(S.of(context), mediaType),
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? statusColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
