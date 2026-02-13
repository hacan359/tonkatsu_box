// Универсальный статус элемента коллекции.

import 'package:flutter/material.dart';

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
  planned('planned'),

  /// На паузе (для сериалов).
  onHold('on_hold');

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
      case ItemStatus.onHold:
        return 'On Hold';
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
      case ItemStatus.onHold:
        return AppColors.statusOnHold;
    }
  }

  /// Иконка статуса (эмодзи).
  String get icon {
    switch (this) {
      case ItemStatus.notStarted:
        return '\u2B1C'; // ⬜
      case ItemStatus.inProgress:
        return '\uD83C\uDFAE'; // 🎮
      case ItemStatus.completed:
        return '\u2705'; // ✅
      case ItemStatus.dropped:
        return '\u23F8\uFE0F'; // ⏸️
      case ItemStatus.planned:
        return '\uD83D\uDCCB'; // 📋
      case ItemStatus.onHold:
        return '\uD83D\uDD50'; // 🕐
    }
  }

  /// Отображаемый текст с иконкой.
  String displayText(MediaType mediaType) => '$icon ${displayLabel(mediaType)}';

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
      case ItemStatus.onHold:
        return 3;
      case ItemStatus.completed:
        return 4;
      case ItemStatus.dropped:
        return 5;
    }
  }
}
