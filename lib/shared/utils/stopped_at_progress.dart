import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';

import '../../l10n/app_localizations.dart';
import 'custom_progress_units.dart';

/// The card's "stopped at" line. A `null` [value] means the type tracks
/// progress but nothing is marked yet; a `null` result means it never does.
class StoppedAtProgress {
  const StoppedAtProgress({this.value, this.tooltip});

  final String? value;
  final String? tooltip;

  /// Tracker-backed types (series, Kitsu anime, albums) take their last mark
  /// from the caller; counter types read `current_episode` / `current_season`.
  static StoppedAtProgress? forItem(
    CollectionItem item,
    S l, {
    (int, int)? lastWatchedEpisode,
    (int, int)? lastListenedTrack,
  }) {
    if (item.usesEpisodeTracker) {
      if (lastWatchedEpisode == null) return const StoppedAtProgress();
      final (int season, int episode) = lastWatchedEpisode;
      return StoppedAtProgress(
        value: l.itemMarkEpisodeShort(season, episode),
        tooltip: l.releasesEpisode(season, episode),
      );
    }
    return switch (item.mediaType) {
      MediaType.book => _counter(
          unit: (item.book?.isComic ?? false) ? l.unitIssue : l.unitPage,
          current: item.currentEpisode,
          total: item.book?.pageCount,
        ),
      MediaType.manga => _counter(
          unit: l.unitChapter,
          current: item.currentEpisode,
          total: item.manga?.chapters,
          group: item.currentSeason > 0
              ? _axis(l.unitVolume, item.currentSeason, item.manga?.volumes)
              : null,
        ),
      MediaType.anime => _counter(
          unit: l.unitEpisode,
          current: item.currentEpisode,
          total: item.anime?.episodes,
        ),
      MediaType.audio => _audio(item, l, lastListenedTrack),
      MediaType.custom => _custom(item, l),
      MediaType.game ||
      MediaType.movie ||
      MediaType.tvShow ||
      MediaType.animation ||
      MediaType.visualNovel =>
        null,
    };
  }

  /// Podcast episodes carry a feed id as their position, so "the highest one
  /// listened" means nothing there — only albums get the line.
  static StoppedAtProgress? _audio(
    CollectionItem item,
    S l,
    (int, int)? lastListenedTrack,
  ) {
    if (item.audioItem?.isPodcast ?? true) return null;
    if (lastListenedTrack == null) return const StoppedAtProgress();
    final (int disc, int track) = lastListenedTrack;
    // trackCount spans every disc, so a per-disc position gets no total.
    if (disc > 1) {
      return StoppedAtProgress(value: l.likesTrackWithDisc(track, disc));
    }
    return StoppedAtProgress(
      value: _axis(l.unitTrack, track, item.audioItem?.trackCount),
    );
  }

  static StoppedAtProgress? _custom(CollectionItem item, S l) {
    if (item.customUnitTotal == null && item.customUnitGroupTotal == null) {
      return null;
    }
    final MediaType type = item.displayMediaType;
    final String? groupUnit = CustomProgressUnits.groupUnit(type, l);
    return _counter(
      unit: CustomProgressUnits.fineUnit(type, l),
      current: item.currentEpisode,
      total: item.customUnitTotal,
      group: groupUnit != null && item.currentSeason > 0
          ? _axis(groupUnit, item.currentSeason, item.customUnitGroupTotal)
          : null,
    );
  }

  /// A coarse mark alone (volume set, chapter not) still counts as a
  /// position; the fine axis alone reads as "nothing yet" at zero.
  static StoppedAtProgress _counter({
    required String unit,
    required int current,
    required int? total,
    String? group,
  }) {
    final String fine = _axis(unit, current, total);
    if (group != null) return StoppedAtProgress(value: '$fine · $group');
    return current > 0
        ? StoppedAtProgress(value: fine)
        : const StoppedAtProgress();
  }

  static String _axis(String unit, int current, int? total) =>
      total != null && total > 0 ? '$unit $current / $total' : '$unit $current';
}
