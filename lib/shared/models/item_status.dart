// Универсальный статус элемента коллекции.

import 'media_type.dart';

/// Универсальный статус элемента коллекции.
///
/// Расширяет [GameStatus] добавлением [onHold] для сериалов.
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
  ///
  /// Поддерживает legacy-значения из [GameStatus]:
  /// - `playing` → [inProgress]
  /// - `not_started` → [notStarted]
  static ItemStatus fromString(String value) {
    // Legacy mapping: GameStatus.playing → ItemStatus.inProgress
    if (value == 'playing') {
      return ItemStatus.inProgress;
    }
    for (final ItemStatus status in ItemStatus.values) {
      if (status.value == value) {
        return status;
      }
    }
    return ItemStatus.notStarted;
  }

  /// Значение для БД с учётом типа медиа.
  ///
  /// Для игр [inProgress] пишется как `playing` (совместимость),
  /// для остальных — как `in_progress`.
  String dbValue(MediaType mediaType) {
    if (this == ItemStatus.inProgress && mediaType == MediaType.game) {
      return 'playing';
    }
    return value;
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
}
