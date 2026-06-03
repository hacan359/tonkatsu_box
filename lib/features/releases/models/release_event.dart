import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/media_type.dart';

/// One aired-or-upcoming episode of a tracked show, placed on the calendar by
/// its air date.
class ReleaseEvent {
  const ReleaseEvent({
    required this.externalId,
    required this.mediaType,
    required this.showTitle,
    required this.airDate,
    required this.watched,
    required this.isUpcoming,
    this.season,
    this.episode,
    this.posterUrl,
    this.imageType,
    this.cacheImageId,
    this.collectionId,
    this.itemId,
  });

  final int externalId;
  final MediaType mediaType;
  final String showTitle;

  /// Season / episode for TV-episode events; null for manual calendar entries.
  final int? season;
  final int? episode;
  final DateTime airDate;
  final bool watched;
  final bool isUpcoming;
  final String? posterUrl;

  /// Cache routing for [posterUrl] — the item's own image type and cache key,
  /// so the poster reuses the on-disk cache instead of refetching.
  final ImageType? imageType;
  final String? cacheImageId;

  /// A representative collection item for navigation; null if the show is
  /// tracked but no longer in any collection.
  final int? collectionId;
  final int? itemId;
}

/// Everything the Releases calendar needs in one snapshot.
class ReleasesCalendarData {
  const ReleasesCalendarData({
    required this.trackedCount,
    required this.events,
  });

  /// Number of tracked shows (to tell "nothing tracked" from "nothing dated").
  final int trackedCount;

  final List<ReleaseEvent> events;
}
