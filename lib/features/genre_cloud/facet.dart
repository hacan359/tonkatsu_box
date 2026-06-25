// Facet dimensions visualized in the preference cloud.
//
// Word colour encodes the media type (see MediaTypeTheme), not the facet — the
// facet is a filter dimension toggled via the legend.

/// A searchable dimension the preference cloud groups words by.
enum Facet {
  /// Genres / book subjects.
  genre('genre'),

  /// Game / visual-novel platforms.
  platform('platform'),

  /// Release decade (bucketed from the year).
  decade('decade');

  const Facet(this.value);

  /// Stable string id.
  final String value;
}
