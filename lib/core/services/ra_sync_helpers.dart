import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/media_type.dart';
import '../database/database_service.dart';
import '../../features/collections/providers/collections_provider.dart';

/// Pass [ref] to optimistically update the UI without reloading the list.
/// Status merge rules live in [mergeExternalStatus].
Future<void> syncRaDataToCollectionItem({
  required DatabaseService db,
  required int itemId,
  required int? collectionId,
  required ItemStatus? status,
  ItemStatus? currentStatus,
  Ref? ref,
  DateTime? startedAt,
  DateTime? lastActivityAt,
  DateTime? completedAt,
}) async {
  // RA is the authoritative progress source, so downgrades are allowed
  // (completed → inProgress when the user reset some achievements).
  ItemStatus? effectiveStatus;
  if (status != null && currentStatus != null) {
    effectiveStatus = mergeExternalStatus(
      currentStatus: currentStatus,
      externalStatus: status,
      allowDowngrade: true,
    );
  } else if (status != null) {
    // currentStatus unknown (first write) — accept as is
    effectiveStatus = status;
  }

  if (effectiveStatus != null) {
    await db.updateItemStatus(
        itemId, effectiveStatus, mediaType: MediaType.game);
  }
  await db.updateItemActivityDates(
    itemId,
    startedAt: startedAt,
    lastActivityAt: lastActivityAt,
    completedAt: completedAt,
  );

  if (ref != null) {
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateItemDates(
          itemId,
          startedAt: startedAt,
          lastActivityAt: lastActivityAt,
          completedAt: completedAt,
          status: effectiveStatus,
        );
  }
}
