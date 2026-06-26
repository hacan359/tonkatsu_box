import 'dart:math' as math;

/// Sparse feature vector: feature name -> weight. Absent keys are treated as
/// `0.0`.
///
/// Used by the recommendation engine for taste titles, candidates and cluster
/// centroids alike. Operations are read-only and never mutate [values].
class SparseVector {
  /// Creates a vector from a feature -> weight map.
  ///
  /// The map is referenced as-is (not copied) for speed; callers must not
  /// mutate it after handing it over.
  const SparseVector(this.values);

  /// An empty (all-zero) vector.
  const SparseVector.empty() : values = const <String, double>{};

  /// Feature -> weight. Absent features are zero.
  final Map<String, double> values;

  /// Whether the vector has no components.
  bool get isEmpty => values.isEmpty;

  /// Euclidean norm ‖v‖.
  double get norm {
    double sum = 0;
    for (final double v in values.values) {
      sum += v * v;
    }
    return math.sqrt(sum);
  }

  /// Dot product over the keys the two vectors share.
  double dot(SparseVector other) {
    // Iterate the smaller map so the lookups happen against the larger one.
    final bool thisSmaller = values.length <= other.values.length;
    final Map<String, double> small = thisSmaller ? values : other.values;
    final Map<String, double> large = thisSmaller ? other.values : values;
    double sum = 0;
    for (final MapEntry<String, double> e in small.entries) {
      final double? lv = large[e.key];
      if (lv != null) sum += e.value * lv;
    }
    return sum;
  }

  /// Cosine similarity in `[-1, 1]`; `0` when either vector is all-zero.
  double cosine(SparseVector other) {
    final double denom = norm * other.norm;
    if (denom == 0) return 0;
    return dot(other) / denom;
  }

  /// A unit-norm copy, or an empty vector when this one is all-zero.
  SparseVector normalized() {
    final double n = norm;
    if (n == 0) return const SparseVector.empty();
    return SparseVector(<String, double>{
      for (final MapEntry<String, double> e in values.entries)
        e.key: e.value / n,
    });
  }

  /// The (un-normalized) sum of [vectors], each scaled by the matching entry
  /// in [weights]. [vectors] and [weights] must have equal length.
  static SparseVector weightedSum(
    List<SparseVector> vectors,
    List<double> weights,
  ) {
    assert(
      vectors.length == weights.length,
      'vectors and weights must align',
    );
    final Map<String, double> acc = <String, double>{};
    for (int i = 0; i < vectors.length; i++) {
      final double w = weights[i];
      for (final MapEntry<String, double> e in vectors[i].values.entries) {
        acc[e.key] = (acc[e.key] ?? 0) + e.value * w;
      }
    }
    return SparseVector(acc);
  }
}
