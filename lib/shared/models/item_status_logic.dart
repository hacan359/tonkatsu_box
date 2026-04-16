// Чистые функции для вычисления статусов и дат активности элемента коллекции.
//
// Используются во всех местах, где меняется `ItemStatus`, `startedAt`,
// `completedAt`, `lastActivityAt`: ручное редактирование в карточке, авто-апдейт
// по прогрессу эпизодов/глав, импорты (Steam / RA / Trakt) и внешний sync
// (Kodi). Централизация гарантирует единообразное поведение и 100% покрытие
// чистыми тестами.
//
// Файл не импортирует Flutter — только Dart core.

import 'item_status.dart';

/// Результат вычисления новых дат при смене статуса.
///
/// Поля `clearStartedAt`/`clearCompletedAt` нужны для вызывающего кода,
/// который использует `CollectionItem.copyWith` с явным затиранием значения
/// (потому что `null` в `copyWith` трактуется как «не менять»).
class StatusDatesUpdate {
  /// Создаёт [StatusDatesUpdate].
  const StatusDatesUpdate({
    required this.status,
    required this.lastActivityAt,
    this.startedAt,
    this.completedAt,
    this.clearStartedAt = false,
    this.clearCompletedAt = false,
  });

  /// Итоговый статус (совпадает с `newStatus`, дублируется для удобства).
  final ItemStatus status;

  /// Новое значение `startedAt`. Если `clearStartedAt == true` — значение
  /// должно быть затёрто (null в БД); иначе — применяется как есть.
  final DateTime? startedAt;

  /// Новое значение `completedAt`. Если `clearCompletedAt == true` —
  /// должно быть затёрто; иначе — применяется как есть.
  final DateTime? completedAt;

  /// Новое значение `lastActivityAt`. Всегда не null.
  final DateTime lastActivityAt;

  /// Нужно ли явно затереть `startedAt` (для `copyWith(clearStartedAt: true)`).
  final bool clearStartedAt;

  /// Нужно ли явно затереть `completedAt`.
  final bool clearCompletedAt;
}

/// Вычисляет новые даты активности при смене статуса.
///
/// Правила:
/// - `notStarted` — обе даты `startedAt`/`completedAt` очищаются
///   (`clearStartedAt = clearCompletedAt = true`).
/// - `inProgress` — `startedAt` ставится если ещё не был, `completedAt`
///   очищается.
/// - `completed` — `completedAt = now`; `startedAt` проставляется если
///   ещё не был.
/// - `planned`/`dropped` — даты не меняются.
/// - `lastActivityAt = now` во всех случаях.
///
/// [now] — момент изменения. UI-сценарий передаёт `DateTime.now()`,
/// внешний sync (Kodi) — дату события из источника.
StatusDatesUpdate computeDatesForStatus({
  required ItemStatus newStatus,
  required DateTime? currentStartedAt,
  required DateTime? currentCompletedAt,
  required DateTime now,
}) {
  switch (newStatus) {
    case ItemStatus.notStarted:
      return StatusDatesUpdate(
        status: newStatus,
        lastActivityAt: now,
        clearStartedAt: true,
        clearCompletedAt: true,
      );
    case ItemStatus.inProgress:
      return StatusDatesUpdate(
        status: newStatus,
        startedAt: currentStartedAt ?? now,
        lastActivityAt: now,
        clearCompletedAt: true,
      );
    case ItemStatus.completed:
      return StatusDatesUpdate(
        status: newStatus,
        startedAt: currentStartedAt ?? now,
        completedAt: now,
        lastActivityAt: now,
      );
    case ItemStatus.planned:
    case ItemStatus.dropped:
      return StatusDatesUpdate(
        status: newStatus,
        startedAt: currentStartedAt,
        completedAt: currentCompletedAt,
        lastActivityAt: now,
      );
  }
}

/// Вычисляет новый статус при ручной установке дат активности.
///
/// Используется когда юзер в карточке двигает `Started`/`Completed`
/// через DatePicker.
///
/// Правила:
/// - Задан `newCompletedAt`, статус ещё не `completed` → `completed`.
/// - Задан `newStartedAt` без `newCompletedAt`, статус `notStarted`/`planned`
///   → `inProgress`.
/// - Иначе — `null` (статус не меняется).
///
/// `dropped` / `completed` / `inProgress` не меняются при установке
/// `startedAt` — юзер уже решил сознательно.
ItemStatus? computeStatusForDates({
  required ItemStatus currentStatus,
  required DateTime? newCompletedAt,
  required DateTime? newStartedAt,
}) {
  if (newCompletedAt != null && currentStatus != ItemStatus.completed) {
    return ItemStatus.completed;
  }
  if (newStartedAt != null &&
      newCompletedAt == null &&
      (currentStatus == ItemStatus.notStarted ||
          currentStatus == ItemStatus.planned)) {
    return ItemStatus.inProgress;
  }
  return null;
}

/// Вычисляет новый статус по прогрессу (эпизоды / главы / тома).
///
/// Используется для:
/// - TV-сериалов (просмотренные эпизоды → статус).
/// - Манги (прочитанные главы/тома → статус).
/// - Аниме (просмотренные эпизоды → статус).
/// - Kodi TV-sync (после обновления `watched_episodes`).
///
/// Параметры — булевы флаги, caller сам решает что считать «прогрессом»
/// и «полным завершением» (это позволяет манге учитывать и главы, и тома).
///
/// Правила:
/// - `dropped` — никогда не меняем (пользовательское решение).
/// - `!hasAnyProgress` — `notStarted` (только если был `inProgress`
///   или `completed`).
/// - `isFullyCompleted` — `completed` (если ещё не был).
/// - Иначе (есть прогресс, но не полное завершение) — `inProgress`
///   (из `notStarted`/`planned`/`completed`).
///
/// Возвращает `null` если статус менять не нужно.
ItemStatus? computeStatusFromProgress({
  required ItemStatus currentStatus,
  required bool hasAnyProgress,
  required bool isFullyCompleted,
}) {
  if (currentStatus == ItemStatus.dropped) return null;

  if (!hasAnyProgress) {
    if (currentStatus == ItemStatus.inProgress ||
        currentStatus == ItemStatus.completed) {
      return ItemStatus.notStarted;
    }
    return null;
  }

  if (isFullyCompleted) {
    if (currentStatus != ItemStatus.completed) {
      return ItemStatus.completed;
    }
    return null;
  }

  // hasAnyProgress && !isFullyCompleted.
  if (currentStatus == ItemStatus.notStarted ||
      currentStatus == ItemStatus.planned ||
      currentStatus == ItemStatus.completed) {
    return ItemStatus.inProgress;
  }
  return null;
}

/// Слияние локального статуса с внешним (external sync).
///
/// Применяется при получении статуса из внешнего источника: RA, Steam,
/// Trakt, Kodi. Гарантирует что данные трекера не затрут решения
/// пользователя.
///
/// Общие правила:
/// - Локальный `dropped` защищён от любой перезаписи — юзер решил бросить.
/// - Внешний `dropped` игнорируется если локальный `notStarted`/`planned`
///   (источник даёт `dropped` по длительному простою, юзер мог просто ещё
///   не начать).
///
/// Параметр [allowDowngrade]:
/// - `false` (по умолчанию, Steam/Trakt/Kodi): внешний статус применяется
///   только если он «выше» локального по приоритету (`notStarted` <
///   `planned` < `inProgress` < `completed` < `dropped`). Юзер-решение
///   «completed» не откатывается если трекер показывает меньше прогресса.
/// - `true` (RA): внешний статус — источник правды, принимаем как есть
///   (после проверки двух правил выше). Используется где трекер надёжно
///   даёт актуальный статус (RA считает достижения).
///
/// Возвращает `null` если менять не нужно.
ItemStatus? mergeExternalStatus({
  required ItemStatus currentStatus,
  required ItemStatus externalStatus,
  bool allowDowngrade = false,
}) {
  if (currentStatus == ItemStatus.dropped) return null;
  if (currentStatus == externalStatus) return null;

  if (externalStatus == ItemStatus.dropped &&
      (currentStatus == ItemStatus.notStarted ||
          currentStatus == ItemStatus.planned)) {
    return null;
  }

  if (allowDowngrade) {
    return externalStatus;
  }

  final int currentPriority = _externalStatusPriority(currentStatus);
  final int externalPriority = _externalStatusPriority(externalStatus);

  if (externalPriority > currentPriority) {
    return externalStatus;
  }
  return null;
}

int _externalStatusPriority(ItemStatus status) {
  switch (status) {
    case ItemStatus.notStarted:
      return 0;
    case ItemStatus.planned:
      return 1;
    case ItemStatus.inProgress:
      return 2;
    case ItemStatus.completed:
      return 3;
    case ItemStatus.dropped:
      return 4;
  }
}
