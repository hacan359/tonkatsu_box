// Универсальный выпадающий список для выбора статуса элемента коллекции.

import 'package:flutter/material.dart';

import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';

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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (compact) {
      return _buildCompactDropdown(colorScheme);
    }

    return _buildFullDropdown(theme, colorScheme);
  }

  Widget _buildCompactDropdown(ColorScheme colorScheme) {
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

  Widget _buildFullDropdown(ThemeData theme, ColorScheme colorScheme) {
    final Color statusColor = _getStatusColor(colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
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
            const SizedBox(width: 8),
            Text(
              status.displayLabel(mediaType),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
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
                    Icon(
                      Icons.check,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (status) {
      case ItemStatus.notStarted:
        return colorScheme.onSurfaceVariant;
      case ItemStatus.inProgress:
        return colorScheme.tertiary;
      case ItemStatus.completed:
        return colorScheme.primary;
      case ItemStatus.dropped:
        return colorScheme.error;
      case ItemStatus.planned:
        return colorScheme.secondary;
      case ItemStatus.onHold:
        return colorScheme.outline;
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color color = _getStatusColor(colorScheme);

    if (small) {
      return Text(
        status.icon,
        style: const TextStyle(fontSize: 16),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(status.icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            status.displayLabel(mediaType),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (status) {
      case ItemStatus.notStarted:
        return colorScheme.onSurfaceVariant;
      case ItemStatus.inProgress:
        return colorScheme.tertiary;
      case ItemStatus.completed:
        return colorScheme.primary;
      case ItemStatus.dropped:
        return colorScheme.error;
      case ItemStatus.planned:
        return colorScheme.secondary;
      case ItemStatus.onHold:
        return colorScheme.outline;
    }
  }
}
