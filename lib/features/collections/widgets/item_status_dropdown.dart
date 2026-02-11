// Универсальный выпадающий список для выбора статуса элемента коллекции.

import 'package:flutter/material.dart';

import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Выпадающий список для выбора статуса элемента коллекции.
///
/// Работает с [ItemStatus] и [MediaType] для контекстно-зависимых меток:
/// - Для игр: "Playing"
/// - Для фильмов/сериалов: "Watching"
/// - Для сериалов: включает [ItemStatus.onHold]
class ItemStatusDropdown extends StatelessWidget {
  /// Создаёт [ItemStatusDropdown].
  const ItemStatusDropdown({
    required this.status,
    required this.mediaType,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  /// Текущий статус.
  final ItemStatus status;

  /// Тип медиа (влияет на метки и доступные статусы).
  final MediaType mediaType;

  /// Callback при изменении статуса.
  final void Function(ItemStatus) onChanged;

  /// Компактный режим (только иконка).
  final bool compact;

  /// Доступные статусы в зависимости от типа медиа.
  List<ItemStatus> get _availableStatuses {
    if (mediaType == MediaType.tvShow) {
      return ItemStatus.values;
    }
    // Для игр и фильмов — без onHold
    return ItemStatus.values
        .where((ItemStatus s) => s != ItemStatus.onHold)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactDropdown();
    }

    return _buildFullDropdown();
  }

  Widget _buildCompactDropdown() {
    return PopupMenuButton<ItemStatus>(
      initialValue: status,
      onSelected: onChanged,
      tooltip: 'Change status',
      icon: Text(
        status.icon,
        style: const TextStyle(fontSize: 20),
      ),
      itemBuilder: (BuildContext context) {
        return _availableStatuses.map((ItemStatus s) {
          return PopupMenuItem<ItemStatus>(
            value: s,
            child: Row(
              children: <Widget>[
                Text(s.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(s.displayLabel(mediaType)),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildFullDropdown() {
    final Color statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withAlpha(76),
        ),
      ),
      child: PopupMenuButton<ItemStatus>(
        initialValue: status,
        onSelected: onChanged,
        tooltip: 'Change status',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(status.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              status.displayLabel(mediaType),
              style: AppTypography.body.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: statusColor,
            ),
          ],
        ),
        itemBuilder: (BuildContext context) {
          return _availableStatuses.map((ItemStatus s) {
            final bool isSelected = s == status;
            return PopupMenuItem<ItemStatus>(
              value: s,
              child: Row(
                children: <Widget>[
                  Text(s.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.displayLabel(mediaType),
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check,
                      size: 18,
                      color: AppColors.gameAccent,
                    ),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case ItemStatus.notStarted:
        return AppColors.textSecondary;
      case ItemStatus.inProgress:
        return AppColors.statusInProgress;
      case ItemStatus.completed:
        return AppColors.statusCompleted;
      case ItemStatus.dropped:
        return AppColors.statusDropped;
      case ItemStatus.planned:
        return AppColors.movieAccent;
      case ItemStatus.onHold:
        return AppColors.statusOnHold;
    }
  }
}

/// Чип для отображения статуса элемента (без возможности редактирования).
class ItemStatusChip extends StatelessWidget {
  /// Создаёт [ItemStatusChip].
  const ItemStatusChip({
    required this.status,
    required this.mediaType,
    this.small = false,
    super.key,
  });

  /// Статус для отображения.
  final ItemStatus status;

  /// Тип медиа (влияет на метки).
  final MediaType mediaType;

  /// Уменьшенный размер.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final Color color = _getStatusColor();

    if (small) {
      return Text(
        status.icon,
        style: const TextStyle(fontSize: 16),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(status.icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.displayLabel(mediaType),
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case ItemStatus.notStarted:
        return AppColors.textSecondary;
      case ItemStatus.inProgress:
        return AppColors.statusInProgress;
      case ItemStatus.completed:
        return AppColors.statusCompleted;
      case ItemStatus.dropped:
        return AppColors.statusDropped;
      case ItemStatus.planned:
        return AppColors.movieAccent;
      case ItemStatus.onHold:
        return AppColors.statusOnHold;
    }
  }
}
