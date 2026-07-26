import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/utils/item_card_progress.dart';
import '../providers/episode_tracker_provider.dart';

/// Card progress for shows whose marks live in the episode tracker rather
/// than on the item ([itemCardProgress] returns null for them). Null for
/// uncategorized items — episode tracking is collection-only.
ItemCardProgress? trackerCardProgress(WidgetRef ref, CollectionItem item) {
  final int? collectionId = item.collectionId;
  if (collectionId == null) return null;
  if (!item.mediaType.isTvBacked) return null;
  final EpisodeTrackerState trackerState =
      ref.watch(episodeTrackerNotifierProvider((
    collectionId: collectionId,
    showId: item.externalId,
    source: item.dataSource,
  )));
  final int watched = trackerState.totalWatchedCount;
  if (watched == 0) return null;
  final int cachedTotal = item.tvShow?.totalEpisodes ?? 0;
  final int total =
      cachedTotal > 0 ? cachedTotal : trackerState.totalEpisodes ?? 0;
  return ItemCardProgress(
    label: total > 0 ? '$watched/$total' : '$watched',
    fraction: total > 0 ? (watched / total).clamp(0.0, 1.0) : null,
  );
}
