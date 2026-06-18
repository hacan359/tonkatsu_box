import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/media_type.dart';

/// `collection_items` date columns store seconds since the Unix epoch.
int? epochSeconds(DateTime? date) =>
    date == null ? null : date.millisecondsSinceEpoch ~/ 1000;

/// Total across a per-media-type tally (the shape `ImportWriteResult` uses).
int sumByType(Map<MediaType, int> byType) {
  int total = 0;
  for (final int value in byType.values) {
    total += value;
  }
  return total;
}

/// Column map for a status change on an existing item: the new status plus the
/// activity dates the transition implies, mirroring [computeDatesForStatus]
/// (the same rules the per-row `updateItemStatus` applied). Shared by the
/// source adapters whose re-sync merges an external status into a local item.
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
