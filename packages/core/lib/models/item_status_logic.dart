import 'item_status.dart';

/// The `clear*` flags exist because `CollectionItem.copyWith` reads `null` as
/// "leave unchanged", so erasing a date needs an explicit signal.
class StatusDatesUpdate {
  const StatusDatesUpdate({
    required this.status,
    required this.lastActivityAt,
    this.startedAt,
    this.completedAt,
    this.clearStartedAt = false,
    this.clearCompletedAt = false,
  });

  final ItemStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime lastActivityAt;
  final bool clearStartedAt;
  final bool clearCompletedAt;
}

/// [now] is injected rather than read from the clock: external sync (Kodi)
/// passes the source event's timestamp, not the moment of import.
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
    // `replaying` is a bare indicator: the item was already completed once,
    // so a replay must not erase or rewrite the existing dates.
    case ItemStatus.replaying:
    case ItemStatus.ignored:
      return StatusDatesUpdate(
        status: newStatus,
        startedAt: currentStartedAt,
        completedAt: currentCompletedAt,
        lastActivityAt: now,
      );
  }
}

/// Matches MAL "times watched" / AniList "repeat": `null` means never
/// completed, so the first completion lands on `0`, not `1`.
int? computeRewatchCountForStatus({
  required ItemStatus oldStatus,
  required ItemStatus newStatus,
  required int? currentCount,
}) {
  if (newStatus != ItemStatus.completed ||
      oldStatus == ItemStatus.completed) {
    return currentCount;
  }
  return currentCount == null ? 0 : currentCount + 1;
}

/// Drives status off a manual date edit. `dropped` / `completed` / `inProgress`
/// are left alone — the user already made that call deliberately.
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

/// Progress arrives as booleans, not counts, so the caller decides what counts
/// as progress — manga weighs both chapters and volumes. `null` means no change.
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

  if (currentStatus == ItemStatus.notStarted ||
      currentStatus == ItemStatus.planned ||
      currentStatus == ItemStatus.completed) {
    return ItemStatus.inProgress;
  }
  return null;
}

/// Folds a tracker status into the local one without overwriting a user
/// decision. `null` means no change.
ItemStatus? mergeExternalStatus({
  required ItemStatus currentStatus,
  required ItemStatus externalStatus,
  bool allowDowngrade = false,
}) {
  if (currentStatus == ItemStatus.dropped) return null;
  if (currentStatus == externalStatus) return null;

  // Trackers report `dropped` on mere idleness, which says nothing about an
  // item the user has not started yet.
  if (externalStatus == ItemStatus.dropped &&
      (currentStatus == ItemStatus.notStarted ||
          currentStatus == ItemStatus.planned)) {
    return null;
  }

  // Only RA sets this: achievement counts are authoritative, so its status may
  // move the item backwards. Others must outrank the local status to apply.
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
    // Above `completed`: an external "replaying" means the user re-engaged
    // with an already finished item.
    case ItemStatus.replaying:
      return 4;
    case ItemStatus.dropped:
      return 5;
    // Top priority so a tracker never pulls an item back out of the pile the
    // user deliberately put it in; only RA's `allowDowngrade` may.
    case ItemStatus.ignored:
      return 6;
  }
}
