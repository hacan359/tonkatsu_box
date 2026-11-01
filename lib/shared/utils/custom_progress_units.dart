import 'package:core/models/media_type.dart';

import '../../l10n/app_localizations.dart';

/// A custom card borrows the vocabulary of the type it masquerades as: the
/// fine axis is `current_episode`, the optional coarse one `current_season`.
abstract final class CustomProgressUnits {
  /// Label for the fine progress axis of a custom item displayed as [type].
  static String fineLabel(MediaType type, S l) => switch (type) {
        MediaType.tvShow || MediaType.animation || MediaType.anime =>
          l.customUnitEpisodes,
        MediaType.manga => l.customUnitChapters,
        MediaType.book => l.customUnitPages,
        _ => l.customUnitParts,
      };

  /// Singular noun for one fine unit ("Page"), for a position readout.
  static String fineUnit(MediaType type, S l) => switch (type) {
        MediaType.tvShow || MediaType.animation || MediaType.anime =>
          l.unitEpisode,
        MediaType.manga => l.unitChapter,
        MediaType.book => l.unitPage,
        _ => l.unitPart,
      };

  /// Singular noun for one coarse unit, or `null` when [type] has none.
  static String? groupUnit(MediaType type, S l) {
    if (!hasGroupAxis(type)) return null;
    return type == MediaType.manga ? l.unitVolume : l.unitSeason;
  }

  /// Label for the coarse progress axis, or `null` when [type] has none.
  static String? groupLabel(MediaType type, S l) {
    if (!hasGroupAxis(type)) return null;
    return type == MediaType.manga ? l.customUnitVolumes : l.customUnitSeasons;
  }

  /// Whether a custom item displayed as [type] has a coarse axis at all.
  static bool hasGroupAxis(MediaType type) =>
      type == MediaType.tvShow ||
      type == MediaType.animation ||
      type == MediaType.manga;
}
