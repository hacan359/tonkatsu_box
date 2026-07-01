import '../../l10n/app_localizations.dart';
import '../models/media_type.dart';

/// Resolves the unit labels for a custom item's universal progress tracker.
///
/// A custom card masquerades as a real type, so its progress units take that
/// type's vocabulary: the fine axis (backed by `current_episode`) reads as
/// episodes / chapters / pages / parts, and the optional coarse axis (backed by
/// `current_season`) as seasons / volumes. Types without a natural sub-division
/// expose only the fine axis.
abstract final class CustomProgressUnits {
  /// Label for the fine progress axis of a custom item displayed as [type].
  static String fineLabel(MediaType type, S l) => switch (type) {
        MediaType.tvShow || MediaType.animation || MediaType.anime =>
          l.customUnitEpisodes,
        MediaType.manga => l.customUnitChapters,
        MediaType.book => l.customUnitPages,
        _ => l.customUnitParts,
      };

  /// Label for the coarse progress axis, or `null` when [type] has none.
  static String? groupLabel(MediaType type, S l) => switch (type) {
        MediaType.tvShow || MediaType.animation => l.customUnitSeasons,
        MediaType.manga => l.customUnitVolumes,
        _ => null,
      };

  /// Whether a custom item displayed as [type] has a coarse axis at all.
  static bool hasGroupAxis(MediaType type) =>
      type == MediaType.tvShow ||
      type == MediaType.animation ||
      type == MediaType.manga;
}
