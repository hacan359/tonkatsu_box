/// Tuning constants for the recommendation engine.
///
/// See `dev/backlog/recommendation_v1_movies.md` for the rationale behind each
/// value. Kept in one place so the algorithm stays tweakable without hunting
/// through the code.
abstract final class RecommendationConfig {
  /// Weight of a present genre in a title's raw feature map (pre-IDF). Binary
  /// for v1: a genre is either present (this value) or absent.
  static const double genreValue = 1.0;

  /// Weight of a completed-but-unrated title — a mild positive signal.
  static const double defaultUnrated = 0.3;

  /// A favorited title gets at least this weight regardless of its rating, so
  /// an explicit "I love this" always pulls the profile toward it.
  static const double favoriteFloor = 0.8;

  /// Neutral rating used to centre weights when nothing is rated at all.
  static const double neutralFallback = 6.0;

  /// Below this many positively-weighted titles, skip clustering and use a
  /// single centroid (small collections don't have enough signal to split).
  static const int minTitlesForClustering = 8;

  /// Lower bound on the number of taste clusters.
  static const int kMin = 2;

  /// Upper bound on the number of taste clusters.
  static const int kMax = 6;

  /// Hard iteration cap for k-means.
  static const int kmeansMaxIter = 50;

  /// How strongly proximity to disliked titles is subtracted from a score.
  static const double penaltyFactor = 0.5;

  /// Candidates scoring below this are dropped (too unlike anything liked).
  static const double scoreThreshold = 0.05;

  /// Neighbours used for kNN rating prediction.
  static const int knnForPrediction = 8;
}
