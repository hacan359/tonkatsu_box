import '../models/collection_item.dart';
import '../models/media_type.dart';

/// Card progress: [label] like `12/24` / `V2 · 12/24`, [fraction] 0..1
/// for the bar (null when the total is unknown).
class ItemCardProgress {
  const ItemCardProgress({required this.label, this.fraction});

  final String label;

  final double? fraction;
}

/// Null for untracked types and empty progress. TMDB shows are excluded for
/// now: their marks live in `watched_episodes`, not on the item.
ItemCardProgress? itemCardProgress(CollectionItem item) {
  final int current = item.currentEpisode;
  final int group = item.currentSeason;
  if (current <= 0 && group <= 0) return null;

  final MediaType type = item.displayMediaType;

  int? fineTotal;
  // S = seasons, V = volumes, null = no coarse axis.
  String? groupMark;

  if (item.mediaType == MediaType.custom) {
    fineTotal = item.customUnitTotal;
    groupMark = switch (type) {
      MediaType.manga => 'V',
      MediaType.tvShow || MediaType.animation => 'S',
      _ => null,
    };
  } else {
    switch (type) {
      case MediaType.anime:
        // Kitsu anime run on the episode tracker, so their progress lives in
        // `watched_episodes` — same reason TV shows are excluded here.
        if (item.usesEpisodeTracker) return null;
        fineTotal = item.anime?.episodes;
      case MediaType.manga:
        fineTotal = item.manga?.chapters;
        groupMark = 'V';
      case MediaType.book:
        fineTotal = item.book?.pageCount;
      case MediaType.tvShow:
      case MediaType.animation:
      case MediaType.game:
      case MediaType.movie:
      case MediaType.visualNovel:
      case MediaType.custom:
        return null;
    }
  }

  final StringBuffer buf = StringBuffer();
  if (group > 0 && groupMark != null) {
    buf.write('$groupMark$group');
  }
  if (current > 0) {
    if (buf.isNotEmpty) buf.write(' · ');
    buf.write(
      fineTotal != null && fineTotal > 0 ? '$current/$fineTotal' : '$current',
    );
  }
  if (buf.isEmpty) return null;

  final double? fraction = current > 0 && fineTotal != null && fineTotal > 0
      ? (current / fineTotal).clamp(0.0, 1.0)
      : null;

  return ItemCardProgress(label: buf.toString(), fraction: fraction);
}
