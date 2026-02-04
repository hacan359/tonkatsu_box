import 'package:flutter/material.dart';

import '../../../shared/models/collection_game.dart';

/// Выпадающий список для выбора статуса игры.
class StatusDropdown extends StatelessWidget {
  /// Создаёт [StatusDropdown].
  const StatusDropdown({
    required this.status,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  /// Текущий статус.
  final GameStatus status;

  /// Callback при изменении статуса.
  final void Function(GameStatus) onChanged;

  /// Компактный режим (только иконка).
  final bool compact;

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
    return PopupMenuButton<GameStatus>(
      initialValue: status,
      onSelected: onChanged,
      tooltip: 'Change status',
      icon: Text(
        status.icon,
        style: const TextStyle(fontSize: 20),
      ),
      itemBuilder: (BuildContext context) {
        return GameStatus.values.map((GameStatus s) {
          return PopupMenuItem<GameStatus>(
            value: s,
            child: Row(
              children: <Widget>[
                Text(s.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(s.label),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildFullDropdown(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(colorScheme).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(colorScheme).withValues(alpha: 0.3),
        ),
      ),
      child: PopupMenuButton<GameStatus>(
        initialValue: status,
        onSelected: onChanged,
        tooltip: 'Change status',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(status.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              status.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _getStatusColor(colorScheme),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: _getStatusColor(colorScheme),
            ),
          ],
        ),
        itemBuilder: (BuildContext context) {
          return GameStatus.values.map((GameStatus s) {
            final bool isSelected = s == status;
            return PopupMenuItem<GameStatus>(
              value: s,
              child: Row(
                children: <Widget>[
                  Text(s.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.label,
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
      case GameStatus.notStarted:
        return colorScheme.onSurfaceVariant;
      case GameStatus.playing:
        return colorScheme.tertiary;
      case GameStatus.completed:
        return colorScheme.primary;
      case GameStatus.dropped:
        return colorScheme.error;
      case GameStatus.planned:
        return colorScheme.secondary;
    }
  }
}

/// Чип для отображения статуса (без возможности редактирования).
class StatusChip extends StatelessWidget {
  /// Создаёт [StatusChip].
  const StatusChip({
    required this.status,
    this.small = false,
    super.key,
  });

  /// Статус для отображения.
  final GameStatus status;

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
            status.label,
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
      case GameStatus.notStarted:
        return colorScheme.onSurfaceVariant;
      case GameStatus.playing:
        return colorScheme.tertiary;
      case GameStatus.completed:
        return colorScheme.primary;
      case GameStatus.dropped:
        return colorScheme.error;
      case GameStatus.planned:
        return colorScheme.secondary;
    }
  }
}
