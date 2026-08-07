import 'engine/recommendation_config.dart';
import 'engine/recommendation_models.dart';

/// Shared vectorizer for name-keyed feature domains (anime / manga): genres
/// and tags at equal weight; the engine's IDF handles discrimination.
TasteTitle? buildNameFeatureTitle({
  required String id,
  required String label,
  required List<String>? genres,
  required List<String>? tags,
  required double? rating,
  required bool isFavorite,
}) {
  final Set<String> features = <String>{
    for (final String g in genres ?? const <String>[])
      if (g.trim().isNotEmpty) g,
    for (final String t in tags ?? const <String>[])
      if (t.trim().isNotEmpty) t,
  };
  if (features.isEmpty) return null;
  return TasteTitle(
    id: id,
    label: label,
    features: <String, double>{
      for (final String f in features) f: RecommendationConfig.genreValue,
    },
    rating: rating,
    isFavorite: isFavorite,
  );
}
