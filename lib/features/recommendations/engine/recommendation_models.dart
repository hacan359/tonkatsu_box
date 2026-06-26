import 'sparse_vector.dart';

/// A media title reduced to the signal the engine needs: weighted features plus
/// the user's sentiment (rating / favorite).
///
/// Media-type agnostic — movies and TV (and later anime via a different
/// adapter) all map onto this. The engine never sees a [Movie] or [TvShow].
class TasteTitle {
  /// Creates a taste title.
  const TasteTitle({
    required this.id,
    required this.label,
    required this.features,
    this.rating,
    this.isFavorite = false,
  });

  /// Stable identity, e.g. `movie:603` / `tv:1396`.
  final String id;

  /// Display name, used for "because you liked …" headers.
  final String label;

  /// Raw feature -> value (genre name -> [RecommendationConfig.genreValue] for
  /// v1), before IDF weighting is applied by the engine.
  final Map<String, double> features;

  /// User rating on a 1–10 scale, or `null` when unrated.
  final double? rating;

  /// Whether the user favorited this title.
  final bool isFavorite;
}

/// A candidate scored against the taste profile.
class ScoredTitle {
  /// Creates a scored title.
  const ScoredTitle({
    required this.id,
    required this.label,
    required this.score,
  });

  /// Identity matching the candidate's [TasteTitle.id].
  final String id;

  /// Display name.
  final String label;

  /// Final score (higher is a better match).
  final double score;
}

/// One direction of taste — a centroid plus the titles that formed it.
class TasteCluster {
  /// Creates a taste cluster.
  const TasteCluster({
    required this.centroid,
    required this.members,
    required this.topGenres,
  });

  /// Unit-norm centroid vector.
  final SparseVector centroid;

  /// Member titles, strongest (highest weight) first.
  final List<TasteTitle> members;

  /// Genre names ranked by centroid weight — the cluster's defining genres.
  final List<String> topGenres;
}

/// The learned taste profile: clusters of liked titles, an optional anti-signal
/// centroid, and the IDF table used to vectorize everything.
class TasteProfile {
  /// Creates a taste profile.
  const TasteProfile({
    required this.clusters,
    required this.dislikedCenter,
    required this.idf,
    required this.neutral,
  });

  /// Taste clusters, strongest first.
  final List<TasteCluster> clusters;

  /// Unit-norm centroid of disliked titles, or `null` when there are none.
  final SparseVector? dislikedCenter;

  /// Feature -> IDF weight, computed over the completed set.
  final Map<String, double> idf;

  /// Neutral rating used when weighting titles.
  final double neutral;

  /// Whether there is no positive taste signal to recommend from.
  bool get isEmpty => clusters.isEmpty;
}

/// A row of recommendations grouped under one taste cluster.
class RecommendationRow {
  /// Creates a recommendation row.
  const RecommendationRow({
    required this.becauseTitles,
    required this.topGenres,
    required this.items,
  });

  /// Top member labels of the cluster, for the "because you liked …" header.
  final List<String> becauseTitles;

  /// The cluster's defining genres (the aggregation behind the row), shown as
  /// the rationale so coarse-genre misses are at least explainable.
  final List<String> topGenres;

  /// Scored candidates in this row, best score first.
  final List<ScoredTitle> items;
}
