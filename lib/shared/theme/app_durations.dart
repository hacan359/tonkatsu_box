// Animation duration scale.

/// Standard animation durations.
///
/// One scale for all UI motion so transitions feel uniform across screens.
/// Deliberate outliers (splash reveal, badge pulses, shimmer sweep) keep
/// their own inline values.
abstract final class AppDurations {
  /// 150ms — micro-interactions: hover, focus, small fades.
  static const Duration fast = Duration(milliseconds: 150);

  /// 200ms — standard widget transitions.
  static const Duration normal = Duration(milliseconds: 200);

  /// 300ms — panel- and page-level transitions.
  static const Duration slow = Duration(milliseconds: 300);

  /// 500ms — emphasized transitions (splash, reveals).
  static const Duration slower = Duration(milliseconds: 500);

  /// Hover delay before a tooltip appears.
  static const Duration tooltipDelay = Duration(milliseconds: 500);
}
