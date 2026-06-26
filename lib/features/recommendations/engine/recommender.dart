import 'dart:math' as math;

import 'recommendation_config.dart';
import 'recommendation_models.dart';
import 'sparse_vector.dart';

/// Content-based recommender.
///
/// Construct it from the completed (taste-forming) titles; it computes IDF,
/// per-title weights and a clustered taste profile up front. Then score
/// candidates with [recommend], or use [similarTo] / [predictRating].
///
/// Deterministic: cluster initialization is greedy farthest-point (no RNG), so
/// identical input always yields identical output. Pure Dart — no Flutter, no
/// IO — so the whole thing is unit-testable in isolation.
class Recommender {
  /// Builds the profile from [completed]. Titles with no features contribute
  /// nothing and are dropped.
  Recommender(List<TasteTitle> completed)
      : _completed = completed
            .where((TasteTitle t) => t.features.isNotEmpty)
            .toList(growable: false) {
    _build();
  }

  final List<TasteTitle> _completed;

  late final Map<String, double> _idf;
  late final double _neutral;
  final Map<String, SparseVector> _vectorById = <String, SparseVector>{};
  final Map<String, double> _weightById = <String, double>{};
  late final TasteProfile _profile;

  /// The learned taste profile.
  TasteProfile get profile => _profile;

  void _build() {
    _idf = _computeIdf(_completed);
    _neutral = _computeNeutral(_completed);
    for (final TasteTitle t in _completed) {
      _vectorById[t.id] = _vectorize(t.features);
      _weightById[t.id] = _weightFor(t);
    }
    _profile = _buildProfile();
  }

  /// Scores [candidates] against the taste profile and groups them into rows,
  /// one per cluster. Each candidate lands only in its best-matching cluster.
  ///
  /// Candidates that share an id with a completed title, vectorize to nothing
  /// (only unknown genres), or score below [RecommendationConfig.scoreThreshold]
  /// are dropped. Rows and the candidates inside them come back sorted best
  /// first.
  List<RecommendationRow> recommend(List<TasteTitle> candidates) {
    if (_profile.clusters.isEmpty) return const <RecommendationRow>[];

    final List<List<ScoredTitle>> perCluster = List<List<ScoredTitle>>.generate(
      _profile.clusters.length,
      (_) => <ScoredTitle>[],
    );

    for (final TasteTitle cand in candidates) {
      if (_vectorById.containsKey(cand.id)) continue;
      final SparseVector v = _vectorize(cand.features);
      if (v.isEmpty) continue;

      int bestCluster = -1;
      double bestSim = 0;
      for (int c = 0; c < _profile.clusters.length; c++) {
        final double sim = v.cosine(_profile.clusters[c].centroid);
        if (sim > bestSim) {
          bestSim = sim;
          bestCluster = c;
        }
      }
      if (bestCluster == -1) continue;

      double finalScore = bestSim;
      final SparseVector? disliked = _profile.dislikedCenter;
      if (disliked != null) {
        final double penalty = math.max(v.cosine(disliked), 0);
        finalScore -= RecommendationConfig.penaltyFactor * penalty;
      }
      if (finalScore < RecommendationConfig.scoreThreshold) continue;

      perCluster[bestCluster].add(
        ScoredTitle(id: cand.id, label: cand.label, score: finalScore),
      );
    }

    final List<RecommendationRow> rows = <RecommendationRow>[];
    for (int c = 0; c < _profile.clusters.length; c++) {
      final List<ScoredTitle> items = perCluster[c]
        ..sort((ScoredTitle a, ScoredTitle b) => b.score.compareTo(a.score));
      if (items.isEmpty) continue;
      final TasteCluster cluster = _profile.clusters[c];
      final List<String> because =
          cluster.members.take(3).map((TasteTitle t) => t.label).toList();
      final List<String> genres = cluster.topGenres.take(4).toList();
      rows.add(RecommendationRow(
        becauseTitles: because,
        topGenres: genres,
        items: items,
      ));
    }
    return rows;
  }

  /// Top [limit] titles from [pool] most similar to [target] by cosine,
  /// excluding the target itself. Profile-free — for a "more like this" row on
  /// a title's page.
  List<ScoredTitle> similarTo(
    TasteTitle target,
    List<TasteTitle> pool, {
    int limit = 10,
  }) {
    final SparseVector tv = _vectorize(target.features);
    if (tv.isEmpty) return const <ScoredTitle>[];
    final List<ScoredTitle> scored = <ScoredTitle>[];
    for (final TasteTitle other in pool) {
      if (other.id == target.id) continue;
      final double sim = tv.cosine(_vectorize(other.features));
      if (sim <= 0) continue;
      scored.add(ScoredTitle(id: other.id, label: other.label, score: sim));
    }
    scored.sort((ScoredTitle a, ScoredTitle b) => b.score.compareTo(a.score));
    return scored.take(limit).toList();
  }

  /// Predicts the rating [candidate] would receive, as a cosine-weighted
  /// average over the nearest [RecommendationConfig.knnForPrediction] rated
  /// completed titles. `null` when there is no rated neighbour with positive
  /// similarity.
  double? predictRating(TasteTitle candidate) {
    final SparseVector v = _vectorize(candidate.features);
    if (v.isEmpty) return null;

    final List<({double sim, double rating})> neighbours =
        <({double sim, double rating})>[];
    for (final TasteTitle t in _completed) {
      final double? r = t.rating;
      if (r == null) continue;
      final double sim = v.cosine(_vectorById[t.id]!);
      if (sim <= 0) continue;
      neighbours.add((sim: sim, rating: r));
    }
    if (neighbours.isEmpty) return null;
    neighbours.sort(
      (({double sim, double rating}) a, ({double sim, double rating}) b) =>
          b.sim.compareTo(a.sim),
    );

    double weightedSum = 0;
    double weightTotal = 0;
    for (final ({double sim, double rating}) nb
        in neighbours.take(RecommendationConfig.knnForPrediction)) {
      weightedSum += nb.sim * nb.rating;
      weightTotal += nb.sim;
    }
    if (weightTotal == 0) return null;
    return weightedSum / weightTotal;
  }

  static Map<String, double> _computeIdf(List<TasteTitle> titles) {
    final int n = titles.length;
    final Map<String, int> df = <String, int>{};
    for (final TasteTitle t in titles) {
      for (final String f in t.features.keys) {
        df[f] = (df[f] ?? 0) + 1;
      }
    }
    final Map<String, double> idf = <String, double>{};
    df.forEach((String f, int d) {
      idf[f] = math.log((n + 1) / (d + 1)) + 1;
    });
    return idf;
  }

  static double _computeNeutral(List<TasteTitle> titles) {
    double sum = 0;
    int count = 0;
    for (final TasteTitle t in titles) {
      final double? r = t.rating;
      if (r != null) {
        sum += r;
        count++;
      }
    }
    if (count == 0) return RecommendationConfig.neutralFallback;
    return sum / count;
  }

  /// Maps raw features to `value * idf`, skipping features unseen in the
  /// completed set — an unknown genre carries no taste signal.
  SparseVector _vectorize(Map<String, double> features) {
    final Map<String, double> v = <String, double>{};
    features.forEach((String f, double value) {
      final double? idf = _idf[f];
      if (idf != null) v[f] = value * idf;
    });
    return SparseVector(v);
  }

  /// Per-title weight in `[-1, 1]`-ish: positive pulls the profile toward the
  /// title, negative pushes away. Favorites floor at
  /// [RecommendationConfig.favoriteFloor].
  double _weightFor(TasteTitle t) {
    final double base;
    final double? r = t.rating;
    if (r != null) {
      final double span = math.max(10 - _neutral, _neutral - 1);
      base = span == 0 ? 0 : (r - _neutral) / span;
    } else {
      base = RecommendationConfig.defaultUnrated;
    }
    if (t.isFavorite) {
      return math.max(base, RecommendationConfig.favoriteFloor);
    }
    return base;
  }

  TasteProfile _buildProfile() {
    final List<TasteTitle> positives = <TasteTitle>[];
    final List<TasteTitle> negatives = <TasteTitle>[];
    for (final TasteTitle t in _completed) {
      final double w = _weightById[t.id]!;
      if (w > 0) {
        positives.add(t);
      } else if (w < 0) {
        negatives.add(t);
      }
    }

    final SparseVector? dislikedCenter = negatives.isEmpty
        ? null
        : SparseVector.weightedSum(
            negatives.map((TasteTitle t) => _vectorById[t.id]!).toList(),
            List<double>.filled(negatives.length, 1),
          ).normalized();

    final List<TasteCluster> clusters;
    if (positives.isEmpty) {
      clusters = const <TasteCluster>[];
    } else if (positives.length < RecommendationConfig.minTitlesForClustering) {
      clusters = <TasteCluster>[_clusterOf(positives)];
    } else {
      clusters = _kmeans(positives);
    }

    return TasteProfile(
      clusters: clusters,
      dislikedCenter: dislikedCenter,
      idf: _idf,
      neutral: _neutral,
    );
  }

  TasteCluster _clusterOf(List<TasteTitle> members) {
    final SparseVector centroid = _centroid(members);
    final List<TasteTitle> sorted = members.toList()
      ..sort((TasteTitle a, TasteTitle b) =>
          _weightById[b.id]!.compareTo(_weightById[a.id]!));
    return TasteCluster(
      centroid: centroid,
      members: sorted,
      topGenres: _topGenres(centroid),
    );
  }

  SparseVector _centroid(List<TasteTitle> members) {
    return SparseVector.weightedSum(
      members.map((TasteTitle t) => _vectorById[t.id]!).toList(),
      members.map((TasteTitle t) => _weightById[t.id]!).toList(),
    ).normalized();
  }

  static List<String> _topGenres(SparseVector centroid) {
    final List<MapEntry<String, double>> entries =
        centroid.values.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
              b.value.compareTo(a.value));
    return entries.map((MapEntry<String, double> e) => e.key).toList();
  }

  // Greedy farthest-point init (no RNG) keeps clustering deterministic.
  List<TasteCluster> _kmeans(List<TasteTitle> positives) {
    final int n = positives.length;
    final int k = math.min(
      RecommendationConfig.kMax,
      math.max(RecommendationConfig.kMin, math.sqrt(n / 2).round()),
    );

    final List<SparseVector> vectors =
        positives.map((TasteTitle t) => _vectorById[t.id]!).toList();

    List<SparseVector> centers = _initCenters(vectors, k);
    List<int> assignment = List<int>.filled(n, -1);

    for (int iter = 0; iter < RecommendationConfig.kmeansMaxIter; iter++) {
      final List<int> next = List<int>.generate(
        n,
        (int i) => _nearestCenter(vectors[i], centers),
      );
      if (_listEquals(next, assignment)) break;
      assignment = next;
      centers = _recomputeCenters(positives, assignment, centers.length);
    }

    final List<List<TasteTitle>> groups = _group(positives, assignment, k);
    final List<TasteCluster> clusters = <TasteCluster>[
      for (final List<TasteTitle> g in groups)
        if (g.isNotEmpty) _clusterOf(g),
    ];
    clusters.sort((TasteCluster a, TasteCluster b) =>
        _clusterWeight(b).compareTo(_clusterWeight(a)));
    return clusters;
  }

  /// Greedy farthest-point initialization (deterministic, no RNG): the first
  /// centre is the highest-norm vector (the most defined taste); each next
  /// centre is the vector farthest (lowest max cosine) from the chosen set.
  List<SparseVector> _initCenters(List<SparseVector> vectors, int k) {
    final int n = vectors.length;
    final List<SparseVector> centers = <SparseVector>[];
    final List<bool> chosen = List<bool>.filled(n, false);

    int first = 0;
    double bestNorm = -1;
    for (int i = 0; i < n; i++) {
      final double nv = vectors[i].norm;
      if (nv > bestNorm) {
        bestNorm = nv;
        first = i;
      }
    }
    centers.add(vectors[first]);
    chosen[first] = true;

    while (centers.length < k) {
      int farthest = -1;
      double farthestDist = -1;
      for (int i = 0; i < n; i++) {
        if (chosen[i]) continue;
        double maxSim = -1;
        for (final SparseVector c in centers) {
          final double sim = vectors[i].cosine(c);
          if (sim > maxSim) maxSim = sim;
        }
        final double dist = 1 - maxSim;
        if (dist > farthestDist) {
          farthestDist = dist;
          farthest = i;
        }
      }
      if (farthest == -1) break;
      centers.add(vectors[farthest]);
      chosen[farthest] = true;
    }
    return centers;
  }

  List<SparseVector> _recomputeCenters(
    List<TasteTitle> positives,
    List<int> assignment,
    int centerCount,
  ) {
    final List<List<TasteTitle>> groups =
        _group(positives, assignment, centerCount);
    return <SparseVector>[
      for (final List<TasteTitle> g in groups)
        if (g.isEmpty) const SparseVector.empty() else _centroid(g),
    ];
  }

  static List<List<TasteTitle>> _group(
    List<TasteTitle> positives,
    List<int> assignment,
    int centerCount,
  ) {
    final List<List<TasteTitle>> groups =
        List<List<TasteTitle>>.generate(centerCount, (_) => <TasteTitle>[]);
    for (int i = 0; i < positives.length; i++) {
      groups[assignment[i]].add(positives[i]);
    }
    return groups;
  }

  static int _nearestCenter(SparseVector v, List<SparseVector> centers) {
    int best = 0;
    double bestSim = double.negativeInfinity;
    for (int i = 0; i < centers.length; i++) {
      final double sim = v.cosine(centers[i]);
      if (sim > bestSim) {
        bestSim = sim;
        best = i;
      }
    }
    return best;
  }

  double _clusterWeight(TasteCluster c) {
    double sum = 0;
    for (final TasteTitle t in c.members) {
      sum += _weightById[t.id]!;
    }
    return sum;
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
