import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/item_status_logic.dart';
import 'package:core/models/media_type.dart';

/// `collection_items` date columns store seconds since the Unix epoch.
int? epochSeconds(DateTime? date) =>
    date == null ? null : date.millisecondsSinceEpoch ~/ 1000;

int sumByType(Map<MediaType, int> byType) {
  int total = 0;
  for (final int value in byType.values) {
    total += value;
  }
  return total;
}

/// A repeat counter is meaningful once completion happened at least once
/// (0 there = "no repeats"); for other statuses 0 is untracked → stay null.
bool repeatIsTracked(ItemStatus status, int repeat) =>
    status == ItemStatus.completed ||
    status == ItemStatus.replaying ||
    repeat > 0;

/// Status-change columns for an existing item, mirroring
/// [computeDatesForStatus] so re-sync matches per-row `updateItemStatus`.
Map<String, dynamic> statusDateColumns(
  ItemStatus newStatus,
  CollectionItem existing, {
  DateTime? now,
}) {
  final StatusDatesUpdate dates = computeDatesForStatus(
    newStatus: newStatus,
    currentStartedAt: existing.startedAt,
    currentCompletedAt: existing.completedAt,
    now: now ?? DateTime.now(),
  );
  return <String, dynamic>{
    'status': dates.status.value,
    'started_at': dates.clearStartedAt ? null : epochSeconds(dates.startedAt),
    'completed_at':
        dates.clearCompletedAt ? null : epochSeconds(dates.completedAt),
    'last_activity_at': epochSeconds(dates.lastActivityAt),
  };
}
