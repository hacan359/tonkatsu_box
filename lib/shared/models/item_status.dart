// Универсальный статус элемента коллекции.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'media_type.dart';

/// Универсальный статус элемента коллекции.
///
/// Поддерживает контекстно-зависимые метки в зависимости от [MediaType].
enum ItemStatus {
  /// Не начат.
  notStarted('not_started'),

  /// В процессе (играет / смотрит).
  inProgress('in_progress'),

  /// Завершён (пройден / просмотрен).
  completed('completed'),

  /// Брошен.
  dropped('dropped'),

  /// Запланирован.
  planned('planned');

  const ItemStatus(this.value);

  /// Строковое значение для хранения в БД.
  final String value;

  /// Создаёт [ItemStatus] из строки.
  static ItemStatus fromString(String value) {
    for (final ItemStatus status in ItemStatus.values) {
      if (status.value == value) {
        return status;
      }
    }
    return ItemStatus.notStarted;
  }

  /// Отображаемая метка с учётом типа медиа.
  String displayLabel(MediaType mediaType) {
    switch (this) {
      case ItemStatus.notStarted:
        return 'Not Started';
      case ItemStatus.inProgress:
        return mediaType == MediaType.game ? 'Playing' : 'Watching';
      case ItemStatus.completed:
        return 'Completed';
      case ItemStatus.dropped:
        return 'Dropped';
      case ItemStatus.planned:
        return 'Planned';
    }
  }

  /// Цвет для визуальной индикации статуса.
  Color get color {
    switch (this) {
      case ItemStatus.notStarted:
        return AppColors.textSecondary;
      case ItemStatus.inProgress:
        return AppColors.statusInProgress;
      case ItemStatus.completed:
        return AppColors.statusCompleted;
      case ItemStatus.dropped:
        return AppColors.statusDropped;
      case ItemStatus.planned:
        return AppColors.statusPlanned;
    }
  }

  /// Material-иконка статуса.
  IconData get materialIcon {
    switch (this) {
      case ItemStatus.notStarted:
        return Icons.radio_button_unchecked;
      case ItemStatus.inProgress:
        return Icons.play_arrow_rounded;
      case ItemStatus.completed:
        return Icons.check_circle;
      case ItemStatus.dropped:
        return Icons.pause_circle_filled;
      case ItemStatus.planned:
        return Icons.bookmark;
    }
  }

  /// Локализованная метка с учётом типа медиа.
  String localizedLabel(S l, MediaType mediaType) {
    switch (this) {
      case ItemStatus.notStarted:
        return l.statusNotStarted;
      case ItemStatus.inProgress:
        return mediaType == MediaType.game ? l.statusPlaying : l.statusWatching;
      case ItemStatus.completed:
        return l.statusCompleted;
      case ItemStatus.dropped:
        return l.statusDropped;
      case ItemStatus.planned:
        return l.statusPlanned;
    }
  }

  /// Приоритет для сортировки по статусу (меньше = выше в списке).
  ///
  /// Активные элементы показываются первыми, завершённые — последними.
  int get statusSortPriority {
    switch (this) {
      case ItemStatus.inProgress:
        return 0;
      case ItemStatus.planned:
        return 1;
      case ItemStatus.notStarted:
        return 2;
      case ItemStatus.completed:
        return 3;
      case ItemStatus.dropped:
        return 4;
    }
  }
}
