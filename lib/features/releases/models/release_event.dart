import '../../../shared/models/media_type.dart';

/// One aired-or-upcoming episode of a tracked show, placed on the calendar by
/// its air date.
class ReleaseEvent {
  const ReleaseEvent({
    required this.externalId,
    required this.mediaType,
    required this.showTitle,
    required this.season,
    required this.episode,
    required this.airDate,
    required this.watched,
    required this.isUpcoming,
    this.posterUrl,
    this.collectionId,
    this.itemId,
  });

  final int externalId;
  final MediaType mediaType;
  final String showTitle;
  final int season;
  final int episode;
  final DateTime airDate;
  final bool watched;
  final bool isUpcoming;
  final String? posterUrl;

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
